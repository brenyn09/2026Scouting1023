@echo off
REM ===================================================================
REM  Scout1023 TBA live ripper - double-click to start.
REM  Pulls the whole event (schedule, scores, rankings, OPRs, teams)
REM  from The Blue Alliance every minute into tba_*.csv for Tableau.
REM  Needs internet. Set for IRI 2026; edit -EventKey for other events.
REM ===================================================================
title Scout1023 TBA Live (2026iri)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get-TBALive.ps1" -EventKey 2026iri
echo.
echo The TBA ripper stopped. Press any key to close this window.
pause >nul
