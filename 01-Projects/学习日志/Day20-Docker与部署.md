---
tags:
  - docker
  - deployment
  - devops
  - ci-cd
  - day20
created: 2026-05-30
day: 20
---

# Day 20: Docker 与部署 🐳

## 今日目标

- 掌握 Docker 多阶段构建和镜像优化
- 学会 Docker Compose 编排多服务应用
- 了解 CI/CD 流程和 GitHub Actions
- 对比不同部署方案的优劣

---

## 一、Docker 进阶

### 1.1 多阶段构建

多阶段构建可以显著减小最终镜像大小：

```dockerfile
# ============ 阶段 1: 构建 ============
FROM node:20-alpine AS builder

WORKDIR /app

# 先复制依赖文件（利用缓存层）
COPY package*.json ./
RUN npm ci

# 复制源代码并构建
COPY . .
RUN npm run build

# ============ 阶段 2: 运行 ============
FROM node:20-alpine AS runner

WORKDIR /app

# 只复制必要的文件
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# 安全: 使用非 root 用户
USER node

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### 1.2 Express 应用 Dockerfile

```dockerfile
# ---- 开发环境 ----
FROM node:20-alpine AS development

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 3000
CMD ["npm", "run", "dev"]

# ---- 生产环境 ----
FROM node:20-alpine AS production

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --from=development /app/dist ./dist
COPY --from=development /app/prisma ./prisma

# 生成 Prisma Client
RUN npx prisma generate

USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

### 1.3 Docker Compose 编排

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Express 后端 API
  api:
    build:
      context: ./express-api
      dockerfile: Dockerfile
      target: development
    ports:
      - "3000:3000"
    volumes:
      - ./express-api/src:/app/src  # 热重载
    environment:
      - NODE_ENV=development
      - DATABASE_URL=file:/app/data/db.sqlite
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app-network

  # Next.js 前端
  frontend:
    build:
      context: ./shadcn-app
      dockerfile: Dockerfile
    ports:
      - "3001:3000"
    volumes:
      - ./shadcn-app/src:/app/src
    environment:
      - NEXT_PUBLIC_API_URL=http://api:3000
    depends_on:
      - api
    networks:
      - app-network

  # 数据库 (SQLite 通过卷持久化)
  db:
    image: alpine:latest
    volumes:
      - db-data:/app/data
    command: >
      sh -c "touch /app/data/db.sqlite && 
             echo 'Database volume ready' && 
             tail -f /dev/null"
    healthcheck:
      test: ["CMD", "test", "-f", "/app/data/db.sqlite"]
      interval: 5s
      timeout: 3s
      retries: 3
    networks:
      - app-network

volumes:
  db-data:
    driver: local

networks:
  app-network:
    driver: bridge
```

### 1.4 卷挂载和网络

```yaml
# 卷挂载类型
volumes:
  # 命名卷 - 数据持久化
  db-data:
    driver: local
  
  # 绑定挂载 - 开发热重载
  - ./src:/app/src:cached    # 本地代码同步到容器

  # tmpfs 挂载 - 临时文件
  - type: tmpfs
    target: /app/tmp
    tmpfs:
      size: 100M
```

```yaml
# 网络配置
networks:
  # 默认桥接网络
  app-network:
    driver: bridge
  
  # 前后端隔离网络
  backend-net:
    driver: bridge
    internal: true  # 禁止外部访问

services:
  api:
    networks:
      - app-network      # 可被外部访问
      - backend-net      # 可连接数据库
  
  db:
    networks:
      - backend-net      # 只在内部网络
```

### 1.5 镜像优化技巧

```dockerfile
# ✅ 使用 Alpine 基础镜像
FROM node:20-alpine

# ✅ 利用 .dockerignore 减少上下文
# .dockerignore
# node_modules
# .git
# *.md
# .env
# dist

# ✅ 合并 RUN 指令减少层数
RUN apk add --no-cache dumb-init && \
    npm ci --only=production && \
    npm cache clean --force

# ✅ 先复制 package.json 再 npm install（利用缓存）
COPY package*.json ./
RUN npm ci
COPY . .

# ✅ 使用 dumb-init 正确处理信号
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

镜像大小对比：

| 优化策略 | 镜像大小 |
|---------|---------|
| node:20 (全量) | ~1GB |
| node:20-alpine | ~180MB |
| 多阶段 + alpine | ~120MB |
| distroless | ~80MB |

---

## 二、CI/CD

### 2.1 GitHub Actions 基础

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'

jobs:
  # ===== 测试 =====
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 设置 Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: 安装依赖
        run: npm ci
      
      - name: 代码检查
        run: npm run lint
      
      - name: 运行测试
        run: npm test -- --coverage
      
      - name: 上传覆盖率报告
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  # ===== 构建 =====
  build:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 构建 Docker 镜像
        run: |
          docker build \
            --target production \
            -t myapp:${{ github.sha }} \
            .
      
      - name: 保存构建产物
        run: docker save myapp:${{ github.sha }} | gzip > image.tar.gz
      
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: docker-image
          path: image.tar.gz

  # ===== 部署（仅 main 分支）=====
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: 下载构建产物
        uses: actions/download-artifact@v4
        with:
          name: docker-image
      
      - name: 部署到服务器
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/myapp
            docker compose pull
            docker compose up -d
            docker system prune -f
