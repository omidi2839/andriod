#!/usr/bin/env bash
set -euo pipefail
src="$(cd "$(dirname "$0")" && pwd)"
work="$src/.build/almas_catalog_native"
command -v flutter >/dev/null || { echo 'Flutter SDK 3.32.8 and Android SDK required'; exit 1; }
if [[ ! -d "$work/android" ]]; then flutter create --org iq.sejadalmas --project-name almas_catalog_native --platforms android "$work"; fi
cp "$src/pubspec.yaml" "$work/"
cp "$src/lib/"*.dart "$work/lib/"
rm -f "$work/test/widget_test.dart"
cp "$src/test/"*.dart "$work/test/"
python3 - "$work/android/app/src/main/AndroidManifest.xml" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
if 'android.permission.INTERNET' not in s:s=s.replace('<application','<uses-permission android:name="android.permission.INTERNET" />\n    <application',1)
if 'android:usesCleartextTraffic=' not in s:s=s.replace('<application','<application android:usesCleartextTraffic="false" android:allowBackup="false"',1)
s=s.replace('android:label="almas_catalog_native"','android:label="Almas Catalog"')
p.write_text(s)
PY
cd "$work"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
mkdir -p "$src/dist"
cp build/app/outputs/flutter-apk/app-release.apk "$src/dist/AlmasCatalogNative-1.0.4-test.apk"
