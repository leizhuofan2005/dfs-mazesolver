# 阿里云 MCP 配置指南

## ✅ 已完成

1. ✅ 阿里云 MCP 服务器已创建
2. ✅ 依赖已安装
3. ✅ 配置文件已准备

## 📋 配置步骤

### 第一步：获取阿里云 AccessKey

1. 访问：https://ram.console.aliyun.com/manage/ak
2. 点击 **"创建 AccessKey"**
3. 保存：
   - **AccessKey ID**
   - **AccessKey Secret**（只显示一次，请保存好）

### 第二步：配置 MCP

编辑文件：`C:\Users\think\.cursor\mcp.json`

找到 `aliyun` 部分，填入你的 AccessKey：

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

### 第三步：重启 Cursor

**完全关闭并重新打开 Cursor**，使配置生效。

## 🚀 使用方法

配置完成后，我就可以通过 MCP 直接部署到阿里云了！

### 可用功能

1. **构建并推送 Docker 镜像**
   - 自动构建 Docker 镜像
   - 推送到阿里云容器镜像服务（ACR）

2. **部署到 ACK（容器服务）**
   - 自动生成 Kubernetes 部署配置
   - 部署到阿里云容器服务

3. **部署到 FC（函数计算）**
   - Serverless 部署
   - 自动扩缩容

4. **创建 ECS 实例**
   - 创建云服务器
   - 自动部署应用

5. **获取部署信息**
   - 查看部署状态
   - 获取访问地址

## 💡 示例

配置完成后，你可以说：

- "用阿里云 MCP 部署这个应用到 ACK"
- "构建 Docker 镜像并推送到 ACR"
- "部署到函数计算 FC"

我会自动完成所有步骤！

## ⚠️ 注意事项

1. **ACR 命名空间**：需要先在阿里云控制台创建容器镜像服务的命名空间
2. **ACK 集群**：如果使用 ACK，需要先创建集群
3. **Docker 登录**：推送镜像前需要先登录 ACR
4. **地域**：默认使用 `cn-hangzhou`，可在配置中修改

## 🆘 故障排除

如果 MCP 服务器无法启动：
1. 检查 AccessKey 是否正确
2. 检查文件路径是否正确
3. 查看 Cursor 的错误日志

---

**配置完成后告诉我，我就可以开始自动部署了！**



