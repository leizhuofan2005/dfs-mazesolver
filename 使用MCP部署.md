# 使用 MCP 直接部署到 Railway

## 🎯 优势

配置好 Railway MCP 后，我就可以直接通过命令行调用 Railway API，无需你在 Web 界面手动操作！

## 📋 配置步骤

### 方法一：使用配置脚本（推荐）

1. **获取 Railway API Token**
   - 访问：https://railway.app/account
   - 滚动到 **"API"** 部分
   - 点击 **"New Token"**
   - 复制生成的 token

2. **运行配置脚本**
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup_mcp.ps1
   ```
   - 按提示粘贴你的 Railway API Token

3. **重启 Cursor**
   - 完全关闭 Cursor
   - 重新打开

### 方法二：手动配置

1. **获取 Railway API Token**（同上）

2. **编辑配置文件**
   - 打开：`C:\Users\think\.cursor\mcp.json`
   - 添加以下内容：
   ```json
   {
     "mcpServers": {
       "railway": {
         "command": "npx",
         "args": [
           "-y",
           "@jasontanswe/railway-mcp"
         ],
         "env": {
           "RAILWAY_API_TOKEN": "你的Railway_API_Token"
         }
       }
     }
   }
   ```

3. **重启 Cursor**

## ✅ 配置完成后

一旦配置完成并重启 Cursor，我就可以：

- ✅ 直接创建 Railway 项目
- ✅ 部署后端服务（自动配置构建和启动命令）
- ✅ 部署前端服务（自动设置环境变量）
- ✅ 配置 CORS
- ✅ 查看部署状态
- ✅ 管理环境变量

**你只需要告诉我："用 MCP 部署到 Railway"，我就会自动完成所有步骤！**

## 🔍 验证配置

重启 Cursor 后，你可以问我：
- "列出我的 Railway 项目"
- "部署这个应用到 Railway"

如果我能执行这些操作，说明配置成功了！

