# Check GitHub Actions build status and prepare for deployment

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Checking Build Status" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repo = "leizhuofan2005/dfs-mazesolver"
$ImageUrl = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest"

Write-Host "Repository: $repo" -ForegroundColor Cyan
Write-Host "Image URL: $ImageUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "GitHub Actions Status:" -ForegroundColor Yellow
Write-Host "  View build status: https://github.com/$repo/actions" -ForegroundColor White
Write-Host ""

Write-Host "Build Process:" -ForegroundColor Yellow
Write-Host "  1. GitHub Actions is building the Docker image..." -ForegroundColor Gray
Write-Host "  2. This usually takes 5-10 minutes" -ForegroundColor Gray
Write-Host "  3. Once complete, image will be pushed to ACR" -ForegroundColor Gray
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Wait for build to complete (check GitHub Actions)" -ForegroundColor White
Write-Host "  2. Verify image in ACR console:" -ForegroundColor White
Write-Host "     https://cr.console.aliyun.com" -ForegroundColor Gray
Write-Host "  3. Once image is ready, deploy to ACK:" -ForegroundColor White
Write-Host "     .\deploy-and-get-url.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "To check build status manually:" -ForegroundColor Yellow
Write-Host "  Visit: https://github.com/$repo/actions" -ForegroundColor White
Write-Host ""

Write-Host "To verify image in ACR:" -ForegroundColor Yellow
Write-Host "  1. Login: https://cr.console.aliyun.com" -ForegroundColor White
Write-Host "  2. Go to: algorithm-games / algorithm-games" -ForegroundColor White
Write-Host "  3. Click: Image Versions tab" -ForegroundColor White
Write-Host "  4. Look for: latest tag" -ForegroundColor White
Write-Host ""

Write-Host "Once image is ready, run:" -ForegroundColor Green
Write-Host "  .\deploy-and-get-url.ps1" -ForegroundColor Cyan
Write-Host ""


