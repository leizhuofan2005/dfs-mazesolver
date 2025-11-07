#!/usr/bin/env node
/**
 * 阿里云自动部署脚本
 * 使用阿里云 API 自动完成：
 * 1. 创建 ACR 命名空间和镜像仓库
 * 2. 配置构建规则
 * 3. 触发构建
 * 4. 部署到 ACK
 */

const https = require('https');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// 从环境变量获取配置
const accessKeyId = process.env.ALIBABA_CLOUD_ACCESS_KEY_ID;
const accessKeySecret = process.env.ALIBABA_CLOUD_ACCESS_KEY_SECRET;
const region = process.env.ALIBABA_CLOUD_REGION || 'cn-hangzhou';

if (!accessKeyId || !accessKeySecret) {
  console.error('❌ 错误: 需要设置 ALIBABA_CLOUD_ACCESS_KEY_ID 和 ALIBABA_CLOUD_ACCESS_KEY_SECRET');
  process.exit(1);
}

// 阿里云 API 签名函数
function signRequest(method, uri, query, body, accessKeyId, accessKeySecret) {
  const timestamp = new Date().toISOString().replace(/[:\-]|\.\d{3}/g, '');
  const nonce = Math.random().toString(36).substring(2, 15);
  
  const params = {
    Format: 'JSON',
    Version: '2015-12-15',
    AccessKeyId: accessKeyId,
    SignatureMethod: 'HMAC-SHA1',
    Timestamp: timestamp,
    SignatureVersion: '1.0',
    SignatureNonce: nonce,
    ...query,
  };
  
  // 排序参数
  const sortedParams = Object.keys(params)
    .sort()
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
    .join('&');
  
  const stringToSign = `${method}&${encodeURIComponent(uri)}&${encodeURIComponent(sortedParams)}`;
  
  const signature = crypto
    .createHmac('sha1', accessKeySecret + '&')
    .update(stringToSign)
    .digest('base64');
  
  params.Signature = signature;
  return params;
}

// 发送阿里云 API 请求
function callAliyunAPI(action, params = {}) {
  return new Promise((resolve, reject) => {
    const queryParams = signRequest('POST', '/', { Action: action, ...params }, '', accessKeyId, accessKeySecret);
    const queryString = Object.keys(queryParams)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(queryParams[key])}`)
      .join('&');
    
    const options = {
      hostname: `cr.${region}.aliyuncs.com`,
      port: 443,
      path: '/',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(queryString),
      },
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          if (result.Code || result.Error) {
            reject(new Error(result.Message || result.Error?.Message || JSON.stringify(result)));
          } else {
            resolve(result);
          }
        } catch (e) {
          reject(new Error(`解析响应失败: ${e.message}\n响应: ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(queryString);
    req.end();
  });
}

