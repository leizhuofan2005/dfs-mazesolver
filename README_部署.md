# 🚀 快速部署到阿里云 ACK

## 当前状态

✅ **已完成：**
- kubectl 已安装
- 部署配置文件已准备
- 镜像地址已配置

⏳ **需要完成：**
1. 在 ACR 控制台构建镜像（如果还没有）
2. 配置 kubectl 连接到 ACK 集群
3. 部署应用并获取访问地址

## 🎯 一键获取访问地址

### 如果你已有 ACK 集群和 kubeconfig：

```powershell
# 1. 设置 kubeconfig
$env:KUBECONFIG = "kubeconfig.yaml"  # 替换为你的 kubeconfig 文件路径

# 2. 运行部署脚本
.\deploy-and-get-url.ps1
```

脚本会自动：
- ✅ 应用部署配置
- ✅ 等待 Pod 启动
- ✅ 获取并显示外部访问地址

### 如果你还没有配置：

请按照 `获取访问地址.md` 中的步骤操作。

## 📝 快速检查清单

在运行部署脚本前，请确认：

- [ ] ACR 镜像已构建：`registry.cn-hangzhou.aliyuncs.com/algorithm-games/algorithm-games:latest`
- [ ] ACK 集群已创建
- [ ] kubeconfig 已配置
- [ ] kubectl 可以连接到集群：`kubectl get nodes`

## 🌐 获取访问地址

部署完成后，访问地址格式：
```
http://你的外部IP
```

外部 IP 会在 LoadBalancer 分配后显示（通常需要 1-2 分钟）。

## 📚 详细文档

- `获取访问地址.md` - 完整部署步骤
- `完整部署指南.md` - 详细指南
- `ack-deployment.yaml` - Kubernetes 部署配置

## 🆘 需要帮助？

运行诊断命令：
```powershell
.\deploy-and-get-url.ps1
```

或查看详细文档：`获取访问地址.md`


