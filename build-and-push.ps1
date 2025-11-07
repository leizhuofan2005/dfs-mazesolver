# Build and push to ACR

$ErrorActionPreference = "Continue"

$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build and Push to ACR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "[1/5] Checking Docker..." -ForegroundColor Yellow
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Docker is not running, please start Docker Desktop" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Docker is running" -ForegroundColor Green

# Login to ACR
Write-Host ""
Write-Host "[2/5] Login to ACR..." -ForegroundColor Yellow
Write-Host "  Please enter your Alibaba Cloud account email and ACR password" -ForegroundColor Gray
Write-Host ""

$username = Read-Host "Alibaba Cloud account email"
$password = Read-Host "ACR service password" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

Write-Host ""
Write-Host "Logging in..." -ForegroundColor Cyan
$loginResult = echo $plainPassword | docker login --username=$username --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK ACR login successful" -ForegroundColor Green
} else {
    Write-Host "  X ACR login failed" -ForegroundColor Red
    Write-Host "  Error: $loginResult" -ForegroundColor Yellow
    exit 1
}

# Build image
Write-Host ""
Write-Host "[3/5] Building Docker image..." -ForegroundColor Yellow
Write-Host "  This will take 5-10 minutes, please wait..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Image build failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Image built successfully" -ForegroundColor Green

# Tag image
Write-Host ""
Write-Host "[4/5] Tagging image..." -ForegroundColor Yellow
docker tag $ImageName $FullImageName
Write-Host "  OK Tag created" -ForegroundColor Green

# Push image
Write-Host ""
Write-Host "[5/5] Pushing image to ACR..." -ForegroundColor Yellow
docker push $FullImageName

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK Image pushed successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Build Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Image: $FullImageName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next step: Deploy to ACK" -ForegroundColor Yellow
    Write-Host "  Run: .\deploy-and-get-url.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  X Image push failed" -ForegroundColor Red
    Write-Host "  Please check login status and permissions" -ForegroundColor Yellow
}
