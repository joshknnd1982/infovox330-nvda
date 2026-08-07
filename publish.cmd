@echo off
REM ---------------------------------------------------------------------------
REM  Convenience wrapper for tools\publish_release.ps1.
REM
REM  Usage, from the repository root:
REM
REM      .\publish.cmd -Addon .\dist\infovox330.nvda-addon -Draft
REM
REM  Drop -Draft to publish immediately. The version comes from
REM  addon\infovox330\manifest.ini unless you pass -Version.
REM ---------------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\publish_release.ps1" %*
