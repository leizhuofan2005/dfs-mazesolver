# 全自动部署脚本 - 构建、推送、部署、获取访问地址

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  全自动部署 - 开始执行" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置信息
$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"
$AccessKeyId = "LTAI5tFDDZiMKb29RrdPSU3h"
$AccessKeySecret = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"

# 步骤 1: 检查 Docker
Write-Host "[步骤 1/6] 检查 Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  ✗ Docker 未安装，正在安装..." -ForegroundColor Yellow
    try {
        winget install --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        Write-Host "  ✓ Docker 安装完成，但需要重启终端" -ForegroundColor Green
        Write-Host "  请重启 PowerShell 后重新运行此脚本" -ForegroundColor Yellow
        exit 0
    } catch {
        Write-Host "  ✗ Docker 安装失败，请手动安装" -ForegroundColor Red
        Write-Host "  下载: https://www.docker.com/products/docker-desktop" -ForegroundColor White
        exit 1
    }
}

Write-Host "  ✓ Docker 已安装" -ForegroundColor Green

# 步骤 2: 登录 ACR（使用 AccessKey）
Write-Host ""
Write-Host "[步骤 2/6] 登录 ACR..." -ForegroundColor Yellow

# 尝试使用 AccessKey 登录（个人版可能需要账号密码，但先试试）
$loginResult = echo $AccessKeySecret | docker login --username=$AccessKeyId --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ ACR 登录成功（使用 AccessKey）" -ForegroundColor Green
} else {
    # 如果 AccessKey 登录失败，尝试使用账号密码
    Write-Host "  ⚠ AccessKey 登录失败，尝试其他方式..." -ForegroundColor Yellow
    
    # 使用阿里云 CLI 获取临时密码（如果可用）
    $aliyunCli = Get-Command aliyun -ErrorAction SilentlyContinue
    if ($aliyunCli) {
        try {
            aliyun configure set --profile default --mode AK --region cn-hangzhou --access-key-id $AccessKeyId --access-key-secret $AccessKeySecret 2>&1 | Out-Null
            $token = aliyun cr GetAuthorizationToken --Region cn-hangzhou 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ 获取临时密码成功" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ⚠ 无法自动获取登录凭证" -ForegroundColor Yellow
            Write-Host "  请手动登录：" -ForegroundColor Cyan
            Write-Host "  docker login --username=你的阿里云账号邮箱 $Registry" -ForegroundColor White
            Write-Host "  然后重新运行此脚本" -ForegroundColor White
            exit 1
        }
    } else {
        Write-Host "  ✗ 需要手动登录 ACR" -ForegroundColor Red
        Write-Host "  运行: docker login --username=你的阿里云账号邮箱 $Registry" -ForegroundColor White
        Write-Host "  然后重新运行此脚本" -ForegroundColor White
        exit 1
    }
}

# 步骤 3: 构建镜像
Write-Host ""
Write-Host "[步骤 3/6] 构建 Docker 镜像..." -ForegroundColor Yellow
Write-Host "  这可能需要 5-10 分钟，请耐心等待..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 镜像构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ 镜像构建成功" -ForegroundColor Green

# 步骤 4: 打标签并推送
Write-Host ""
Write-Host "[步骤 4/6] 推送镜像到 ACR..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName
docker push $FullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 镜像推送失败" -ForegroundColor Red
    Write-Host "  请检查 ACR 登录状态和权限" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ 镜像推送成功" -ForegroundColor Green
Write-Host "  镜像地址: $FullImageName" -ForegroundColor Cyan

# 步骤 5: 检查并更新部署配置
Write-Host ""
Write-Host "[步骤 5/6] 更新部署配置..." -ForegroundColor Yellow

# 更新 ack-deployment.yaml 中的镜像地址
$deploymentContent = Get-Content "ack-deployment.yaml" -Raw
$deploymentContent = $deploymentContent -replace 'registry\.cn-hangzhou\.aliyuncs\.com/algorithm-games/algorithm-games:latest', $FullImageName
$deploymentContent | Out-File -Encoding utf8 "ack-deployment.yaml" -NoNewline

