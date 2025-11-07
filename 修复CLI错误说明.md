# 修复 CLI 安装错误

## 🔍 问题

`@alicloud/cli` 包在 npm 中不存在，导致安装失败。

## ✅ 解决方案

已简化工作流，直接使用账号密码登录，这是最可靠的方式。

### 已移除
- ❌ 阿里云 CLI 安装步骤
- ❌ 临时令牌获取步骤

### 保留
- ✅ 直接使用账号密码登录
- ✅ 简单可靠

## 📋 需要的 GitHub Secrets

只需要 2 个 Secrets：

1. **ALIYUN_USERNAME**
   - 值：你的阿里云账号邮箱（例如：`hi312*****@aliyun.com`）

2. **ALIYUN_ACR_PASSWORD**
   - 值：ACR 服务密码（从 ACR 控制台获取）

## 🔧 配置步骤

1. **访问 Secrets 页面**
   - https://github.com/leizhuofan2005/dfs-mazesolver/settings/secrets/actions

2. **确保有这两个 Secrets**
   - `ALIYUN_USERNAME`
   - `ALIYUN_ACR_PASSWORD`

3. **如果之前添加了 AccessKey Secrets，可以删除**
   - `ALIYUN_ACCESS_KEY_ID`（不再需要）
   - `ALIYUN_ACCESS_KEY_SECRET`（不再需要）

## 🚀 工作原理

工作流现在直接使用账号密码登录 ACR，这是最简单可靠的方式。

## ⚠️ 重要提示

确保：
- ✅ 使用完整的阿里云账号邮箱作为用户名
- ✅ 使用 ACR 服务密码（不是 AccessKey）
- ✅ 密码从 ACR 控制台的"访问凭证"中获取

---

**工作流已简化，请推送并触发构建！**

