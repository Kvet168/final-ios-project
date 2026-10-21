<#
  Preview WAYFARER on this PC (no phone needed): starts the Android emulator "wayfarer" in a window,
  installs the app and opens it.

  Run from the project folder:   powershell -ExecutionPolicy Bypass -File .\demo-on-pc.ps1
  First start takes 1-2 minutes. Close the emulator window when you are done.
#>
$ErrorActionPreference = "Continue"   # adb prints to stderr while no emulator is running yet
$sdk = "C:\dev\android-sdk"
$adb = Join-Path $sdk "platform-tools\adb.exe"
$apk = Join-Path $PSScriptRoot "dist\WAYFARER-android-x64-for-PC-emulator.apk"
if (-not (Test-Path $apk)) { Write-Host "Missing $apk"; exit 1 }

$booted = (& $adb shell getprop sys.boot_completed 2>$null)
if ("$booted".Trim() -ne "1") {
  Write-Host "Starting the emulator..."
  Start-Process -FilePath (Join-Path $sdk "emulator\emulator.exe") -ArgumentList "-avd", "wayfarer", "-gpu", "auto", "-no-snapshot-save", "-memory", "3072"
  do { Start-Sleep -Seconds 4; $booted = (& $adb shell getprop sys.boot_completed 2>$null) } until ("$booted".Trim() -eq "1")
}
Write-Host "Installing WAYFARER..."
& $adb install -r $apk | Out-Null
& $adb shell am start -n com.wayfarer.wayfarer/.MainActivity | Out-Null
Write-Host "Done. The app is open in the emulator window."
