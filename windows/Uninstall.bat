@echo off
rem Removes the Next Token screensaver for the current user.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
