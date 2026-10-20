@echo off
rem Installs the Next Token screensaver for the current user.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
