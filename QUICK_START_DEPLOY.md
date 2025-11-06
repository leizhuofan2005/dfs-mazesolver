# 🚀 快速部署指南（5分钟上手）

## 最简单的方法：Railway

### 第一步：准备代码

```bash
# 确保代码已提交到 GitHub
git add .
git commit -m "准备部署"
git push origin main
```

### 第二步：部署后端

1. 访问 https://railway.app
2. 使用 GitHub 登录
3. 点击 **"New Project"** → **"Deploy from GitHub repo"**
4. 选择你的仓库
5. 在设置中配置：
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
6. 等待部署完成，复制后端 URL（例如：`https://your-backend.railway.app`）

### 第三步：部署前端

1. 在同一个 Railway 项目中，点击 **"New"** → **"Service"** → **"GitHub Repo"**
2. 选择同一个仓库
3. 在设置中配置：
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npx serve -s dist -l $PORT`
4. 在 **Variables** 中添加：
   - **Key**: `VITE_API_URL`
   - **Value**: 你的后端 URL（从第二步复制）
5. 等待部署完成

### 完成！

访问前端 URL，你的应用就可以使用了！

---

## 其他快速选项

### Render.com

1. 后端：https://render.com → New Web Service
2. 前端：https://render.com → New Static Site
3. 详细步骤见 `DEPLOY.md`

### Vercel（前端）+ Railway（后端）

1. 后端：按上面的 Railway 步骤
2. 前端：https://vercel.com → Import Project
3. 设置环境变量 `VITE_API_URL`

---

## 需要帮助？

查看 `DEPLOY.md` 获取详细说明和故障排除指南。

