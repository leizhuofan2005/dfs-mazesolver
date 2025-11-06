# 云端部署完整指南

本指南提供了多种云端部署方案，从最简单到最灵活。

## 📋 部署前准备

### 1. 修改代码以支持环境变量

代码已经修改为使用环境变量 `VITE_API_URL`。如果没有设置，默认使用 `http://127.0.0.1:8000`（本地开发）。

### 2. 确保代码已提交到 GitHub

```bash
git add .
git commit -m "准备部署"
git push origin main
```

---

## 🚀 方案一：Railway（推荐，最简单）

### 优点
- 免费额度充足
- 自动 HTTPS
- 简单易用
- 支持前后端分离部署

### 后端部署步骤

1. **访问 Railway**
   - 打开 https://railway.app
   - 使用 GitHub 登录

2. **创建后端服务**
   - 点击 "New Project" → "Deploy from GitHub repo"
   - 选择你的仓库
   - Railway 会自动检测 Python 项目

3. **配置后端**
   - 在 Settings → Deploy 中设置：
     - **Root Directory**: 留空
     - **Build Command**: `pip install -r backend/requirements.txt`
     - **Start Command**: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
   - 在 Variables 中添加（可选）：
     - `ALLOWED_ORIGINS`: 你的前端域名（例如：`https://your-frontend.railway.app`）

4. **获取后端 URL**
   - 部署完成后，在 Settings → Networking 中查看 URL
   - 例如：`https://your-backend.railway.app`

### 前端部署步骤

1. **创建前端服务**
   - 在同一个项目中，点击 "New" → "Service" → "GitHub Repo"
   - 选择同一个仓库

2. **配置前端**
   - 在 Settings → Deploy 中设置：
     - **Root Directory**: 留空
     - **Build Command**: `npm install && npm run build`
     - **Start Command**: `npx serve -s dist -l $PORT`
   - 在 Variables 中添加：
     - `VITE_API_URL`: 你的后端 URL（例如：`https://your-backend.railway.app`）

3. **完成**
   - 部署完成后，访问前端 URL 即可使用

---

## 🌐 方案二：Render.com

### 后端部署

1. 访问 https://render.com，使用 GitHub 登录
2. 点击 "New" → "Web Service"
3. 选择你的仓库
4. 配置：
   - **Name**: `algorithm-games-backend`
   - **Environment**: Python 3
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
5. 点击 "Create Web Service"
6. 等待部署完成，获取 URL

### 前端部署

1. 点击 "New" → "Static Site"
2. 选择你的仓库
3. 配置：
   - **Name**: `algorithm-games-frontend`
   - **Build Command**: `npm install && npm run build`
   - **Publish Directory**: `dist`
4. 在 Environment Variables 中添加：
   - `VITE_API_URL`: 你的后端 URL
5. 部署完成

---

## ⚡ 方案三：Vercel（前端）+ Railway/Render（后端）

### 后端
按照方案一或方案二部署后端

### 前端（Vercel）

1. 访问 https://vercel.com，使用 GitHub 登录
2. 点击 "Add New" → "Project"
3. 导入你的仓库
4. 配置：
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`
5. 在 Environment Variables 中添加：
   - `VITE_API_URL`: 你的后端 URL
6. 点击 "Deploy"

---

## 🐳 方案四：Docker + 云服务器

### 构建 Docker 镜像

```bash
docker build -t algorithm-games .
```

### 运行容器

```bash
docker run -p 8000:8000 \
  -e ALLOWED_ORIGINS="https://your-frontend.com" \
  algorithm-games
```

### 部署到云平台

#### Fly.io

1. 安装 Fly CLI: `curl -L https://fly.io/install.sh | sh`
2. 登录: `fly auth login`
3. 初始化: `fly launch`
4. 部署: `fly deploy`

#### Google Cloud Run

```bash
gcloud run deploy algorithm-games \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### AWS App Runner / Azure Container Instances

按照各自平台的 Docker 部署文档操作。

---

## 🔧 方案五：单服务部署（前后端一起）

如果你想在一个服务中同时运行前后端：

### 修改后端以提供静态文件

创建 `backend/static_handler.py`:

```python
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI
import os

def setup_static_files(app: FastAPI):
    """设置静态文件服务"""
    static_dir = os.path.join(os.path.dirname(__file__), "..", "dist")
    if os.path.exists(static_dir):
        app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")
```

然后在 `backend/main.py` 中：

```python
from .static_handler import setup_static_files
# ... 其他导入

setup_static_files(app)
```

### 部署步骤

1. 构建前端: `npm run build`
2. 将 `dist` 目录复制到后端目录
3. 按照后端部署步骤部署

---

## 📝 环境变量说明

### 后端环境变量

- `ALLOWED_ORIGINS`: 允许的前端域名，用逗号分隔（例如：`https://app1.com,https://app2.com`）
- `PORT`: 服务端口（通常由平台自动设置）

### 前端环境变量

- `VITE_API_URL`: 后端 API 地址（例如：`https://your-backend.railway.app`）

---

## ✅ 部署检查清单

- [ ] 代码已提交到 GitHub
- [ ] 后端部署成功，可以访问 `/health` 端点
- [ ] 前端环境变量 `VITE_API_URL` 已设置
- [ ] 前端部署成功
- [ ] CORS 配置正确（后端允许前端域名）
- [ ] 测试所有功能是否正常

---

## 🐛 常见问题

### 1. CORS 错误

**问题**: 前端无法访问后端 API

**解决**: 
- 检查后端 `ALLOWED_ORIGINS` 环境变量
- 确保包含前端域名（包括协议，如 `https://`）

### 2. 404 错误

**问题**: API 请求返回 404

**解决**:
- 检查后端 URL 是否正确
- 确保后端服务正在运行
- 检查路由是否正确注册

### 3. 环境变量不生效

**问题**: 前端仍然使用默认的 localhost URL

**解决**:
- Vite 环境变量必须以 `VITE_` 开头
- 重新构建前端: `npm run build`
- 检查部署平台的环境变量设置

### 4. 静态文件 404

**问题**: 刷新页面后出现 404

**解决**:
- 配置 URL 重写规则（见 `vercel.json` 示例）
- 确保所有路由都指向 `index.html`

---

## 🎯 推荐方案

**最简单**: Railway（前后端分离）
**最灵活**: Docker + Fly.io
**最经济**: Render.com（免费额度）

选择最适合你的方案开始部署吧！
