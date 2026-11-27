import os, base64, re
from pathlib import Path
keys=['ANDROID_KEYSTORE_BASE64','ANDROID_STORE_PASSWORD','ANDROID_KEY_ALIAS','ANDROID_KEY_PASSWORD']
if any(not os.environ.get(k) for k in keys): raise SystemExit('Missing Android signing secrets')
app=Path('android/app'); p=app/'build.gradle.kts'
if not p.exists(): raise SystemExit('Expected Flutter Kotlin Gradle template; inspect and adapt signing')
s=p.read_text()
if not re.search(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',s): raise SystemExit('Unknown release signing template; refusing to build with debug signing')
(app/'release-upload.jks').write_bytes(base64.b64decode(os.environ[keys[0]],validate=True)); (app/'release-upload.jks').chmod(0o600)
# Read credentials from environment directly; no credentials written to Gradle file.
block='''android {
    signingConfigs {
        create("almasRelease") {
            storeFile = file("release-upload.jks")
            storePassword = System.getenv("ANDROID_STORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }
'''
if 'android {' not in s: raise SystemExit('Android Gradle block missing')
s=s.replace('android {',block,1)
s=re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("almasRelease")',s)
p.write_text(s)
