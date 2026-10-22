<#
  Preview WAYFARER on this PC (no phone needed): starts an Android emulator in a window,
  installs the app and opens it. Keeps the screen awake for the whole demo.

  Run from the project folder:   powershell -ExecutionPolicy Bypass -File .\demo-on-pc.ps1
  Optional: -Avd Pixel_9a   (default: Pixel_7a)
  First start takes 1-2 minutes. Close the emulator window when you are done.
#>
param([string]$Avd = "Pixel_7a")
$ErrorActionPreference = "Continue"   # adb prints to stderr while no emulator is running yet

$sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk", "C:\dev\android-sdk") |
  Where-Object { $_ -and (Test-Path (Join-Path $_ "platform-tools\adb.exe")) } | Select-Object -First 1
if (-not $sdk) { Write-Host "Android SDK not found."; exit 1 }
$adb = Join-Path $sdk "platform-tools\adb.exe"
$apk = Join-Path $PSScriptRoot "dist\WAYFARER-android-x64-for-PC-emulator.apk"
if (-not (Test-Path $apk)) { Write-Host "Missing $apk"; exit 1 }

$booted = (& $adb shell getprop sys.boot_completed 2>$null)
if ("$booted".Trim() -ne "1") {
  Write-Host "Starting the emulator ($Avd)..."
  Start-Process -FilePath (Join-Path $sdk "emulator\emulator.exe") -ArgumentList "-avd", $Avd, "-gpu", "host", "-no-boot-anim", "-no-snapshot-save"
  $tries = 0
  do { Start-Sleep -Seconds 4; $tries++; $booted = (& $adb shell getprop sys.boot_completed 2>$null) } until ("$booted".Trim() -eq "1" -or $tries -gt 90)
  if ("$booted".Trim() -ne "1") { Write-Host "Emulator did not boot. Check that AVD '$Avd' exists (emulator -list-avds)."; exit 1 }
}
& $adb shell settings put system screen_off_timeout 2147483647 | Out-Null
& $adb shell svc power stayon true | Out-Null
& $adb shell input keyevent KEYCODE_WAKEUP | Out-Null
Write-Host "Installing WAYFARER..."
& $adb install -r $apk | Out-Null
& $adb shell am force-stop com.wayfarer.wayfarer | Out-Null
& $adb shell am start -n com.wayfarer.wayfarer/.MainActivity | Out-Null
Write-Host "Done. The app is open in the emulator window."
Write-Host "Customer: tap 'Try the demo account' (maya@demo.wayfarer.test / Wayfarer#Demo2026)"
