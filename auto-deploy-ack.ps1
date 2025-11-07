# 阿里云 ACK 自动部署脚本
# 使用 ACR 构建服务（无需本地 Docker）

param(
    [string]$Namespace = "algorithm-games",
    [string]$Region = "cn-hangzhou"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 阿里云 ACK 自动部署脚本" -ForegroundColor Green
Write-Host "使用 ACR 构建服务（无需本地 Docker）" -ForegroundColor Cyan
Write-Host ""

# 设置环境变量
$env:ALIBABA_CLOUD_ACCESS_KEY_ID = "LTAI5tFDDZiMKb29RrdPSU3h"
$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"
$env:ALIBABA_CLOUD_REGION = $Region

$ImageUrl = "registry.$Region.aliyuncs.com/$Namespace/algorithm-games:latest"

Write-Host "📋 部署配置：" -ForegroundColor Cyan
Write-Host "  命名空间: $Namespace" -ForegroundColor White
Write-Host "  地域: $Region" -ForegroundColor White
Write-Host "  镜像地址: $ImageUrl" -ForegroundColor White
Write-Host ""

# 检查阿里云 CLI
Write-Host "🔧 检查阿里云 CLI..." -ForegroundColor Yellow
$aliyunCli = Get-Command aliyun -ErrorAction SilentlyContinue

if (-not $aliyunCli) {
    Write-Host "  ⚠️  阿里云 CLI 未安装" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📝 安装阿里云 CLI：" -ForegroundColor Cyan
    Write-Host "  npm install -g @alicloud/cli" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 或者使用控制台部署（推荐）：" -ForegroundColor Yellow
    Write-Host "  1. 登录: https://cr.console.aliyun.com" -ForegroundColor White
    Write-Host "  2. 创建命名空间: $Namespace" -ForegroundColor White
    Write-Host "  3. 创建镜像仓库: algorithm-games" -ForegroundColor White
    Write-Host "  4. 配置构建规则并触发构建" -ForegroundColor White
    Write-Host "  5. 等待构建完成" -ForegroundColor White
    Write-Host ""
    
    # 生成部署配置
    Write-Host "📋 生成部署配置..." -ForegroundColor Yellow
    $deploymentYaml = "apiVersion: apps/v1`nkind: Deployment`nmetadata:`n  name: algorithm-games`n  namespace: default`nspec:`n  replicas: 1`n  selector:`n    matchLabels:`n      app: algorithm-games`n  template:`n    metadata:`n      labels:`n        app: algorithm-games`n    spec:`n      containers:`n      - name: algorithm-games`n        image: $ImageUrl`n        ports:`n        - containerPort: 8000`n        env:`n        - name: ALLOWED_ORIGINS`n          value: `"*`"`n        - name: PORT`n          value: `"8000`"`n        resources:`n          requests:`n            memory: `"256Mi`"`n            cpu: `"250m`"`n          limits:`n            memory: `"512Mi`"`n            cpu: `"500m`"`n---`napiVersion: v1`nkind: Service`nmetadata:`n  name: algorithm-games-service`n  namespace: default`nspec:`n  selector:`n    app: algorithm-games`n  ports:`n  - port: 80`n    targetPort: 8000`n    protocol: TCP`n  type: LoadBalancer"
    
    $deploymentYaml | Out-File -Encoding utf8 "ack-deployment-final.yaml"
    Write-Host "  ✅ 部署配置已保存到: ack-deployment-final.yaml" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📝 控制台部署步骤：" -ForegroundColor Cyan
    Write-Host "  1. 在 ACR 中构建镜像（见上方步骤）" -ForegroundColor White
    Write-Host "  2. 登录: https://cs.console.aliyun.com" -ForegroundColor White
    Write-Host "  3. 选择集群 → 工作负载 → 无状态 → 使用镜像创建" -ForegroundColor White
    Write-Host "  4. 镜像: $ImageUrl" -ForegroundColor White
    Write-Host "  5. 端口: 8000" -ForegroundColor White
    Write-Host "  6. 环境变量: ALLOWED_ORIGINS=*" -ForegroundColor White
    Write-Host ""
    
    exit 0
}

# 配置阿里云 CLI
Write-Host "  ✅ 阿里云 CLI 已安装" -ForegroundColor Green
Write-Host ""
Write-Host "🔐 配置阿里云 CLI..." -ForegroundColor Yellow

try {
    # 配置 AccessKey
    aliyun configure set `
        --profile default `
        --mode AK `
        --region $Region `
        --access-key-id $env:ALIBABA_CLOUD_ACCESS_KEY_ID `
        --access-key-secret $env:ALIBABA_CLOUD_ACCESS_KEY_SECRET `
        2>&1 | Out-Null
    
    Write-Host "  ✅ CLI 配置成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  CLI 配置失败: $_" -ForegroundColor Yellow
}

# 检查/创建命名空间
Write-Host ""
Write-Host "📦 检查 ACR 命名空间..." -ForegroundColor Yellow

try {
    $namespaceResult = aliyun cr GetNamespace --Region $Region --Namespace $Namespace 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ 命名空间已存在" -ForegroundColor Green
    } else {
        Write-Host "  📝 创建命名空间..." -ForegroundColor White
        aliyun cr CreateNamespace --Region $Region --Namespace $Namespace 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 命名空间创建成功" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  创建命名空间失败，请手动在控制台创建" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ⚠️  检查命名空间失败，请手动在控制台创建" -ForegroundColor Yellow
    Write-Host "     访问: https://cr.console.aliyun.com" -ForegroundColor White
}

# 检查/创建镜像仓库
Write-Host ""
Write-Host "📦 检查镜像仓库..." -ForegroundColor Yellow

try {
    $repoResult = aliyun cr GetRepo --Region $Region --RepoNamespace $Namespace --RepoName algorithm-games 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ 镜像仓库已存在" -ForegroundColor Green
    } else {
        Write-Host "  📝 创建镜像仓库..." -ForegroundColor White
        aliyun cr CreateRepo `
            --Region $Region `
            --RepoNamespace $Namespace `
            --RepoName algorithm-games `
            --RepoType PRIVATE `
            --Summary "Algorithm Games Application" `
            2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 镜像仓库创建成功" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  创建镜像仓库失败，请手动在控制台创建" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ⚠️  检查镜像仓库失败，请手动在控制台创建" -ForegroundColor Yellow
}

# 生成部署配置
Write-Host ""
Write-Host "📋 生成部署配置..." -ForegroundColor Yellow

$deploymentYaml = "apiVersion: apps/v1`nkind: Deployment`nmetadata:`n  name: algorithm-games`n  namespace: default`nspec:`n  replicas: 1`n  selector:`n    matchLabels:`n      app: algorithm-games`n  template:`n    metadata:`n      labels:`n        app: algorithm-games`n    spec:`n      containers:`n      - name: algorithm-games`n        image: $ImageUrl`n        ports:`n        - containerPort: 8000`n        env:`n        - name: ALLOWED_ORIGINS`n          value: `"*`"`n        - name: PORT`n          value: `"8000`"`n        resources:`n          requests:`n            memory: `"256Mi`"`n            cpu: `"250m`"`n          limits:`n            memory: `"512Mi`"`n            cpu: `"500m`"`n---`napiVersion: v1`nkind: Service`nmetadata:`n  name: algorithm-games-service`n  namespace: default`nspec:`n  selector:`n    app: algorithm-games`n  ports:`n  - port: 80`n    targetPort: 8000`n    protocol: TCP`n  type: LoadBalancer"

$deploymentYaml | Out-File -Encoding utf8 "ack-deployment-final.yaml"
Write-Host "  ✅ 部署配置已保存到: ack-deployment-final.yaml" -ForegroundColor Green

Write-Host ""
Write-Host "✅ 自动化部署准备完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📝 下一步操作：" -ForegroundColor Cyan
Write-Host "  1. 在 ACR 控制台配置构建规则并触发构建" -ForegroundColor White
Write-Host "     - 登录: https://cr.console.aliyun.com" -ForegroundColor Gray
Write-Host "     - 命名空间: $Namespace" -ForegroundColor Gray
Write-Host "     - 仓库: algorithm-games" -ForegroundColor Gray
Write-Host "     - Dockerfile 路径: ./Dockerfile" -ForegroundColor Gray
Write-Host "  2. 等待镜像构建完成（约 5-10 分钟）" -ForegroundColor White
Write-Host "  3. 在 ACK 控制台部署应用" -ForegroundColor White
Write-Host "     - 登录: https://cs.console.aliyun.com" -ForegroundColor Gray
Write-Host "     - 镜像: $ImageUrl" -ForegroundColor Gray
Write-Host "     - 端口: 8000" -ForegroundColor Gray
Write-Host "  4. 或使用 kubectl: kubectl apply -f ack-deployment-final.yaml" -ForegroundColor White
Write-Host ""

