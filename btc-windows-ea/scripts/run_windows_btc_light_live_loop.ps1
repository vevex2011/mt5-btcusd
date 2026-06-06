param(
  [string]$ConfigFile = "",
  [string]$RepoRoot = "D:\workspace\mt5",
  [string]$EdgeDashboardDir = "",
  [string]$Mt5FilesDir = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files",
  [string]$PgHost = "",
  [string]$PgPort = "",
  [string]$PgDatabase = "",
  [string]$PgUser = "",
  [string]$PgPassword = "",
  [int]$IntervalSeconds = 60,
  [int]$MaxBarsPerSymbol = 360,
  [double]$Threshold = 0.58
)

$ErrorActionPreference = "Stop"

if ($ConfigFile -ne "") {
  $resolvedConfig = Resolve-Path $ConfigFile -ErrorAction Stop
  . $resolvedConfig
}

if ($EdgeDashboardDir -eq "") {
  $candidates = @(
    (Join-Path $RepoRoot "EDGE_DASHBOARD"),
    (Join-Path $RepoRoot "edge-dashboard")
  )
  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      $EdgeDashboardDir = $candidate
      break
    }
  }
}
if ($EdgeDashboardDir -eq "" -or !(Test-Path $EdgeDashboardDir)) {
  throw "edge-dashboard directory not found under $RepoRoot"
}

if ($PgHost -ne "") { $env:PGHOST = $PgHost }
if ($PgPort -ne "") { $env:PGPORT = $PgPort }
if ($PgDatabase -ne "") { $env:PGDATABASE = $PgDatabase }
if ($PgUser -ne "") { $env:PGUSER = $PgUser }
if ($PgPassword -ne "") { $env:PGPASSWORD = $PgPassword }

$env:MT5_FILES_DIR = $Mt5FilesDir
$env:CODEX_MT5_HOME = Join-Path $RepoRoot "CodexMT5"
$env:MODEL_EXPORT_PREFERRED_SOURCE_MODEL = "PER_SYMBOL_PURE_PY_MLP"
$env:BROKER_COST_PROFILE = "TMGM_REAL"
$env:BROKER_COST_FOREX_SPREAD_POINTS = "0"
$env:BROKER_COST_FOREX_COMMISSION_POINTS = "5"
$env:BROKER_COST_XAUUSD_SPREAD_POINTS = "8"
$env:BROKER_COST_XAUUSD_COMMISSION_POINTS = "5"
$env:BROKER_COST_BTCUSD_SPREAD_POINTS = "14"
$env:BROKER_COST_BTCUSD_COMMISSION_POINTS = "0"
$env:PYTHONWARNINGS = "ignore::DeprecationWarning"

$modelDir = Join-Path $env:CODEX_MT5_HOME "models"
$outputDir = Join-Path $Mt5FilesDir "codex-edge-model"
$stateDir = Join-Path $EdgeDashboardDir ".state"
New-Item -ItemType Directory -Force -Path $modelDir, $outputDir, $stateDir | Out-Null

$modelFile = Join-Path $modelDir "deep_short_model_btcusd.json"
if (!(Test-Path $modelFile)) {
  throw "BTC lightweight model not found: $modelFile"
}

$python = Join-Path $EdgeDashboardDir ".venv\Scripts\python.exe"
if (!(Test-Path $python)) {
  $python = "python"
}

$logFile = Join-Path $stateDir "windows_btc_light_live_loop.log"
Write-Host "Starting BTC Windows light-model loop. log=$logFile"
Write-Host "DB=$($env:PGUSER)@$($env:PGHOST):$($env:PGPORT)/$($env:PGDATABASE), MT5_FILES_DIR=$Mt5FilesDir"

Push-Location $EdgeDashboardDir
try {
  while ($true) {
    $startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
      "[$startedAt] infer BTCUSD M1" | Tee-Object -FilePath $logFile -Append | Out-Host
      & $python "scripts\models\light\infer_light_model_recommendations.py" `
        --symbols BTCUSD `
        --timeframe M1 `
        --max-bars-per-symbol $MaxBarsPerSymbol `
        --threshold $Threshold 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Host
      if ($LASTEXITCODE -ne 0) {
        throw "light inference exited with code $LASTEXITCODE"
      }

      "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] export edge_recommendations.json" | Tee-Object -FilePath $logFile -Append | Out-Host
      & $python "scripts\export_model_recommendations.py" `
        --symbols BTCUSD `
        --preferred-source-model PER_SYMBOL_PURE_PY_MLP `
        --output-dir $outputDir 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Host
      if ($LASTEXITCODE -ne 0) {
        throw "recommendation export exited with code $LASTEXITCODE"
      }
    }
    catch {
      "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] ERROR: $($_.Exception.Message)" | Tee-Object -FilePath $logFile -Append | Out-Host
    }

    Start-Sleep -Seconds $IntervalSeconds
  }
}
finally {
  Pop-Location
}
