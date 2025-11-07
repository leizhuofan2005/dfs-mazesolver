# 修复 GitHub Secrets 配置

## 🔍 问题诊断

错误信息：`Username and password required`

这说明 GitHub Actions 无法读取到 Secrets，可能的原因：

1. **Secret 名称不正确**（大小写敏感）
2. **Secret 值为空**
3. **Secret 未正确保存**

## ✅ 正确的 Secret 配置

### 必需的 Secrets（名称必须完全一致）

1. **ALIYUN_USERNAME**（大写，下划线）
   - 值：你的阿里云账号邮箱 或 AccessKey ID
   - 例如：`hi312*****@aliyun.com` 或 `LTAI5tFDDZiMKb29RrdPSU3h`

2. **ALIYUN_ACR_PASSWORD**（大写，下划线）
   - 值：ACR 服务密码 或 AccessKey Secret
   - 例如：你的 ACR 密码 或 `Q0TbTjlio3msQKMDqcTPTQNTOE2oac`

## 🔧 修复步骤

### 步骤 1: 检查当前 Secrets

1. 访问：https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions
2. 查看是否有以下 Secrets：
   - `ALIYUN_USERNAME`
   - `ALIYUN_ACR_PASSWORD`

### 步骤 2: 如果 Secrets 不存在或名称不对

1. **删除旧的 Secrets**（如果有）
2. **创建新的 Secrets**：
   - 点击 "New repository secret"
   - **Name**: `ALIYUN_USERNAME`（必须完全一致，包括大小写）
   - **Secret**: 你的阿里云账号邮箱或 AccessKey ID
   - 点击 "Add secret"

   - 再次点击 "New repository secret"
   - **Name**: `ALIYUN_ACR_PASSWORD`（必须完全一致，包括大小写）
   - **Secret**: ACR 服务密码或 AccessKey Secret
   - 点击 "Add secret"

### 步骤 3: 验证 Secrets

确保：
- ✅ Secret 名称完全匹配（包括大小写）
- ✅ Secret 值不为空
- ✅ 没有多余的空格

### 步骤 4: 重新触发构建

1. 在 GitHub Actions 页面
2. 点击失败的 workflow
3. 点击 "Re-run jobs" → "Re-run failed jobs"

或者推送一个空提交：

```powershell
git commit --allow-empty -m "Retry build"
git push
```

## 🧪 测试账号密码

运行测试脚本验证账号密码是否正确：

```powershell
.\test-acr-login.ps1
```

## 📝 两种登录方式

### 方式 1: 使用 AccessKey（如果支持）

```
ALIYUN_USERNAME: LTAI5tFDDZiMKb29RrdPSU3h
ALIYUN_ACR_PASSWORD: Q0TbTjlio3msQKMDqcTPTQNTOE2oac
```

### 方式 2: 使用账号密码（推荐）

1. **获取 ACR 密码**：
   - 登录：https://cr.console.aliyun.com
   - 点击 **访问凭证**
   - 重置或查看密码

2. **配置 Secrets**：
   ```
   ALIYUN_USERNAME: 你的阿里云账号邮箱（例如：hi312*****@aliyun.com）
   ALIYUN_ACR_PASSWORD: ACR 服务密码
   ```

## ⚠️ 常见错误

### 错误 1: Secret 名称大小写错误
- ❌ `aliyun_username` 
- ❌ `Aliyun_Username`
- ✅ `ALIYUN_USERNAME`

### 错误 2: Secret 值为空
- 确保输入了实际的值
- 检查是否有空格

### 错误 3: 使用了错误的密码
- 不是 AccessKey Secret
- 是 ACR 服务激活时设置的密码
- 如果忘记，在 ACR 控制台重置

## 🔄 快速修复

1. **删除所有相关 Secrets**
2. **重新创建**（使用正确的名称）
3. **重新触发构建**

---

**重要提示**：Secret 名称必须与工作流文件中的完全一致！


