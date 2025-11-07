# 完整自动化部署脚本
# 使用阿里云 CLI 和 kubectl 完成部署

$ErrorActionPreference = "Continue"

$Namespace = "algorithm-games"
$Region = "cn-hangzhou"
$ImageUrl = "registry.$Region.aliyuncs.com/$Namespace/algorithm-games:latest"

Write-Host "🚀 开始完整自动化部署..." -ForegroundColor Green
Write-Host ""

# 设置环境变量
$env:ALIBABA_CLOUD_ACCESS_KEY_ID = "LTAI5tFDDZiMKb29RrdPSU3h"
$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"
$env:ALIBABA_CLOUD_REGION = $Region

# 检查阿里云 CLI
Write-Host "🔧 检查阿里云 CLI..." -ForegroundColor Yellow
$aliyunCli = Get-Command aliyun -ErrorAction SilentlyContinue

if (-not $aliyunCli) {
    Write-Host "  ⚠️  阿里云 CLI 未安装" -ForegroundColor Yellow
    Write-Host "  📝 安装命令: npm install -g @alicloud/cli" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 由于需要构建镜像，请先在 ACR 控制台完成以下操作：" -ForegroundColor Cyan
    Write-Host "  1. 登录: https://cr.console.aliyun.com" -ForegroundColor White
    Write-Host "  2. 创建命名空间: $Namespace" -ForegroundColor White
    Write-Host "  3. 创建镜像仓库: algorithm-games" -ForegroundColor White
    Write-Host "  4. 配置构建规则并触发构建" -ForegroundColor White
    Write-Host "  5. 等待构建完成" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  ✅ 阿里云 CLI 已安装" -ForegroundColor Green
    
    # 配置阿里云 CLI
    Write-Host ""
    Write-Host "🔐 配置阿里云 CLI..." -ForegroundColor Yellow
    try {
        aliyun configure set --profile default --mode AK --region $Region --access-key-id $env:ALIBABA_CLOUD_ACCESS_KEY_ID --access-key-secret $env:ALIBABA_CLOUD_ACCESS_KEY_SECRET 2>&1 | Out-Null
        Write-Host "  ✅ CLI 配置成功" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  CLI 配置失败" -ForegroundColor Yellow
    }
    
    # 创建命名空间
    Write-Host ""
    Write-Host "📦 创建 ACR 命名空间..." -ForegroundColor Yellow
    try {
        $result = aliyun cr CreateNamespace --Region $Region --Namespace $Namespace 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 命名空间创建成功" -ForegroundColor Green
        } else {
            if ($result -match "已存在" -or $result -match "already exists") {
                Write-Host "  ✅ 命名空间已存在" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  创建命名空间失败: $result" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ⚠️  创建命名空间失败" -ForegroundColor Yellow
    }
    
    # 创建镜像仓库
    Write-Host ""
    Write-Host "📦 创建镜像仓库..." -ForegroundColor Yellow
    try {
        $result = aliyun cr CreateRepository --Region $Region --RepoNamespace $Namespace --RepoName algorithm-games --RepoType PRIVATE --Summary "Algorithm Games" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 镜像仓库创建成功" -ForegroundColor Green
        } else {
            if ($result -match "已存在" -or $result -match "already exists") {
                Write-Host "  ✅ 镜像仓库已存在" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  创建镜像仓库失败: $result" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ⚠️  创建镜像仓库失败" -ForegroundColor Yellow
    }
}

# 生成部署配置
Write-Host ""
Write-Host "📋 生成部署配置..." -ForegroundColor Yellow

$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: algorithm-games
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: algorithm-games
  template:
    metadata:
      labels:
        app: algorithm-games
    spec:
      containers:
      - name: algorithm-games
        image: $ImageUrl
        ports:
        - containerPort: 8000
        env:
        - name: ALLOWED_ORIGINS
          value: "*"
        - name: PORT
          value: "8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: algorithm-games-service
  namespace: default
spec:
  selector:
    app: algorithm-games
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  type: LoadBalancer
"@

$deploymentYaml | Out-File -Encoding utf8 "ack-deployment-final.yaml"
Write-Host "  ✅ 部署配置已保存到: ack-deployment-final.yaml" -ForegroundColor Green

# 检查 kubectl
Write-Host ""
Write-Host "🔧 检查 kubectl..." -ForegroundColor Yellow
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $kubectl) {
    Write-Host "  ⚠️  kubectl 未安装" -ForegroundColor Yellow
    Write-Host "  📝 安装命令: winget install Kubernetes.kubectl" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 部署步骤：" -ForegroundColor Cyan
    Write-Host "  1. 在 ACR 控制台构建镜像（如果还没有）" -ForegroundColor White
    Write-Host "  2. 在 ACK 控制台部署应用" -ForegroundColor White
    Write-Host "     - 登录: https://cs.console.aliyun.com" -ForegroundColor Gray
    Write-Host "     - 选择集群 → 工作负载 → 无状态 → 使用镜像创建" -ForegroundColor Gray
    Write-Host "     - 镜像: $ImageUrl" -ForegroundColor Gray
    Write-Host "  3. 在控制台查看服务外部 IP" -ForegroundColor White
} else {
    Write-Host "  ✅ kubectl 已安装" -ForegroundColor Green
    
    # 检查 kubeconfig
    Write-Host ""
    Write-Host "🔍 检查 kubeconfig..." -ForegroundColor Yellow
    $kubeconfig = $env:KUBECONFIG
    
    if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
        Write-Host "  ⚠️  未设置 KUBECONFIG" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📝 配置 kubectl 连接到 ACK：" -ForegroundColor Cyan
        Write-Host "  1. 登录: https://cs.console.aliyun.com" -ForegroundColor White
        Write-Host "  2. 选择集群 → 连接信息" -ForegroundColor White
        Write-Host "  3. 复制 kubeconfig 内容" -ForegroundColor White
        Write-Host "  4. 保存到文件并设置环境变量：" -ForegroundColor White
        Write-Host "     `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "或者使用阿里云 CLI：" -ForegroundColor Cyan
        Write-Host "  aliyun cs GET /k8s/你的集群ID/user_config | Out-File -Encoding utf8 kubeconfig.yaml" -ForegroundColor Gray
        Write-Host "  `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor Gray
    } else {
        Write-Host "  ✅ KUBECONFIG: $kubeconfig" -ForegroundColor Green
        
        # 测试连接
        Write-Host ""
        Write-Host "🔍 测试集群连接..." -ForegroundColor Yellow
        try {
            $nodes = kubectl get nodes 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ 集群连接成功" -ForegroundColor Green
                
                # 部署应用
                Write-Host ""
                Write-Host "🚀 部署应用到 ACK..." -ForegroundColor Yellow
                
                # 先检查镜像是否存在（提示用户）
                Write-Host "  ⚠️  请确保镜像已构建完成: $ImageUrl" -ForegroundColor Yellow
                Write-Host "  📝 如果镜像未构建，请在 ACR 控制台触发构建" -ForegroundColor White
                Write-Host ""
                
                # 应用部署配置
                kubectl apply -f ack-deployment-final.yaml
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ 部署配置已应用" -ForegroundColor Green
                    
                    # 等待 Pod 启动
                    Write-Host ""
                    Write-Host "⏳ 等待 Pod 启动..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                    
                    # 获取服务信息
                    Write-Host ""
                    Write-Host "📊 获取服务信息..." -ForegroundColor Yellow
                    kubectl get svc algorithm-games-service -n default
                    
                    Write-Host ""
                    Write-Host "🌐 获取外部访问地址..." -ForegroundColor Yellow
                    $svcInfo = kubectl get svc algorithm-games-service -n default -o json 2>&1 | ConvertFrom-Json
                    
                    if ($svcInfo.status.loadBalancer.ingress) {
                        $externalIP = $svcInfo.status.loadBalancer.ingress[0].ip
                        if (-not $externalIP) {
                            $externalIP = $svcInfo.status.loadBalancer.ingress[0].hostname
                        }
                        Write-Host ""
                        Write-Host "✅ 部署成功！" -ForegroundColor Green
                        Write-Host ""
                        Write-Host "🌐 访问地址: http://$externalIP" -ForegroundColor Cyan
                        Write-Host ""
                    } else {
                        Write-Host ""
                        Write-Host "⏳ 等待 LoadBalancer 分配外部 IP..." -ForegroundColor Yellow
                        Write-Host "  请稍后运行以下命令查看：" -ForegroundColor White
                        Write-Host "  kubectl get svc algorithm-games-service -n default" -ForegroundColor Gray
                        Write-Host ""
                    }
                } else {
                    Write-Host "  ❌ 部署失败" -ForegroundColor Red
                }
            } else {
                Write-Host "  ❌ 集群连接失败" -ForegroundColor Red
                Write-Host "  请检查 kubeconfig 配置" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ 集群连接失败: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "📝 后续操作：" -ForegroundColor Cyan
Write-Host "  - 查看 Pod 状态: kubectl get pods -n default" -ForegroundColor White
Write-Host "  - 查看服务状态: kubectl get svc algorithm-games-service -n default" -ForegroundColor White
Write-Host "  - 查看 Pod 日志: kubectl logs -n default -l app=algorithm-games" -ForegroundColor White
Write-Host ""


