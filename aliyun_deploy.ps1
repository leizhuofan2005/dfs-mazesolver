# 阿里云自动部署脚本
# 使用阿里云 CLI 或 API 自动部署

param(
    [string]$AccessKeyId = "",
    [string]$AccessKeySecret = "",
    [string]$Region = "cn-hangzhou",
    [string]$Namespace = "",
    [string]$ImageName = "algorithm-games"
)

Write-Host "🚀 阿里云自动部署脚本" -ForegroundColor Green
Write-Host ""

# 检查参数
if ([string]::IsNullOrWhiteSpace($AccessKeyId) -or [string]::IsNullOrWhiteSpace($AccessKeySecret)) {
    Write-Host "⚠️  需要提供阿里云访问凭证" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "使用方法：" -ForegroundColor Cyan
    Write-Host "  .\aliyun_deploy.ps1 -AccessKeyId '你的AccessKeyId' -AccessKeySecret '你的AccessKeySecret' -Region 'cn-hangzhou' -Namespace '你的命名空间'" -ForegroundColor White
    Write-Host ""
    Write-Host "或者设置环境变量：" -ForegroundColor Cyan
    Write-Host "  `$env:ALIBABA_CLOUD_ACCESS_KEY_ID = '你的AccessKeyId'" -ForegroundColor White
    Write-Host "  `$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = '你的AccessKeySecret'" -ForegroundColor White
    Write-Host ""
    exit 1
}

# 检查 Docker
Write-Host "📦 检查 Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "  ✅ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Docker 未安装，请先安装 Docker" -ForegroundColor Red
    exit 1
}

# 构建 Docker 镜像
Write-Host ""
Write-Host "🔨 构建 Docker 镜像..." -ForegroundColor Yellow
docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ 镜像构建失败" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ 镜像构建成功" -ForegroundColor Green

# 登录 ACR
Write-Host ""
Write-Host "🔐 登录阿里云容器镜像服务..." -ForegroundColor Yellow
$registry = "registry.$Region.aliyuncs.com"
$fullImageName = "$registry/$Namespace/$ImageName:latest"

# 使用阿里云 CLI 登录（如果已安装）
try {
    aliyun configure set --profile default --access-key-id $AccessKeyId --access-key-secret $AccessKeySecret --region $Region
    aliyun cr GetAuthorizationToken --Region $Region
    Write-Host "  ✅ 登录成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  阿里云 CLI 未安装，请手动登录：" -ForegroundColor Yellow
    Write-Host "    docker login --username=你的用户名 $registry" -ForegroundColor White
}

# 打标签
Write-Host ""
Write-Host "🏷️  打标签..." -ForegroundColor Yellow
docker tag $ImageName $fullImageName
Write-Host "  ✅ 标签: $fullImageName" -ForegroundColor Green

# 推送镜像
Write-Host ""
Write-Host "📤 推送镜像到 ACR..." -ForegroundColor Yellow
docker push $fullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ 镜像推送失败，请检查登录状态" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ 镜像推送成功" -ForegroundColor Green

Write-Host ""
Write-Host "✅ 部署准备完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 登录阿里云控制台" -ForegroundColor White
Write-Host "2. 进入容器服务 ACK 或函数计算 FC" -ForegroundColor White
Write-Host "3. 使用镜像: $fullImageName" -ForegroundColor White
Write-Host "4. 配置环境变量和域名" -ForegroundColor White

