# 配置 GitHub Secrets

## 🔧 需要配置的 Secrets

访问：https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions

### 必需的 4 个 Secrets

#### 1. ALIYUN_ACCESS_KEY_ID
- **Name**: `ALIYUN_ACCESS_KEY_ID`
- **Value**: `LTAI5tFDDZiMKb29RrdPSU3h`

#### 2. ALIYUN_ACCESS_KEY_SECRET
- **Name**: `ALIYUN_ACCESS_KEY_SECRET`
- **Value**: `Q0TbTjlio3msQKMDqcTPTQNTOE2oac`

#### 3. ALIYUN_USERNAME
- **Name**: `ALIYUN_USERNAME`
- **Value**: 你的阿里云账号邮箱（例如：`hi312*****@aliyun.com`）

#### 4. ALIYUN_ACR_PASSWORD
- **Name**: `ALIYUN_ACR_PASSWORD`
- **Value**: ACR 服务密码（从 ACR 控制台获取）

## 📋 配置步骤

1. **访问 Secrets 页面**
   - https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions

2. **检查现有 Secrets**
   - 如果已有 `ALIYUN_USERNAME` 和 `ALIYUN_ACR_PASSWORD`，保留它们
   - 如果名称不对，删除并重新创建

3. **添加新的 Secrets**
   - 点击 "New repository secret"
   - 添加 `ALIYUN_ACCESS_KEY_ID`
   - 添加 `ALIYUN_ACCESS_KEY_SECRET`

4. **验证所有 Secrets**
   - 确保有 4 个 Secrets
   - 名称完全一致（大小写敏感）
   - 值不为空

## 🚀 工作原理

新的工作流会：

1. **尝试获取临时令牌**（使用 AccessKey）
   - 如果成功 → 使用令牌登录
   - 如果失败 → 回退到使用账号密码

2. **构建并推送镜像**

## ✅ 配置完成后

1. 在 GitHub Actions 页面点击 "Run workflow"
2. 或等待自动触发（已推送代码）

---

**重要**：确保所有 4 个 Secrets 都已配置！

