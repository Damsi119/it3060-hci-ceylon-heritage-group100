param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'

# Keep large Gradle downloads and temporary build files on the project's drive.
$taskRoot = $PSScriptRoot
$taskStorage = Join-Path $taskRoot '.tooling'
$env:GRADLE_USER_HOME = Join-Path $taskStorage 'gradle'
$env:TEMP = Join-Path $taskStorage 'tmp'
$env:TMP = $env:TEMP
if (Test-Path (Join-Path $taskStorage 'avd\Pixel_6_API_36.ini')) {
    $env:ANDROID_AVD_HOME = Join-Path $taskStorage 'avd'
}
New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME, $env:TEMP | Out-Null

# Avoid this machine's broken WindowsApps PowerShell alias.
$env:Path = ($env:Path -split ';' | Where-Object {
    $_.TrimEnd('\') -ine "$env:LOCALAPPDATA\Microsoft\WindowsApps"
}) -join ';'

Push-Location (Join-Path $taskRoot 'frontend')
try {
    & flutter.bat pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
    if ($DeviceId) {
        & flutter.bat run -d $DeviceId -t lib/member4_main.dart
    } else {
        & flutter.bat run -t lib/member4_main.dart
    }
    if ($LASTEXITCODE -ne 0) { throw 'Flutter launch failed; see the output above.' }
} finally {
    Pop-Location
}
