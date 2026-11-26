$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$work = Join-Path $source '.build\almas_catalog_native'
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDK 3.32.8 and Android SDK are required.' }
function Run-Flutter { & flutter @args; if ($LASTEXITCODE -ne 0) { throw "Flutter failed: $args" } }
if (!(Test-Path (Join-Path $work 'android'))) {
  Run-Flutter create --org iq.sejadalmas --project-name almas_catalog_native --platforms android $work
}
Copy-Item (Join-Path $source 'pubspec.yaml') $work -Force
Copy-Item (Join-Path $source 'lib\*') (Join-Path $work 'lib') -Force
Remove-Item (Join-Path $work 'test\widget_test.dart') -ErrorAction SilentlyContinue
Copy-Item (Join-Path $source 'test\*') (Join-Path $work 'test') -Force
$manifest = Join-Path $work 'android\app\src\main\AndroidManifest.xml'
$s = Get-Content $manifest -Raw
if ($s -notmatch 'android.permission.INTERNET') { $s = $s.Replace('<application','<uses-permission android:name="android.permission.INTERNET" />' + "`n    <application") }
if ($s -notmatch 'android:usesCleartextTraffic=') { $s = $s.Replace('<application','<application android:usesCleartextTraffic="false" android:allowBackup="false"') }
$s = $s.Replace('android:label="almas_catalog_native"','android:label="Almas Catalog"')
[System.IO.File]::WriteAllText($manifest,$s,[System.Text.UTF8Encoding]::new($false))
Push-Location $work
try {
  Run-Flutter pub get
  Run-Flutter analyze --no-fatal-infos --no-fatal-warnings
  Run-Flutter test
  Run-Flutter build apk --release --target-platform android-arm,android-arm64,android-x64
  New-Item -ItemType Directory -Force (Join-Path $source 'dist') | Out-Null
  Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $source 'dist\AlmasCatalogNative-1.0.4-test.apk') -Force
} finally { Pop-Location }
Write-Host 'APK: dist\AlmasCatalogNative-1.0.4-test.apk'
