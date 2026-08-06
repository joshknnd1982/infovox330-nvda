<#
================================================================================
  ivx_diag.ps1 - Infovox 330 / NVDA bring-up diagnostic  (READ-ONLY)

  Reports what Infovox and SAPI 4 material is present on this machine and how
  it is registered. Nothing is installed and nothing is changed. Admin rights
  are not required; running as admin only lets it read a few extra keys.

  Usage:
      powershell -ExecutionPolicy Bypass -File tools\ivx_diag.ps1
      powershell -ExecutionPolicy Bypass -File tools\ivx_diag.ps1 -Folder "D:\ivx330setup"

  -Folder is the directory holding your extracted 'Ivx330' and 'Voices Ivx330'
  folders. It defaults to the parent of the repository. The report is written
  to _diag_report.txt in that folder and also printed to the console.
================================================================================
#>

[CmdletBinding()]
param([string] $Folder)

$ErrorActionPreference = 'SilentlyContinue'
if (-not $Folder) { $Folder = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$folder = $Folder
$report = Join-Path $folder '_diag_report.txt'
$out = New-Object System.Collections.Generic.List[string]
function A($s){ $out.Add([string]$s); Write-Host $s }

A "===== Infovox 330 / NVDA 2026.1 bring-up diagnostic ====="
A ("Timestamp   : " + (Get-Date))
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
A ("OS          : " + $os.Caption + "  (build " + $os.BuildNumber + ")")
A ("OS arch     : " + $os.OSArchitecture)
A ("Proc arch   : native=" + $env:PROCESSOR_ARCHITECTURE + "  W6432=" + $env:PROCESSOR_ARCHITEW6432)
A ("System type : " + $cs.SystemType)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
A ("Admin?      : " + $isAdmin)
A ""

A "----- NVDA -----"
$nv = Get-Process nvda -ErrorAction SilentlyContinue
if($nv){ A ("NVDA running: yes  PID(s)=" + ($nv.Id -join ',')) } else { A "NVDA running: no" }
foreach($p in @(
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\NVDA',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NVDA',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NVDA')){
  $k = Get-ItemProperty $p -ErrorAction SilentlyContinue
  if($k){ A ("NVDA (uninstall key): version=" + $k.DisplayVersion + "  loc=" + $k.InstallLocation) }
}
foreach($d in @("$env:ProgramFiles\NVDA","${env:ProgramFiles(x86)}\NVDA")){
  if(Test-Path $d){
    A ("NVDA dir    : " + $d)
    $exe = Join-Path $d 'nvda.exe'
    if(Test-Path $exe){ A ("   nvda.exe product version: " + (Get-Item $exe).VersionInfo.ProductVersion) }
    foreach($sub in '_synthDrivers32','synthDrivers','library','synthDrivers32'){
      if(Test-Path (Join-Path $d $sub)){ A ("   contains: " + $sub) }
    }
  }
}
A ""

A "----- Microsoft SAPI 4 runtime (TTS Enumerator CLSID) -----"
$enum = '{D67C0280-C743-11cd-80E5-00AA003E4B50}'
$clsidViews = @(
  @('64-bit view','HKLM:\SOFTWARE\Classes\CLSID\'),
  @('32-bit view','HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\')
)
foreach($v in $clsidViews){
  $p = $v[1] + $enum
  if(Test-Path $p){
    $ip = (Get-ItemProperty (Join-Path $p 'InprocServer32') -ErrorAction SilentlyContinue).'(default)'
    A ($v[0] + ": PRESENT  -> " + $ip)
  } else { A ($v[0] + ": absent") }
}
A ""

A "----- Infovox 330 registration -----"
$ivxViews = @(
  @('64-bit','HKLM:\SOFTWARE\Babel-Infovox AB\Infovox 330'),
  @('32-bit','HKLM:\SOFTWARE\WOW6432Node\Babel-Infovox AB\Infovox 330')
)
foreach($v in $ivxViews){
  if(Test-Path $v[1]){
    A ("Babel-Infovox key (" + $v[0] + "): PRESENT -> " + $v[1])
    try { foreach($pn in (Get-Item $v[1]).Property){ A ("     " + $pn + " = " + (Get-ItemProperty $v[1]).$pn) } } catch {}
  } else { A ("Babel-Infovox key (" + $v[0] + "): absent") }
}
$modes = [ordered]@{
  'Larry (Am English)' = '{0E2C09C5-F800-4d06-B532-A4891BEC2AFA}'
  'AnnMarie (Swedish)' = '{BA1B5740-B4FB-11d1-8E7B-0000C07862E9}'
  'Gerhard (German)'   = '{19478D11-74B4-11d2-9BE9-00C04F9CA344}'
}
foreach($m in $modes.GetEnumerator()){
  foreach($view in $clsidViews){
    $p = $view[1] + $m.Value
    if(Test-Path $p){
      $ip = (Get-ItemProperty (Join-Path $p 'InprocServer32') -ErrorAction SilentlyContinue).'(default)'
      A ("Mode " + $m.Key + " (" + $view[0] + "): PRESENT -> " + $ip)
    }
  }
}
A ""

A "----- Extracted engine / voice files -----"
foreach($f in 'Ivx330\Ivx330nt.dll','Ivx330\Sx32w.dll','Ivx330\spchapi.exe','Ivx330\Demo330.exe',
              'Voices Ivx330\VoiceDescriptions.txt','Voices Ivx330\am00.ddb','Voices Ivx330\sw00.ddb'){
  $p = Join-Path $folder $f
  if(Test-Path $p){ A ("  present : " + $f + "  (" + [math]::Round((Get-Item $p).Length/1KB) + " KB)") }
  else           { A ("  MISSING : " + $f) }
}
A ""
A "----- SAPI4 runtime files already on system? -----"
foreach($n in 'spchapi.exe','Speech.dll','xtts50.dll'){
  foreach($dir in "$env:windir\SysWOW64","$env:windir\System32"){
    $fp = Join-Path $dir $n
    if(Test-Path $fp){ A ("  found: " + $fp) }
  }
}

$out -join "`r`n" | Out-File -FilePath $report -Encoding UTF8
Write-Host ""
Write-Host ("Report written to: " + $report)
