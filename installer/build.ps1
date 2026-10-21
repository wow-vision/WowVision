<#
build.ps1 - build the WowVision installer and the file that describes it.

  .\installer\build.ps1
      1. dotnet build -c Release (installer + self-test).
      2. Copy WowVisionInstaller.exe into installer\dist\.
      3. Write installer\dist\installer-version.txt: version= and sha256= of
         THAT file (what installed copies check before they replace themselves).
      4. Check the pair with the self-test's "versionfile" command.

  .\installer\build.ps1 -RunTests
      The same, plus the network-free self-test suite ("offline") before the
      files are written. The Installer workflow runs this.

  .\installer\build.ps1 -UploadTo beta
      The same, then attach the exe, the version file and the bootstrap script
      to that existing release of wow-vision/WowVision (needs gh signed in with
      write access). The Installer workflow normally does this by itself after
      every release and every beta; this is for doing it by hand.

  Bump <Version> in WowVisionInstaller\WowVisionInstaller.csproj when the
  installer changes: an installed copy only replaces itself with a HIGHER
  version, so an unchanged number keeps everyone on what they have.
#>
param(
    [switch]$RunTests,
    [string]$UploadTo,
    [string]$Repo = 'wow-vision/WowVision'
)

# NOT 'Stop': native tools (gh, dotnet) write normal status to stderr, which
# PowerShell 5.1 turns into a fatal error under 'Stop'. $LASTEXITCODE is checked
# after every native call instead.
$ErrorActionPreference = 'Continue'

$Root        = $PSScriptRoot
$Csproj      = Join-Path $Root 'WowVisionInstaller\WowVisionInstaller.csproj'
$TestCsproj  = Join-Path $Root 'WowVisionSelfTest\WowVisionSelfTest.csproj'
$ExeBuilt    = Join-Path $Root 'WowVisionInstaller\bin\Release\net48\WowVisionInstaller.exe'
$SelfTestExe = Join-Path $Root 'WowVisionSelfTest\bin\Release\net48\WowVisionSelfTest.exe'
$Dist        = Join-Path $Root 'dist'
$ExeDist     = Join-Path $Dist 'WowVisionInstaller.exe'
$VersionFile = Join-Path $Dist 'installer-version.txt'
$Bootstrap   = Join-Path $Root 'bootstrap\Install-WowVisionUpdater.ps1'

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Run($what, [scriptblock]$do) {
    Info "  $what"
    & $do
    if ($LASTEXITCODE -ne 0) { throw "FAILED ($LASTEXITCODE): $what" }
}

# The version as the installer itself formats it (AppVersion.Number): trailing
# zero components dropped, never below major.minor.
function Get-InstallerVersion {
    $fv = (Get-Item $ExeDist).VersionInfo.FileVersion    # e.g. "1.0.0.0"
    if (-not $fv) { throw "No version resource in $ExeDist." }
    $parts = @($fv.Split('.'))
    $last = $parts.Count - 1
    while ($last -gt 1 -and $parts[$last] -eq '0') { $last-- }
    return ($parts[0..$last] -join '.')
}

Run "dotnet build installer (Release)" { dotnet build $Csproj -c Release -nologo -clp:NoSummary }
Run "dotnet build self-test (Release)" { dotnet build $TestCsproj -c Release -nologo -clp:NoSummary }
if ($RunTests) { Run "self-test: offline" { & $SelfTestExe offline } }

New-Item -ItemType Directory -Force $Dist | Out-Null
Copy-Item $ExeBuilt $ExeDist -Force -ErrorAction Stop
$ver = Get-InstallerVersion
$hash = (Get-FileHash $ExeDist -Algorithm SHA256).Hash.ToLower()
# No BOM, LF only: the parser tolerates both, but there is no reason to test it.
[System.IO.File]::WriteAllText($VersionFile, "version=$ver`nsha256=$hash`n", (New-Object System.Text.UTF8Encoding($false)))
Info "  installer-version.txt: version=$ver sha256=$($hash.Substring(0,12))..."
Run "self-test: versionfile" { & $SelfTestExe versionfile $VersionFile }

if ($UploadTo) {
    # Both in ONE call, so the exe and its checksum can never land separately.
    Run "attach to $UploadTo on $Repo" {
        gh release upload $UploadTo $ExeDist $VersionFile $Bootstrap --repo $Repo --clobber
    }
}
