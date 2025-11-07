# Railway Deployment Check Script
Write-Host "Checking deployment configuration..." -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# Check 1: Backend requirements.txt
Write-Host "Checking backend dependencies..." -ForegroundColor Yellow
if (Test-Path "backend\requirements.txt") {
    $req = Get-Content "backend\requirements.txt"
    if ($req -match "fastapi" -and $req -match "uvicorn") {
        Write-Host "  [OK] backend/requirements.txt exists with required dependencies" -ForegroundColor Green
    } else {
        $errors += "backend/requirements.txt missing required dependencies"
    }
} else {
    $errors += "backend/requirements.txt does not exist"
}

# Check 2: Frontend package.json
Write-Host "Checking frontend configuration..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    $pkg = Get-Content "package.json" | ConvertFrom-Json
    if ($pkg.scripts.build) {
        Write-Host "  [OK] package.json exists with build script" -ForegroundColor Green
    } else {
        $errors += "package.json missing build script"
    }
} else {
    $errors += "package.json does not exist"
}

# Check 3: API configuration
Write-Host "Checking API configuration..." -ForegroundColor Yellow
if (Test-Path "src\config.ts") {
    $config = Get-Content "src\config.ts" -Raw
    if ($config -match "VITE_API_URL") {
        Write-Host "  [OK] src/config.ts configured for environment variables" -ForegroundColor Green
    } else {
        $errors += "src/config.ts not configured for VITE_API_URL"
    }
} else {
    $errors += "src/config.ts does not exist"
}

# Check 4: Backend main.py
Write-Host "Checking backend main file..." -ForegroundColor Yellow
if (Test-Path "backend\main.py") {
    $main = Get-Content "backend\main.py" -Raw
    if ($main -match "FastAPI" -and $main -match "CORS") {
        Write-Host "  [OK] backend/main.py exists and configured correctly" -ForegroundColor Green
    } else {
        $warnings += "backend/main.py may be missing CORS configuration"
    }
} else {
    $errors += "backend/main.py does not exist"
}

# Check 5: Git status
Write-Host "Checking Git status..." -ForegroundColor Yellow
try {
    $gitStatus = git status --porcelain 2>&1
    if ($gitStatus -and $gitStatus -notmatch "fatal") {
        $warnings += "There are uncommitted changes, recommend committing first"
        Write-Host "  [WARN] Uncommitted changes detected" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Working directory is clean" -ForegroundColor Green
    }
} catch {
    $warnings += "Cannot check Git status"
}

# Check 6: Build test
Write-Host "Testing frontend build..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    try {
        npm run build 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Frontend build successful" -ForegroundColor Green
        } else {
            $errors += "Frontend build failed"
        }
    } catch {
        $warnings += "Cannot test build (may need to run npm install first)"
    }
} else {
    $warnings += "node_modules does not exist, need to run npm install first"
}

# Output results
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "[SUCCESS] All checks passed! Ready to deploy" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Found $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "[WARNING] Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Ensure code is pushed to GitHub" -ForegroundColor White
Write-Host "2. Visit https://railway.app/dashboard" -ForegroundColor White
Write-Host "3. Follow steps in RAILWAY_DEPLOY.md" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor Cyan
