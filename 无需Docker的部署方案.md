# 无需 Docker 的部署方案

## 当前情况

Docker 尚未安装或不可用。以下是无需本地 Docker 的部署方案：

## 方案 1: 使用 ACR 控制台手动构建（推荐）

### 步骤 1: 在 ACR 控制台配置构建

1. **登录 ACR 控制台**
   - 访问：https://cr.console.aliyun.com
   - 选择地域：华东1（杭州）

2. **进入仓库**
   - 命名空间：`algorithm-games`
   - 仓库：`algorithm-games`

3. **配置构建规则**
   - 由于你的仓库是"本地仓库"，可能不支持自动构建
   - 但可以尝试以下方法：
     - 查看是否有"构建"或"触发器"选项
     - 查看页面顶部是否有"构建"标签

### 步骤 2: 如果找不到构建选项

由于是"本地仓库"，可能需要：
1. **升级到企业版**（支持自动构建）
2. **或使用方案 2**

---

## 方案 2: 使用 GitHub Actions 自动构建（推荐）

如果你的代码在 GitHub 上，可以使用 GitHub Actions 自动构建并推送到 ACR。

### 创建 GitHub Actions 工作流

创建文件：`.github/workflows/build-and-push.yml`

```yaml
name: Build and Push to ACR

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Alibaba Cloud ACR
      uses: docker/login-action@v2
      with:
        registry: crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com
        username: ${{ secrets.ALIYUN_USERNAME }}
        password: ${{ secrets.ALIYUN_ACR_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: crpi-yvms4cndr4xq7550.cn-hangzhou.personal.cr.aliyuncs.com/algorithm-games/algorithm-games:latest
```

### 配置 GitHub Secrets

在 GitHub 仓库设置中添加：
- `ALIYUN_USERNAME`: 你的阿里云账号邮箱
- `ALIYUN_ACR_PASSWORD`: ACR 服务密码

### 触发构建

推送代码到 GitHub 或手动触发工作流，GitHub Actions 会自动构建并推送镜像。

---

## 方案 3: 使用阿里云 CLI 触发构建（如果支持）

如果安装了阿里云 CLI：

```powershell
# 安装阿里云 CLI
npm install -g @alicloud/cli

# 配置
aliyun configure set --profile default --mode AK --region cn-hangzhou --access-key-id LTAI5tFDDZiMKb29RrdPSU3h --access-key-secret Q0TbTjlio3msQKMDqcTPTQNTOE2oac

# 创建构建规则（需要先配置代码源）
# 这个比较复杂，建议使用方案 2
```

---

## 方案 4: 安装 Docker 后使用自动化脚本

如果选择安装 Docker：

1. **安装 Docker Desktop**
   - 下载：https://www.docker.com/products/docker-desktop
   - 或使用：`winget install Docker.DockerDesktop`

2. **启动 Docker Desktop**

3. **重启 PowerShell 终端**

4. **运行自动化脚本**
   ```powershell
   .\check-and-deploy.ps1
   ```

---

## 推荐方案

**如果代码在 GitHub**：使用方案 2（GitHub Actions），完全自动化，无需本地 Docker。

**如果代码不在 GitHub**：使用方案 4（安装 Docker），然后运行自动化脚本。

---

## 构建完成后

无论使用哪种方案，构建完成后：

1. **在 ACR 控制台验证镜像**
   - 进入仓库 → "镜像版本"标签
   - 确认 `latest` 标签的镜像已存在

2. **部署到 ACK**
   - 获取 ACK 集群的 kubeconfig
   - 运行：`kubectl apply -f ack-deployment.yaml`
   - 获取访问地址：`kubectl get svc algorithm-games-service -n default`

---

## 快速检查

你的代码是否在 GitHub 上？
- **是** → 使用方案 2（GitHub Actions）
- **否** → 使用方案 4（安装 Docker）


