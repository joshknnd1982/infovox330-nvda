@echo off
REM ---------------------------------------------------------------------------
REM  Convenience wrapper for tools\build_addon.ps1.
REM
REM  Exists so the build is a short command that is hard to mistype, and so it
REM  runs under Windows PowerShell 5.1, which is what ships with Windows. The
REM  scripts do not require PowerShell 7.
REM
REM  Usage, from the repository root:
REM
REM      .\build.cmd
REM
REM  With no arguments it uses the engine and voice data committed inside
REM  addon\infovox330\synthDrivers32. To build from other media instead:
REM
REM      .\build.cmd -Engine "D:\Ivx330" -Voices "D:\Voices Ivx330"
REM ---------------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_addon.ps1" %*
