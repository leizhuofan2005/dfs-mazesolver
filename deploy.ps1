# PowerShell 部署脚本
Write-Host "🚀 开始部署流程..." -ForegroundColor Green

# 检查是否在 Git 仓库中
if (-not (Test-Path ".git")) {
    Write-Host "❌ 错误: 当前目录不是 Git 仓库" -ForegroundColor Red
    exit 1
}

# 构建前端
Write-Host "📦 构建前端..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 前端构建失败" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 前端构建成功" -ForegroundColor Green

# 检查是否有未提交的更改
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  警告: 有未提交的更改" -ForegroundColor Yellow
    $response = Read-Host "是否继续部署? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        exit 1
    }
}

Write-Host ""
Write-Host "📝 部署准备完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "1. 如果使用 Railway: 访问 https://railway.app 并按照 DEPLOY.md 中的步骤操作"
Write-Host "2. 如果使用 Render: 访问 https://render.com 并按照 DEPLOY.md 中的步骤操作"
Write-Host "3. 如果使用 Vercel: 访问 https://vercel.com 并按照 DEPLOY.md 中的步骤操作"
Write-Host ""
Write-Host "记得设置环境变量 VITE_API_URL 为你的后端 URL！" -ForegroundColor Yellow

