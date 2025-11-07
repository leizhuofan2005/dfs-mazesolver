# 阿里云 ACK 自动部署脚本（简化版）
# 生成部署配置并指导部署步骤

$Namespace = "algorithm-games"
$Region = "cn-hangzhou"
$ImageUrl = "registry.$Region.aliyuncs.com/$Namespace/algorithm-games:latest"

Write-Host "🚀 阿里云 ACK 自动部署配置生成" -ForegroundColor Green
Write-Host ""

# 读取现有的部署配置
$deploymentContent = Get-Content -Path "ack-deployment.yaml" -Raw -ErrorAction SilentlyContinue

if (-not $deploymentContent) {
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
} else {
    # 更新镜像地址
    $deploymentContent = $deploymentContent -replace 'registry\.cn-hangzhou\.aliyuncs\.com/algorithm-games/algorithm-games:latest', $ImageUrl
    $deploymentContent | Out-File -Encoding utf8 "ack-deployment-final.yaml"
    Write-Host "  ✅ 已更新部署配置: ack-deployment-final.yaml" -ForegroundColor Green
}

Write-Host ""
Write-Host "📝 部署步骤：" -ForegroundColor Cyan
Write-Host ""
Write-Host "步骤 1: 在 ACR 中构建镜像" -ForegroundColor Yellow
Write-Host "  1. 登录: https://cr.console.aliyun.com" -ForegroundColor White
Write-Host "  2. 创建命名空间: $Namespace" -ForegroundColor White
Write-Host "  3. 创建镜像仓库: algorithm-games" -ForegroundColor White
Write-Host "  4. 配置构建规则:" -ForegroundColor White
Write-Host "     - Dockerfile 路径: ./Dockerfile" -ForegroundColor Gray
Write-Host "     - 构建上下文: /" -ForegroundColor Gray
Write-Host "     - 构建版本: latest" -ForegroundColor Gray
Write-Host "  5. 触发构建，等待完成（约 5-10 分钟）" -ForegroundColor White
Write-Host ""
Write-Host "步骤 2: 部署到 ACK" -ForegroundColor Yellow
Write-Host "  方式 A - 使用控制台（推荐）:" -ForegroundColor White
Write-Host "    1. 登录: https://cs.console.aliyun.com" -ForegroundColor Gray
Write-Host "    2. 选择集群 → 工作负载 → 无状态 → 使用镜像创建" -ForegroundColor Gray
Write-Host "    3. 镜像: $ImageUrl" -ForegroundColor Gray
Write-Host "    4. 端口: 8000" -ForegroundColor Gray
Write-Host "    5. 环境变量: ALLOWED_ORIGINS=*" -ForegroundColor Gray
Write-Host ""
Write-Host "  方式 B - 使用 kubectl:" -ForegroundColor White
Write-Host "    kubectl apply -f ack-deployment-final.yaml" -ForegroundColor Gray
Write-Host "    kubectl get svc -n default" -ForegroundColor Gray
Write-Host ""
Write-Host "Configuration ready!" -ForegroundColor Green
Write-Host ""

