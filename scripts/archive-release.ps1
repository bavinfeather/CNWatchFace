param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$KeyPath = "$PSScriptRoot\..\keys\CNWatchFace-release.der",
    [string]$ReleaseNotesPath = "$PSScriptRoot\..\RELEASE_NOTES.md"
)

$projectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$sdkJar = 'C:\Users\bavin\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeybrains.jar'
$expectedKeyHash = '51D8BE964D98E7DC32EF6BCD529E8DA3165E43BCCC0986EB150F9453A88F8FB9'
$archiveDir = Join-Path $projectRoot "releases\$Version"
$iqPath = Join-Path $archiveDir "CNWatchFace-$Version.iq"
$logPath = Join-Path $archiveDir 'build.log'

if (!(Test-Path -LiteralPath $KeyPath)) { throw "Release key not found: $KeyPath" }
if (!(Test-Path -LiteralPath $sdkJar)) { throw "Connect IQ SDK not found: $sdkJar" }
if (!(Test-Path -LiteralPath $ReleaseNotesPath)) { throw "Release notes not found: $ReleaseNotesPath" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $KeyPath).Hash -ne $expectedKeyHash) {
    throw 'Release key fingerprint does not match the original store signing key.'
}
$versionFile = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
if ($versionFile -ne $Version) {
    throw "VERSION file ($versionFile) does not match requested release ($Version)."
}
if (Test-Path -LiteralPath $archiveDir) {
    throw "Release archive already exists and will not be overwritten: $archiveDir"
}

New-Item -ItemType Directory -Force -Path $archiveDir | Out-Null
Push-Location $projectRoot
try {
    & java '-Xms1g' '-Dfile.encoding=UTF-8' '-Dapple.awt.UIElement=true' -jar $sdkJar -o $iqPath -f 'monkey.jungle' -y $KeyPath -e -r -w 2>&1 | Tee-Object -FilePath $logPath
    if ($LASTEXITCODE -ne 0) { throw "Export failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

$iqHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $iqPath).Hash
@(
    "SHA256  CNWatchFace-$Version.iq",
    $iqHash
) | Set-Content -LiteralPath (Join-Path $archiveDir 'SHA256SUMS.txt') -Encoding ascii

Copy-Item -LiteralPath (Join-Path $projectRoot 'manifest.xml'),(Join-Path $projectRoot 'monkey.jungle'),(Join-Path $projectRoot 'VERSION'),$ReleaseNotesPath -Destination $archiveDir -Force
Write-Output "Archived release ${Version}: $iqPath"
