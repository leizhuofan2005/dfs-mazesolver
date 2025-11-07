# 快速构建和推送脚本（如果已安装 Docker）

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ACR 镜像构建和推送" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Namespace = "algorithm-games"
$Region = "cn-hangzhou"
$ImageName = "algorithm-games"
$FullImageName = "registry.$Region.aliyuncs.com/$Namespace/$ImageName:latest"

# 检查 Docker
Write-Host "[1/4] 检查 Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue

if (-not $docker) {
    Write-Host "  ✗ Docker 未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "请使用控制台方法构建镜像：" -ForegroundColor Cyan
    Write-Host "1. 登录: https://cr.console.aliyun.com" -ForegroundColor White
    Write-Host "2. 进入仓库: algorithm-games" -ForegroundColor White
    Write-Host "3. 配置构建规则并触发构建" -ForegroundColor White
    Write-Host ""
    Write-Host "详细步骤请查看: ACR构建和部署指南.md" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ Docker 已安装" -ForegroundColor Green

# 登录 ACR
Write-Host ""
Write-Host "[2/4] 登录 ACR..." -ForegroundColor Yellow

$accessKeyId = "LTAI5tFDDZiMKb29RrdPSU3h"
$accessKeySecret = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"
$registry = "registry.$Region.aliyuncs.com"

# 使用 AccessKey 登录
$password = $accessKeySecret | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($accessKeyId, $password)

# 尝试登录
$loginResult = echo $accessKeySecret | docker login --username=$accessKeyId --password-stdin $registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ ACR 登录成功" -ForegroundColor Green
} else {
    Write-Host "  ✗ ACR 登录失败" -ForegroundColor Red
    Write-Host "  错误: $loginResult" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请手动登录：" -ForegroundColor Cyan
    Write-Host "  docker login --username=$accessKeyId registry.$Region.aliyuncs.com" -ForegroundColor White
    Write-Host "  输入密码: $accessKeySecret" -ForegroundColor White
    exit 1
}

# 构建镜像
Write-Host ""
Write-Host "[3/4] 构建 Docker 镜像..." -ForegroundColor Yellow
Write-Host "  这可能需要几分钟..." -ForegroundColor Gray

docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 镜像构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ 镜像构建成功" -ForegroundColor Green

# 打标签
Write-Host ""
Write-Host "[4/4] 推送镜像到 ACR..." -ForegroundColor Yellow

docker tag $ImageName $FullImageName
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
    Write-Host "下一步：部署到 ACK" -ForegroundColor Yellow
    Write-Host "  1. 获取 ACK 集群的 kubeconfig" -ForegroundColor White
    Write-Host "  2. 运行: .\deploy-and-get-url.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  ✗ 镜像推送失败" -ForegroundColor Red
    Write-Host "  请检查：" -ForegroundColor Yellow
    Write-Host "    1. ACR 登录状态" -ForegroundColor White
    Write-Host "    2. 命名空间和仓库名称是否正确" -ForegroundColor White
    Write-Host "    3. 是否有推送权限" -ForegroundColor White
}


