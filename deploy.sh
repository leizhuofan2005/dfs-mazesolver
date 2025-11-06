#!/bin/bash
# 快速部署脚本

echo "🚀 开始部署流程..."

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 错误: 当前目录不是 Git 仓库"
    exit 1
fi

# 构建前端
echo "📦 构建前端..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ 前端构建失败"
    exit 1
fi

echo "✅ 前端构建成功"

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  警告: 有未提交的更改"
    read -p "是否继续部署? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📝 部署准备完成！"
echo ""
echo "下一步："
echo "1. 如果使用 Railway: 访问 https://railway.app 并按照 DEPLOY.md 中的步骤操作"
echo "2. 如果使用 Render: 访问 https://render.com 并按照 DEPLOY.md 中的步骤操作"
echo "3. 如果使用 Vercel: 访问 https://vercel.com 并按照 DEPLOY.md 中的步骤操作"
echo ""
echo "记得设置环境变量 VITE_API_URL 为你的后端 URL！"

