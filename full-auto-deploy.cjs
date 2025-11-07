#!/usr/bin/env node
/**
 * 完整自动化部署脚本
 * 使用阿里云 API 完成所有部署步骤
 */

const https = require('https');
const crypto = require('crypto');
const fs = require('fs');
const { execSync } = require('child_process');

// 从环境变量获取配置
const accessKeyId = process.env.ALIBABA_CLOUD_ACCESS_KEY_ID;
const accessKeySecret = process.env.ALIBABA_CLOUD_ACCESS_KEY_SECRET;
const region = process.env.ALIBABA_CLOUD_REGION || 'cn-hangzhou';

if (!accessKeyId || !accessKeySecret) {
  console.error('❌ 错误: 需要设置 ALIBABA_CLOUD_ACCESS_KEY_ID 和 ALIBABA_CLOUD_ACCESS_KEY_SECRET');
  process.exit(1);
}

const namespace = 'algorithm-games';
const repoName = 'algorithm-games';
const imageUrl = `registry.${region}.aliyuncs.com/${namespace}/${repoName}:latest`;

// 阿里云 API 签名函数
function signRequest(method, uri, params, accessKeyId, accessKeySecret) {
  const timestamp = new Date().toISOString().replace(/[:\-]|\.\d{3}/g, '');
  const nonce = Math.random().toString(36).substring(2, 15);
  
  const allParams = {
    Format: 'JSON',
    Version: '2018-12-01', // ACR API 版本
    AccessKeyId: accessKeyId,
    SignatureMethod: 'HMAC-SHA1',
    Timestamp: timestamp,
    SignatureVersion: '1.0',
    SignatureNonce: nonce,
    RegionId: region,
    ...params,
  };
  
  // 排序参数
  const sortedParams = Object.keys(allParams)
    .sort()
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(allParams[key])}`)
    .join('&');
  
  const stringToSign = `${method}&${encodeURIComponent(uri)}&${encodeURIComponent(sortedParams)}`;
  
  const signature = crypto
    .createHmac('sha1', accessKeySecret + '&')
    .update(stringToSign)
    .digest('base64');
  
  allParams.Signature = signature;
  return allParams;
}

// 发送阿里云 API 请求
function callAliyunAPI(service, action, params = {}) {
  return new Promise((resolve, reject) => {
    const hostname = service === 'cr' ? `cr.${region}.aliyuncs.com` : `${service}.${region}.aliyuncs.com`;
    const uri = '/';
    
    const queryParams = signRequest('POST', uri, { Action: action, ...params }, accessKeyId, accessKeySecret);
    const queryString = Object.keys(queryParams)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(queryParams[key])}`)
      .join('&');
    
    const options = {
      hostname,
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
          if (result.Code && result.Code !== '200') {
            reject(new Error(result.Message || JSON.stringify(result)));
          } else if (result.Error) {
            reject(new Error(result.Error.Message || JSON.stringify(result)));
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
  console.log('🚀 开始完整自动化部署...\n');
  
  try {
    // 步骤 1: 创建 ACR 命名空间
    console.log('📦 步骤 1: 创建 ACR 命名空间...');
    try {
      await callAliyunAPI('cr', 'CreateNamespace', {
        Namespace: namespace,
      });
      console.log(`  ✅ 命名空间 "${namespace}" 创建成功`);
    } catch (error) {
      if (error.message.includes('已存在') || error.message.includes('already exists')) {
        console.log(`  ✅ 命名空间 "${namespace}" 已存在`);
      } else {
        console.log(`  ⚠️  创建命名空间失败: ${error.message}`);
        console.log(`  💡 请手动在 ACR 控制台创建命名空间: ${namespace}`);
      }
    }
    
    // 步骤 2: 创建镜像仓库
    console.log('\n📦 步骤 2: 创建镜像仓库...');
    try {
      await callAliyunAPI('cr', 'CreateRepository', {
        RepoNamespace: namespace,
        RepoName: repoName,
        RepoType: 'PRIVATE',
        Summary: 'Algorithm Games Application',
      });
      console.log(`  ✅ 镜像仓库 "${repoName}" 创建成功`);
    } catch (error) {
      if (error.message.includes('已存在') || error.message.includes('already exists')) {
        console.log(`  ✅ 镜像仓库 "${repoName}" 已存在`);
      } else {
        console.log(`  ⚠️  创建镜像仓库失败: ${error.message}`);
        console.log(`  💡 请手动在 ACR 控制台创建镜像仓库`);
      }
    }
    
    // 步骤 3: 列出 ACK 集群
    console.log('\n🔍 步骤 3: 查找 ACK 集群...');
    let clusterId = null;
    try {
      const clusters = await callAliyunAPI('cs', 'DescribeClusters', {});
      if (clusters.clusters && clusters.clusters.length > 0) {
        clusterId = clusters.clusters[0].cluster_id;
        console.log(`  ✅ 找到集群: ${clusterId}`);
        console.log(`     集群名称: ${clusters.clusters[0].name}`);
      } else {
        console.log(`  ⚠️  未找到现有集群`);
        console.log(`  💡 请先在 ACK 控制台创建集群: https://cs.console.aliyun.com`);
      }
    } catch (error) {
      console.log(`  ⚠️  查找集群失败: ${error.message}`);
      console.log(`  💡 请先在 ACK 控制台创建集群: https://cs.console.aliyun.com`);
    }
    
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
    console.log('📝 重要提示：');
    console.log('  由于需要构建 Docker 镜像，请完成以下步骤：\n');
    console.log('  1. 在 ACR 控制台配置构建规则：');
    console.log('     - 登录: https://cr.console.aliyun.com');
    console.log(`     - 命名空间: ${namespace}`);
    console.log(`     - 仓库: ${repoName}`);
    console.log('     - Dockerfile 路径: ./Dockerfile');
    console.log('     - 构建上下文: /');
    console.log('     - 触发构建\n');
    console.log('  2. 等待镜像构建完成（约 5-10 分钟）\n');
    console.log('  3. 部署到 ACK：');
    if (clusterId) {
      console.log(`     - 集群 ID: ${clusterId}`);
      console.log('     - 使用 kubectl 部署: kubectl apply -f ack-deployment-auto.yaml');
    } else {
      console.log('     - 登录: https://cs.console.aliyun.com');
      console.log('     - 选择集群 → 工作负载 → 无状态 → 使用镜像创建');
      console.log(`     - 镜像: ${imageUrl}`);
    }
    console.log('\n  4. 获取访问地址：');
    console.log('     kubectl get svc algorithm-games-service -n default');
    console.log('');
    
  } catch (error) {
    console.error('\n❌ 部署失败:', error.message);
    process.exit(1);
  }
}

main().catch(console.error);

