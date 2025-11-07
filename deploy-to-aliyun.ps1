# 阿里云 ACK 自动部署脚本
# 使用 MCP 工具生成的配置

param(
    [string]$Namespace = "algorithm-games",
    [string]$ClusterId = "",
    [string]$Region = "cn-hangzhou"
)

Write-Host "🚀 阿里云 ACK 部署脚本" -ForegroundColor Green
Write-Host ""

# 检查参数
if ([string]::IsNullOrWhiteSpace($ClusterId)) {
    Write-Host "⚠️  需要提供 ACK 集群 ID" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "使用方法：" -ForegroundColor Cyan
    Write-Host "  .\deploy-to-aliyun.ps1 -Namespace 'algorithm-games' -ClusterId '你的集群ID'" -ForegroundColor White
    Write-Host ""
    Write-Host "获取集群 ID：" -ForegroundColor Cyan
    Write-Host "  1. 登录阿里云控制台" -ForegroundColor White
    Write-Host "  2. 进入容器服务 Kubernetes 版 ACK" -ForegroundColor White
    Write-Host "  3. 在集群列表中查看集群 ID" -ForegroundColor White
    Write-Host ""
    exit 1
}

$ImageUrl = "registry.$Region.aliyuncs.com/$Namespace/algorithm-games:latest"

Write-Host "📋 部署配置：" -ForegroundColor Cyan
Write-Host "  命名空间: $Namespace" -ForegroundColor White
Write-Host "  集群 ID: $ClusterId" -ForegroundColor White
Write-Host "  镜像地址: $ImageUrl" -ForegroundColor White
Write-Host ""

# 检查 Docker（可选）
Write-Host "📦 检查 Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "  ✅ Docker: $dockerVersion" -ForegroundColor Green
        $hasDocker = $true
    } else {
        $hasDocker = $false
    }
} catch {
    $hasDocker = $false
}

if (-not $hasDocker) {
    Write-Host "  ⚠️  Docker 未安装，将使用 ACR 构建服务" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📝 下一步操作：" -ForegroundColor Cyan
    Write-Host "  1. 登录阿里云控制台" -ForegroundColor White
    Write-Host "  2. 进入容器镜像服务 ACR" -ForegroundColor White
    Write-Host "  3. 创建镜像仓库并配置构建规则" -ForegroundColor White
    Write-Host "  4. 触发构建，等待完成" -ForegroundColor White
    Write-Host "  5. 然后继续执行部署步骤" -ForegroundColor White
    Write-Host ""
} else {
    # 检查是否已登录 ACR
    Write-Host "🔐 检查 ACR 登录状态..." -ForegroundColor Yellow
    $registry = "registry.$Region.aliyuncs.com"
    
    # 尝试登录（使用 AccessKey）
    $accessKeyId = $env:ALIBABA_CLOUD_ACCESS_KEY_ID
    $accessKeySecret = $env:ALIBABA_CLOUD_ACCESS_KEY_SECRET
    
    if ($accessKeyId -and $accessKeySecret) {
        Write-Host "  使用 AccessKey 登录 ACR..." -ForegroundColor White
        $loginCmd = "echo $accessKeySecret | docker login --username=$accessKeyId --password-stdin $registry"
        Invoke-Expression $loginCmd 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ ACR 登录成功" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  ACR 登录失败，请手动登录" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  未找到 AccessKey，请手动登录 ACR" -ForegroundColor Yellow
        Write-Host "     docker login --username=你的用户名 $registry" -ForegroundColor White
    }
    
    # 构建镜像
    Write-Host ""
    Write-Host "🔨 构建 Docker 镜像..." -ForegroundColor Yellow
    docker build -t algorithm-games .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ 镜像构建失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ 镜像构建成功" -ForegroundColor Green
    
    # 打标签
    Write-Host ""
    Write-Host "🏷️  打标签..." -ForegroundColor Yellow
    docker tag algorithm-games $ImageUrl
    Write-Host "  ✅ 标签: $ImageUrl" -ForegroundColor Green
    
    # 推送镜像
    Write-Host ""
    Write-Host "📤 推送镜像到 ACR..." -ForegroundColor Yellow
    docker push $ImageUrl
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ 镜像推送失败" -ForegroundColor Red
        Write-Host "  请检查：" -ForegroundColor Yellow
        Write-Host "    1. ACR 登录状态" -ForegroundColor White
        Write-Host "    2. 命名空间是否存在" -ForegroundColor White
        Write-Host "    3. 是否有推送权限" -ForegroundColor White
        exit 1
    }
    Write-Host "  ✅ 镜像推送成功" -ForegroundColor Green
}

