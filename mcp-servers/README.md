# 阿里云 MCP 服务器

这是一个自定义的阿里云 MCP 服务器，提供阿里云资源管理和部署功能。

## 功能

- ✅ 构建并推送 Docker 镜像到 ACR
- ✅ 部署应用到 ACK（容器服务）
- ✅ 部署到 FC（函数计算）
- ✅ 创建 ECS 实例
- ✅ 获取部署信息

## 安装

```bash
npm install
```

## 配置

在 `C:\Users\think\.cursor\mcp.json` 中配置：

```json
{
  "mcpServers": {
    "aliyun": {
      "command": "node",
      "args": [
        "C:\\Users\\think\\Documents\\GitHub\\dfs-mazesolver\\mcp-servers\\aliyun-mcp-server.js"
      ],
      "env": {
        "ALIBABA_CLOUD_ACCESS_KEY_ID": "你的AccessKeyId",
        "ALIBABA_CLOUD_ACCESS_KEY_SECRET": "你的AccessKeySecret",
        "ALIBABA_CLOUD_REGION": "cn-hangzhou"
      }
    }
  }
}
```

## 使用

配置完成后，重启 Cursor，然后就可以通过 MCP 使用阿里云部署功能了！



