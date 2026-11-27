#!/usr/bin/env bash
set -euo pipefail
: "${IOS_CERTIFICATE_BASE64:?missing certificate}" "${IOS_CERTIFICATE_PASSWORD:?missing certificate password}" "${IOS_PROFILE_BASE64:?missing provisioning profile}" "${IOS_TEAM_ID:?missing team ID}"
work=$(mktemp -d); keychain="$work/almas.keychain-db"; pass=$(openssl rand -hex 24); profile_dest=''
cleanup(){ security delete-keychain "$keychain" >/dev/null 2>&1 || true; if [[ -n "$profile_dest" ]]; then rm -f "$profile_dest"; fi; rm -rf "$work"; }
trap cleanup EXIT
export SIGN_WORK="$work"
python3 - <<'PY'
import os,base64,pathlib
p=pathlib.Path(os.environ['SIGN_WORK'])
for key,name in [('IOS_CERTIFICATE_BASE64','cert.p12'),('IOS_PROFILE_BASE64','profile.mobileprovision')]:
    f=p/name; f.write_bytes(base64.b64decode(os.environ[key],validate=True)); f.chmod(0o600)
PY
security create-keychain -p "$pass" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$pass" "$keychain"
security import "$work/cert.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$keychain"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$pass" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain"
security find-identity -v -p codesigning "$keychain" > "$work/identities"
security cms -D -i "$work/profile.mobileprovision" > "$work/profile.plist"
python3 - <<'PY'
import os,plistlib,pathlib,datetime
w=pathlib.Path(os.environ['SIGN_WORK']); p=plistlib.loads((w/'profile.plist').read_bytes()); team=os.environ['IOS_TEAM_ID']; bundle='iq.sejadalmas.almasShop'
# Read actual bundle ID from generated Runner build configuration below instead of relying on an assumed camelCase.
import re
s=pathlib.Path('ios/Runner.xcodeproj/project.pbxproj').read_text(); ids=set(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);',s)); ids={x for x in ids if not x.endswith('.RunnerTests')}
if len(ids)!=1: raise SystemExit('Cannot resolve Runner bundle identifier')
bundle=ids.pop()
if team not in p['TeamIdentifier'] or p['Entitlements'].get('application-identifier')!=team+'.'+bundle: raise SystemExit('Profile does not match team and exact Runner bundle ID: '+bundle)
if p['ExpirationDate'].replace(tzinfo=datetime.timezone.utc)<=datetime.datetime.now(datetime.timezone.utc): raise SystemExit('Expired provisioning profile')
import hashlib
identities=(w/'identities').read_text(); matches=[hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates'] if hashlib.sha1(c).hexdigest().upper() in identities]
if len(matches)!=1: raise SystemExit('Certificate identity does not match provisioning profile')
(w/'identity').write_text(matches[0]); (w/'uuid').write_text(p['UUID']); (w/'name').write_text(p['Name']); (w/'bundle').write_text(bundle)
method=os.environ['IOS_EXPORT_METHOD'];
if method not in ('app-store-connect','release-testing','debugging','ad-hoc','app-store','development'): raise SystemExit('Unsupported export method')
(w/'export.plist').write_bytes(plistlib.dumps({'method':method,'teamID':team,'signingStyle':'manual','signingCertificate':matches[0],'provisioningProfiles':{bundle:p['Name']}}))
PY
uuid=$(cat "$work/uuid"); profile=$(cat "$work/name"); mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
profile_dest="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/$uuid.mobileprovision"
cp "$work/profile.mobileprovision" "$profile_dest"
cp "$work/profile.mobileprovision" "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
# Set signing only on Runner configurations, not dependency or test targets.
python3 - <<'PY'
import os,pathlib,re
p=pathlib.Path('ios/Runner.xcodeproj/project.pbxproj');s=p.read_text();w=pathlib.Path(os.environ['SIGN_WORK']);bundle=(w/'bundle').read_text();profile=(w/'name').read_text();team=os.environ['IOS_TEAM_ID']; identity=(w/'identity').read_text()
def quote(x): return '"'+x.replace('\\','\\\\').replace('"','\\"')+'"'
def fix(m):
    body=m.group(0)
    if not re.search(r'PRODUCT_BUNDLE_IDENTIFIER = '+re.escape(bundle)+r';',body): return body
    body=re.sub(r'^\s*(?:CODE_SIGN_STYLE|DEVELOPMENT_TEAM|PROVISIONING_PROFILE_SPECIFIER|CODE_SIGN_IDENTITY)(?:\[[^\n]*?\])?\s*=.*?;\s*$', '', body, flags=re.M)
    return body.replace('buildSettings = {','buildSettings = {\n\t\t\t\tCODE_SIGN_STYLE = Manual;\n\t\t\t\tDEVELOPMENT_TEAM = '+quote(team)+';\n\t\t\t\tCODE_SIGN_IDENTITY = '+quote(identity)+';\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = '+quote(profile)+';')
s,n=re.subn(r'buildSettings = \{.*?\n\s*\};',fix,s,flags=re.S)
if 'PROVISIONING_PROFILE_SPECIFIER' not in s: raise SystemExit('Unable to configure Runner signing')
p.write_text(s)
PY
# Existing unsigned Flutter build prepared the generated configuration and dependencies.
mkdir -p signed
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -archivePath "$work/Runner.xcarchive" archive
xcodebuild -exportArchive -archivePath "$work/Runner.xcarchive" -exportPath signed -exportOptionsPlist "$work/export.plist"
rm -f "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
