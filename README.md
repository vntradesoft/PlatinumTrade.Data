# PlatinumTrade.Data

**English** | [Vietnamese](README.vi.md)

Storage and distribution repository for candlestick history data used by the **PlatinumTrade** project.

This repository contains the main `manifest.json` file which guides the client downloader, and the compressed `.zip` data packages containing binary candlestick history for each Symbol.

---

## 📂 Automation Scripts

The repository provides two PowerShell scripts to automate the data packaging and publishing process to GitHub:

### 1. Main Script: `sync-data.ps1`
A versatile script that automates the entire workflow: scanning local data, packaging into ZIP files, creating/updating the main `manifest.json`, performing Git sync, and uploading assets directly to GitHub Releases.

### 2. Shortcut Script: `sync-btc-eth.ps1`
A helper script designed to **quickly sync only 2 Symbols: `BTC-USDT-SWAP` and `ETH-USDT-SWAP`**.
*   It directly calls the main script `sync-data.ps1` with preconfigured parameters.
*   You only need to select the datatype (`demo` or `real`) and the script handles the rest automatically without requiring any further input.

---

## 🛠 Prerequisites & Initial Setup

To ensure the automation runs smoothly, you need to configure the following tools once:

### 1. Install and log in to GitHub CLI (`gh`)
*   **Installation:** Open PowerShell and run:
    ```powershell
    winget install --id GitHub.cli
    ```
    *(Restart PowerShell after installation)*
*   **Authenticate Account (Requires write/owner permission to this repo):**
    ```powershell
    gh auth login
    ```
    Select **GitHub.com** -> Select **HTTPS** -> Select **Yes** to sync Git credentials -> Select **Login with a web browser** and enter the OTP code displayed on the screen into your browser to authenticate.

### 2. Configure Git Remote for Local Directory
If your script directory is not yet connected to GitHub, run these commands to initialize and link:
```powershell
git init
git remote add origin https://github.com/vntradesoft/PlatinumTrade.Data.git
git branch -M main
```

> ⚠️ **Note on Git Push (Rejected) issues:**
> If the git push is rejected due to history mismatch with GitHub (usually on the first run after `git init`), run the following command to pull remote commits before pushing:
> ```powershell
> git pull origin main --allow-unrelated-histories --rebase
> git push origin main
> ```

---

## 🚀 How to Use the Scripts

Open PowerShell in this directory and choose one of the following execution methods:

### Option 1: Fast Sync BTC & ETH (Recommended for general data updates)
Run the shortcut script to quickly sync these two symbols to GitHub Releases:
```powershell
powershell -ExecutionPolicy Bypass -File .\sync-btc-eth.ps1
```

### Option 2: Run Main Script in Interactive Mode
Run the main script and follow the on-screen prompts to configure the run details:
```powershell
powershell -ExecutionPolicy Bypass -File .\sync-data.ps1
```

### Option 3: Run Main Script in Automated (Non-Interactive) Mode
Use command-line parameters to run silently or integrate with CI/CD without manual input:

*   **Upload all Demo datasets, commit changes, and publish to Release `datasets-v1`:**
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\sync-data.ps1 -Datatype demo -Symbols * -GitSync -ReleaseUpload -TagName datasets-v1
    ```
*   **Only pack and sync specific Symbols (e.g. BTC and ETH):**
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\sync-data.ps1 -Datatype demo -Symbols "BTC-USDT-SWAP,ETH-USDT-SWAP" -GitSync -ReleaseUpload
    ```

---

## 📝 `sync-data.ps1` Parameter Reference

| Parameter | Data Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `-Datatype` | `string` | None (will prompt) | The source data type: `"demo"` or `"real"`. |
| `-Symbols` | `string` | None (will prompt) | Comma-separated list of symbols to process (e.g., `"BTC-USDT-SWAP,ETH-USDT-SWAP"`), indices, or `"*"` for all. |
| `-GitSync` | `switch` | None (will prompt) | Automatically commits and pushes the updated `manifest.json` to Git. |
| `-ReleaseUpload`| `switch` | None (will prompt) | Automatically uploads the ZIP files to GitHub Releases as download assets. |
| `-TagName` | `string` | `"datasets-v1"` | The release tag on GitHub where ZIP assets are uploaded. |
