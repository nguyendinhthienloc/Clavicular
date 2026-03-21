param(
    [string]$BaseUrl = "http://127.0.0.1:8016",
    [switch]$SkipSources
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$diagPath = Join-Path $root "requests/diagnose.sample.json"
$srcPath = Join-Path $root "requests/sources.sample.json"

if (-not (Test-Path $diagPath)) {
    throw "Missing file: $diagPath"
}

if (-not $SkipSources -and -not (Test-Path $srcPath)) {
    throw "Missing file: $srcPath"
}

# Validate JSON files before sending.
$diagObj = Get-Content -Raw -Encoding UTF8 $diagPath | ConvertFrom-Json
$diagBody = $diagObj | ConvertTo-Json -Depth 20

$health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
Write-Host "[OK] /health => $($health | ConvertTo-Json -Compress)"

$diagRes = Invoke-RestMethod -Uri "$BaseUrl/api/diagnose" -Method Post -ContentType "application/json" -Body $diagBody
$severity = $diagRes.data.severity
Write-Host "[OK] /api/diagnose severity=$severity"

if (-not $SkipSources) {
    $srcObj = Get-Content -Raw -Encoding UTF8 $srcPath | ConvertFrom-Json
    $srcBody = $srcObj | ConvertTo-Json -Depth 20
    $srcRes = Invoke-RestMethod -Uri "$BaseUrl/api/sources" -Method Post -ContentType "application/json" -Body $srcBody
    $count = 0
    if ($null -ne $srcRes.results) {
        $count = @($srcRes.results).Count
    }
    Write-Host "[OK] /api/sources results=$count"
}

Write-Host "Smoke test completed successfully."
