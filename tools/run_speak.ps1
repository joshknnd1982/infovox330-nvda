<#
================================================================================
  run_speak.ps1 - drive the Infovox engine directly, outside NVDA

  Runs the registry-free engine harness and speaks every available voice in
  turn. Touches nothing in the registry and needs no admin rights.

  This is the fastest way to tell whether a speech problem lives in the engine
  layer or the NVDA layer: if you hear voices here but NVDA is silent, the
  engine is fine and the problem is in the driver or NVDA's audio output.

  Requires ivxspeak.exe and its companion DLLs in -Folder. Those diagnostic
  executables are not part of this repository.

  Usage:
      powershell -ExecutionPolicy Bypass -File tools\run_speak.ps1
      powershell -ExecutionPolicy Bypass -File tools\run_speak.ps1 -Folder "D:\ivx330setup"
================================================================================
#>

[CmdletBinding()]
param([string] $Folder)

$ErrorActionPreference = 'Stop'

if (-not $Folder) { $Folder = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }

$exe = Join-Path $Folder 'ivxspeak.exe'
if (-not (Test-Path $exe)) {
    Write-Host "ivxspeak.exe was not found in $Folder." -ForegroundColor Yellow
    Write-Host "Pass -Folder <path> pointing at the directory that contains it." -ForegroundColor Yellow
    exit 1
}

# Files copied off removable media or downloaded arrive with a mark-of-the-web
# that blocks execution. Clear it so the harness can load its DLLs.
Get-ChildItem $Folder -Include *.exe, *.dll -Recurse -ErrorAction SilentlyContinue |
    Unblock-File -ErrorAction SilentlyContinue

Write-Host "Turn up your volume. You should hear each voice speak in turn." -ForegroundColor Cyan
Write-Host ""
& $exe

Write-Host ""
Write-Host "Finished. A transcript is written to _ivx_speak.txt in $Folder." -ForegroundColor Green
