# Downloads the newest WowVision installer, checks it against the published
# SHA-256 and starts it. For people who would rather run one PowerShell line
# than download an exe by hand:
#   irm https://github.com/wow-vision/WowVision/releases/latest/download/Install-WowVisionUpdater.ps1 | iex
# (Taken from the Sku installer's bootstrap.)
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$base = 'https://github.com/wow-vision/WowVision/releases/latest/download'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('WowVisionSetup-' + [Guid]::NewGuid().ToString('N'))
$metadataPath = Join-Path $temp 'installer-version.txt'
$downloadPath = Join-Path $temp 'WowVisionInstaller.exe'

try {
    New-Item -ItemType Directory -Path $temp | Out-Null
    Write-Host 'Downloading the WowVision installer.'
    Invoke-WebRequest "$base/installer-version.txt" -OutFile $metadataPath -UseBasicParsing
    Invoke-WebRequest "$base/WowVisionInstaller.exe" -OutFile $downloadPath -UseBasicParsing

    $metadata = Get-Content $metadataPath
    $expected = (($metadata | Where-Object { $_ -match '^sha256=' } | Select-Object -First 1) -replace '^sha256=', '').Trim().ToLowerInvariant()
    if ($expected -notmatch '^[0-9a-f]{64}$') { throw 'The published SHA-256 checksum is missing or invalid.' }
    $actual = (Get-FileHash -Algorithm SHA256 -Path $downloadPath).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { throw 'The SHA-256 checksum of the downloaded installer does not match.' }

    Write-Host 'Download verified. Starting the accessible WowVision installer.'
    Start-Process -FilePath $downloadPath
}
catch {
    Write-Error $_
    Read-Host 'Press Enter to close'
    exit 1
}
