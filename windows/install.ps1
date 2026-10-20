# Next Token — Windows installer (current user only, no administrator rights needed)
#   Run with Install.bat, or:  powershell -ExecutionPolicy Bypass -File install.ps1 [-WaitMinutes 10]
param([int]$WaitMinutes = 10)
$ErrorActionPreference = 'Stop'

$src  = $PSScriptRoot
$dest = Join-Path $env:LOCALAPPDATA 'NextToken'

# The HTML lives at the top of the repository; also accept a copy next to this script.
$html = @("$src\next-token.html", "$src\..\next-token.html") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $html)                         { throw "next-token.html not found. Keep the downloaded folder structure intact." }
if (-not (Test-Path "$src\NextToken.scr")) { throw "NextToken.scr not found next to install.ps1." }

$edgePaths = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
if (-not ($edgePaths | Where-Object { Test-Path $_ })) { Write-Warning "Microsoft Edge was not found. Next Token needs Edge to play." }

# Stop a running copy before replacing files
Get-Process NextToken -ErrorAction SilentlyContinue | Stop-Process -Force

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item "$src\NextToken.scr" $dest -Force
Copy-Item $html "$dest\next-token.html" -Force
# Files downloaded from the internet carry a "Mark of the Web"; remove it from these two copies
# so Windows doesn't block the screensaver when it starts on its own.
Unblock-File "$dest\NextToken.scr", "$dest\next-token.html"
$scr = "$dest\NextToken.scr"

# Register as the current user's screensaver (Windows prefers the short 8.3 path here)
$short = (New-Object -ComObject Scripting.FileSystemObject).GetFile($scr).ShortPath
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'SCRNSAVE.EXE' -Value $short

Add-Type -Namespace CT -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint action, uint param, System.IntPtr vparam, uint flags);
'@
$SPIF = 3   # update user profile + broadcast change
[CT.Native]::SystemParametersInfo(0x0011, 1, [IntPtr]::Zero, $SPIF) | Out-Null                      # screensaver on
[CT.Native]::SystemParametersInfo(0x000F, [uint32]($WaitMinutes * 60), [IntPtr]::Zero, $SPIF) | Out-Null  # wait time

# "Next Token" shortcuts (Desktop + Start menu) to play it on demand
$wsh = New-Object -ComObject WScript.Shell
foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $lnk = $wsh.CreateShortcut((Join-Path $dir 'Next Token.lnk'))
    $lnk.TargetPath = $scr; $lnk.Arguments = '/s'; $lnk.IconLocation = "$scr,0"
    $lnk.WorkingDirectory = $dest; $lnk.Description = 'Play the Next Token screensaver now'
    $lnk.Save()
}

# School-managed PCs: Group Policy can override the user's screensaver choice
$pol = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
if ((Test-Path $pol) -and (Get-ItemProperty $pol -ErrorAction SilentlyContinue).'SCRNSAVE.EXE') {
    Write-Warning "A Group Policy sets this PC's screensaver. It will override Next Token; ask your IT department."
}

Write-Host ""
Write-Host "Next Token installed to $dest"
Write-Host "It starts after $WaitMinutes minutes of inactivity. Use the 'Next Token' shortcut to play it now."
Write-Host "Touch the screen, click, or press any key to exit."
Start-Process control.exe 'desk.cpl,,@screensaver'   # open Screen Saver Settings to confirm
