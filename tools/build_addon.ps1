<#
================================================================================
  build_addon.ps1 - assemble the Infovox 330 NVDA add-on

  Combines the add-on source tree in this repository with the proprietary
  Infovox 330 engine files and voice data that YOU supply, and produces
  dist\infovox330.nvda-addon.

  Usage, from anywhere:

      pwsh -File tools\build_addon.ps1 -Engine "C:\path\to\Ivx330" -Voices "C:\path\to\Voices Ivx330"

  If -Engine and -Voices are omitted the script looks for folders named
  "Ivx330" and "Voices Ivx330" next to the repository root, which is how the
  original working folder was laid out.

  The engine folder must contain, at minimum:
      Ivx330nt.dll      the Infovox 330 SAPI 4 engine
      Sx32w.dll         engine support library
      cryput.dll        CrypKey licensing runtime the engine links against

  The voices folder must contain VoiceDescriptions.txt plus the .ddb, .phm
  and .ivx files for every voice you want included.

  None of those files are distributed with this repository. See docs/BUILDING.md.
================================================================================
#>

[CmdletBinding()]
param(
    [string] $Engine,
    [string] $Voices,
    [string] $OutFile
)

$ErrorActionPreference = 'Stop'

# --- locate things -----------------------------------------------------------

$repoRoot = Split-Path -Parent $PSScriptRoot
$addonSrc = Join-Path $repoRoot 'addon'
$buildDir = Join-Path $repoRoot 'build\infovox330'
$distDir  = Join-Path $repoRoot 'dist'

if (-not $Engine)  { $Engine  = Join-Path (Split-Path -Parent $repoRoot) 'Ivx330' }
if (-not $Voices)  { $Voices  = Join-Path (Split-Path -Parent $repoRoot) 'Voices Ivx330' }
if (-not $OutFile) { $OutFile = Join-Path $distDir 'infovox330.nvda-addon' }

function Fail($message) {
    Write-Host ""
    Write-Host "BUILD FAILED: $message" -ForegroundColor Red
    Write-Host ""
    Write-Host "See docs/BUILDING.md for what these folders need to contain." -ForegroundColor Yellow
    exit 1
}

