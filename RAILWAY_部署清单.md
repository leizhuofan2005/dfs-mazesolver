# Railway 部署清单 ✅

## 📋 部署前准备（已完成）

- ✅ 后端依赖配置 (`backend/requirements.txt`)
- ✅ 前端构建配置 (`package.json`)
- ✅ API 环境变量支持 (`src/config.ts`)
- ✅ CORS 配置 (`backend/main.py`)
- ✅ 前端构建测试通过

## 🚀 在 Railway 上的操作步骤

### 第一步：提交代码到 GitHub

```bash
git add .
git commit -m "准备部署到 Railway"
git push origin main
```

### 第二步：部署后端（在 Railway Dashboard）

1. 访问：https://railway.app/dashboard
2. 点击 **"New Project"** → **"Deploy from GitHub repo"**
3. 选择仓库：`dfs-mazesolver`
4. 在服务设置中配置：
   ```
   Build Command: pip install -r backend/requirements.txt
   Start Command: cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
5. 等待部署完成
6. 在 **Settings** → **Networking** → 点击 **"Generate Domain"**
7. **复制后端 URL**（例如：`https://xxx-production.up.railway.app`）

### 第三步：部署前端（在同一项目中）

1. 在项目页面，点击 **"New"** → **"Service"** → **"GitHub Repo"**
2. 再次选择同一个仓库：`dfs-mazesolver`
3. 在服务设置中配置：
   ```
   Build Command: npm install && npm run build
   Start Command: npx serve -s dist -l $PORT
   ```
4. 在 **Variables** 标签页添加：
   ```
   Key: VITE_API_URL
   Value: [粘贴第二步复制的后端URL，不要加斜杠]
   ```
5. 等待部署完成
6. 在 **Settings** → **Networking** → 点击 **"Generate Domain"**
7. **复制前端 URL**

### 第四步：配置 CORS

1. 回到后端服务
2. 在 **Variables** 标签页添加：
   ```
   Key: ALLOWED_ORIGINS
   Value: [粘贴第三步复制的后端URL]
   ```
3. 保存后会自动重新部署

## ✅ 验证部署

1. **测试后端**：访问 `https://你的后端URL/health`
   - 应该返回：`{"status":"ok"}`

2. **测试前端**：访问前端 URL
   - 应该能看到应用界面
   - 测试各个功能是否正常

## 📝 重要提示

- ⚠️ **环境变量 `VITE_API_URL` 必须设置**，否则前端无法连接后端
- ⚠️ **CORS 配置**：生产环境建议限制为前端域名
- ⚠️ **URL 格式**：不要加斜杠结尾（例如：`https://xxx.railway.app` 而不是 `https://xxx.railway.app/`）

## 🆘 遇到问题？

查看 `RAILWAY_DEPLOY.md` 获取详细的故障排除指南。

