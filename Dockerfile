# 多阶段构建 Dockerfile
# 阶段1: 构建前端
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
COPY vite.config.ts tsconfig.json ./
COPY index.html ./
COPY index.tsx ./
COPY App.tsx ./
COPY components/ ./components/
COPY types.ts ./
COPY src/ ./src/
RUN npm install
RUN npm run build

# 阶段2: Python 后端
FROM python:3.11-slim
WORKDIR /app

# 安装依赖
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制后端代码
COPY backend/ ./backend/

# 复制前端构建产物到 static 目录（后端会自动提供静态文件服务）
COPY --from=frontend-builder /app/dist ./static

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
