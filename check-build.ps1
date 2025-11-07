# Check GitHub Actions build status

$repo = "leizhuofan2005/dfs-mazesolver"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Actions Build Status" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Repository: $repo" -ForegroundColor Cyan
Write-Host ""

Write-Host "View build status:" -ForegroundColor Yellow
Write-Host "  https://github.com/$repo/actions" -ForegroundColor White
Write-Host ""

Write-Host "What to check:" -ForegroundColor Cyan
Write-Host "  1. Latest workflow run" -ForegroundColor White
Write-Host "  2. 'Login to Alibaba Cloud ACR' step" -ForegroundColor White
Write-Host "     - If green checkmark: Secrets are correct!" -ForegroundColor Green
Write-Host "     - If red X: Check Secret names and values" -ForegroundColor Red
Write-Host ""

Write-Host "If login succeeds:" -ForegroundColor Green
Write-Host "  Build will continue automatically" -ForegroundColor Gray
Write-Host "  Total time: 5-10 minutes" -ForegroundColor Gray
Write-Host ""

Write-Host "If login fails:" -ForegroundColor Red
Write-Host "  Check Secret names (case-sensitive):" -ForegroundColor Yellow
Write-Host "    - ALIYUN_USERNAME" -ForegroundColor White
Write-Host "    - ALIYUN_ACR_PASSWORD" -ForegroundColor White
Write-Host "  See: 修复GitHub Secrets.md" -ForegroundColor Gray
Write-Host ""

Write-Host "Manual trigger (if needed):" -ForegroundColor Cyan
Write-Host "  https://github.com/$repo/actions/workflows/build-and-push.yml" -ForegroundColor White
Write-Host "  Click 'Run workflow' button" -ForegroundColor Gray
Write-Host ""


