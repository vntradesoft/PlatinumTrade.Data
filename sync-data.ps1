# D:\CryptoProject\PlatinumTrade.Data\sync-data.ps1
# Script to synchronize, package, and publish history data for PlatinumTrade

[CmdletBinding()]
param(
    [ValidateSet("demo", "real")]
    [string]$Datatype,
    
    [string]$Symbols, # comma-separated list of symbol indices, names, or '*' for all
    
    [switch]$GitSync,
    
    [switch]$ReleaseUpload,
    
    [string]$TagName = "datasets-v1"
)

$ErrorActionPreference = "Stop"

Write-Host "=== PlatinumTrade Data Sync & Packaging Script ===" -ForegroundColor Cyan

# 1. Choose Environment (demo or real)
if ([string]::IsNullOrWhiteSpace($Datatype)) {
    $choices = @("&Demo", "&Real")
    $choice = $Host.UI.PromptForChoice("Select Datatype", "Choose the source data folder:", $choices, 0)
    $Datatype = if ($choice -eq 0) { "demo" } else { "real" }
}
Write-Host "Selected Datatype: $Datatype" -ForegroundColor Green

# 2. Resolve paths
$appData = [System.IO.Path]::Combine($env:LOCALAPPDATA, "PlatinumTrade", "Histories", $Datatype, "bin")
if (-not (Test-Path -LiteralPath $appData)) {
    throw "Source directory not found: $appData"
}

$repoRoot = $PSScriptRoot
$destManifestPath = Join-Path $repoRoot "manifest.json"

# 3. List available symbols
$availableSymbols = Get-ChildItem -Path $appData -Directory | Select-Object -ExpandProperty Name
if ($availableSymbols.Count -eq 0) {
    throw "No symbol directories found in $appData"
}

# Prompt or parse selection
$selectedSymbols = @()
if ([string]::IsNullOrWhiteSpace($Symbols)) {
    Write-Host "`nAvailable Symbols in ${Datatype}:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $availableSymbols.Count; $i++) {
        Write-Host "  [$i] $($availableSymbols[$i])"
    }

    $selectionInput = Read-Host "`nEnter symbol indices to sync (comma separated, e.g., 0,1 or '*' for all)"
} else {
    $selectionInput = $Symbols
}

if ($selectionInput.Trim() -eq "*") {
    $selectedSymbols = $availableSymbols
} else {
    $parts = $selectionInput -split "," | ForEach-Object { $_.Trim() }
    foreach ($part in $parts) {
        if ([int]::TryParse($part, [ref]$val) -and $val -ge 0 -and $val -lt $availableSymbols.Count) {
            $selectedSymbols += $availableSymbols[$val]
        } elseif ($availableSymbols -contains $part) {
            $selectedSymbols += $part
        } else {
            Write-Host "Invalid index or symbol name ignored: $part" -ForegroundColor Yellow
        }
    }
}

if ($selectedSymbols.Count -eq 0) {
    Write-Host "No symbols selected. Exiting." -ForegroundColor Red
    exit
}

Write-Host "`nSelected symbols for processing: $($selectedSymbols -join ', ')" -ForegroundColor Green

# 4. Load or create destination manifest.json
$destManifest = @{
    version = 1
    datasets = @()
}

if (Test-Path -LiteralPath $destManifestPath) {
    try {
        $jsonContent = Get-Content -LiteralPath $destManifestPath -Raw
        $parsed = ConvertFrom-Json $jsonContent
        if ($null -ne $parsed -and $null -ne $parsed.version) {
            $destManifest.version = $parsed.version
            # Copy existing datasets that are NOT being updated in this run
            foreach ($ds in $parsed.datasets) {
                $isUpdating = ($selectedSymbols -contains $ds.symbol) -and ($ds.datatype -eq $Datatype)
                if (-not $isUpdating) {
                    $destManifest.datasets += $ds
                }
            }
        }
    } catch {
        Write-Host "Warning: Could not parse existing manifest.json. Creating new one." -ForegroundColor Yellow
    }
}

