# Next Token — Windows uninstaller (current user)
$ErrorActionPreference = 'Continue'
$dest = Join-Path $env:LOCALAPPDATA 'NextToken'

Get-Process NextToken -ErrorAction SilentlyContinue | Stop-Process -Force

# Unregister only if Next Token is the current screensaver
$desk = 'HKCU:\Control Panel\Desktop'
$cur = (Get-ItemProperty $desk -ErrorAction SilentlyContinue).'SCRNSAVE.EXE'
if ($cur -and ($cur -match 'NextToken|NEXTTO~')) {
    Remove-ItemProperty $desk -Name 'SCRNSAVE.EXE'
    Add-Type -Namespace CT -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint action, uint param, System.IntPtr vparam, uint flags);
'@
    [CT.Native]::SystemParametersInfo(0x0011, 0, [IntPtr]::Zero, 3) | Out-Null   # screensaver off
}

foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    Remove-Item (Join-Path $dir 'Next Token.lnk') -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 500
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Next Token removed."
