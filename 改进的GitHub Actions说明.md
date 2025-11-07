# 改进的 GitHub Actions 工作流

## 🔄 改进内容

已更新工作流，添加了两种认证方式：

### 方式 1: 使用临时令牌（优先）

1. 安装阿里云 CLI
2. 使用 AccessKey 获取 ACR 临时令牌
3. 使用临时令牌登录

### 方式 2: 使用账号密码（备用）

如果获取令牌失败，回退到使用账号密码。

## 📋 需要的 GitHub Secrets

### 必需（用于获取令牌）

1. **ALIYUN_ACCESS_KEY_ID**
   - 值：`LTAI5tFDDZiMKb29RrdPSU3h`

2. **ALIYUN_ACCESS_KEY_SECRET**
   - 值：`Q0TbTjlio3msQKMDqcTPTQNTOE2oac`

### 必需（用于登录）

3. **ALIYUN_USERNAME**
   - 值：你的阿里云账号邮箱（例如：`hi312*****@aliyun.com`）

4. **ALIYUN_ACR_PASSWORD**
   - 值：ACR 服务密码（从 ACR 控制台获取）

## 🔧 配置步骤

### 步骤 1: 更新 GitHub Secrets

访问：https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions

确保有以下 4 个 Secrets：

1. `ALIYUN_ACCESS_KEY_ID` = `LTAI5tFDDZiMKb29RrdPSU3h`
2. `ALIYUN_ACCESS_KEY_SECRET` = `Q0TbTjlio3msQKMDqcTPTQNTOE2oac`
3. `ALIYUN_USERNAME` = 你的账号邮箱
4. `ALIYUN_ACR_PASSWORD` = ACR 服务密码

### 步骤 2: 推送更新后的工作流

```powershell
git add .github/workflows/build-and-push.yml
git commit -m "Improve ACR authentication with token fallback"
git push
```

### 步骤 3: 触发构建

构建会自动触发，或手动在 GitHub Actions 页面点击 "Run workflow"。

## 🎯 工作原理

1. **尝试获取临时令牌**
   - 使用 AccessKey 调用阿里云 API
   - 获取 ACR 临时授权令牌

2. **如果成功**
   - 使用临时令牌登录 ACR
   - 继续构建和推送

3. **如果失败**
   - 回退到使用账号密码
   - 继续构建和推送

## ⚠️ 注意事项

- 确保 AccessKey 有 ACR 访问权限
- 确保标准 ACR 中有命名空间 `algorithm-games`
- 如果标准 ACR 不存在，令牌获取会失败，但会回退到密码方式

---

**已更新工作流文件，请推送并触发构建！**

