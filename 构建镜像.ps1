# 使用本地 Docker 构建并推送到 ACR

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  构建并推送镜像到 ACR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 从控制台获取的实际仓库地址
$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"
$Namespace = "algorithm-games"
$ImageName = "algorithm-games"
$FullImageName = "$Registry/$Namespace/$ImageName:latest"

Write-Host "仓库地址: $Registry" -ForegroundColor Cyan
Write-Host "完整镜像地址: $FullImageName" -ForegroundColor Cyan
Write-Host ""

# 检查 Docker
Write-Host "[1/5] 检查 Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  ✗ Docker 未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先安装 Docker Desktop:" -ForegroundColor Cyan
    Write-Host "  下载: https://www.docker.com/products/docker-desktop" -ForegroundColor White
    Write-Host "  或使用: winget install Docker.DockerDesktop" -ForegroundColor White
    exit 1
}

Write-Host "  ✓ Docker 已安装" -ForegroundColor Green

# 登录 ACR
Write-Host ""
Write-Host "[2/5] 登录 ACR..." -ForegroundColor Yellow
Write-Host "  用户名: 你的阿里云账号邮箱（例如: hi312*****@aliyun.com）" -ForegroundColor Gray
Write-Host "  密码: ACR 服务激活时设置的密码（不是 AccessKey）" -ForegroundColor Gray
Write-Host ""

$username = Read-Host "请输入阿里云账号邮箱"
$password = Read-Host "请输入 ACR 密码" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# 登录
$loginCmd = echo $plainPassword | docker login --username=$username --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ ACR 登录成功" -ForegroundColor Green
} else {
    Write-Host "  ✗ ACR 登录失败" -ForegroundColor Red
    Write-Host "  错误信息:" -ForegroundColor Yellow
    Write-Host $loginCmd -ForegroundColor Red
    Write-Host ""
    Write-Host "提示：" -ForegroundColor Cyan
    Write-Host "  - 用户名应该是完整的阿里云账号邮箱" -ForegroundColor White
    Write-Host "  - 密码是 ACR 服务激活时设置的密码" -ForegroundColor White
    Write-Host "  - 如果忘记密码，可以在 ACR 控制台的'访问凭证'中重置" -ForegroundColor White
    exit 1
}

# 构建镜像
Write-Host ""
Write-Host "[3/5] 构建 Docker 镜像..." -ForegroundColor Yellow
Write-Host "  这可能需要几分钟，请耐心等待..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 镜像构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ 镜像构建成功" -ForegroundColor Green

# 打标签
Write-Host ""
Write-Host "[4/5] 打标签..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ 标签已创建: $FullImageName" -ForegroundColor Green
} else {
    Write-Host "  ✗ 打标签失败" -ForegroundColor Red
    exit 1
}

# 推送镜像
Write-Host ""
Write-Host "[5/5] 推送镜像到 ACR..." -ForegroundColor Yellow
Write-Host "  这可能需要几分钟..." -ForegroundColor Gray

docker push $FullImageName

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ 镜像推送成功" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  构建完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  镜像地址: $FullImageName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Yellow
    Write-Host "  1. 在 ACR 控制台的'镜像版本'标签中查看镜像" -ForegroundColor White
    Write-Host "  2. 获取 ACK 集群的 kubeconfig" -ForegroundColor White
    Write-Host "  3. 运行: .\deploy-and-get-url.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  ✗ 镜像推送失败" -ForegroundColor Red
    Write-Host "  请检查：" -ForegroundColor Yellow
    Write-Host "    1. ACR 登录状态" -ForegroundColor White
    Write-Host "    2. 仓库地址是否正确" -ForegroundColor White
    Write-Host "    3. 是否有推送权限" -ForegroundColor White
}


