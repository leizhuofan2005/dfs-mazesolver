# Monitor GitHub Actions build status

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Status Monitor" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repo = "leizhuofan2005/dfs-mazesolver"

Write-Host "Repository: $repo" -ForegroundColor Cyan
Write-Host ""

Write-Host "Build has been triggered!" -ForegroundColor Green
Write-Host ""

Write-Host "View build status:" -ForegroundColor Yellow
Write-Host "  https://github.com/$repo/actions" -ForegroundColor White
Write-Host ""

Write-Host "What to check:" -ForegroundColor Cyan
Write-Host "  1. Go to Actions tab" -ForegroundColor White
Write-Host "  2. Click on the latest workflow run" -ForegroundColor White
Write-Host "  3. Check if 'Login to Alibaba Cloud ACR' step succeeds" -ForegroundColor White
Write-Host ""

Write-Host "Expected timeline:" -ForegroundColor Yellow
Write-Host "  - Login step: ~10 seconds" -ForegroundColor Gray
Write-Host "  - Build step: 5-10 minutes" -ForegroundColor Gray
Write-Host "  - Push step: 1-2 minutes" -ForegroundColor Gray
Write-Host ""

Write-Host "If login succeeds but build fails:" -ForegroundColor Cyan
Write-Host "  - Check Dockerfile for errors" -ForegroundColor White
Write-Host "  - Check build logs for details" -ForegroundColor White
Write-Host ""

Write-Host "If login still fails:" -ForegroundColor Red
Write-Host "  - Double-check Secret names (case-sensitive)" -ForegroundColor White
Write-Host "  - Verify Secret values are not empty" -ForegroundColor White
Write-Host "  - Check: 修复GitHub Secrets.md" -ForegroundColor White
Write-Host ""

Write-Host "Once build completes successfully:" -ForegroundColor Green
Write-Host "  1. Verify image in ACR console" -ForegroundColor White
Write-Host "  2. Run: .\deploy-and-get-url.ps1" -ForegroundColor White
Write-Host ""


