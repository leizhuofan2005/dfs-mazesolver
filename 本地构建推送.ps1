# 本地构建并推送到个人版 ACR（绕过 GitHub Actions 问题）

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  本地构建并推送到 ACR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"

Write-Host "使用个人版 ACR（本地可以解析）" -ForegroundColor Cyan
Write-Host "Registry: $Registry" -ForegroundColor Gray
Write-Host "Image: $FullImageName" -ForegroundColor Gray
Write-Host ""

# 检查 Docker
Write-Host "[1/4] 检查 Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  X Docker 未安装" -ForegroundColor Red
    Write-Host "  请先安装 Docker Desktop" -ForegroundColor Yellow
    Write-Host "  下载: https://www.docker.com/products/docker-desktop" -ForegroundColor White
    exit 1
}

Write-Host "  OK Docker 已安装" -ForegroundColor Green

# 检查 Docker 是否运行
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  X Docker 未运行" -ForegroundColor Red
    Write-Host "  请启动 Docker Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host "  OK Docker 正在运行" -ForegroundColor Green

# 登录 ACR
Write-Host ""
Write-Host "[2/4] 登录 ACR..." -ForegroundColor Yellow
Write-Host "  需要你的阿里云账号邮箱和 ACR 服务密码" -ForegroundColor Gray
Write-Host ""

$username = Read-Host "请输入阿里云账号邮箱"
$password = Read-Host "请输入 ACR 服务密码" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$loginResult = echo $plainPassword | docker login --username=$username --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK ACR 登录成功" -ForegroundColor Green
} else {
    Write-Host "  X ACR 登录失败" -ForegroundColor Red
    Write-Host "  错误: $loginResult" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "提示：" -ForegroundColor Cyan
    Write-Host "  - 用户名应该是完整的阿里云账号邮箱" -ForegroundColor White
    Write-Host "  - 密码是 ACR 服务密码（在 ACR 控制台的'访问凭证'中获取）" -ForegroundColor White
    exit 1
}

# 构建镜像
Write-Host ""
Write-Host "[3/4] 构建 Docker 镜像..." -ForegroundColor Yellow
Write-Host "  这需要 5-10 分钟，请耐心等待..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  X 镜像构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "  OK 镜像构建成功" -ForegroundColor Green

# 打标签并推送
Write-Host ""
Write-Host "[4/4] 推送镜像到 ACR..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName
docker push $FullImageName

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK 镜像推送成功" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  构建完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  镜像地址: $FullImageName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步：部署到 ACK" -ForegroundColor Yellow
    Write-Host "  1. 更新 ack-deployment.yaml 中的镜像地址" -ForegroundColor White
    Write-Host "  2. 运行: .\deploy-and-get-url.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  X 镜像推送失败" -ForegroundColor Red
    Write-Host "  请检查登录状态和权限" -ForegroundColor Yellow
}


