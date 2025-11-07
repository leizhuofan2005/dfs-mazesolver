# 修复 DNS 解析错误

## 🔍 问题

错误：`no such host: crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com`

**原因**：个人版 ACR 的特殊域名在 GitHub Actions 环境中无法解析。

## ✅ 解决方案

已修复工作流文件，改用标准 ACR 域名格式：

- **旧域名**：`crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com`
- **新域名**：`registry.cn-hangzhou.aliyuncs.com`

## 📝 已更新的文件

1. **`.github/workflows/build-and-push.yml`**
   - 使用标准域名：`registry.cn-hangzhou.aliyuncs.com`
   - 镜像标签：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`

2. **`ack-deployment.yaml`**
   - 镜像地址已更新为标准格式

## 🚀 下一步

### 步骤 1: 推送修复后的工作流

```powershell
git add .github/workflows/build-and-push.yml ack-deployment.yaml
git commit -m "Fix DNS error: use standard ACR domain"
git push
```

### 步骤 2: 验证 ACR 命名空间

确保在标准 ACR 中有命名空间 `algorithm-games`：

1. 登录：https://cr.console.aliyun.com
2. 检查是否有命名空间：`algorithm-games`
3. 如果没有，创建它

### 步骤 3: 重新触发构建

在 GitHub Actions 页面：
- 点击 "Run workflow" 按钮
- 或等待自动触发（如果已推送）

## ⚠️ 重要提示

### 如果使用个人版 ACR

个人版 ACR 的特殊域名可能无法在 GitHub Actions 中使用。有两个选择：

**选择 1: 使用标准 ACR（推荐）**
- 在 ACR 控制台创建标准命名空间
- 使用标准域名：`registry.cn-hangzhou.aliyuncs.com`

**选择 2: 使用本地 Docker 构建**
- 个人版域名在本地可以正常使用
- 使用本地 Docker 构建并推送

## 🔄 如果标准域名仍然失败

可能需要：
1. **确认命名空间存在**：在标准 ACR 中创建 `algorithm-games`
2. **检查权限**：确保 AccessKey 有推送权限
3. **使用企业版 ACR**：企业版支持标准域名

---

**已修复工作流文件，请推送并重新触发构建！**


