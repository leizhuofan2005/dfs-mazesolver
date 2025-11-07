# 完整自动化部署脚本 - 获取访问地址

$ErrorActionPreference = "Continue"

$Namespace = "algorithm-games"
$Region = "cn-hangzhou"
$ImageUrl = "registry.$Region.aliyuncs.com/$Namespace/algorithm-games:latest"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  完整自动化部署 - 获取访问地址" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 设置环境变量
$env:ALIBABA_CLOUD_ACCESS_KEY_ID = "LTAI5tFDDZiMKb29RrdPSU3h"
$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"
$env:ALIBABA_CLOUD_REGION = $Region

# 检查阿里云 CLI
Write-Host "[1/6] 检查阿里云 CLI..." -ForegroundColor Yellow
$aliyunCli = Get-Command aliyun -ErrorAction SilentlyContinue

if ($aliyunCli) {
    Write-Host "  ✓ 阿里云 CLI 已安装" -ForegroundColor Green
    
    # 配置 CLI
    try {
        aliyun configure set --profile default --mode AK --region $Region --access-key-id $env:ALIBABA_CLOUD_ACCESS_KEY_ID --access-key-secret $env:ALIBABA_CLOUD_ACCESS_KEY_SECRET 2>&1 | Out-Null
        Write-Host "  ✓ CLI 配置成功" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ CLI 配置失败" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ 阿里云 CLI 未安装" -ForegroundColor Yellow
    Write-Host "  安装命令: npm install -g @alicloud/cli" -ForegroundColor Gray
}

# 检查 kubectl
Write-Host ""
Write-Host "[2/6] 检查 kubectl..." -ForegroundColor Yellow
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if ($kubectl) {
    Write-Host "  ✓ kubectl 已安装" -ForegroundColor Green
} else {
    Write-Host "  ⚠ kubectl 未安装" -ForegroundColor Yellow
    Write-Host "  请在新终端中使用 kubectl（需要重启终端）" -ForegroundColor Gray
}

# 检查 kubeconfig
Write-Host ""
Write-Host "[3/6] 检查 kubeconfig..." -ForegroundColor Yellow
$kubeconfig = $env:KUBECONFIG

if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
    Write-Host "  ⚠ KUBECONFIG 未设置" -ForegroundColor Yellow
    
    # 尝试查找 kubeconfig 文件
    $possibleKubeconfig = @(
        "kubeconfig.yaml",
        "$env:USERPROFILE\.kube\config",
        ".\kubeconfig.yaml"
    )
    
    $foundKubeconfig = $null
    foreach ($path in $possibleKubeconfig) {
        if (Test-Path $path) {
            $foundKubeconfig = $path
            break
        }
    }
    
    if ($foundKubeconfig) {
        $env:KUBECONFIG = (Resolve-Path $foundKubeconfig).Path
        Write-Host "  ✓ 找到 kubeconfig: $env:KUBECONFIG" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 未找到 kubeconfig 文件" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  请完成以下步骤获取 kubeconfig:" -ForegroundColor Cyan
        Write-Host "  1. 登录: https://cs.console.aliyun.com" -ForegroundColor White
        Write-Host "  2. 选择集群 -> 连接信息" -ForegroundColor White
        Write-Host "  3. 复制 kubeconfig 并保存为 kubeconfig.yaml" -ForegroundColor White
        Write-Host "  4. 设置: `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host "  ✓ KUBECONFIG: $kubeconfig" -ForegroundColor Green
}

# 测试集群连接
if ($kubectl -and $env:KUBECONFIG) {
    Write-Host ""
    Write-Host "[4/6] 测试集群连接..." -ForegroundColor Yellow
    try {
        $nodes = kubectl get nodes 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ 集群连接成功" -ForegroundColor Green
            $clusterConnected = $true
        } else {
            Write-Host "  ✗ 集群连接失败" -ForegroundColor Red
            $clusterConnected = $false
        }
    } catch {
        Write-Host "  ✗ 集群连接失败: $_" -ForegroundColor Red
        $clusterConnected = $false
    }
} else {
    $clusterConnected = $false
    Write-Host ""
    Write-Host "[4/6] 跳过集群连接测试（kubectl 或 kubeconfig 未配置）" -ForegroundColor Yellow
}

