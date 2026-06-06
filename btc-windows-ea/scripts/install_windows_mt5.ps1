param(
  [string]$Mt5DataPath = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5",
  [string]$MetaEditorPath = "C:\Program Files\MetaTrader 5\MetaEditor64.exe",
  [string]$ExpertSubdir = "CodexAutotrade"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$eaDir = Join-Path $projectDir "ea"

if (!(Test-Path $eaDir)) {
  throw "EA directory not found: $eaDir"
}
if (!(Test-Path $MetaEditorPath)) {
  throw "MetaEditor not found: $MetaEditorPath"
}

$expertsDir = Join-Path $Mt5DataPath "Experts\$ExpertSubdir"
$filesDir = Join-Path $Mt5DataPath "Files\codex-edge-model"
New-Item -ItemType Directory -Force -Path $expertsDir | Out-Null
New-Item -ItemType Directory -Force -Path $filesDir | Out-Null

Get-ChildItem -Path $eaDir -Filter "*.mqh" | ForEach-Object {
  Copy-Item -Force $_.FullName (Join-Path $expertsDir $_.Name)
}

$eaSources = @(
  "CodexBTCWindowsLightEA.mq5",
  "CodexBTCWindowsPendingEA.mq5"
)

foreach ($eaName in $eaSources) {
  $source = Join-Path $eaDir $eaName
  if (!(Test-Path $source)) {
    throw "EA source not found: $source"
  }

  $stem = [System.IO.Path]::GetFileNameWithoutExtension($eaName)
  $targetEa = Join-Path $expertsDir $eaName
  $compileLog = Join-Path $expertsDir "$stem.compile.log"
  $targetEx5 = Join-Path $expertsDir "$stem.ex5"

  Copy-Item -Force $source $targetEa
  Remove-Item -Force -ErrorAction SilentlyContinue $compileLog, $targetEx5

  $args = @(
    "/compile:$targetEa",
    "/log:$compileLog"
  )
  $proc = Start-Process -FilePath $MetaEditorPath -ArgumentList $args -Wait -PassThru

  if (!(Test-Path $targetEx5)) {
    if (Test-Path $compileLog) {
      Get-Content $compileLog | Select-Object -Last 80
    }
    throw "Compiled EX5 not found: $targetEx5"
  }

  Write-Host "Installed EA: $targetEa"
  Write-Host "Compiled EX5: $targetEx5"
  Write-Host "Compile log: $compileLog"
  Write-Host "MetaEditor exit code: $($proc.ExitCode)"
}

Write-Host "MT5 model output folder: $filesDir"