# 5. Process each symbol
foreach ($symbol in $selectedSymbols) {
    $symbolDir = Join-Path $appData $symbol
    $localManifestPath = Join-Path $symbolDir "manifest.json"
    
    # Get lastYearMonth
    $lastYearMonth = ""
    if (Test-Path -LiteralPath $localManifestPath) {
        try {
            $localJson = Get-Content -LiteralPath $localManifestPath -Raw | ConvertFrom-Json
            if ($null -ne $localJson.partitions) {
                $partitionKeys = $localJson.partitions.psobject.properties.name | Sort-Object
                if ($partitionKeys.Count -gt 0) {
                    $lastYearMonth = $partitionKeys[-1]
                }
            }
        } catch {
            Write-Host "Warning: Failed to read local manifest for $symbol" -ForegroundColor Yellow
        }
    }
    
    # Fallback to scanning .bin files if manifest is missing or empty
    if ([string]::IsNullOrWhiteSpace($lastYearMonth)) {
        $binFiles = Get-ChildItem -Path $symbolDir -Filter "*.bin" | Select-Object -ExpandProperty BaseName | Sort-Object
        if ($binFiles.Count -gt 0) {
            $lastYearMonth = $binFiles[-1]
        } else {
            $lastYearMonth = "unknown"
        }
    }
    
    Write-Host "`nProcessing $symbol (Latest partition: $lastYearMonth)..." -ForegroundColor Cyan
    
    $zipFileName = "$symbol.zip"
    $zipPath = Join-Path $repoRoot $zipFileName
    
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    
    # Zip the folder contents (flat structure inside ZIP)
    Write-Host "Creating archive: $zipFileName"
    Compress-Archive -Path (Join-Path $symbolDir "*") -DestinationPath $zipPath
    
    # Add entry to manifest
    $datasetEntry = [ordered]@{
        symbol = $symbol
        datatype = $Datatype
        kind = "bin"
        file = $zipFileName
        lastYearMonth = $lastYearMonth
    }
    $destManifest.datasets += $datasetEntry
}

# Save manifest.json
$jsonOutput = ConvertTo-Json $destManifest -Depth 100
[System.IO.File]::WriteAllText($destManifestPath, $jsonOutput)
Write-Host "`nUpdated main manifest.json at: $destManifestPath" -ForegroundColor Green

# 6. Git Synchronization
$doGitSync = $GitSync.IsPresent
if (-not $PSBoundParameters.ContainsKey("GitSync")) {
    $gitChoice = $Host.UI.PromptForChoice("Git Sync", "Do you want to commit and push changes to Git?", @("&Yes", "&No"), 1)
    $doGitSync = ($gitChoice -eq 0)
}

if ($doGitSync) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot ".git"))) {
        Write-Host "Initializing git repository..." -ForegroundColor Yellow
        & git init
    }
    
    Write-Host "Running Git sync..." -ForegroundColor Cyan
    & git add manifest.json
    $commitMsg = "Update history datasets for " + ($selectedSymbols -join ", ")
    & git commit -m "$commitMsg"
    
    # Check if remote is configured
    $remote = & git remote
    if ([string]::IsNullOrWhiteSpace($remote)) {
        $defaultRemote = "https://github.com/vntradesoft/PlatinumTrade.Data.git"
        $remoteUrl = Read-Host "No git remote configured. Enter remote URL (Default: $defaultRemote)"
        if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
            $remoteUrl = $defaultRemote
        }
        if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
            & git remote add origin $remoteUrl
            & git branch -M main
            & git push -u origin main
        }
    } else {
        $branch = & git branch --show-current
        & git push origin $branch
    }
}

# 7. GitHub Release Upload (if gh CLI is available)
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($null -ne $gh) {
    $doReleaseUpload = $ReleaseUpload.IsPresent
    if (-not $PSBoundParameters.ContainsKey("ReleaseUpload")) {
        $releaseChoice = $Host.UI.PromptForChoice("GitHub Release Upload", "Do you want to upload ZIP files as release assets?", @("&Yes", "&No"), 1)
        $doReleaseUpload = ($releaseChoice -eq 0)
    }
    
    if ($doReleaseUpload) {
        if (-not $PSBoundParameters.ContainsKey("TagName") -and [string]::IsNullOrWhiteSpace($TagName)) {
            $TagName = Read-Host "Enter release tag name (e.g., datasets-v1)"
            if ([string]::IsNullOrWhiteSpace($TagName)) { $TagName = "datasets-v1" }
        }
        
        Write-Host "Uploading assets to release $TagName..." -ForegroundColor Cyan
        
        # Ensure release exists
        & gh release view $TagName --repo (git config --get remote.origin.url) 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Creating release $TagName..." -ForegroundColor Yellow
            & gh release create $tagName --title "History Datasets" --notes "Automated history data release"
        }
        
        # Upload manifest and zip files
        & gh release upload $TagName manifest.json --clobber
        foreach ($symbol in $selectedSymbols) {
            $zipFile = "$symbol.zip"
            & gh release upload $TagName $zipFile --clobber
        }
        Write-Host "Release upload completed successfully." -ForegroundColor Green
    }
} else {
    Write-Host "`nInfo: GitHub CLI (gh) is not installed. Skipping Release Upload option." -ForegroundColor DarkYellow
}

Write-Host "`nProcessing Completed!" -ForegroundColor Green
