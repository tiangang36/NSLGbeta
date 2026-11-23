$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){$q=[char]34;Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',($q+$PSCommandPath+$q));exit}
Get-NetFirewallRule -DisplayName 'Codex NSL Offline Test' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
