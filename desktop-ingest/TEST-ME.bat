@echo off
REM ===================================================================
REM  Scout1023 watcher SELF-TEST - double-click to verify the laptop.
REM  Seeds sample data, runs one merge pass, shows master.csv.
REM  No USB needed. Delete inbox + master.csv afterward for a clean start.
REM ===================================================================
title Scout1023 Watcher - SELF TEST
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Self-Test.ps1"
echo.
echo Press any key to close this window.
pause >nul
