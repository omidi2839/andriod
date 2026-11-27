#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo 'Install Flutter first'; exit 1; }
# Generate native runners separately, so Flutter never overwrites our Dart source or pubspec.
if [[ ! -f android/app/src/main/AndroidManifest.xml || ! -f ios/Runner/Info.plist ]]; then
  temp=$(mktemp -d); trap 'rm -rf "$temp"' EXIT
  flutter create --no-pub --platforms=android,ios --org iq.sejadalmas --project-name almas_shop "$temp/almas_shop"
  for platform in android ios; do
    if [[ ! -d "$platform" ]]; then cp -R "$temp/almas_shop/$platform" .; fi
  done
  if [[ ! -f .metadata ]]; then cp "$temp/almas_shop/.metadata" .; fi
fi
python3 - <<'PY'
from pathlib import Path
import plistlib
p=Path('android/app/src/main/AndroidManifest.xml');s=p.read_text()
if 'android.permission.INTERNET' not in s:s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET" />\n    <application',1)
if 'android:usesCleartextTraffic' not in s:s=s.replace('<application','<application android:usesCleartextTraffic="false"',1)
s=s.replace('android:label="almas_shop"','android:label="سجاد الألماس"');p.write_text(s)
p=Path('ios/Runner/Info.plist');d=plistlib.loads(p.read_bytes());d['CFBundleDisplayName']='سجاد الألماس';p.write_bytes(plistlib.dumps(d,sort_keys=False))
PY
flutter pub get
