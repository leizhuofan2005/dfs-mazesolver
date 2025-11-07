# Railway MCP 配置脚本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Railway MCP 配置助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js
Write-Host "检查 Node.js 版本..." -ForegroundColor Yellow
$nodeVersion = node --version
Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green

# 提示获取 API Token
Write-Host ""
Write-Host "第一步：获取 Railway API Token" -ForegroundColor Yellow
Write-Host "1. 访问: https://railway.app/account" -ForegroundColor White
Write-Host "2. 滚动到 'API' 部分" -ForegroundColor White
Write-Host "3. 点击 'New Token'" -ForegroundColor White
Write-Host "4. 复制生成的 token" -ForegroundColor White
Write-Host ""

# 获取用户输入
$token = Read-Host "请粘贴你的 Railway API Token"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "错误: Token 不能为空" -ForegroundColor Red
    exit 1
}

# 配置文件路径
$mcpConfigPath = "$env:USERPROFILE\.cursor\mcp.json"

# 读取现有配置
$config = @{}
if (Test-Path $mcpConfigPath) {
    try {
        $config = Get-Content $mcpConfigPath | ConvertFrom-Json | ConvertTo-Hashtable
    } catch {
        Write-Host "警告: 无法读取现有配置，将创建新配置" -ForegroundColor Yellow
        $config = @{}
    }
}

# 确保 mcpServers 存在
if (-not $config.mcpServers) {
    $config.mcpServers = @{}
}

# 添加 Railway MCP 配置
$config.mcpServers.railway = @{
    command = "npx"
    args = @("-y", "@jasontanswe/railway-mcp")
    env = @{
        RAILWAY_API_TOKEN = $token
    }
}

# 确保目录存在
$configDir = Split-Path $mcpConfigPath -Parent
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# 保存配置
try {
    $config | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigPath -Encoding UTF8
    Write-Host ""
    Write-Host "✅ 配置已保存到: $mcpConfigPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Cyan
    Write-Host "1. 完全关闭 Cursor" -ForegroundColor White
    Write-Host "2. 重新打开 Cursor" -ForegroundColor White
    Write-Host "3. 配置生效后，我就可以直接通过 MCP 部署了！" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "错误: 无法保存配置 - $_" -ForegroundColor Red
    exit 1
}

