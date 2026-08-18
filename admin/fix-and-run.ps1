# Abdul Ghaffar Meat Shop — Admin Dashboard Fix & Run Script
# Run this in PowerShell as Administrator

Write-Host "=== Abdul Ghaffar Meat Shop Admin - Fix & Run ===" -ForegroundColor Green

# Step 1: Kill any running Next.js processes
Write-Host "`n[1/6] Cleaning up old processes..." -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Step 2: Remove node_modules safely (handle EPERM)
Write-Host "[2/6] Removing corrupted node_modules..." -ForegroundColor Cyan
$nodeModules = "D:\Quater-5\A-Gaffar meat shop\admin\node_modules"
if (Test-Path $nodeModules) {
    # Use robust deletion with retries
    $retries = 3
    for ($i = 0; $i -lt $retries; $i++) {
        try {
            Remove-Item -Path $nodeModules -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ node_modules deleted" -ForegroundColor Green
            break
        } catch {
            Write-Host "  Retry $($i+1): $_" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
}

# Step 3: Remove package-lock.json
Write-Host "[3/6] Removing package-lock.json..." -ForegroundColor Cyan
$lockFile = "D:\Quater-5\A-Gaffar meat shop\admin\package-lock.json"
if (Test-Path $lockFile) {
    Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ package-lock.json deleted" -ForegroundColor Green
}

# Step 4: Disable Windows Defender real-time scanning for this folder (speeds up npm)
Write-Host "[4/6] Optimizing Windows Defender..." -ForegroundColor Cyan
try {
    Add-MpPreference -ExclusionPath "D:\Quater-5\A-Gaffar meat shop\admin\node_modules" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "D:\Quater-5\A-Gaffar meat shop\admin\.next" -ErrorAction SilentlyContinue
    Write-Host "  ✓ Defender exclusions added" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ Could not add exclusions (not critical)" -ForegroundColor Yellow
}

# Step 5: Install dependencies
Write-Host "[5/6] Installing npm dependencies..." -ForegroundColor Cyan
Set-Location "D:\Quater-5\A-Gaffar meat shop\admin"
npm install --no-optional --legacy-peer-deps 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  npm install failed. Trying with --force..." -ForegroundColor Yellow
    npm install --no-optional --legacy-peer-deps --force 2>&1
}
Write-Host "  ✓ npm install complete" -ForegroundColor Green

# Step 6: Start dev server
Write-Host "[6/6] Starting development server..." -ForegroundColor Cyan
Write-Host "  → Opening http://localhost:3000" -ForegroundColor Magenta
npm run dev
