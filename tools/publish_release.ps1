<#
================================================================================
  publish_release.ps1 - tag a version and publish the built add-on to GitHub

  Attaches infovox330.nvda-addon to a GitHub release as a release asset. The
  file is far too large to live in the repository - GitHub caps repository
  files at 100 MB, while release assets may be up to 2 GB - so this is the
  only way to distribute a built add-on through GitHub.

  What it does, stopping at the first thing that looks wrong:

    1. validates the archive: readable ZIP, manifest.ini at the root, engine
       and voice data present, correct version
    2. warns if the archive is stale relative to the committed source
    3. checks the working tree is clean and pushed
    4. creates and pushes the tag
    5. creates the GitHub release
    6. uploads the add-on and a SHA-256 checksum file

  Safe to re-run. An existing tag or release is reused rather than duplicated,
  and assets are replaced rather than rejected.

  READ NOTICE.md FIRST. The built add-on embeds the Infovox engine and the
  complete voice data, which are not yours to redistribute. Publishing this
  file is a different decision from publishing the source.

  Usage:
      pwsh -File tools\publish_release.ps1 -Addon ..\infovox330.nvda-addon
      pwsh -File tools\publish_release.ps1 -Addon ..\infovox330.nvda-addon -Draft
      pwsh -File tools\publish_release.ps1 -Version 1.0.1 -Addon .\dist\infovox330.nvda-addon
================================================================================
#>

[CmdletBinding()]
param(
    [string] $Addon,
    [string] $Version,
    [string] $NotesFile,
    [switch] $Draft,
    [switch] $PreRelease,
    [switch] $SkipDirtyCheck,
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

function Say($text, $colour = 'Gray') { Write-Host $text -ForegroundColor $colour }
function Step($n, $text) { Write-Host ""; Write-Host "[$n] $text" -ForegroundColor Cyan }
function Stop-With($text) {
    Write-Host ""
    Write-Host $text -ForegroundColor Red
    Write-Host ""
    exit 1
}

function Resolve-Exe {
    param([Parameter(Mandatory)][string] $Name)
    # Resolve to a full path: PowerShell function names are case-insensitive,
    # so a helper called Git would otherwise shadow git.exe.
    $cmd = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    return $null
}

<#
  Native commands are invoked through here so that stderr output cannot become
  a terminating error. Windows PowerShell turns any stderr writing from a
  native program into an ErrorRecord, and under $ErrorActionPreference = Stop
  that kills the script even when the command succeeded. The exit code is the
  signal that actually means something.
#>
function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]   $Exe,
        [Parameter(Mandatory)][string[]] $Arguments,
        [switch] $Quiet
    )
    $path = Resolve-Exe $Exe
    if (-not $path) { throw "Executable not found on PATH: $Exe" }
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $path @Arguments 2>&1
        $code   = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    if (-not $Quiet -and $text) {
        $text -split "`n" |
            Where-Object { $_.Trim() } |
            ForEach-Object { Say "    $($_.TrimEnd())" }
    }
    [pscustomobject]@{ Code = $code; Output = $text; Ok = ($code -eq 0) }
}

function Run-Git      { Invoke-Native -Exe 'git' -Arguments $args }
function Run-GitQuiet { Invoke-Native -Exe 'git' -Arguments $args -Quiet }
function Run-Gh       { Invoke-Native -Exe 'gh'  -Arguments $args }
function Run-GhQuiet  { Invoke-Native -Exe 'gh'  -Arguments $args -Quiet }

