# 部署并获取访问地址

$ErrorActionPreference = "Continue"

Write-Host "Deploying to ACK and getting access URL..." -ForegroundColor Green
Write-Host ""

# 检查 kubectl
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $kubectl) {
    Write-Host "kubectl not found. Please install it first." -ForegroundColor Yellow
    Write-Host "Install: winget install Kubernetes.kubectl" -ForegroundColor White
    Write-Host ""
    Write-Host "Or deploy via console:" -ForegroundColor Cyan
    Write-Host "1. Login: https://cs.console.aliyun.com" -ForegroundColor White
    Write-Host "2. Select cluster -> Workloads -> Stateless -> Create with Image" -ForegroundColor White
    Write-Host "3. Image: registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest" -ForegroundColor White
    exit 1
}

# 检查 kubeconfig
$kubeconfig = $env:KUBECONFIG
if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
    Write-Host "KUBECONFIG not set. Please configure it first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To get kubeconfig:" -ForegroundColor Cyan
    Write-Host "1. Login: https://cs.console.aliyun.com" -ForegroundColor White
    Write-Host "2. Select cluster -> Connection Info" -ForegroundColor White
    Write-Host "3. Copy kubeconfig and save to file" -ForegroundColor White
    Write-Host "4. Set: `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor White
    exit 1
}

# 应用部署配置
Write-Host "Applying deployment configuration..." -ForegroundColor Yellow
kubectl apply -f ack-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting for pods to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 获取服务信息
Write-Host ""
Write-Host "Getting service information..." -ForegroundColor Yellow
kubectl get svc algorithm-games-service -n default

Write-Host ""
Write-Host "Checking for external IP..." -ForegroundColor Yellow

# 等待 LoadBalancer 分配 IP
$maxAttempts = 12
$attempt = 0
$externalIP = $null

while ($attempt -lt $maxAttempts) {
    $svcJson = kubectl get svc algorithm-games-service -n default -o json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $svcInfo = $svcJson | ConvertFrom-Json
        if ($svcInfo.status.loadBalancer.ingress) {
            $externalIP = $svcInfo.status.loadBalancer.ingress[0].ip
            if (-not $externalIP) {
                $externalIP = $svcInfo.status.loadBalancer.ingress[0].hostname
            }
            if ($externalIP) {
                break
            }
        }
    }
    $attempt++
    Write-Host "  Attempt $attempt/$maxAttempts - Waiting for LoadBalancer IP..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

Write-Host ""
if ($externalIP) {
    Write-Host "Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access URL: http://$externalIP" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Deployment applied, but external IP not yet assigned." -ForegroundColor Yellow
    Write-Host "Please check later with:" -ForegroundColor White
    Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or check in ACK console:" -ForegroundColor White
    Write-Host "  https://cs.console.aliyun.com" -ForegroundColor Gray
}

Write-Host "Pod status:" -ForegroundColor Cyan
kubectl get pods -n default -l app=algorithm-games

Write-Host ""


