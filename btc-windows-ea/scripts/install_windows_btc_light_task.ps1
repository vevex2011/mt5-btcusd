param(
  [string]$TaskName = "CodexBtcWindowsLightLoop",
  [string]$ConfigFile = "",
  [string]$RepoRoot = "D:\workspace\mt5",
  [int]$IntervalSeconds = 60
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loopScript = Join-Path $scriptDir "run_windows_btc_light_live_loop.ps1"
if (!(Test-Path $loopScript)) {
  throw "Loop script not found: $loopScript"
}

$argParts = @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", "`"$loopScript`"",
  "-RepoRoot", "`"$RepoRoot`"",
  "-IntervalSeconds", "$IntervalSeconds"
)
if ($ConfigFile -ne "") {
  $resolvedConfig = Resolve-Path $ConfigFile -ErrorAction Stop
  $argParts += @("-ConfigFile", "`"$resolvedConfig`"")
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ($argParts -join " ")
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "Registered and started task: $TaskName"
Write-Host "Loop script: $loopScript"
if ($ConfigFile -ne "") {
  Write-Host "Config file: $ConfigFile"
}

