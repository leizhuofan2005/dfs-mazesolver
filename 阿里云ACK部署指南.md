# 阿里云 ACK 部署指南

## 📋 前置准备

### 1. 开通服务

- ✅ **容器镜像服务 ACR**：https://cr.console.aliyun.com
  - 创建命名空间（例如：`algorithm-games`）
- ✅ **容器服务 Kubernetes 版 ACK**：https://cs.console.aliyun.com
  - 创建集群（如果还没有）

### 2. 获取必要信息

- **ACR 命名空间**：例如 `algorithm-games`
- **ACK 集群 ID**：在 ACK 控制台查看
- **AccessKey**：已配置在 MCP 中 ✅

---

## 🚀 方案一：使用 ACR 构建服务（推荐，无需本地 Docker）

### 步骤 1：在 ACR 中创建构建规则

1. 登录阿里云控制台
2. 进入 **容器镜像服务 ACR** → **镜像仓库**
3. 创建镜像仓库：
   - **命名空间**：`algorithm-games`
   - **仓库名称**：`algorithm-games`
   - **仓库类型**：私有
   - **代码源**：选择 **GitHub** 或 **本地代码**
4. 配置构建规则：
   - **Dockerfile 路径**：`./Dockerfile`
   - **构建上下文**：`/`
   - **构建分支**：`main` 或 `master`
   - **构建版本规则**：`latest`

### 步骤 2：触发构建

1. 在镜像仓库页面，点击 **构建**
2. 选择构建规则，点击 **立即构建**
3. 等待构建完成（约 5-10 分钟）

### 步骤 3：部署到 ACK

1. 登录阿里云控制台
2. 进入 **容器服务 Kubernetes 版 ACK**
3. 选择你的集群
4. 点击 **工作负载** → **无状态**
5. 点击 **使用镜像创建**
6. 配置应用：
   - **应用名称**：`algorithm-games`
   - **镜像**：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
   - **端口**：`8000`
   - **环境变量**：
     - `ALLOWED_ORIGINS=*`
     - `PORT=8000`
7. 点击 **创建**

### 步骤 4：配置服务访问

1. 在 ACK 控制台，进入 **服务** → **服务**
2. 找到 `algorithm-games-service`
3. 查看 **外部端点**，获取访问地址

---

## 🚀 方案二：本地构建并推送（需要安装 Docker）

### 步骤 1：安装 Docker Desktop

1. 下载：https://www.docker.com/products/docker-desktop
2. 安装并启动 Docker Desktop

### 步骤 2：登录 ACR

```powershell
# 使用 AccessKey 登录（推荐）
$env:ALIBABA_CLOUD_ACCESS_KEY_ID = "LTAI5tFDDZiMKb29RrdPSU3h"
$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET = "Q0TbTjlio3msQKMDqcTPTQNTOE2oac"

# 登录 ACR（使用 AccessKey）
docker login --username=$env:ALIBABA_CLOUD_ACCESS_KEY_ID --password=$env:ALIBABA_CLOUD_ACCESS_KEY_SECRET registry.cn-hangzhou.aliyuncs.com
```

### 步骤 3：构建并推送镜像

```powershell
# 进入项目目录
cd C:\Users\think\Documents\GitHub\dfs-mazesolver

# 构建镜像
docker build -t algorithm-games .

# 打标签
docker tag algorithm-games registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest

# 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest
```

### 步骤 4：部署到 ACK

使用 `ack-deployment.yaml` 文件：

```powershell
# 配置 kubectl（需要先安装阿里云 CLI）
aliyun cs GET /k8s/你的集群ID/user_config | Out-File -Encoding utf8 kubeconfig.yaml
$env:KUBECONFIG = "kubeconfig.yaml"

# 应用部署配置
kubectl apply -f ack-deployment.yaml

# 查看部署状态
kubectl get pods -n default
kubectl get svc -n default
```

---

## 🔧 使用 kubectl 部署（如果已配置）

如果你已经配置了 `kubectl` 并连接到 ACK 集群：

```powershell
# 应用部署配置
kubectl apply -f ack-deployment.yaml

# 查看部署状态
kubectl get deployment algorithm-games -n default
kubectl get pods -n default
kubectl get svc algorithm-games-service -n default

# 查看服务外部 IP
kubectl get svc algorithm-games-service -n default -o wide
```

---

## 📝 函数计算 FC 部署（可选）

如果你想部署到函数计算 FC：

1. 登录阿里云控制台
2. 进入 **函数计算 FC**
3. 创建服务：`algorithm-games`
4. 创建函数：
   - **函数名称**：`algorithm-games`
   - **运行时**：容器镜像
   - **镜像地址**：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
   - **内存**：512 MB
5. 配置触发器（HTTP 触发器）
6. 获取访问地址

---

## ✅ 验证部署

部署完成后，访问服务地址：

```bash
# 获取服务地址（ACK）
kubectl get svc algorithm-games-service -n default

# 或通过控制台查看外部端点
```

访问 `http://你的服务地址` 应该能看到应用界面。

---

## 🔍 故障排查

### 镜像拉取失败

```powershell
# 检查镜像是否存在
docker pull registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest

# 如果失败，检查 ACR 登录状态
docker login registry.cn-hangzhou.aliyuncs.com
```

### Pod 启动失败

```powershell
# 查看 Pod 日志
kubectl logs -n default -l app=algorithm-games

# 查看 Pod 状态
kubectl describe pod -n default -l app=algorithm-games
```

### 服务无法访问

```powershell
# 检查服务配置
kubectl get svc algorithm-games-service -n default -o yaml

# 检查端口映射
kubectl get endpoints algorithm-games-service -n default
```

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 错误信息
2. Pod 日志：`kubectl logs -n default -l app=algorithm-games`
3. 服务状态：`kubectl get svc -n default`


