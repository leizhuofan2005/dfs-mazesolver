# 自动部署到函数计算 FC 并获取访问地址

$ErrorActionPreference = "Continue"

Write-Host "Deploying to Alibaba Cloud Function Compute (FC)..." -ForegroundColor Green
Write-Host ""

# 设置环境变量
$env:ALIBABA_CLOUD_ACCESS_KEY_ID = "LTAI5tFDDZiMKb29RrdPSU3h"
$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"
$env:ALIBABA_CLOUD_REGION = "cn-hangzhou"

$ImageUrl = "registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Image: $ImageUrl" -ForegroundColor White
Write-Host "  Service: algorithm-games" -ForegroundColor White
Write-Host "  Function: algorithm-games" -ForegroundColor White
Write-Host ""

# 检查 Fun CLI
Write-Host "Checking Fun CLI..." -ForegroundColor Yellow
$fun = Get-Command fun -ErrorAction SilentlyContinue

if (-not $fun) {
    Write-Host "  Fun CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @alicloud/fun 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Fun CLI installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  Failed to install Fun CLI" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install manually:" -ForegroundColor Cyan
        Write-Host "  npm install -g @alicloud/fun" -ForegroundColor White
        Write-Host ""
        Write-Host "Or deploy via console:" -ForegroundColor Cyan
        Write-Host "  1. Login: https://fcnext.console.aliyun.com" -ForegroundColor White
        Write-Host "  2. Create service: algorithm-games" -ForegroundColor White
        Write-Host "  3. Create function with container image: $ImageUrl" -ForegroundColor White
        Write-Host "  4. Configure HTTP trigger" -ForegroundColor White
        exit 1
    }
}

# 创建 fun.yaml 配置文件
Write-Host ""
Write-Host "Creating fun.yaml configuration..." -ForegroundColor Yellow

$funYaml = @"
ROSTemplateFormatVersion: '2015-09-01'
Transform: 'Aliyun::Serverless-2018-04-03'
Resources:
  algorithm-games:
    Type: 'Aliyun::Serverless::Service'
    Properties:
      Description: 'Algorithm Games Application'
    algorithm-games:
      Type: 'Aliyun::Serverless::Function'
      Properties:
        Description: 'Algorithm Games Function'
        Runtime: custom
        Handler: 'not-used'
        CodeUri: '.'
        Timeout: 60
        MemorySize: 512
        CustomContainerConfig:
          Image: '$ImageUrl'
          Command: '[`"uvicorn`", `"backend.main:app`", `"--host`", `"0.0.0.0`", `"--port`", `"9000`"]'
          Args: '[]'
      Events:
        httpTrigger:
          Type: HTTP
          Properties:
            AuthType: ANONYMOUS
            Methods: ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'PATCH']
"@

$funYaml | Out-File -Encoding utf8 "fun.yaml"
Write-Host "  Configuration saved to fun.yaml" -ForegroundColor Green

# 配置 Fun CLI
Write-Host ""
Write-Host "Configuring Fun CLI..." -ForegroundColor Yellow

# 创建 .env 文件
$envContent = @"
ALIBABA_CLOUD_ACCESS_KEY_ID=$env:ALIBABA_CLOUD_ACCESS_KEY_ID
ALIBABA_CLOUD_ACCESS_KEY_SECRET=$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET
ALIBABA_CLOUD_REGION=$env:ALIBABA_CLOUD_REGION
"@

$envContent | Out-File -Encoding utf8 ".env"
Write-Host "  Environment configured" -ForegroundColor Green

# 部署
Write-Host ""
Write-Host "Deploying to Function Compute..." -ForegroundColor Yellow
Write-Host "  Note: This requires the image to be built first in ACR" -ForegroundColor Gray
Write-Host ""

fun deploy --use-docker 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Getting function URL..." -ForegroundColor Yellow
    
    # 获取函数 URL
    $functionInfo = fun info 2>&1
    Write-Host $functionInfo
    
    Write-Host ""
    Write-Host "Access your application at the URL above" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Deployment failed. Please check:" -ForegroundColor Red
    Write-Host "  1. Image is built in ACR: $ImageUrl" -ForegroundColor White
    Write-Host "  2. Fun CLI is configured correctly" -ForegroundColor White
    Write-Host "  3. AccessKey has proper permissions" -ForegroundColor White
    Write-Host ""
    Write-Host "Or deploy via console:" -ForegroundColor Cyan
    Write-Host "  https://fcnext.console.aliyun.com" -ForegroundColor White
}

Write-Host ""

