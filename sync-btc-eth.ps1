# D:\CryptoProject\PlatinumTrade.Data\sync-btc-eth.ps1
# Shortcut script to quickly package and sync BTC-USDT-SWAP and ETH-USDT-SWAP to GitHub

$ErrorActionPreference = "Stop"

Write-Host "=== PlatinumTrade Quick Sync (BTC & ETH) ===" -ForegroundColor Cyan

# Select Datatype (Demo/Real)
$choices = @("&Demo", "&Real")
$choice = $Host.UI.PromptForChoice("Select Datatype", "Choose the datatype to sync:", $choices, 0)
$datatype = if ($choice -eq 0) { "demo" } else { "real" }

Write-Host "`nRunning quick sync for BTC-USDT-SWAP and ETH-USDT-SWAP ($datatype)..." -ForegroundColor Yellow

# Call the main script with pre-configured parameters
& "$PSScriptRoot\sync-data.ps1" -Datatype $datatype -Symbols "BTC-USDT-SWAP,ETH-USDT-SWAP" -GitSync -ReleaseUpload -TagName "datasets-v1"

Write-Host "`nQuick Sync Completed!" -ForegroundColor Green
