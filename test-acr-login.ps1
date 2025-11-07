# Test ACR login credentials

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing ACR Login Credentials" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Registry = "crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com"

Write-Host "Registry: $Registry" -ForegroundColor Cyan
Write-Host ""

# Test with AccessKey (might not work for personal registry)
Write-Host "[Test 1] Testing with AccessKey..." -ForegroundColor Yellow
$AccessKeyId = "LTAI5tFDDZiMKb29RrdPSU3h"
$AccessKeySecret = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"

$test1 = echo $AccessKeySecret | docker login --username=$AccessKeyId --password-stdin $Registry 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK AccessKey login successful!" -ForegroundColor Green
    Write-Host "  You can use AccessKey for GitHub Actions" -ForegroundColor Green
    Write-Host ""
    Write-Host "GitHub Secrets should be:" -ForegroundColor Cyan
    Write-Host "  ALIYUN_USERNAME: $AccessKeyId" -ForegroundColor White
    Write-Host "  ALIYUN_ACR_PASSWORD: $AccessKeySecret" -ForegroundColor White
} else {
    Write-Host "  X AccessKey login failed" -ForegroundColor Red
    Write-Host "  Error: $test1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[Test 2] You need to use ACR service password" -ForegroundColor Yellow
    Write-Host "  Please provide your Alibaba Cloud account email" -ForegroundColor White
    Write-Host "  And ACR service password (not AccessKey)" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Secrets Configuration" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please verify your GitHub Secrets:" -ForegroundColor Yellow
Write-Host "  1. Go to: https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions" -ForegroundColor White
Write-Host "  2. Check these secrets exist:" -ForegroundColor White
Write-Host "     - ALIYUN_USERNAME (exact name, case-sensitive)" -ForegroundColor Gray
Write-Host "     - ALIYUN_ACR_PASSWORD (exact name, case-sensitive)" -ForegroundColor Gray
Write-Host "  3. Make sure values are not empty" -ForegroundColor White
Write-Host ""

Write-Host "If AccessKey doesn't work, use:" -ForegroundColor Yellow
Write-Host "  ALIYUN_USERNAME: Your Alibaba Cloud account email" -ForegroundColor White
Write-Host "  ALIYUN_ACR_PASSWORD: ACR service password" -ForegroundColor White
Write-Host "  (Get password from: https://cr.console.aliyun.com -> Access Credentials)" -ForegroundColor Gray
Write-Host ""


