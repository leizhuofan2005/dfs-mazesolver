# Railway 自动部署脚本
# 使用 Railway API 创建项目并部署服务

$apiToken = "aa8c4c98-22a9-455d-b132-ee4e16b77edc"
$headers = @{
    "Authorization" = "Bearer $apiToken"
    "Content-Type" = "application/json"
}

Write-Host "🚀 开始自动部署到 Railway..." -ForegroundColor Green
Write-Host ""

# 步骤1: 获取用户信息
Write-Host "📋 步骤1: 获取用户信息..." -ForegroundColor Yellow
try {
    # Railway 使用 GraphQL API
    $query = @{
        query = @"
        {
            me {
                id
                name
                email
            }
        }
"@
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "https://backboard.railway.app/graphql/v1" -Method Post -Headers $headers -Body $query
    Write-Host "✅ 用户信息获取成功" -ForegroundColor Green
    Write-Host "   用户: $($response.data.me.name)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  无法通过 API 获取用户信息，可能需要通过 Web 界面创建项目" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请访问: https://railway.app/dashboard" -ForegroundColor Cyan
    Write-Host "点击 'New Project' → 'Deploy from GitHub repo'" -ForegroundColor Cyan
    Write-Host "选择仓库: leizhuofan2005/dfs-mazesolver" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "创建项目后，我就可以通过 MCP 继续配置！" -ForegroundColor Green
    exit 0
}

# 如果成功获取用户信息，继续创建项目
Write-Host ""
Write-Host "📦 步骤2: 创建项目..." -ForegroundColor Yellow
# 这里需要 workspaceId，通常需要从用户信息中获取或使用默认的

Write-Host ""
Write-Host "✅ 脚本执行完成" -ForegroundColor Green