function Step($n, $text) {
    Write-Host ""
    Write-Host "[$n] $text" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Infovox 330 add-on builder" -ForegroundColor Green
Write-Host "  repository : $repoRoot"
Write-Host "  engine     : $Engine"
Write-Host "  voices     : $Voices"
Write-Host "  output     : $OutFile"

# --- validate inputs ---------------------------------------------------------

Step 1 "Checking inputs"

if (-not (Test-Path $addonSrc)) { Fail "add-on source tree not found at $addonSrc" }
if (-not (Test-Path $Engine))   { Fail "engine folder not found at $Engine. Pass -Engine <path>." }
if (-not (Test-Path $Voices))   { Fail "voices folder not found at $Voices. Pass -Voices <path>." }

# The three engine DLLs do not always sit together. On a machine where Infovox
# was unpacked rather than installed, cryput.dll in particular often ends up
# one level up from the other two. Search a few sensible places rather than
# failing over a file that is sitting right there.
$searchDirs = @(
    $Engine
    Split-Path -Parent $Engine
    Split-Path -Parent $repoRoot
    Join-Path (Split-Path -Parent $repoRoot) 'Ivx330'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$requiredEngine = @('Ivx330nt.dll', 'Sx32w.dll', 'cryput.dll')
$engineFiles = @{}
$missingEngine = @()
foreach ($name in $requiredEngine) {
    $hit = $null
    foreach ($dir in $searchDirs) {
        $candidate = Join-Path $dir $name
        if (Test-Path -LiteralPath $candidate) { $hit = $candidate; break }
    }
    if ($hit) { $engineFiles[$name] = $hit } else { $missingEngine += $name }
}
if ($missingEngine) {
    Write-Host ""
    Write-Host "Searched:" -ForegroundColor Yellow
    $searchDirs | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    Fail "could not find engine file(s): $($missingEngine -join ', ')"
}

if (-not (Test-Path (Join-Path $Voices 'VoiceDescriptions.txt'))) {
    Fail "voices folder is missing VoiceDescriptions.txt"
}

$ddbCount = @(Get-ChildItem -Path $Voices -Filter *.ddb -File -ErrorAction SilentlyContinue).Count
if ($ddbCount -eq 0) { Fail "voices folder contains no .ddb diphone databases" }
Write-Host "    engine files present, $ddbCount diphone database(s) found" -ForegroundColor Green

$hostDll = Join-Path $addonSrc 'synthDrivers32\infovox_host.dll'
if (-not (Test-Path $hostDll)) { Fail "registry-virtualisation shim missing at $hostDll" }

# --- assemble ----------------------------------------------------------------

Step 2 "Staging the add-on source tree"

if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
Copy-Item -Path (Join-Path $addonSrc '*') -Destination $buildDir -Recurse -Force

# never ship compiled Python from the source tree
Get-ChildItem -Path $buildDir -Filter '__pycache__' -Recurse -Directory -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Step 3 "Copying the Infovox engine"

$engineOut = Join-Path $buildDir 'synthDrivers32\Ivx330'
New-Item -ItemType Directory -Force -Path $engineOut | Out-Null
foreach ($name in $requiredEngine) {
    Copy-Item -LiteralPath $engineFiles[$name] -Destination (Join-Path $engineOut $name) -Force
    Write-Host "    $name  <-  $($engineFiles[$name])" -ForegroundColor DarkGray
}
Write-Host "    copied $($requiredEngine.Count) engine file(s)" -ForegroundColor Green

Step 4 "Copying voice data (this is the slow step, roughly 250 MB)"

$voicesOut = Join-Path $buildDir 'synthDrivers32\Voices Ivx330'
New-Item -ItemType Directory -Force -Path $voicesOut | Out-Null

$voiceFiles = Get-ChildItem -Path $Voices -File |
    Where-Object { $_.Extension -match '^\.(ddb|ivx|phm|dll|txt)$' }

$i = 0
foreach ($f in $voiceFiles) {
    $i++
    Write-Progress -Activity 'Copying voice data' -Status $f.Name -PercentComplete (100 * $i / $voiceFiles.Count)
    Copy-Item $f.FullName -Destination $voicesOut -Force
}
Write-Progress -Activity 'Copying voice data' -Completed

$voiceMb = [math]::Round(((Get-ChildItem $voicesOut -File | Measure-Object Length -Sum).Sum / 1MB), 1)
Write-Host "    copied $($voiceFiles.Count) voice file(s), $voiceMb MB" -ForegroundColor Green

# --- package -----------------------------------------------------------------

Step 5 "Packaging into the .nvda-addon archive"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Entries are added one at a time rather than with ZipFile::CreateFromDirectory,
# because on Windows PowerShell 5.1 that helper writes the platform separator
# into entry names, producing paths like "synthDrivers32\infovox_host.dll".
# The ZIP specification (APPNOTE 4.4.17.1) requires forward slashes, and tools
# that follow it - including anything reading the archive on a non-Windows
# system - will not find those entries. Building the entries by hand lets us
# normalise the separator and guarantee a spec-compliant archive.
$prefixLength = $buildDir.TrimEnd('\', '/').Length + 1
$files = @(Get-ChildItem -LiteralPath $buildDir -Recurse -File -Force)

$archive = [System.IO.Compression.ZipFile]::Open($OutFile, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $i = 0
    foreach ($f in $files) {
        $i++
        $entryName = $f.FullName.Substring($prefixLength) -replace '\\', '/'
        Write-Progress -Activity 'Compressing' -Status $entryName -PercentComplete (100 * $i / $files.Count)
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $f.FullName, $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    $archive.Dispose()
    Write-Progress -Activity 'Compressing' -Completed
}

# --- verify what we just wrote ------------------------------------------------

Step 6 "Verifying the archive"

$verify = [System.IO.Compression.ZipFile]::OpenRead($OutFile)
try {
    $names = @($verify.Entries | ForEach-Object { $_.FullName })

    $backslashed = @($names | Where-Object { $_ -like '*\*' })
    if ($backslashed.Count) {
        Fail "$($backslashed.Count) entries use backslash separators. The archive is not spec-compliant."
    }

    foreach ($needed in 'manifest.ini',
                        'synthDrivers/infovox330.py',
                        'synthDrivers32/infovox330.py',
                        'synthDrivers32/_infovox_sapi4.py',
                        'synthDrivers32/infovox_host.dll',
                        'synthDrivers32/Ivx330/Ivx330nt.dll') {
        if ($names -notcontains $needed) { Fail "the finished archive is missing $needed" }
    }

    $ddbCountOut = @($names | Where-Object { $_ -like '*.ddb' }).Count
    if ($ddbCountOut -eq 0) { Fail "the finished archive contains no voice data" }

    Write-Host "    $($names.Count) entries, $ddbCountOut voice database(s), all paths spec-compliant" -ForegroundColor Green
}
finally {
    $verify.Dispose()
}

$addonMb = [math]::Round(((Get-Item $OutFile).Length / 1MB), 1)

Write-Host ""
Write-Host "BUILD SUCCEEDED" -ForegroundColor Green
Write-Host "  $OutFile  ($addonMb MB)" -ForegroundColor Green
Write-Host ""
Write-Host "To install: open the file, or use NVDA menu > Tools > Add-on store >" -ForegroundColor Green
Write-Host "Install from external source. Let NVDA restart, then pick 'Infovox 330'" -ForegroundColor Green
Write-Host "under NVDA menu > Preferences > Settings > Speech." -ForegroundColor Green
Write-Host ""
