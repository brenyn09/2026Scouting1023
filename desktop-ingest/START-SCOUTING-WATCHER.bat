@echo off
REM ===================================================================
REM  Scout1023 USB watcher - double-click to start.
REM  Copy this whole folder to any Windows laptop and run this file.
REM  No internet and no installs required.
REM ===================================================================
title Scout1023 USB Watcher
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Watch-Scouting.ps1"
echo.
echo The watcher stopped. Press any key to close this window.
pause >nul