# 检查 kubectl
Write-Host ""
Write-Host "🔧 检查 kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client 2>&1
    if ($kubectlVersion) {
        Write-Host "  ✅ kubectl 已安装" -ForegroundColor Green
        $hasKubectl = $true
    } else {
        $hasKubectl = $false
    }
} catch {
    $hasKubectl = $false
}

if (-not $hasKubectl) {
    Write-Host "  ⚠️  kubectl 未安装" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📝 安装 kubectl：" -ForegroundColor Cyan
    Write-Host "  winget install Kubernetes.kubectl" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 配置 kubectl 连接到 ACK：" -ForegroundColor Cyan
    Write-Host "  1. 安装阿里云 CLI: npm install -g @alicloud/cli" -ForegroundColor White
    Write-Host "  2. 配置 AccessKey" -ForegroundColor White
    Write-Host "  3. 获取 kubeconfig: aliyun cs GET /k8s/$ClusterId/user_config" -ForegroundColor White
    Write-Host ""
    Write-Host "或者通过阿里云控制台部署：" -ForegroundColor Cyan
    Write-Host "  1. 登录阿里云控制台" -ForegroundColor White
    Write-Host "  2. 进入容器服务 Kubernetes 版 ACK" -ForegroundColor White
    Write-Host "  3. 选择集群，点击 工作负载 → 无状态 → 使用镜像创建" -ForegroundColor White
    Write-Host "  4. 使用镜像: $ImageUrl" -ForegroundColor White
    Write-Host ""
} else {
    # 检查 kubeconfig
    Write-Host "  📋 检查 kubeconfig..." -ForegroundColor White
    $kubeconfig = $env:KUBECONFIG
    if ([string]::IsNullOrWhiteSpace($kubeconfig)) {
        Write-Host "  ⚠️  未设置 KUBECONFIG，请先配置" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "配置方法：" -ForegroundColor Cyan
        Write-Host "  `$env:KUBECONFIG = 'kubeconfig.yaml'" -ForegroundColor White
        Write-Host "  # 或使用阿里云 CLI 获取" -ForegroundColor Gray
        Write-Host "  aliyun cs GET /k8s/$ClusterId/user_config | Out-File -Encoding utf8 kubeconfig.yaml" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  ✅ KUBECONFIG: $kubeconfig" -ForegroundColor Green
        
        # 应用部署配置
        Write-Host ""
        Write-Host "🚀 部署到 ACK..." -ForegroundColor Yellow
        
        # 更新 deployment.yaml 中的镜像地址
        $deploymentYaml = Get-Content ack-deployment.yaml -Raw
        $deploymentYaml = $deploymentYaml -replace 'registry\.cn-hangzhou\.aliyuncs\.com/algorithm-games/algorithm-games:latest', $ImageUrl
        $deploymentYaml | Out-File -Encoding utf8 ack-deployment-temp.yaml
        
        kubectl apply -f ack-deployment-temp.yaml
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 部署成功" -ForegroundColor Green
            Write-Host ""
            Write-Host "📊 查看部署状态：" -ForegroundColor Cyan
            Write-Host "  kubectl get pods -n default" -ForegroundColor White
            Write-Host "  kubectl get svc -n default" -ForegroundColor White
            Write-Host ""
            
            # 清理临时文件
            Remove-Item ack-deployment-temp.yaml -ErrorAction SilentlyContinue
        } else {
            Write-Host "  ❌ 部署失败" -ForegroundColor Red
            Write-Host "  请检查 kubectl 配置和集群连接" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "✅ 部署脚本执行完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📝 下一步：" -ForegroundColor Cyan
Write-Host "  1. 查看 Pod 状态: kubectl get pods -n default" -ForegroundColor White
Write-Host "  2. 查看服务地址: kubectl get svc algorithm-games-service -n default" -ForegroundColor White
Write-Host "  3. 访问应用: http://你的服务地址" -ForegroundColor White
Write-Host ""