```

### 2.2 自动测试 + 构建 + 部署

```yaml
# 完整的 CI/CD 流程示例
name: Full Pipeline

on:
  push:
    branches: [main]

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      # 测试
      - name: 运行测试
        run: |
          npm ci
          npm run lint
          npm test
      
      # 构建
      - name: 构建项目
        run: npm run build
      
      # 部署到 Railway
      - name: 部署到 Railway
        uses: bervProject/railway-deploy@main
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: my-express-api
```

---

## 三、部署选项对比

### 3.1 Vercel（前端最佳选择）

```bash
# 安装 CLI
npm i -g vercel

# 部署
vercel --prod

# 配置 vercel.json
{
  "framework": "nextjs",
  "regions": ["hkg1"],
  "env": {
    "NEXT_PUBLIC_API_URL": "@api-url"
  }
}
```

**优点：** 免费额度大、全球 CDN、自动 HTTPS、Git 集成  
**缺点：** 主要面向前端、后端有执行时间限制

### 3.2 Railway / Render（后端推荐）

```bash
# Railway 部署
# 1. 连接 GitHub 仓库
# 2. 自动检测 Node.js 项目
# 3. 配置环境变量
# 4. 自动部署

# Render 部署
# render.yaml
services:
  - type: web
    name: my-api
    env: node
    buildCommand: npm install && npm run build
    startCommand: node dist/index.js
    envVars:
      - key: DATABASE_URL
        sync: false
```

**优点：** 简单易用、免费额度、自动 SSL  
**缺点：** 免费版冷启动慢、自定义有限

### 3.3 VPS 自建（完全控制）

```bash
# 服务器初始化
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose-v2 -y

# 克隆项目
git clone https://github.com/user/myapp.git
cd myapp

# 配置环境变量
cp .env.example .env
nano .env

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# Nginx 反向代理
sudo apt install nginx
```

```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**优点：** 完全控制、可定制、长期成本低  
**缺点：** 需要自行维护、安全责任自负

### 3.4 方案对比表

| 特性 | Vercel | Railway | Render | VPS |
|-----|--------|---------|--------|-----|
| 适合场景 | 前端 | 全栈 | 后端 | 完全控制 |
| 免费额度 | 100GB/月 | $5/月 | 750小时/月 | 无 |
| 自定义域名 | ✅ | ✅ | ✅ | ✅ |
| 自动SSL | ✅ | ✅ | ✅ | 需配置 |
| 冷启动 | 无 | 有 | 有 | 无 |
| 难度 | ⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

---

## 四、监控和日志

### 4.1 应用日志

```typescript
// src/utils/logger.ts
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'express-api' },
  transports: [
    // 控制台输出
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    // 文件输出
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log' 
    })
  ]
});

export default logger;
```

### 4.2 请求日志中间件

```typescript
// src/middleware/logger.ts
import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('请求完成', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip
    });
  });
  
  next();
}
```

### 4.3 健康检查端点

```typescript
// src/routes/health.ts
import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

router.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      database: 'unknown'
    }
  };

  try {
    await prisma.$queryRaw`SELECT 1`;
    health.checks.database = 'ok';
  } catch (error) {
    health.checks.database = 'error';
    health.status = 'degraded';
    res.status(503);
  }

  res.json(health);
});

export default router;
```

### 4.4 Docker 日志管理

```yaml
# docker-compose.prod.yml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 五、Docker 常用命令

```bash
# 构建镜像
docker build -t myapp:latest .

# 运行容器
docker run -d -p 3000:3000 --name api myapp:latest

# 查看日志
docker logs -f api
docker logs --tail 100 api

# 进入容器
docker exec -it api sh

# 清理
docker system prune -a          # 清理所有未使用资源
docker image prune -a           # 清理未使用镜像
docker volume prune             # 清理未使用卷

# Docker Compose
docker compose up -d            # 启动
docker compose down             # 停止
docker compose logs -f api      # 查看日志
docker compose exec api sh      # 进入容器
docker compose ps               # 查看状态
```

---

## 今日练习

1. 为 Express API 编写 Dockerfile（多阶段构建）
2. 编写 docker-compose.yml 编排前后端 + 数据库
3. 创建 GitHub Actions CI/CD 流程
4. 对比 Vercel 和 Railway 的部署体验

---

## 今日总结

| 主题 | 掌握程度 |
|-----|---------|
| Docker 多阶段构建 | ⭐⭐⭐⭐ |
| Docker Compose 编排 | ⭐⭐⭐ |
| CI/CD 流程 | ⭐⭐⭐ |
| 部署方案对比 | ⭐⭐⭐⭐ |
| 监控和日志 | ⭐⭐⭐ |

> **明日预告：** 性能优化与监控 — 让应用更快更稳定！