// 主函数
async function main() {
  console.log('🚀 开始阿里云自动部署...\n');
  
  const namespace = 'algorithm-games';
  const repoName = 'algorithm-games';
  const imageUrl = `registry.${region}.aliyuncs.com/${namespace}/${repoName}:latest`;
  
  try {
    // 步骤 1: 检查/创建命名空间
    console.log('📦 步骤 1: 检查 ACR 命名空间...');
    try {
      const namespaces = await callAliyunAPI('GetNamespace', {
        RegionId: region,
        Namespace: namespace,
      });
      console.log(`  ✅ 命名空间 "${namespace}" 已存在`);
    } catch (error) {
      if (error.message.includes('不存在') || error.message.includes('NotFound')) {
        console.log(`  📝 创建命名空间 "${namespace}"...`);
        try {
          await callAliyunAPI('CreateNamespace', {
            RegionId: region,
            Namespace: namespace,
          });
          console.log(`  ✅ 命名空间创建成功`);
        } catch (createError) {
          console.log(`  ⚠️  创建命名空间失败: ${createError.message}`);
          console.log(`  💡 请手动在 ACR 控制台创建命名空间: ${namespace}`);
        }
      } else {
        console.log(`  ⚠️  检查命名空间失败: ${error.message}`);
      }
    }
    
    // 步骤 2: 检查/创建镜像仓库
    console.log('\n📦 步骤 2: 检查镜像仓库...');
    try {
      const repo = await callAliyunAPI('GetRepo', {
        RegionId: region,
        RepoNamespace: namespace,
        RepoName: repoName,
      });
      console.log(`  ✅ 镜像仓库 "${repoName}" 已存在`);
    } catch (error) {
      if (error.message.includes('不存在') || error.message.includes('NotFound')) {
        console.log(`  📝 创建镜像仓库 "${repoName}"...`);
        try {
          await callAliyunAPI('CreateRepo', {
            RegionId: region,
            RepoNamespace: namespace,
            RepoName: repoName,
            RepoType: 'PRIVATE',
            Summary: 'Algorithm Games Application',
          });
          console.log(`  ✅ 镜像仓库创建成功`);
        } catch (createError) {
          console.log(`  ⚠️  创建镜像仓库失败: ${createError.message}`);
          console.log(`  💡 请手动在 ACR 控制台创建镜像仓库`);
        }
      } else {
        console.log(`  ⚠️  检查镜像仓库失败: ${error.message}`);
      }
    }
    
    // 步骤 3: 配置构建规则（需要 GitHub 仓库或手动上传）
    console.log('\n🔨 步骤 3: 配置构建规则...');
    console.log('  ⚠️  构建规则需要在 ACR 控制台手动配置');
    console.log('  📝 配置步骤:');
    console.log('     1. 登录: https://cr.console.aliyun.com');
    console.log(`     2. 进入命名空间: ${namespace}`);
    console.log(`     3. 选择仓库: ${repoName}`);
    console.log('     4. 配置构建规则:');
    console.log('        - Dockerfile 路径: ./Dockerfile');
    console.log('        - 构建上下文: /');
    console.log('        - 构建版本: latest');
    console.log('     5. 触发构建');
    
    // 步骤 4: 生成部署配置
    console.log('\n📋 步骤 4: 生成部署配置...');
    const deploymentYaml = `apiVersion: apps/v1
kind: Deployment
metadata:
  name: algorithm-games
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: algorithm-games
  template:
    metadata:
      labels:
        app: algorithm-games
    spec:
      containers:
      - name: algorithm-games
        image: ${imageUrl}
        ports:
        - containerPort: 8000
        env:
        - name: ALLOWED_ORIGINS
          value: "*"
        - name: PORT
          value: "8000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: algorithm-games-service
  namespace: default
spec:
  selector:
    app: algorithm-games
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  type: LoadBalancer
`;
    
    fs.writeFileSync('ack-deployment-auto.yaml', deploymentYaml);
    console.log('  ✅ 部署配置已保存到: ack-deployment-auto.yaml');
    
    console.log('\n✅ 自动化部署准备完成！\n');
    console.log('📝 下一步操作:');
    console.log('  1. 在 ACR 控制台配置构建规则并触发构建');
    console.log('  2. 等待镜像构建完成');
    console.log('  3. 在 ACK 控制台部署应用:');
    console.log(`     - 镜像: ${imageUrl}`);
    console.log('     - 端口: 8000');
    console.log('     - 环境变量: ALLOWED_ORIGINS=*');
    console.log('\n或者使用 kubectl:');
    console.log('  kubectl apply -f ack-deployment-auto.yaml');
    
  } catch (error) {
    console.error('\n❌ 部署失败:', error.message);
    console.error('\n💡 提示:');
    console.error('  1. 检查 AccessKey 是否正确');
    console.error('  2. 检查是否有相应权限');
    console.error('  3. 可以手动在控制台完成部署');
    process.exit(1);
  }
}

main().catch(console.error);

