# GitHub Actions 自动构建和部署指南

## ✅ 已检测到

- ✅ 代码在 GitHub：`leizhuofan2005/dfs-mazesolver`
- ✅ GitHub Actions 工作流已创建：`.github/workflows/build-and-push.yml`

## 🚀 快速开始（3 步）

### 步骤 1: 配置 GitHub Secrets

1. **登录 GitHub**
   - 访问：https://github.com/leizhuofan2005/dfs-mazesolver
   - 点击 **Settings** → **Secrets and variables** → **Actions**

2. **添加以下 Secrets**：
   - `ALIYUN_USERNAME`: 你的阿里云账号邮箱（例如：hi312*****@aliyun.com）
   - `ALIYUN_ACR_PASSWORD`: ACR 服务密码（不是 AccessKey）

### 步骤 2: 推送工作流文件到 GitHub

```powershell
git add .github/workflows/build-and-push.yml
git commit -m "Add GitHub Actions workflow for auto build and push"
git push
```

### 步骤 3: 触发构建

推送代码后，GitHub Actions 会自动：
1. ✅ 检出代码
2. ✅ 构建 Docker 镜像
3. ✅ 推送到 ACR
4. ✅ 镜像地址：`crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest`

## 📋 详细步骤

### 1. 获取 ACR 密码

如果不知道 ACR 密码：

1. 登录 ACR 控制台：https://cr.console.aliyun.com
2. 点击 **访问凭证**
3. 重置或查看密码
4. 复制密码

### 2. 配置 GitHub Secrets

在 GitHub 仓库设置中添加：

**ALIYUN_USERNAME**:
- 值：你的完整阿里云账号邮箱
- 例如：`hi312*****@aliyun.com`

**ALIYUN_ACR_PASSWORD**:
- 值：ACR 服务密码
- 不是 AccessKey Secret

### 3. 推送并触发

```powershell
# 添加工作流文件
git add .github/workflows/build-and-push.yml
git add github-actions-build.yml
git add "无需Docker的部署方案.md"

# 提交
git commit -m "Add GitHub Actions for auto build and push to ACR"

# 推送
git push
```

### 4. 查看构建状态

1. 在 GitHub 仓库页面，点击 **Actions** 标签
2. 查看工作流运行状态
3. 等待构建完成（约 5-10 分钟）

### 5. 验证镜像

1. 登录 ACR 控制台：https://cr.console.aliyun.com
2. 进入仓库：`algorithm-games` → `algorithm-games`
3. 点击 **镜像版本** 标签
4. 确认 `latest` 标签的镜像已存在

## 🚀 构建完成后部署到 ACK

镜像构建完成后，部署到 ACK：

### 方法 1: 使用自动化脚本

```powershell
# 更新部署配置中的镜像地址
# 然后运行
.\deploy-and-get-url.ps1
```

### 方法 2: 手动部署

```powershell
# 1. 获取 kubeconfig
# 在 ACK 控制台获取

# 2. 设置 kubeconfig
$env:KUBECONFIG = "kubeconfig.yaml"

# 3. 更新部署配置中的镜像地址为：
# crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest

# 4. 部署
kubectl apply -f ack-deployment.yaml

# 5. 获取访问地址
kubectl get svc algorithm-games-service -n default
```

## 🔄 自动触发

工作流会在以下情况自动触发：
- ✅ 推送到 `main` 或 `master` 分支
- ✅ 手动触发（在 Actions 页面点击 "Run workflow"）

## 📝 更新部署配置

构建完成后，需要更新 `ack-deployment.yaml` 中的镜像地址：

```yaml
image: crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest
```

## 🆘 常见问题

### Q: 构建失败？
A: 检查：
- GitHub Secrets 是否正确配置
- ACR 密码是否正确
- Dockerfile 路径是否正确

### Q: 如何查看构建日志？
A: 在 GitHub Actions 页面点击运行的工作流，查看详细日志

### Q: 如何手动触发构建？
A: 在 GitHub Actions 页面，点击 "Run workflow" 按钮

---

**优势**：无需本地 Docker，完全自动化，每次推送代码自动构建和推送镜像！


