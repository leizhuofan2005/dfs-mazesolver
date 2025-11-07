#!/usr/bin/env node
/**
 * 阿里云 MCP 服务器
 * 提供阿里云资源管理和部署功能
 * 使用阿里云 REST API
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const https = require('https');
const crypto = require('crypto');

// 从环境变量获取配置
const accessKeyId = process.env.ALIBABA_CLOUD_ACCESS_KEY_ID;
const accessKeySecret = process.env.ALIBABA_CLOUD_ACCESS_KEY_SECRET;
const region = process.env.ALIBABA_CLOUD_REGION || 'cn-hangzhou';

if (!accessKeyId || !accessKeySecret) {
  console.error('错误: 需要设置 ALIBABA_CLOUD_ACCESS_KEY_ID 和 ALIBABA_CLOUD_ACCESS_KEY_SECRET');
  process.exit(1);
}

// 创建 MCP 服务器
const server = new Server(
  {
    name: 'aliyun-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// 工具列表
const tools = [
  {
    name: 'build_and_push_docker',
    description: '构建 Docker 镜像并推送到阿里云 ACR',
    inputSchema: {
      type: 'object',
      properties: {
        namespace: {
          type: 'string',
          description: 'ACR 命名空间',
        },
        imageName: {
          type: 'string',
          description: '镜像名称',
          default: 'algorithm-games',
        },
        dockerfilePath: {
          type: 'string',
          description: 'Dockerfile 路径',
          default: './Dockerfile',
        },
      },
      required: ['namespace'],
    },
  },
  {
    name: 'deploy_to_ack',
    description: '部署应用到阿里云容器服务 ACK',
    inputSchema: {
      type: 'object',
      properties: {
        clusterId: {
          type: 'string',
          description: 'ACK 集群 ID',
        },
        namespace: {
          type: 'string',
          description: 'Kubernetes 命名空间',
          default: 'default',
        },
        imageUrl: {
          type: 'string',
          description: '镜像地址，如 registry.cn-hangzhou.aliyuncs.com/namespace/image:tag',
        },
        appName: {
          type: 'string',
          description: '应用名称',
          default: 'algorithm-games',
        },
        port: {
          type: 'number',
          description: '服务端口',
          default: 8000,
        },
      },
      required: ['clusterId', 'imageUrl'],
    },
  },
  {
    name: 'deploy_to_fc',
    description: '部署到阿里云函数计算 FC',
    inputSchema: {
      type: 'object',
      properties: {
        serviceName: {
          type: 'string',
          description: '服务名称',
          default: 'algorithm-games',
        },
        functionName: {
          type: 'string',
          description: '函数名称',
          default: 'algorithm-games',
        },
        imageUrl: {
          type: 'string',
          description: '镜像地址',
        },
        memory: {
          type: 'number',
          description: '内存大小（MB）',
          default: 512,
        },
      },
      required: ['imageUrl'],
    },
  },
  {
    name: 'create_ecs_instance',
    description: '创建 ECS 实例并部署应用',
    inputSchema: {
      type: 'object',
      properties: {
        instanceName: {
          type: 'string',
          description: '实例名称',
          default: 'algorithm-games',
        },
        instanceType: {
          type: 'string',
          description: '实例规格',
          default: 'ecs.t5-lc1m1.small',
        },
        imageId: {
          type: 'string',
          description: '镜像 ID（Ubuntu 20.04）',
        },
        securityGroupId: {
          type: 'string',
          description: '安全组 ID',
        },
      },
      required: ['instanceName'],
    },
  },
  {
    name: 'get_deployment_info',
    description: '获取部署信息和访问地址',
    inputSchema: {
      type: 'object',
      properties: {
        deploymentType: {
          type: 'string',
          description: '部署类型：ack, fc, ecs',
          enum: ['ack', 'fc', 'ecs'],
        },
        resourceId: {
          type: 'string',
          description: '资源 ID（集群 ID、服务名或实例 ID）',
        },
      },
      required: ['deploymentType', 'resourceId'],
    },
  },
];

// 处理工具列表请求
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools,
}));

// 处理工具调用请求
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'build_and_push_docker':
        return await buildAndPushDocker(args);

      case 'deploy_to_ack':
        return await deployToACK(args);

      case 'deploy_to_fc':
        return await deployToFC(args);

      case 'create_ecs_instance':
        return await createECSInstance(args);

      case 'get_deployment_info':
        return await getDeploymentInfo(args);

      default:
        throw new Error(`未知工具: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `错误: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// 构建并推送 Docker 镜像
async function buildAndPushDocker(args) {
  const { execSync } = require('child_process');
  const registry = `registry.${region}.aliyuncs.com`;
  const fullImageName = `${registry}/${args.namespace}/${args.imageName || 'algorithm-games'}:latest`;

  const commands = [
    `docker build -t ${args.imageName || 'algorithm-games'} ${args.dockerfilePath || './Dockerfile'}`,
    `docker tag ${args.imageName || 'algorithm-games'} ${fullImageName}`,
    `docker push ${fullImageName}`,
  ];

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          message: 'Docker 构建和推送指令',
          commands,
          imageUrl: fullImageName,
          instructions: `请执行以下命令（需要先登录 ACR）:\n1. docker login --username=你的用户名 ${registry}\n2. ${commands.join('\n3. ')}`,
        }, null, 2),
      },
    ],
  };
}

// 部署到 ACK
async function deployToACK(args) {
  const deploymentYaml = `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${args.appName || 'algorithm-games'}
  namespace: ${args.namespace || 'default'}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${args.appName || 'algorithm-games'}
  template:
    metadata:
      labels:
        app: ${args.appName || 'algorithm-games'}
    spec:
      containers:
      - name: ${args.appName || 'algorithm-games'}
        image: ${args.imageUrl}
        ports:
        - containerPort: ${args.port || 8000}
        env:
        - name: ALLOWED_ORIGINS
          value: "*"
        - name: PORT
          value: "${args.port || 8000}"
---
apiVersion: v1
kind: Service
metadata:
  name: ${args.appName || 'algorithm-games'}-service
  namespace: ${args.namespace || 'default'}
spec:
  selector:
    app: ${args.appName || 'algorithm-games'}
  ports:
  - port: 80
    targetPort: ${args.port || 8000}
  type: LoadBalancer`;

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          message: 'ACK 部署配置已生成',
          clusterId: args.clusterId,
          namespace: args.namespace || 'default',
          appName: args.appName || 'algorithm-games',
          deploymentYaml,
          instructions: `使用以下命令部署到 ACK:\n1. 配置 kubectl: aliyun cs GET /k8s/${args.clusterId}/user_config\n2. 应用配置: kubectl apply -f - <<EOF\n${deploymentYaml}\nEOF\n3. 查看状态: kubectl get svc -n ${args.namespace || 'default'}`,
        }, null, 2),
      },
    ],
  };
}

// 部署到函数计算 FC
async function deployToFC(args) {
  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          message: '函数计算 FC 部署配置',
          serviceName: args.serviceName || 'algorithm-games',
          functionName: args.functionName || 'algorithm-games',
          imageUrl: args.imageUrl,
          instructions: `使用以下命令部署到 FC:\n1. 安装 Fun CLI: npm install @alicloud/fun -g\n2. 创建 fun.yaml 配置文件\n3. 部署: fun deploy --use-docker\n\n或者通过阿里云控制台:\n1. 登录函数计算控制台\n2. 创建服务和应用\n3. 选择容器镜像运行时\n4. 使用镜像: ${args.imageUrl}`,
        }, null, 2),
      },
    ],
  };
}

// 创建 ECS 实例
async function createECSInstance(args) {
  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          message: 'ECS 实例创建配置',
          instanceName: args.instanceName,
          instanceType: args.instanceType || 'ecs.t5-lc1m1.small',
          instructions: `创建 ECS 实例后，使用以下命令部署:\n1. SSH 连接到实例\n2. 安装 Docker: curl -fsSL https://get.docker.com | sh\n3. 拉取镜像: docker pull ${args.imageUrl || '你的镜像地址'}\n4. 运行容器: docker run -d -p 8000:8000 --name algorithm-games ${args.imageUrl || '你的镜像地址'}`,
        }, null, 2),
      },
    ],
  };
}

// 获取部署信息
async function getDeploymentInfo(args) {
  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          message: '获取部署信息',
          deploymentType: args.deploymentType,
          resourceId: args.resourceId,
          instructions: `查看部署信息:\n- ACK: kubectl get svc -n default\n- FC: 在函数计算控制台查看触发器地址\n- ECS: 查看实例公网 IP`,
        }, null, 2),
      },
    ],
  };
}

// 启动服务器
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('阿里云 MCP 服务器已启动');
}

main().catch(console.error);
