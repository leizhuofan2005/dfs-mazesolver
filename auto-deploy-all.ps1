# Full Auto Deploy Script

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Full Auto Deploy - Starting" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"
$AccessKeyId = "LTAI5tFDDZiMKb29RrdPSU3h"
$AccessKeySecret = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"

# Step 1: Check Docker
Write-Host "[Step 1/6] Checking Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  X Docker not installed" -ForegroundColor Red
    Write-Host "  Installing Docker..." -ForegroundColor Yellow
    try {
        winget install --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        Write-Host "  Docker installed, but requires terminal restart" -ForegroundColor Green
        Write-Host "  Please restart PowerShell and run this script again" -ForegroundColor Yellow
        exit 0
    } catch {
        Write-Host "  X Docker installation failed" -ForegroundColor Red
        Write-Host "  Please install manually: https://www.docker.com/products/docker-desktop" -ForegroundColor White
        exit 1
    }
}

Write-Host "  OK Docker installed" -ForegroundColor Green

# Step 2: Login to ACR
Write-Host ""
Write-Host "[Step 2/6] Logging into ACR..." -ForegroundColor Yellow

# Try AccessKey first
$loginResult = echo $AccessKeySecret | docker login --username=$AccessKeyId --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK ACR login successful (using AccessKey)" -ForegroundColor Green
} else {
    Write-Host "  X AccessKey login failed" -ForegroundColor Red
    Write-Host "  Please login manually:" -ForegroundColor Yellow
    Write-Host "  docker login --username=your-aliyun-email $Registry" -ForegroundColor White
    Write-Host "  Then run this script again" -ForegroundColor White
    exit 1
}

# Step 3: Build image
Write-Host ""
Write-Host "[Step 3/6] Building Docker image..." -ForegroundColor Yellow
Write-Host "  This may take 5-10 minutes, please wait..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Image build failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Image built successfully" -ForegroundColor Green

# Step 4: Tag and push
Write-Host ""
Write-Host "[Step 4/6] Pushing image to ACR..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName
docker push $FullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Image push failed" -ForegroundColor Red
    Write-Host "  Please check ACR login status and permissions" -ForegroundColor Yellow
    exit 1
}

Write-Host "  OK Image pushed successfully" -ForegroundColor Green
Write-Host "  Image: $FullImageName" -ForegroundColor Cyan

# Step 5: Update deployment config
Write-Host ""
Write-Host "[Step 5/6] Updating deployment config..." -ForegroundColor Yellow

$deploymentContent = Get-Content "ack-deployment.yaml" -Raw
$deploymentContent = $deploymentContent -replace 'registry\.cn-hangzhou\.aliyuncs\.com/algorithm-games/algorithm-games:latest', $FullImageName
$deploymentContent | Out-File -Encoding utf8 "ack-deployment.yaml" -NoNewline

Write-Host "  OK Deployment config updated" -ForegroundColor Green

# Step 6: Deploy to ACK
Write-Host ""
Write-Host "[Step 6/6] Deploying to ACK and getting access URL..." -ForegroundColor Yellow

$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $kubectl) {
    Write-Host "  X kubectl not installed" -ForegroundColor Yellow
    Write-Host "  Image built successfully. Please deploy manually:" -ForegroundColor Cyan
    Write-Host "  1. Get ACK cluster kubeconfig" -ForegroundColor White
    Write-Host "  2. Run: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
    Write-Host "  3. Run: kubectl get svc algorithm-games-service -n default" -ForegroundColor White
    Write-Host ""
    Write-Host "Image: $FullImageName" -ForegroundColor Cyan
    exit 0
}

# Check kubeconfig
$kubeconfig = $env:KUBECONFIG
if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
    $possibleKubeconfig = @("kubeconfig.yaml", "$env:USERPROFILE\.kube\config", ".\kubeconfig.yaml")
    $foundKubeconfig = $null
    foreach ($path in $possibleKubeconfig) {
        if (Test-Path $path) {
            $foundKubeconfig = (Resolve-Path $path).Path
            break
        }
    }
    if ($foundKubeconfig) {
        $env:KUBECONFIG = $foundKubeconfig
        Write-Host "  OK Found kubeconfig: $env:KUBECONFIG" -ForegroundColor Green
    } else {
        Write-Host "  X kubeconfig not found" -ForegroundColor Yellow
        Write-Host "  Image built successfully. Please complete:" -ForegroundColor Cyan
        Write-Host "  1. Get kubeconfig from ACK console" -ForegroundColor White
        Write-Host "  2. Save as kubeconfig.yaml" -ForegroundColor White
        Write-Host "  3. Run: `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor White
        Write-Host "  4. Run: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
        Write-Host ""
        Write-Host "Image: $FullImageName" -ForegroundColor Cyan
        exit 0
    }
}

# Test cluster connection
Write-Host "  Testing cluster connection..." -ForegroundColor Gray
$nodes = kubectl get nodes 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Cluster connection failed" -ForegroundColor Red
    Write-Host "  Please check kubeconfig configuration" -ForegroundColor Yellow
    Write-Host "Image: $FullImageName" -ForegroundColor Cyan
    exit 1
}

Write-Host "  OK Cluster connected" -ForegroundColor Green

# Deploy
Write-Host "  Deploying application..." -ForegroundColor Gray
kubectl apply -f ack-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "  OK Deployment applied" -ForegroundColor Green

# Wait for pods
Write-Host "  Waiting for pods to start (30 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Get access URL
Write-Host "  Getting access URL..." -ForegroundColor Gray

$maxAttempts = 12
$attempt = 0
$externalIP = $null

while ($attempt -lt $maxAttempts) {
    $svcJson = kubectl get svc algorithm-games-service -n default -o json 2>&1
    if ($LASTEXITCODE -eq 0) {
        try {
            $svc = $svcJson | ConvertFrom-Json
            if ($svc.status.loadBalancer.ingress) {
                $externalIP = $svc.status.loadBalancer.ingress[0].ip
                if (-not $externalIP) {
                    $externalIP = $svc.status.loadBalancer.ingress[0].hostname
                }
                if ($externalIP -and $externalIP -ne "<pending>") {
                    break
                }
            }
        } catch {
        }
    }
    $attempt++
    if ($attempt -lt $maxAttempts) {
        Write-Host "    Attempt $attempt/$maxAttempts - Waiting for LoadBalancer IP..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($externalIP) {
    Write-Host "  Access URL: http://$externalIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  If unable to access, wait 1-2 minutes for service to fully start" -ForegroundColor Yellow
} else {
    Write-Host "  Deployment successful, but external IP not yet assigned" -ForegroundColor Yellow
    Write-Host "  Check later with:" -ForegroundColor White
    Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Current status:" -ForegroundColor Cyan
kubectl get pods -n default -l app=algorithm-games
kubectl get svc algorithm-games-service -n default

Write-Host ""


