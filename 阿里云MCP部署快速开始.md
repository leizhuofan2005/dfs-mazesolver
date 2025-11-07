# 阿里云 MCP 部署快速开始

## ✅ 当前状态

- ✅ AccessKey 已配置在 MCP 中
- ✅ Dockerfile 已准备
- ✅ Kubernetes 部署配置已生成（`ack-deployment.yaml`）
- ✅ 部署脚本已准备（`deploy-to-aliyun.ps1`）

## 📋 需要的信息

在开始部署前，请准备以下信息：

1. **ACR 命名空间**
   - 登录：https://cr.console.aliyun.com
   - 创建命名空间（例如：`algorithm-games`）

2. **ACK 集群 ID**
   - 登录：https://cs.console.aliyun.com
   - 创建集群（如果还没有）
   - 在集群列表中查看集群 ID

## 🚀 快速部署（3 种方式）

### 方式 1：使用 ACR 构建服务（最简单，推荐）

**优点**：不需要本地安装 Docker

1. **在 ACR 中创建镜像仓库**
   - 登录：https://cr.console.aliyun.com
   - 创建镜像仓库：
     - 命名空间：`algorithm-games`（或你自定义的）
     - 仓库名称：`algorithm-games`
     - 代码源：选择 GitHub 仓库或上传代码

2. **配置构建规则**
   - Dockerfile 路径：`./Dockerfile`
   - 构建上下文：`/`
   - 构建版本：`latest`

3. **触发构建**
   - 点击"立即构建"，等待完成（约 5-10 分钟）

4. **部署到 ACK**
   - 登录：https://cs.console.aliyun.com
   - 选择集群 → 工作负载 → 无状态 → 使用镜像创建
   - 镜像：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
   - 端口：`8000`
   - 环境变量：`ALLOWED_ORIGINS=*`

### 方式 2：使用部署脚本（需要 Docker）

```powershell
# 运行部署脚本
.\deploy-to-aliyun.ps1 -Namespace "algorithm-games" -ClusterId "你的集群ID"
```

脚本会自动：
- 检查 Docker 并构建镜像
- 登录 ACR 并推送镜像
- 使用 kubectl 部署到 ACK（如果已配置）

### 方式 3：手动部署（完全控制）

#### 步骤 1：构建并推送镜像

```powershell
# 登录 ACR（使用 AccessKey）
docker login --username=$env:ALIBABA_CLOUD_ACCESS_KEY_ID --password-stdin registry.cn-hangzhou.aliyuncs.com
# 输入 AccessKey Secret

# 构建镜像
docker build -t algorithm-games .

# 打标签
docker tag algorithm-games registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest

# 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest
```

#### 步骤 2：部署到 ACK

**选项 A：使用 kubectl**

```powershell
# 配置 kubectl（需要先安装阿里云 CLI）
aliyun cs GET /k8s/你的集群ID/user_config | Out-File -Encoding utf8 kubeconfig.yaml
$env:KUBECONFIG = "kubeconfig.yaml"

# 应用部署配置
kubectl apply -f ack-deployment.yaml

# 查看状态
kubectl get pods -n default
kubectl get svc -n default
```

**选项 B：使用控制台**

1. 登录：https://cs.console.aliyun.com
2. 选择集群 → 工作负载 → 无状态 → 使用镜像创建
3. 使用镜像：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
4. 配置端口和环境变量
5. 创建

## 🔍 验证部署

部署完成后：

```powershell
# 查看服务地址
kubectl get svc algorithm-games-service -n default

# 或通过控制台查看外部端点
```

访问 `http://你的服务地址` 应该能看到应用。

## 📝 函数计算 FC 部署（可选）

如果你想部署到函数计算 FC：

1. 登录：https://fcnext.console.aliyun.com
2. 创建服务：`algorithm-games`
3. 创建函数：
   - 运行时：容器镜像
   - 镜像：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
   - 内存：512 MB
4. 配置 HTTP 触发器
5. 获取访问地址

## 🆘 常见问题

### Q: Docker 未安装怎么办？
A: 使用方式 1（ACR 构建服务），不需要本地 Docker。

### Q: kubectl 未配置怎么办？
A: 使用控制台部署（方式 1 或方式 3 选项 B）。

### Q: 镜像拉取失败？
A: 检查：
- ACR 登录状态
- 命名空间和仓库名称是否正确
- 镜像是否已成功构建和推送

### Q: Pod 启动失败？
A: 查看日志：
```powershell
kubectl logs -n default -l app=algorithm-games
kubectl describe pod -n default -l app=algorithm-games
```

## 📚 详细文档

- 完整部署指南：`阿里云ACK部署指南.md`
- Kubernetes 配置：`ack-deployment.yaml`
- 部署脚本：`deploy-to-aliyun.ps1`


