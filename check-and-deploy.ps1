# Smart deploy script that handles Docker installation

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto Deploy Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"

# Check Docker
Write-Host "[1/6] Checking Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  Docker not found" -ForegroundColor Yellow
    Write-Host "  Docker is required for building images" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  1. Install Docker Desktop (recommended)" -ForegroundColor White
    Write-Host "     Download: https://www.docker.com/products/docker-desktop" -ForegroundColor Gray
    Write-Host "     Or: winget install Docker.DockerDesktop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Use ACR build service (if available)" -ForegroundColor White
    Write-Host "     Configure build rules in ACR console" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Wait for Docker installation to complete" -ForegroundColor White
    Write-Host "     Then restart PowerShell and run this script again" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host "  OK Docker is installed" -ForegroundColor Green

# Check if Docker is running
Write-Host "  Checking if Docker is running..." -ForegroundColor Gray
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Docker is not running" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop and run this script again" -ForegroundColor Yellow
    exit 1
}

Write-Host "  OK Docker is running" -ForegroundColor Green

# Login to ACR
Write-Host ""
Write-Host "[2/6] Logging into ACR..." -ForegroundColor Yellow

# Try AccessKey login
$AccessKeyId = "LTAI5tFDDZiMKb29RrdPSU3h"
$AccessKeySecret = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"

$loginResult = echo $AccessKeySecret | docker login --username=$AccessKeyId --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK ACR login successful" -ForegroundColor Green
} else {
    Write-Host "  X AccessKey login failed" -ForegroundColor Red
    Write-Host "  Error: $loginResult" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please login manually:" -ForegroundColor Cyan
    Write-Host "  docker login --username=your-aliyun-email $Registry" -ForegroundColor White
    Write-Host "  Password: Your ACR service password (not AccessKey)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Then run this script again" -ForegroundColor White
    exit 1
}

# Build image
Write-Host ""
Write-Host "[3/6] Building Docker image..." -ForegroundColor Yellow
Write-Host "  This will take 5-10 minutes..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Image built successfully" -ForegroundColor Green

# Tag and push
Write-Host ""
Write-Host "[4/6] Pushing image to ACR..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName
docker push $FullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Push failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Image pushed successfully" -ForegroundColor Green
Write-Host "  Image: $FullImageName" -ForegroundColor Cyan

# Update deployment config
Write-Host ""
Write-Host "[5/6] Updating deployment config..." -ForegroundColor Yellow

$deploymentContent = Get-Content "ack-deployment.yaml" -Raw
$deploymentContent = $deploymentContent -replace 'registry\.cn-hangzhou\.aliyuncs\.com/algorithm-games/algorithm-games:latest', $FullImageName
$deploymentContent | Out-File -Encoding utf8 "ack-deployment.yaml" -NoNewline

Write-Host "  OK Config updated" -ForegroundColor Green

# Deploy to ACK
Write-Host ""
Write-Host "[6/6] Deploying to ACK..." -ForegroundColor Yellow

$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectl) {
    Write-Host "  X kubectl not found" -ForegroundColor Yellow
    Write-Host "  Image built and pushed successfully!" -ForegroundColor Green
    Write-Host "  Image: $FullImageName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Get ACK cluster kubeconfig" -ForegroundColor White
    Write-Host "  2. Run: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
    exit 0
}

# Check kubeconfig
$kubeconfig = $env:KUBECONFIG
if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
    $possibleKubeconfig = @("kubeconfig.yaml", "$env:USERPROFILE\.kube\config")
    $found = $null
    foreach ($path in $possibleKubeconfig) {
        if (Test-Path $path) {
            $found = (Resolve-Path $path).Path
            break
        }
    }
    if ($found) {
        $env:KUBECONFIG = $found
        Write-Host "  OK Found kubeconfig" -ForegroundColor Green
    } else {
        Write-Host "  X kubeconfig not found" -ForegroundColor Yellow
        Write-Host "  Image built and pushed successfully!" -ForegroundColor Green
        Write-Host "  Image: $FullImageName" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Get kubeconfig from ACK console and save as kubeconfig.yaml" -ForegroundColor White
        Write-Host "  Then run: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
        exit 0
    }
}

# Test connection
kubectl get nodes 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Cannot connect to cluster" -ForegroundColor Red
    Write-Host "  Image: $FullImageName" -ForegroundColor Cyan
    exit 1
}

Write-Host "  OK Cluster connected" -ForegroundColor Green

# Deploy
kubectl apply -f ack-deployment.yaml | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Deployment applied" -ForegroundColor Green

# Wait and get URL
Write-Host "  Waiting for service (30 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

$svcJson = kubectl get svc algorithm-games-service -n default -o json 2>&1
if ($LASTEXITCODE -eq 0) {
    try {
        $svc = $svcJson | ConvertFrom-Json
        $externalIP = $svc.status.loadBalancer.ingress[0].ip
        if (-not $externalIP) {
            $externalIP = $svc.status.loadBalancer.ingress[0].hostname
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  Deployment Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Access URL: http://$externalIP" -ForegroundColor Cyan
        Write-Host ""
    } catch {
        Write-Host "  Deployment successful, checking status..." -ForegroundColor Yellow
        kubectl get svc algorithm-games-service -n default
    }
} else {
    Write-Host "  Deployment applied, check status:" -ForegroundColor Yellow
    kubectl get svc algorithm-games-service -n default
}

Write-Host ""


