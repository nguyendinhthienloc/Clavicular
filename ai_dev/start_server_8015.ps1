$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host 'Starting Person 3 API on 0.0.0.0:8015' -ForegroundColor Cyan
& "d:/Hackathon_Clavicular/.venv/Scripts/python.exe" -m uvicorn ai_dev.src.server:app --host 0.0.0.0 --port 8015
