$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Install Flutter and Android Studio, then run flutter doctor.' }
if (!(Test-Path 'android/app/src/main/AndroidManifest.xml')) {
    flutter create --platforms=android,ios --org iq.sejadalmas --project-name almas_shop .
    if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }
}
$p = 'android/app/src/main/AndroidManifest.xml'
$s = [IO.File]::ReadAllText((Join-Path $PSScriptRoot $p))
if ($s -notmatch 'android.permission.INTERNET') { $s = $s.Replace('<application', '<uses-permission android:name="android.permission.INTERNET" />' + "`n    <application") }
$s = $s.Replace('android:label="almas_shop"','android:label="سجاد الألماس"')
if ($s -notmatch 'android:usesCleartextTraffic') { $s=$s.Replace('<application','<application android:usesCleartextTraffic="false"') }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot $p), $s, [System.Text.UTF8Encoding]::new($false))
# Remove only generated default counter-app test; it does not test this app.
if (Test-Path 'test/widget_test.dart') { $t=Get-Content 'test/widget_test.dart' -Raw; if ($t -match 'MyApp\(' -and $t -match 'counter') { Remove-Item 'test/widget_test.dart' } }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analyze failed; inspect output before building.' }
