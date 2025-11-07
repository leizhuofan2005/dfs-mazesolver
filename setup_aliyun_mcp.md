# 阿里云 MCP 配置指南

## 📋 当前情况

目前没有现成的阿里云 MCP 服务器包（类似 Railway MCP），但我们可以通过以下方式实现自动化部署：

## 🚀 方案一：使用阿里云 CLI + 脚本（推荐）

### 第一步：安装阿里云 CLI

```powershell
# 使用 npm 安装
npm install -g @alicloud/cli

# 或者使用 scoop（Windows）
scoop install aliyun-cli
```

### 第二步：配置访问凭证

```powershell
# 获取 AccessKey
# 1. 访问：https://ram.console.aliyun.com/manage/ak
# 2. 创建 AccessKey，保存：
#    - AccessKey ID
#    - AccessKey Secret

# 配置 CLI
aliyun configure set \
  --profile default \
  --mode AK \
  --region cn-hangzhou \
  --access-key-id 你的AccessKeyId \
  --access-key-secret 你的AccessKeySecret
```

### 第三步：使用部署脚本

项目已经包含了 `aliyun_deploy.ps1` 脚本，可以直接使用。

## 🚀 方案二：使用阿里云 SDK + 自定义 MCP（高级）

如果需要类似 Railway MCP 的体验，可以创建一个自定义的 MCP 服务器。

### 安装依赖

```bash
npm install @alicloud/ecs20140526 @alicloud/cs20151215 @alicloud/cr20160607
```

### 创建 MCP 服务器

我可以帮你创建一个基于阿里云 SDK 的 MCP 服务器包装器。

## 🚀 方案三：直接使用 Docker + 阿里云容器服务（最简单）

### 使用现有的 Dockerfile

项目已经包含了 `Dockerfile`，可以直接使用：

1. **构建镜像**
   ```bash
   docker build -t algorithm-games .
   ```

2. **推送到阿里云容器镜像服务 ACR**
   ```bash
   # 登录 ACR
   docker login --username=你的用户名 registry.cn-hangzhou.aliyuncs.com
   
   # 打标签
   docker tag algorithm-games registry.cn-hangzhou.aliyuncs.com/你的命名空间/algorithm-games:latest
   
   # 推送
   docker push registry.cn-hangzhou.aliyuncs.com/你的命名空间/algorithm-games:latest
   ```

3. **在 ACK 中部署**
   - 登录阿里云控制台
   - 进入容器服务 Kubernetes 版
   - 创建应用，选择刚才推送的镜像

## 💡 推荐方案

**最简单**：使用方案三（Docker + ACR + ACK），项目已经准备好了所有配置。

**最自动化**：使用方案一（阿里云 CLI + 脚本），可以实现部分自动化。

**最灵活**：使用方案二（自定义 MCP），可以实现完全自动化，但需要开发工作。

---

**你想使用哪个方案？我可以帮你配置和部署！**



