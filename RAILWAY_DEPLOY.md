# Railway 部署指南

## 📋 部署前检查

### 1. 确保代码已推送到 GitHub

```bash
git status
git add .
git commit -m "准备部署到 Railway"
git push origin main
```

---

## 🚀 部署步骤

### 第一步：部署后端服务

1. **访问 Railway Dashboard**
   - 打开 https://railway.app/dashboard
   - 点击 **"New Project"** 或 **"New"** → **"Empty Project"**

2. **连接 GitHub 仓库**
   - 选择 **"Deploy from GitHub repo"**
   - 授权 Railway 访问你的 GitHub（如果还没授权）
   - 选择你的仓库：`dfs-mazesolver`

3. **配置后端服务**
   - Railway 会自动检测到 Python 项目
   - 点击服务名称进入设置
   - 在 **Settings** → **Deploy** 中配置：
     - **Root Directory**: 留空（使用项目根目录）
     - **Build Command**: `pip install -r backend/requirements.txt`
     - **Start Command**: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
   
4. **获取后端 URL**
   - 等待部署完成（通常 1-2 分钟）
   - 在 **Settings** → **Networking** 中
   - 点击 **"Generate Domain"** 生成域名
   - 复制生成的 URL（例如：`https://your-backend.railway.app`）
   - ⚠️ **重要：保存这个 URL，下一步需要用到**

5. **配置 CORS（可选但推荐）**
   - 在 **Variables** 标签页
   - 添加环境变量：
     - **Key**: `ALLOWED_ORIGINS`
     - **Value**: `*`（暂时允许所有，部署前端后再改为前端域名）

---

### 第二步：部署前端服务

1. **在同一个项目中创建新服务**
   - 在项目页面，点击 **"New"** → **"Service"**
   - 选择 **"GitHub Repo"**
   - 再次选择同一个仓库：`dfs-mazesolver`

2. **配置前端服务**
   - Railway 可能会自动检测为 Node.js 项目
   - 在 **Settings** → **Deploy** 中配置：
     - **Root Directory**: 留空
     - **Build Command**: `npm install && npm run build`
     - **Start Command**: `npx serve -s dist -l $PORT`
   
3. **设置环境变量**
   - 在 **Variables** 标签页
   - 点击 **"New Variable"**
   - 添加：
     - **Key**: `VITE_API_URL`
     - **Value**: 你的后端 URL（从第一步复制的，例如：`https://your-backend.railway.app`）
     - ⚠️ **重要：不要加斜杠结尾**

4. **获取前端 URL**
   - 等待部署完成
   - 在 **Settings** → **Networking** 中
   - 点击 **"Generate Domain"** 生成域名
   - 复制前端 URL

5. **更新后端 CORS（重要）**
   - 回到后端服务的 **Variables**
   - 修改 `ALLOWED_ORIGINS` 的值
   - 改为你的前端域名（例如：`https://your-frontend.railway.app`）
   - 保存后，后端会自动重新部署

---

## ✅ 验证部署

1. **检查后端**
   - 访问：`https://your-backend.railway.app/health`
   - 应该返回：`{"status":"ok"}`

2. **检查前端**
   - 访问前端 URL
   - 应该能看到应用界面
   - 测试各个功能（迷宫、扫雷、排序等）

---

## 🔧 常见问题

### 问题1：前端无法连接后端

**症状**: 前端页面加载，但 API 请求失败

**解决**:
1. 检查前端环境变量 `VITE_API_URL` 是否正确
2. 检查后端 CORS 配置是否包含前端域名
3. 检查后端服务是否正在运行（查看 Logs）

### 问题2：构建失败

**后端构建失败**:
- 检查 `backend/requirements.txt` 是否正确
- 查看 Logs 中的错误信息

**前端构建失败**:
- 检查 Node.js 版本（Railway 会自动选择）
- 查看 Logs 中的错误信息
- 确保 `package.json` 中的依赖正确

### 问题3：端口错误

**症状**: 服务无法启动

**解决**:
- Railway 会自动设置 `$PORT` 环境变量
- 确保启动命令使用 `$PORT` 而不是硬编码端口

---

## 📊 监控和管理

### 查看日志
- 在服务页面点击 **"Logs"** 标签
- 可以实时查看服务运行日志

### 查看指标
- 在服务页面查看 **"Metrics"**
- 可以看到 CPU、内存使用情况

### 重启服务
- 在服务页面点击 **"Deployments"**
- 可以查看部署历史
- 点击 **"Redeploy"** 可以重新部署

---

## 💰 费用说明

Railway 提供：
- **免费额度**: $5/月
- **超出后**: 按使用量付费
- 对于这个项目，免费额度通常足够使用

---

## 🎉 完成！

部署完成后，你的应用就可以通过前端 URL 访问了！

如果需要更新代码：
1. 推送到 GitHub
2. Railway 会自动检测并重新部署

