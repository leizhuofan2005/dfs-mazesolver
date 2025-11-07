# MCP 部署说明

## ✅ 已完成的配置

1. ✅ Railway API Token 已配置到 `C:\Users\think\.cursor\mcp.json`
2. ✅ 代码已提交到 GitHub
3. ✅ 所有部署配置文件已就绪

## ⚠️ 重要：需要重启 Cursor

**MCP 配置需要重启 Cursor 才能生效！**

请：
1. **完全关闭 Cursor**（不是最小化，是完全退出）
2. **重新打开 Cursor**
3. 然后告诉我："开始部署" 或 "用 MCP 部署"

## 🚀 部署流程

重启后，我会通过 MCP 自动执行：

1. **创建 Railway 项目**（如果不存在）
2. **部署后端服务**
   - 构建命令：`pip install -r backend/requirements.txt`
   - 启动命令：`cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
3. **部署前端服务**
   - 构建命令：`npm install && npm run build`
   - 启动命令：`npx serve -s dist -l $PORT`
   - 设置环境变量：`VITE_API_URL`（指向后端 URL）
4. **配置 CORS**
   - 设置 `ALLOWED_ORIGINS` 环境变量

## 📝 当前状态

- ✅ MCP 配置：已完成
- ✅ 代码提交：已完成
- ⏳ 等待：Cursor 重启

**请重启 Cursor 后告诉我，我就可以开始自动部署了！**

