# Railway MCP 配置步骤

## 第一步：获取 Railway API Token

1. 访问：https://railway.app/account
2. 滚动到 **"API"** 部分
3. 点击 **"New Token"**
4. 给 token 起个名字（例如：`cursor-mcp`）
5. **复制生成的 token**（⚠️ 只显示一次，请保存好）

## 第二步：配置 MCP

编辑文件：`C:\Users\think\.cursor\mcp.json`

添加以下配置：

```json
{
  "mcpServers": {
    "railway": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-railway"
      ],
      "env": {
        "RAILWAY_API_TOKEN": "在这里粘贴你的Railway_API_Token"
      }
    }
  }
}
```

## 第三步：重启 Cursor

配置完成后，**完全关闭并重新打开 Cursor**，使配置生效。

## 完成！

配置完成后，我就可以直接通过 MCP 调用 Railway API 来：
- ✅ 创建项目
- ✅ 部署后端服务
- ✅ 部署前端服务
- ✅ 设置环境变量
- ✅ 查看部署状态
- ✅ 管理服务

---

**注意**：Railway MCP Server 是社区构建的工具，可能需要 Node.js 18+。