# 部署应用
if ($clusterConnected) {
    Write-Host ""
    Write-Host "[5/6] 部署应用到 ACK..." -ForegroundColor Yellow
    
    # 检查镜像是否存在（提示）
    Write-Host "  Warning: Please ensure image is built: $ImageUrl" -ForegroundColor Yellow
    Write-Host "  If not built, trigger build in ACR console" -ForegroundColor Gray
    Write-Host ""
    
    # 应用部署配置
    kubectl apply -f ack-deployment.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 部署配置已应用" -ForegroundColor Green
        
        # 等待 Pod 启动
        Write-Host "  等待 Pod 启动..." -ForegroundColor Gray
        Start-Sleep -Seconds 20
        
        # 检查 Pod 状态
        $pods = kubectl get pods -n default -l app=algorithm-games 2>&1
        Write-Host "  Pod 状态:" -ForegroundColor Gray
        Write-Host $pods -ForegroundColor Gray
    } else {
        Write-Host "  ✗ 部署失败" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "[5/6] 跳过部署（集群未连接）" -ForegroundColor Yellow
}

# 获取访问地址
Write-Host ""
Write-Host "[6/6] 获取访问地址..." -ForegroundColor Yellow

if ($clusterConnected) {
    # 获取服务信息
    $svcInfo = kubectl get svc algorithm-games-service -n default -o json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        try {
            $svc = $svcInfo | ConvertFrom-Json
            
            if ($svc.status.loadBalancer.ingress) {
                $externalIP = $svc.status.loadBalancer.ingress[0].ip
                if (-not $externalIP) {
                    $externalIP = $svc.status.loadBalancer.ingress[0].hostname
                }
                
                if ($externalIP -and $externalIP -ne "<pending>") {
                    Write-Host ""
                    Write-Host "========================================" -ForegroundColor Green
                    Write-Host "  部署成功！" -ForegroundColor Green
                    Write-Host "========================================" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "  访问地址: http://$externalIP" -ForegroundColor Cyan
                    Write-Host ""
                    Write-Host "  如果无法访问，请等待 1-2 分钟让 LoadBalancer 完成配置" -ForegroundColor Yellow
                    Write-Host ""
                } else {
                    Write-Host "  ⏳ 等待 LoadBalancer 分配外部 IP..." -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "  请稍后运行以下命令查看:" -ForegroundColor White
                    Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
                    Write-Host ""
                }
            } else {
                Write-Host "  ⏳ LoadBalancer 正在分配外部 IP，请稍候..." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  查看状态:" -ForegroundColor White
                Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
                Write-Host ""
            }
        } catch {
            Write-Host "  ⚠ 解析服务信息失败" -ForegroundColor Yellow
            Write-Host "  服务信息:" -ForegroundColor Gray
            Write-Host $svcInfo -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ 获取服务信息失败" -ForegroundColor Red
        Write-Host "  请检查部署状态:" -ForegroundColor White
        Write-Host "  kubectl get svc -n default" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ 无法获取访问地址（集群未连接）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  请完成以下步骤:" -ForegroundColor Cyan
    Write-Host "  1. 配置 kubeconfig" -ForegroundColor White
    Write-Host "  2. 运行: kubectl apply -f ack-deployment.yaml" -ForegroundColor White
    Write-Host "  3. 运行: kubectl get svc algorithm-games-service -n default" -ForegroundColor White
    Write-Host ""
}

# 显示服务状态
if ($clusterConnected) {
    Write-Host "当前服务状态:" -ForegroundColor Cyan
    kubectl get svc algorithm-games-service -n default 2>&1
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

