# 快速修复 GitHub Secrets

## 🔍 问题

错误：`Username and password required`

原因：GitHub Secrets 未正确配置或名称不匹配

## ✅ 立即修复（3 步）

### 步骤 1: 检查 Secrets 名称

访问：https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions

**必须确保 Secret 名称完全一致（大小写敏感）：**

- ✅ `ALIYUN_USERNAME`（全大写，下划线）
- ✅ `ALIYUN_ACR_PASSWORD`（全大写，下划线）

### 步骤 2: 删除并重新创建

如果名称不对或值有问题：

1. **删除旧的 Secrets**（如果有）
2. **创建新 Secret 1**：
   - Name: `ALIYUN_USERNAME`
   - Value: `LTAI5tFDDZiMKb29RrdPSU3h`（你的 AccessKey ID）
   
3. **创建新 Secret 2**：
   - Name: `ALIYUN_ACR_PASSWORD`
   - Value: `Q0TbTjlio3msQKMDqcTPTQNTOE2oac`（你的 AccessKey Secret）

### 步骤 3: 重新触发构建

在 GitHub Actions 页面：
1. 点击失败的 workflow
2. 点击 "Re-run jobs" → "Re-run failed jobs"

## 📋 验证清单

- [ ] Secret 名称：`ALIYUN_USERNAME`（不是 `aliyun_username` 或其他）
- [ ] Secret 名称：`ALIYUN_ACR_PASSWORD`（不是 `aliyun_acr_password` 或其他）
- [ ] Secret 值不为空
- [ ] 没有多余的空格

## 🔄 如果 AccessKey 不工作

如果使用 AccessKey 登录失败，改用账号密码：

1. **获取 ACR 密码**：
   - 登录：https://cr.console.aliyun.com
   - 点击 **访问凭证**
   - 重置密码

2. **更新 Secrets**：
   - `ALIYUN_USERNAME`: 你的阿里云账号邮箱
   - `ALIYUN_ACR_PASSWORD`: ACR 服务密码

## ⚡ 快速操作

1. 访问 Secrets 页面
2. 删除所有相关 Secrets
3. 重新创建（使用正确的名称）
4. 重新运行 workflow

---

**关键点**：Secret 名称必须与工作流文件中的 `${{ secrets.ALIYUN_USERNAME }}` 完全匹配！


