# Next Token — Windows version

A real Windows screensaver (`NextToken.scr`). It starts on its own after the PC is idle, plays the
animation full screen in Microsoft Edge's kiosk mode, and closes on any touch, click, key press, or
real mouse movement.

**Requirements:** Windows 10 or 11 with Microsoft Edge (included with Windows). No administrator rights.

## Install

1. On GitHub, click **Code → Download ZIP** and extract it. Keep the folder structure: the installer
   uses `next-token.html` from the top-level folder.
2. Open the `windows` folder and double-click **Install.bat**.
3. Screen Saver Settings opens to confirm that **Next Token** is selected. Adjust the wait time there if you like
   (the installer sets 10 minutes).

A **Next Token** shortcut is added to the Desktop and Start menu to play it on demand.

To use a different wait time from the start, run in PowerShell:

    powershell -ExecutionPolicy Bypass -File install.ps1 -WaitMinutes 5

## Remove

Double-click **Uninstall.bat**.

## Notes

- **Security prompts.** `NextToken.scr` is not code-signed. Windows SmartScreen or antivirus software may warn
  about it, because unsigned `.scr` files are a classic malware vector. The installer removes the
  download mark from its own installed copy only. To verify the file, compare its hash with the
  one below, or compile it yourself from `src/` (see Building).
- **School-managed PCs.** Group Policy can force a different screensaver or block screensavers entirely.
  The installer warns you if a policy is detected.
- **Small preview.** The tiny monitor preview in Screen Saver Settings stays blank; use the **Preview** button
  or the shortcut instead.

## Building

Cross-compiled with MinGW-w64, on Linux or macOS:

    sudo apt install gcc-mingw-w64-x86-64    # Ubuntu
    brew install mingw-w64                   # macOS
    bash build-windows.sh

`NextToken.scr` SHA-256: see `NextToken.scr.sha256`.
