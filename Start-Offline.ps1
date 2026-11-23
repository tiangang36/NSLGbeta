$ErrorActionPreference='Stop'
$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){$q=[char]34;Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',($q+$PSCommandPath+$q));exit}
$root=$PSScriptRoot
$capture=Join-Path $root ('run-'+[guid]::NewGuid().ToString()+'.json')
if(Get-Process -Name 'com.bilibili.nslg' -ErrorAction SilentlyContinue){throw 'Exit the running game first.'}
try {
 Get-NetFirewallRule -DisplayName 'Codex NSL Offline Test' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
 New-NetFirewallRule -DisplayName 'Codex NSL Offline Test' -Direction Outbound -Action Block -Program (Join-Path (Get-Item -LiteralPath 'D:/bilibili Game/NSL_2/NSLG Game').FullName 'com.bilibili.nslg.exe') | Out-Null
 Set-Location -LiteralPath 'D:/bilibili Game/NSL_2/NSLG Game'
 & 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' 'C:/Users/Administrator/.codex/tools/rea/node_modules/rea-agents/scripts/rea.mjs' instrument-with-frida spawn 'D:/bilibili Game/NSL_2/NSLG Game/com.bilibili.nslg.exe' --device-id local --script-file (Join-Path $root 'offline-runtime.js') --duration-ms 55000 --json | Out-File $capture -Encoding utf8
 if($LASTEXITCODE -ne 0){throw 'REA launch failed.'}
 $ev=Get-Content $capture -Raw | ConvertFrom-Json
 if($ev.normalized_result.pid){Wait-Process -Id $ev.normalized_result.pid -ErrorAction SilentlyContinue}
}catch{$_ | Out-File (Join-Path $root 'launcher-error.txt');throw}
finally {Get-NetFirewallRule -DisplayName 'Codex NSL Offline Test' -ErrorAction SilentlyContinue | Remove-NetFirewallRule}


