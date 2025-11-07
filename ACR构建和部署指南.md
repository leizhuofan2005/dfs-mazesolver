# ACR 构建和部署完整指南

## ✅ 已完成
- ✅ 命名空间：`algorithm-games`
- ✅ 镜像仓库：`algorithm-games`

## 🚀 下一步：配置构建规则并触发构建

### 方法 1: 通过控制台（推荐，最简单）

#### 步骤 1: 配置构建规则

1. **登录 ACR 控制台**
   - 访问：https://cr.console.aliyun.com
   - 选择地域：`华东1（杭州）`

2. **进入镜像仓库**
   - 点击左侧菜单：**镜像仓库**
   - 选择命名空间：`algorithm-games`
   - 点击仓库名称：`algorithm-games`

3. **配置构建规则**
   - 点击 **构建** 标签页
   - 点击 **添加规则** 或 **创建构建规则**
   - 配置如下：
     ```
     规则名称：default（或任意名称）
     代码源类型：GitHub（如果代码在 GitHub）或 本地代码
     
     如果是 GitHub：
     - 选择你的 GitHub 仓库
     - 分支：main 或 master
     
     如果是本地代码：
     - 需要先上传代码或使用其他方式
     
     Dockerfile 路径：./Dockerfile
     构建上下文：/
     构建版本规则：latest
     ```

4. **触发构建**
   - 配置完成后，点击 **立即构建**
   - 等待构建完成（约 5-10 分钟）
   - 构建完成后，镜像地址为：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`

#### 步骤 2: 部署到 ACK

构建完成后，按照 `最终部署说明.md` 中的步骤部署到 ACK。

---

### 方法 2: 使用本地 Docker 构建并推送（如果已安装 Docker）

如果你本地已安装 Docker Desktop，可以使用以下方法：

```powershell
# 1. 登录 ACR
docker login --username=LTAI5tFDDZiMKb29RrdPSU3h --password-stdin registry.cn-hangzhou.aliyuncs.com
# 输入密码：Q0TbTjlio3msQKMDqcTPTQNTOE2oac

# 2. 构建镜像
cd C:\Users\think\Documents\GitHub\dfs-mazesolver
docker build -t algorithm-games .

# 3. 打标签
docker tag algorithm-games registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest

# 4. 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest
```

---

### 方法 3: 使用阿里云 CLI（如果已安装）

```powershell
# 配置阿里云 CLI（如果还没有）
npm install -g @alicloud/cli
aliyun configure set --profile default --mode AK --region cn-hangzhou --access-key-id LTAI5tFDDZiMKb29RrdPSU3h --access-key-secret Q0TbTjlio3msQKMDqcTPTQNTOE2oac

# 创建构建规则（需要先配置代码源）
# 这个比较复杂，建议使用方法 1
```

---

## 📝 详细操作步骤（控制台方法）

### 1. 配置构建规则

**如果代码在 GitHub：**

1. 在 ACR 控制台，进入仓库 `algorithm-games`
2. 点击 **构建** 标签
3. 点击 **添加规则**
4. 选择 **GitHub**
5. 授权并选择仓库：`think/dfs-mazesolver`（或你的仓库名）
6. 配置：
   - **分支**：`main` 或 `master`
   - **Dockerfile 路径**：`./Dockerfile`
   - **构建上下文**：`/`
   - **构建版本规则**：`latest`
7. 点击 **确定**

**如果代码不在 GitHub：**

1. 在 ACR 控制台，进入仓库 `algorithm-games`
2. 点击 **构建** 标签
3. 点击 **添加规则**
4. 选择 **本地代码** 或 **代码库**
5. 上传代码或配置代码库
6. 配置 Dockerfile 路径和构建上下文
7. 点击 **确定**

### 2. 触发构建

1. 在构建规则列表中，找到刚创建的规则
2. 点击 **立即构建**
3. 等待构建完成（查看构建日志）
4. 构建成功后，镜像会自动推送到仓库

### 3. 验证镜像

1. 在仓库页面，点击 **镜像版本** 标签
2. 应该能看到 `latest` 标签的镜像
3. 镜像地址：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`

---

## 🚀 构建完成后部署到 ACK

构建完成后，按照以下步骤部署：

1. **获取 ACK 集群的 kubeconfig**
   - 登录：https://cs.console.aliyun.com
   - 选择集群 → **连接信息**
   - 复制 kubeconfig，保存为 `kubeconfig.yaml`

2. **部署应用**
   ```powershell
   cd C:\Users\think\Documents\GitHub\dfs-mazesolver
   $env:KUBECONFIG = "kubeconfig.yaml"
   .\deploy-and-get-url.ps1
   ```

---

## 🆘 常见问题

### Q: 构建失败怎么办？
A: 
- 检查 Dockerfile 路径是否正确
- 检查代码是否在正确的分支
- 查看构建日志找出错误原因

### Q: 找不到 GitHub 仓库？
A: 
- 确保已授权 ACR 访问 GitHub
- 检查仓库名称是否正确
- 尝试重新授权

### Q: 构建很慢？
A: 
- 首次构建需要下载基础镜像，会比较慢
- 后续构建会使用缓存，会快很多
- 通常需要 5-10 分钟

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 构建日志（在 ACR 控制台的构建详情中）
2. 错误信息截图
3. 你的代码仓库地址（如果在 GitHub）


