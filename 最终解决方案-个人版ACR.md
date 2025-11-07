# 最终解决方案：使用个人版 ACR

## 🔍 问题总结

标准 ACR (`registry.cn-hangzhou.aliyuncs.com`) 一直返回 403 错误，可能因为：
- 标准 ACR 实例不存在
- 标准 ACR 中没有命名空间
- 认证方式复杂

## ✅ 解决方案：使用个人版 ACR

个人版 ACR 域名在 GitHub Actions 中可能无法解析，但我们可以：

### 方案 1: 使用 ACR 控制台直接构建（推荐，最简单）

在 ACR 控制台直接构建，无需 GitHub Actions。

#### 步骤：

1. **登录 ACR 控制台**
   - https://cr.console.aliyun.com

2. **进入个人版仓库**
   - 选择个人版实例
   - 进入命名空间：`algorithm-games`
   - 进入仓库：`algorithm-games`

3. **配置构建规则**
   - 点击 **构建** 或 **构建规则**
   - 如果找不到，查看是否有 **触发器** 或 **自动构建** 选项
   - 配置：
     - 代码源：GitHub
     - 仓库：`leizhuofan2005/dfs-mazesolver`
     - 分支：`main`
     - Dockerfile 路径：`./Dockerfile`
     - 构建版本：`latest`

4. **触发构建**
   - 点击 **立即构建**
   - 等待构建完成（5-10 分钟）

5. **部署到 ACK**
   - 构建完成后，镜像地址为：
     `crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest`
   - 运行：`.\deploy-and-get-url.ps1`

---

### 方案 2: 本地 Docker 构建（如果方案 1 不可用）

使用本地 Docker 构建并推送到个人版 ACR。

#### 步骤：

1. **安装 Docker Desktop**（如果还没有）
   ```powershell
   winget install Docker.DockerDesktop
   ```

2. **运行构建脚本**
   ```powershell
   .\本地构建推送.ps1
   ```

3. **部署到 ACK**
   ```powershell
   .\deploy-and-get-url.ps1
   ```

---

### 方案 3: 修改 GitHub Actions 使用个人版（可能不工作）

如果个人版域名在 GitHub Actions 中可以解析，可以尝试：

更新工作流使用个人版域名，但可能仍然有 DNS 解析问题。

---

## 🎯 推荐方案

**优先使用方案 1（ACR 控制台构建）**：
- ✅ 无需 GitHub Actions
- ✅ 无需本地 Docker
- ✅ 完全自动化
- ✅ 使用个人版 ACR（已存在）

**如果方案 1 不可用，使用方案 2（本地构建）**：
- ✅ 绕过所有认证问题
- ✅ 使用个人版 ACR
- ✅ 完全控制

---

## 📋 检查清单

- [ ] 尝试在 ACR 控制台配置构建规则
- [ ] 如果找不到构建规则，使用本地 Docker 构建
- [ ] 构建完成后，更新 `ack-deployment.yaml` 使用个人版镜像地址
- [ ] 运行 `.\deploy-and-get-url.ps1` 部署

---

**建议：先尝试方案 1（ACR 控制台构建），这是最简单的方法！**


