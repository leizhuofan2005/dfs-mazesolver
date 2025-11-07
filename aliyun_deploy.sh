#!/bin/bash
# 阿里云自动部署脚本

set -e

ACCESS_KEY_ID="${ALIBABA_CLOUD_ACCESS_KEY_ID:-$1}"
ACCESS_KEY_SECRET="${ALIBABA_CLOUD_ACCESS_KEY_SECRET:-$2}"
REGION="${ALIBABA_CLOUD_REGION:-${3:-cn-hangzhou}}"
NAMESPACE="${4}"
IMAGE_NAME="algorithm-games"

echo "🚀 阿里云自动部署脚本"
echo ""

# 检查参数
if [ -z "$ACCESS_KEY_ID" ] || [ -z "$ACCESS_KEY_SECRET" ]; then
    echo "⚠️  需要提供阿里云访问凭证"
    echo ""
    echo "使用方法："
    echo "  ./aliyun_deploy.sh <AccessKeyId> <AccessKeySecret> [Region] [Namespace]"
    echo ""
    echo "或者设置环境变量："
    echo "  export ALIBABA_CLOUD_ACCESS_KEY_ID='你的AccessKeyId'"
    echo "  export ALIBABA_CLOUD_ACCESS_KEY_SECRET='你的AccessKeySecret'"
    echo ""
    exit 1
fi

# 检查 Docker
echo "📦 检查 Docker..."
if ! command -v docker &> /dev/null; then
    echo "  ❌ Docker 未安装，请先安装 Docker"
    exit 1
fi
echo "  ✅ Docker: $(docker --version)"

# 构建 Docker 镜像
echo ""
echo "🔨 构建 Docker 镜像..."
docker build -t $IMAGE_NAME .

# 登录 ACR
echo ""
echo "🔐 登录阿里云容器镜像服务..."
REGISTRY="registry.${REGION}.aliyuncs.com"
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest"

# 使用阿里云 CLI 登录（如果已安装）
if command -v aliyun &> /dev/null; then
    aliyun configure set --profile default \
        --access-key-id $ACCESS_KEY_ID \
        --access-key-secret $ACCESS_KEY_SECRET \
        --region $REGION
    echo "  ✅ 登录成功"
else
    echo "  ⚠️  阿里云 CLI 未安装，请手动登录："
    echo "    docker login --username=你的用户名 $REGISTRY"
fi

# 打标签
echo ""
echo "🏷️  打标签..."
docker tag $IMAGE_NAME $FULL_IMAGE_NAME
echo "  ✅ 标签: $FULL_IMAGE_NAME"

# 推送镜像
echo ""
echo "📤 推送镜像到 ACR..."
docker push $FULL_IMAGE_NAME

echo ""
echo "✅ 部署准备完成！"
echo ""
echo "下一步："
echo "1. 登录阿里云控制台"
echo "2. 进入容器服务 ACK 或函数计算 FC"
echo "3. 使用镜像: $FULL_IMAGE_NAME"
echo "4. 配置环境变量和域名"

