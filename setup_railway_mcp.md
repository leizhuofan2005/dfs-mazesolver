# Railway MCP 配置指南

## 安装 Railway MCP 服务器

### 方法一：使用 npm（推荐）

```bash
npm install -g @modelcontextprotocol/server-railway
```

### 方法二：使用 npx（无需全局安装）

直接使用 npx 运行，无需安装。

## 获取 Railway API Token

1. 访问 https://railway.app/account
2. 在 **API** 部分
3. 点击 **"New Token"**
4. 复制生成的 token（只显示一次，请保存好）

## 配置 MCP

编辑 `C:\Users\think\.cursor\mcp.json`：

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
        "RAILWAY_API_TOKEN": "你的Railway_API_Token"
      }
    }
  }
}
```

## 重启 Cursor

配置完成后，重启 Cursor 使配置生效。

## 使用方法

配置完成后，我就可以直接通过 MCP 调用 Railway API 来：
- 创建项目
- 部署服务
- 设置环境变量
- 查看部署状态
- 等等