Write-Host "  ✓ 部署配置已更新" -ForegroundColor Green

# 步骤 6: 部署到 ACK 并获取访问地址
Write-Host ""
Write-Host "[步骤 6/6] 部署到 ACK 并获取访问地址..." -ForegroundColor Yellow

# 检查 kubectl
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $kubectl) {
    Write-Host "  ⚠ kubectl 未安装" -ForegroundColor Yellow
    Write-Host "  镜像已构建完成，请手动部署：" -ForegroundColor Cyan
    Write-Host "  1. 获取 ACK 集群的 kubeconfig" -ForegroundColor White
    Write-Host "  2. 运行: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
    Write-Host "  3. 运行: kubectl get svc algorithm-games-service -n default" -ForegroundColor White
    Write-Host ""
    Write-Host "镜像地址: $FullImageName" -ForegroundColor Cyan
    exit 0
}

# 检查 kubeconfig
$kubeconfig = $env:KUBECONFIG
if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
    # 尝试查找 kubeconfig 文件
    $possibleKubeconfig = @(
        "kubeconfig.yaml",
        "$env:USERPROFILE\.kube\config",
        ".\kubeconfig.yaml"
    )
    
    $foundKubeconfig = $null
    foreach ($path in $possibleKubeconfig) {
        if (Test-Path $path) {
            $foundKubeconfig = (Resolve-Path $path).Path
            break
        }
    }
    
    if ($foundKubeconfig) {
        $env:KUBECONFIG = $foundKubeconfig
        Write-Host "  ✓ 找到 kubeconfig: $env:KUBECONFIG" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 未找到 kubeconfig" -ForegroundColor Yellow
        Write-Host "  镜像已构建完成，请完成以下步骤：" -ForegroundColor Cyan
        Write-Host "  1. 在 ACK 控制台获取 kubeconfig" -ForegroundColor White
        Write-Host "  2. 保存为 kubeconfig.yaml" -ForegroundColor White
        Write-Host "  3. 运行: `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor White
        Write-Host "  4. 运行: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
        Write-Host ""
        Write-Host "镜像地址: $FullImageName" -ForegroundColor Cyan
        exit 0
    }
}

# 测试集群连接
Write-Host "  测试集群连接..." -ForegroundColor Gray
$nodes = kubectl get nodes 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 集群连接失败" -ForegroundColor Red
    Write-Host "  请检查 kubeconfig 配置" -ForegroundColor Yellow
    Write-Host "镜像地址: $FullImageName" -ForegroundColor Cyan
    exit 1
}

Write-Host "  ✓ 集群连接成功" -ForegroundColor Green

# 部署应用
Write-Host "  部署应用..." -ForegroundColor Gray
kubectl apply -f ack-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 部署失败" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ 部署配置已应用" -ForegroundColor Green

# 等待 Pod 启动
Write-Host "  等待 Pod 启动（约 30 秒）..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# 获取访问地址
Write-Host "  获取访问地址..." -ForegroundColor Gray

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
            # 继续等待
        }
    }
    $attempt++
    if ($attempt -lt $maxAttempts) {
        Write-Host "    尝试 $attempt/$maxAttempts - 等待 LoadBalancer IP..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  部署完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($externalIP) {
    Write-Host "  访问地址: http://$externalIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  如果无法访问，请等待 1-2 分钟让服务完全启动" -ForegroundColor Yellow
} else {
    Write-Host "  部署成功，但外部 IP 尚未分配" -ForegroundColor Yellow
    Write-Host "  请稍后运行以下命令查看：" -ForegroundColor White
    Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
}

Write-Host ""
Write-Host "当前状态：" -ForegroundColor Cyan
kubectl get pods -n default -l app=algorithm-games
kubectl get svc algorithm-games-service -n default

Write-Host ""


