# Renders what the group health monitor makes a voice say, for measure.py.
# See README.md in this folder for the whole procedure.
#
#   powershell -ExecutionPolicy Bypass -File render.ps1 -List
#   powershell -ExecutionPolicy Bypass -File render.ps1 -Voice "Hedda Desktop,Katja"
#
# -List prints every voice this PC has: the SAPI list (what WoW sees) and
# the OneCore list (Windows' Narrator voices). A OneCore voice does not need
# to be in the SAPI list: SAPI loads it straight from its own list, so no
# registry change is needed to measure one.
#
# -Voice takes parts of voice names, separated by commas (one quoted
# string: powershell -File passes a list as separate words). Each must
# match exactly one voice (case does not matter); "Hedda" alone matches
# both Heddas, so the script stops and lists them. The name, lowercased,
# becomes the profile key: the monitor picks a profile when the key is part
# of the game's voice name.
#
# Per voice the number 3 is rendered at <pitch absmiddle> -10..10, at the
# monitor's default rate 7, three ways (retail/groupHealth/logic.lua,
# GroupHealth.segment and module:announce):
#   plain  the number alone (the reference: absmiddle 0 is 0 semitones)
#   low    the LOW copy: the number spoken, then a silent copy at rate 10
#   high   the HIGH copy: a silent copy at rate 10, then the number spoken
# As in the game, the LOW copy, spoken or silent, carries the pad after the
# number (GroupHealth.uniquePad, here the one for count 1) and, with
# -EndPause, the pause after that (GroupHealth.END_PAUSE, read from
# logic.lua so the two cannot drift apart; a profile's endPause).
# (the silent copy is sped up as the monitor does it; measured 2026-11-02,
# that moves the audible copy's pitch by less than 0.15 semitones at the
# levels in use)
# If the monitor's markup changes, change it here too and measure again.

param(
    [string]$Voice,
    [switch]$List,
    [string]$Out = (Join-Path $PSScriptRoot "render"),
    [int]$Rate = 7,
    [switch]$EndPause
)

$ErrorActionPreference = "Stop"
$names = @($Voice -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })

function Get-AllVoices {
    $result = @()
    $sapi = (New-Object -ComObject SAPI.SpVoice).GetVoices()
    for ($i = 0; $i -lt $sapi.Count; $i++) {
        $token = $sapi.Item($i)
        $result += [pscustomobject]@{ List = "SAPI"; Name = $token.GetDescription(); Token = $token }
    }
    $category = New-Object -ComObject SAPI.SpObjectTokenCategory
    $category.SetId("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", $false)
    $oneCore = $category.EnumerateTokens()
    for ($i = 0; $i -lt $oneCore.Count; $i++) {
        $token = $oneCore.Item($i)
        $name = $token.GetDescription()
        # A OneCore voice already copied into the SAPI list is listed once.
        if (-not ($result | Where-Object { $_.Name -eq $name })) {
            $result += [pscustomobject]@{ List = "OneCore"; Name = $name; Token = $token }
        }
    }
    return $result
}

$all = Get-AllVoices

if ($List -or $names.Count -eq 0) {
    foreach ($v in $all) {
        Write-Output "$($v.List): $($v.Name)"
    }
    if ($names.Count -eq 0) {
        exit 0
    }
}

$chosen = @()
foreach ($part in $names) {
    $found = @($all | Where-Object { $_.Name.ToLower().Contains($part.ToLower()) })
    if ($found.Count -ne 1) {
        Write-Output "`"$part`" matches $($found.Count) voices:"
        foreach ($m in $found) {
            Write-Output "  $($m.List): $($m.Name)"
        }
        Write-Output "Give a part of the name that matches exactly one."
        exit 1
    }
    $chosen += [pscustomobject]@{ Key = $part.ToLower(); Voice = $found[0] }
}

New-Item -ItemType Directory -Force $Out | Out-Null
$manifestPath = Join-Path $Out "voices.json"
$manifest = @{}
if (Test-Path $manifestPath) {
    $old = Get-Content $manifestPath -Raw | ConvertFrom-Json
    foreach ($p in $old.PSObject.Properties) {
        $manifest[$p.Name] = $p.Value
    }
}

$speaker = New-Object -ComObject SAPI.SpVoice
# The LOW copy's end as module:announce builds it: the pad, then the pause.
$pad = " " + ([string][char]0xA0) * 2
$lowEnd = $pad
if ($EndPause) {
    $logic = Join-Path $PSScriptRoot "..\..\retail\groupHealth\logic.lua"
    $match = Select-String -Path $logic -Pattern "^GroupHealth\.END_PAUSE = '(.*)'$"
    if ($null -eq $match) {
        Write-Output "GroupHealth.END_PAUSE not found in $logic"
        exit 1
    }
    $lowEnd = $pad + $match.Matches[0].Groups[1].Value
}
$format = New-Object -ComObject SAPI.SpAudioFormat
$format.Type = 22 # 22 kHz, 16 bit, mono

# $rate: the silent copy is spoken at the engine's fastest rate, 10, as
# the monitor does (GroupHealth.ratePoints); the audible copy at $Rate.
function Segment($volume, $pitch, $words, $rate) {
    $inner = "<pitch absmiddle=`"$pitch`">$words</pitch>"
    if ($null -ne $rate) { $inner = "<rate absspeed=`"$rate`">$inner</rate>" }
    "<volume level=`"$volume`">$inner</volume>"
}

foreach ($c in $chosen) {
    $file = $c.Key -replace "[^a-z0-9]+", "_"
    Write-Output "Rendering $($c.Voice.Name) as `"$($c.Key)`""
    $speaker.Voice = $c.Voice.Token
    $speaker.Rate = $Rate
    foreach ($p in -10..10) {
        $texts = @{
            plain = (Segment 100 $p "3")
            low = (Segment 100 $p "3$lowEnd") + (Segment 0 $p "3" 10)
            high = (Segment 0 $p "3$lowEnd" 10) + (Segment 100 $p "3")
        }
        foreach ($kind in $texts.Keys) {
            $stream = New-Object -ComObject SAPI.SpFileStream
            $stream.Format = $format
            $stream.Open((Join-Path $Out "$($file)_$($kind)$p.wav"), 3, $false)
            $speaker.AudioOutputStream = $stream
            [void]$speaker.Speak($texts[$kind], 8) # 8: the text is SAPI XML
            $stream.Close()
        }
    }
    $manifest[$c.Key] = [pscustomobject]@{
        file = $file
        name = $c.Voice.Name
        list = $c.Voice.List
        rate = $Rate
        endPause = [bool]$EndPause
        date = (Get-Date -Format "yyyy-MM-dd")
    }
}

$manifest | ConvertTo-Json | Set-Content -Encoding utf8 $manifestPath
Write-Output "Done. Next: measure.py (see README.md)."