Push-Location $repoRoot
try {

# ------------------------------------------------------------ prerequisites --

Step 1 "Checking prerequisites"

foreach ($tool in 'git', 'gh') {
    $p = Resolve-Exe $tool
    if (-not $p) {
        Stop-With "$tool is not installed or not on PATH.`n  git : https://git-scm.com/download/win`n  gh  : winget install --id GitHub.cli"
    }
    Say ("    {0,-4} : {1}" -f $tool, $p) 'Green'
}

if (-not (Run-GhQuiet auth status).Ok) {
    Stop-With "The GitHub CLI is not signed in. Run 'gh auth login' and try again."
}
Say "    gh auth : signed in" 'Green'

# --- version, from the manifest unless overridden ---

$manifestPath = Join-Path $repoRoot 'addon\manifest.ini'
if (-not (Test-Path $manifestPath)) { Stop-With "addon\manifest.ini not found." }
$manifestText = Get-Content $manifestPath -Raw
$manifestVersion = ([regex]::Match($manifestText, '(?m)^\s*version\s*=\s*(.+?)\s*$')).Groups[1].Value.Trim('"', ' ')

if (-not $Version) { $Version = $manifestVersion }
if (-not $Version) { Stop-With "Could not determine a version. Pass -Version." }
$tag = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
$bare = $tag.TrimStart('v')

Say "    version : $bare  (tag $tag)" 'Green'
if ($bare -ne $manifestVersion) {
    Say "    WARNING : manifest.ini says $manifestVersion, you asked for $bare" 'Yellow'
}

# --- locate the add-on ---

if (-not $Addon) {
    foreach ($candidate in @(
        (Join-Path $repoRoot 'dist\infovox330.nvda-addon'),
        (Join-Path (Split-Path -Parent $repoRoot) 'infovox330.nvda-addon')
    )) {
        if (Test-Path -LiteralPath $candidate) { $Addon = $candidate; break }
    }
}
if (-not $Addon -or -not (Test-Path -LiteralPath $Addon)) {
    Stop-With "Add-on file not found. Build it with tools\build_addon.ps1, or pass -Addon <path>."
}
$Addon = (Resolve-Path -LiteralPath $Addon).Path
$addonItem = Get-Item -LiteralPath $Addon
Say "    add-on  : $Addon" 'Green'
Say ("    size    : {0:N1} MB" -f ($addonItem.Length / 1MB)) 'Green'

if ($addonItem.Length -gt 2GB) {
    Stop-With "The add-on exceeds GitHub's 2 GB release-asset limit."
}

# ------------------------------------------------------- validate the archive --

Step 2 "Validating the archive"

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = $null
try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Addon)
} catch {
    Stop-With "Not a readable ZIP archive: $($_.Exception.Message)"
}

try {
    $rawEntries = @($zip.Entries | ForEach-Object { $_.FullName })

    # Some archives carry Windows separators in entry names, which the ZIP
    # specification does not permit. Normalise before checking so an archive
    # built by an older script still validates, but say so - it is worth
    # rebuilding rather than shipping.
    $entries = @($rawEntries | ForEach-Object { $_ -replace '\\', '/' })
    $backslashed = @($rawEntries | Where-Object { $_ -like '*\*' })
    if ($backslashed.Count) {
        Say "    WARNING: $($backslashed.Count) entries use backslash separators" 'Yellow'
        Say "    The ZIP spec requires forward slashes. Rebuild with the current" 'Yellow'
        Say "    tools\build_addon.ps1, which writes spec-compliant paths." 'Yellow'
    }

    # Entry lookups below use normalised names; keep a map back to the real ones.
    $entryByNormalised = @{}
    foreach ($e in $zip.Entries) { $entryByNormalised[($e.FullName -replace '\\', '/')] = $e }

    if ($entries -notcontains 'manifest.ini') {
        Stop-With "manifest.ini is not at the root of the archive. NVDA will refuse to install it.`nRebuild with tools\build_addon.ps1."
    }

    $ddb = @($entries | Where-Object { $_ -like '*.ddb' })
    if ($ddb.Count -eq 0) {
        Stop-With "The archive contains no voice data (.ddb files). It would install but never speak."
    }

    foreach ($needed in 'synthDrivers32/infovox_host.dll',
                        'synthDrivers32/Ivx330/Ivx330nt.dll',
                        'synthDrivers32/infovox330.py',
                        'synthDrivers/infovox330.py') {
        if ($entries -notcontains $needed) { Stop-With "The archive is missing $needed." }
    }

    Say "    $($entries.Count) entries, $($ddb.Count) voice database(s), manifest at root" 'Green'

    # --- version agreement between tag and shipped manifest ---
    $me = $entryByNormalised['manifest.ini']
    $reader = New-Object System.IO.StreamReader($me.Open())
    $shippedManifest = $reader.ReadToEnd()
    $reader.Dispose()
    $shippedVersion = ([regex]::Match($shippedManifest, '(?m)^\s*version\s*=\s*(.+?)\s*$')).Groups[1].Value.Trim('"', ' ')

    if ($shippedVersion -ne $bare) {
        Stop-With "The archive's manifest says version $shippedVersion but you are tagging $bare.`nRebuild the add-on so the release asset matches its tag."
    }
    Say "    shipped manifest version $shippedVersion matches the tag" 'Green'

    # --- staleness: does the archive carry the committed source? ---
    $stale = @()
    $pairs = @{
        'manifest.ini'                    = 'addon\manifest.ini'
        'synthDrivers/infovox330.py'      = 'addon\synthDrivers\infovox330.py'
        'synthDrivers32/infovox330.py'    = 'addon\synthDrivers32\infovox330.py'
        'synthDrivers32/_infovox_sapi4.py'= 'addon\synthDrivers32\_infovox_sapi4.py'
        'synthDrivers32/infovox_host.dll' = 'addon\synthDrivers32\infovox_host.dll'
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    foreach ($k in $pairs.Keys) {
        $onDisk = Join-Path $repoRoot $pairs[$k]
        if (-not (Test-Path -LiteralPath $onDisk)) { continue }
        $entry = $entryByNormalised[$k]
        if (-not $entry) { $stale += $k; continue }

        if ($k -match '\.(py|ini|txt)$') {
            # Text files differ legitimately by line endings, because
            # .gitattributes deliberately checks some of them out as CRLF.
            # Compare content with newlines normalised.
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $inZipText = ($reader.ReadToEnd()) -replace "`r`n", "`n"
            $reader.Dispose()
            $onDiskText = ([System.IO.File]::ReadAllText($onDisk)) -replace "`r`n", "`n"
            if ($inZipText -ne $onDiskText) { $stale += $k }
        }
        else {
            $ms = New-Object System.IO.MemoryStream
            $es = $entry.Open(); $es.CopyTo($ms); $es.Dispose()
            $inZipHash = [BitConverter]::ToString($sha.ComputeHash($ms.ToArray()))
            $ms.Dispose()

            $fs = [System.IO.File]::OpenRead($onDisk)
            $onDiskHash = [BitConverter]::ToString($sha.ComputeHash($fs))
            $fs.Dispose()

            if ($inZipHash -ne $onDiskHash) { $stale += $k }
        }
    }
    $sha.Dispose()

    if ($stale) {
        Write-Host ""
        Say "    The archive does not match the source in this repository:" 'Yellow'
        $stale | ForEach-Object { Say "      $_" 'Yellow' }
        Say "    Publishing it would ship an asset that disagrees with its own tag." 'Yellow'
        Say "    Rebuild with tools\build_addon.ps1 unless you know why they differ." 'Yellow'
        if (-not $Yes) {
            $answer = Read-Host "    Continue anyway? (type yes to proceed)"
            if ($answer -ne 'yes') { Stop-With "Stopped. Rebuild and run this again." }
        }
    } else {
        Say "    archive matches the committed source" 'Green'
    }
}
finally {
    if ($zip) { $zip.Dispose() }
}

# ------------------------------------------------------------- repo state ----

Step 3 "Checking repository state"

$dirty = (Run-GitQuiet status --porcelain).Output.Trim()
if ($dirty -and -not $SkipDirtyCheck) {
    Write-Host ""
    $dirty -split "`n" | Select-Object -First 15 | ForEach-Object { Say "    $_" 'Yellow' }
    Stop-With "The working tree has uncommitted changes. Commit them first, or pass -SkipDirtyCheck.`nA tag should point at a commit that reflects what you are releasing."
}
Say "    working tree clean" 'Green'

if (-not (Run-GitQuiet remote get-url origin).Ok) {
    Stop-With "No 'origin' remote. Run setup_github.ps1 first."
}

$branch = (Run-GitQuiet rev-parse --abbrev-ref HEAD).Output.Trim()
Run-GitQuiet fetch origin --tags | Out-Null
$ahead = (Run-GitQuiet rev-list --count "origin/$branch..HEAD").Output.Trim()
if ($ahead -and $ahead -ne '0') {
    Say "    $ahead local commit(s) not yet pushed - pushing" 'Yellow'
    $r = Run-Git push origin $branch
    if (-not $r.Ok) { Stop-With "git push failed. See above." }
}
Say "    branch $branch is in sync with origin" 'Green'

# ------------------------------------------------------------------- tag ----

Step 4 "Tagging $tag"

$tagExists = (Run-GitQuiet rev-parse -q --verify "refs/tags/$tag").Ok
if ($tagExists) {
    Say "    tag already exists locally, reusing it" 'Green'
} else {
    $r = Run-GitQuiet tag -a $tag -m "Infovox 330 for NVDA $bare"
    if (-not $r.Ok) { Stop-With "git tag failed:`n$($r.Output)" }
    Say "    created" 'Green'
}

$r = Run-Git push origin $tag
if (-not $r.Ok) { Say "    (tag may already be on origin - continuing)" 'Yellow' }

# --------------------------------------------------------------- release ----

Step 5 "Creating the GitHub release"

$releaseExists = (Run-GhQuiet release view $tag).Ok

if ($releaseExists) {
    Say "    release $tag already exists, reusing it" 'Green'
} else {
    if (-not $NotesFile) {
        $candidate = Join-Path $repoRoot "docs\release-notes-$bare.md"
        if (Test-Path -LiteralPath $candidate) { $NotesFile = $candidate }
    }

    $ghArgs = @('release', 'create', $tag, '--title', "Infovox 330 for NVDA $bare")
    if ($NotesFile -and (Test-Path -LiteralPath $NotesFile)) {
        $ghArgs += @('--notes-file', $NotesFile)
        Say "    notes from $NotesFile" 'Green'
    } else {
        $ghArgs += @('--generate-notes')
        Say "    no notes file found, using generated notes" 'Yellow'
    }
    if ($Draft)      { $ghArgs += '--draft';      Say "    creating as a DRAFT" 'Yellow' }
    if ($PreRelease) { $ghArgs += '--prerelease'; Say "    marking as a pre-release" 'Yellow' }

    $r = Run-Gh @ghArgs
    if (-not $r.Ok) { Stop-With "gh release create failed. See above." }
    Say "    created" 'Green'
}

# ----------------------------------------------------------------- upload ----

Step 6 "Uploading the add-on"

# A checksum file lets people verify a 160 MB download that they cannot
# reasonably inspect any other way.
$checksumPath = "$Addon.sha256"
Say "    computing SHA-256" 'Cyan'
$hash = (Get-FileHash -LiteralPath $Addon -Algorithm SHA256).Hash.ToLower()
"$hash  $(Split-Path -Leaf $Addon)" | Set-Content -LiteralPath $checksumPath -Encoding ascii -NoNewline
Say "    $hash" 'Green'

Say ("    uploading {0:N1} MB - this takes a while and gh shows no progress" -f ($addonItem.Length / 1MB)) 'Cyan'
$r = Run-Gh release upload $tag $Addon $checksumPath --clobber
if (-not $r.Ok) { Stop-With "Upload failed. Re-run this script to retry; it will reuse the tag and release." }

$url  = (Run-GhQuiet release view $tag --json url --jq .url).Output.Trim()
$slug = (Run-GhQuiet repo view --json nameWithOwner --jq .nameWithOwner).Output.Trim()
if (-not $slug) { $slug = '<owner>/<repo>' }

Write-Host ""
Say "DONE" 'Green'
if ($url) { Say "  $url" 'Green' }
Write-Host ""
if ($Draft) {
    Say "The release is a DRAFT and is not visible to anyone else yet." 'Yellow'
    Say "Publish it from the release page when you are ready." 'Yellow'
    Write-Host ""
}
Say "Verify the download before telling anyone about it. Note --repo: gh works" 'Cyan'
Say "out which repository you mean from the current folder's git remote, so" 'Cyan'
Say "without it these fail anywhere outside a clone." 'Cyan'
Write-Host ""
Say "  gh release download $tag --repo $slug --pattern '*.nvda-addon' --dir `$env:TEMP --clobber"
Say "  Get-FileHash `$env:TEMP\infovox330.nvda-addon -Algorithm SHA256"
Say "  (should be $hash)"
Write-Host ""

}
finally {
    Pop-Location
}
