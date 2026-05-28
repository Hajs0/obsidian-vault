# Day 7 - 部署与 DevOps 学习笔记

> 📅 日期：2026-05-29
> 🎯 学习目标：掌握 Docker 容器化、Docker Compose、CI/CD、云平台部署、监控与日志

---

## 🐳 一、Docker 容器化

### 1.1 什么是 Docker？

Docker 是一个开源的容器化平台，它将应用程序及其依赖打包到一个轻量级、可移植的容器中，实现"一次构建，到处运行"。

**核心概念：**
- **镜像 (Image)**：只读模板，包含运行应用所需的一切
- **容器 (Container)**：镜像的运行实例
- **Dockerfile**：定义如何构建镜像的脚本
- **仓库 (Registry)**：存储和分发镜像的地方（如 Docker Hub）

### 1.2 常用 Docker 命令

```bash
# 镜像操作
docker pull <image>          # 拉取镜像
docker build -t <name> .     # 构建镜像
docker images                # 列出本地镜像
docker rmi <image>           # 删除镜像

# 容器操作
docker run -d -p 3000:3000 <image>  # 后台运行容器并映射端口
docker ps                    # 查看运行中的容器
docker ps -a                 # 查看所有容器
docker stop <container>      # 停止容器
docker rm <container>        # 删除容器
docker logs <container>      # 查看容器日志
docker exec -it <container> sh  # 进入容器

# 清理
docker system prune          # 清理未使用的资源
docker image prune           # 清理悬挂镜像
```

### 1.3 Dockerfile 编写（Node.js 示例）

```dockerfile
# ---- 多阶段构建 ----

# 阶段1：构建
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# 阶段2：运行
FROM node:20-alpine AS runner
WORKDIR /app

# 安全：创建非 root 用户
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser
USER appuser

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "dist/index.js"]
```

**Dockerfile 最佳实践：**
```dockerfile
# ✅ 使用多阶段构建减小镜像体积
# ✅ 使用 .dockerignore 排除不需要的文件
# ✅ 把变化频率低的层放前面（利用缓存）
# ✅ 使用特定版本标签而非 latest
# ✅ 合并 RUN 命令减少层数
# ✅ 使用非 root 用户运行应用
# ✅ 使用 HEALTHCHECK 指令
```

### 1.4 .dockerignore 文件

```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.local
dist
coverage
.github
*.md
Dockerfile
docker-compose*.yml
```

### 1.5 Docker 网络

```bash
# 创建自定义网络
docker network create my-network

# 运行容器时连接网络
docker run --network my-network --name app my-app
docker run --network my-network --name db postgres:16

# 容器间可以通过名称互相访问
# app 容器中可以直接 ping db
```

### 1.6 Docker 数据卷

```bash
# 命名卷
docker volume create my-data
docker run -v my-data:/app/data my-image

# 绑定挂载（开发环境）
docker run -v $(pwd):/app my-image

# 只读挂载
docker run -v config.json:/app/config.json:ro my-image
```

---

## 🎼 二、Docker Compose

### 2.1 什么是 Docker Compose？

Docker Compose 用于定义和运行多容器应用，通过一个 YAML 文件配置所有服务。

### 2.2 完整的 Full-Stack 项目示例

```yaml
# docker-compose.yml
version: '3.8'

services:
  # ---- 前端 ----
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://localhost:8000
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - app-network

  # ---- 后端 API ----
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - NODE_ENV=production
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    networks:
      - app-network

  # ---- 数据库 ----
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: myapp
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # ---- Redis 缓存 ----
  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - app-network

  # ---- Nginx 反向代理 ----
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

### 2.3 多环境配置

```yaml
# docker-compose.override.yml (开发环境，自动加载)
services:
  backend:
    build:
      target: development
    volumes:
      - ./backend/src:/app/src  # 热重载
    command: npm run dev

# docker-compose.prod.yml (生产环境)
services:
  backend:
    build:
      target: production
    restart: always
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
```

```bash
# 使用方式
docker compose up -d                              # 默认
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d  # 生产环境
```

### 2.4 常用 Docker Compose 命令

```bash
docker compose up -d              # 后台启动所有服务
docker compose down               # 停止并删除容器
docker compose down -v            # 同时删除数据卷
docker compose ps                 # 查看服务状态
docker compose logs -f backend    # 实时查看日志
docker compose exec backend sh    # 进入服务容器
docker compose build              # 重新构建镜像
docker compose up -d --build      # 重建并启动
docker compose pull               # 拉取最新镜像
docker compose restart backend    # 重启指定服务
```

---

## 🔄 三、CI/CD 配置

### 3.1 什么是 CI/CD？

- **CI (Continuous Integration)**：持续集成，代码提交后自动构建和测试
- **CD (Continuous Delivery/Deployment)**：持续交付/部署，自动将应用部署到生产环境

### 3.2 GitHub Actions 完整配置

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # ========== 代码检查 ==========
  lint:
    name: 代码检查
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: 安装依赖
        run: npm ci
      
      - name: ESLint 检查
        run: npm run lint
      
      - name: TypeScript 类型检查
        run: npm run type-check

  # ========== 单元测试 ==========
  test:
    name: 测试
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: 安装依赖
        run: npm ci
      
      - name: 运行测试
        run: npm test -- --coverage
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
      
      - name: 上传覆盖率报告
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  # ========== 构建 Docker 镜像 ==========
  build:
    name: 构建镜像
    runs-on: ubuntu-latest
    needs: test
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: 登录 GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: 设置 Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: 构建并推送镜像
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ========== 部署到生产 ==========
  deploy:
    name: 部署
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    
    steps:
      - name: 部署到服务器
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/myapp
            docker compose pull
            docker compose up -d --remove-orphans
            docker image prune -f
```

### 3.3 GitLab CI 配置示例

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: registry.gitlab.com/$CI_PROJECT_PATH

test:
  stage: test
  image: node:20
  cache:
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run lint
    - npm test

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA

deploy_production:
  stage: deploy
  only:
    - main
  script:
    - ssh deploy@$SERVER "cd /opt/app && docker pull $DOCKER_IMAGE:$CI_COMMIT_SHA && docker compose up -d"
  environment:
    name: production
    url: https://myapp.com
```

### 3.4 CI/CD 最佳实践

```
✅ 保持 pipeline 快速（< 10分钟）
✅ 测试先行，测试失败则阻断部署
✅ 使用缓存加速构建（node_modules、Docker layers）
✅ 不同分支使用不同的环境
✅ 使用 secrets 管理敏感信息
✅ 部署后自动运行冒烟测试
✅ 保留回滚能力
✅ 使用环境变量而非硬编码配置
```

---

## ☁️ 四、Vercel / Netlify 部署

### 4.1 Vercel 部署（Next.js 首选）

**项目配置 `vercel.json`：**
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["hkg1", "sin1"],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "s-maxage=60, stale-while-revalidate=300" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/blog/:slug", "destination": "/blog/[slug]" }
  ],
  "env": {
    "DATABASE_URL": "@database-url"
  }
}
```

**部署命令：**
```bash
# 安装 CLI
npm i -g vercel

# 首次部署
vercel

# 部署到生产
vercel --prod

# 查看部署
vercel ls

# 查看日志
vercel logs <url>

# 设置环境变量
vercel env add DATABASE_URL production
```

**Vercel 核心特性：**
```
✅ 零配置部署 Next.js
✅ 全球 CDN + 边缘函数 (Edge Functions)
✅ 自动 HTTPS
✅ 预览部署 (Preview Deployments)
✅ Serverless Functions
✅ 增量静态生成 (ISR)
✅ Web Analytics
✅ 与 GitHub/GitLab/Bitbucket 自动集成
```

**环境变量管理：**
```bash
# 通过 CLI
vercel env add MY_SECRET production
vercel env add MY_SECRET preview

# 在代码中使用
process.env.MY_SECRET  # Server-side
NEXT_PUBLIC_MY_SECRET  # Client-side (需 NEXT_PUBLIC_ 前缀)
```

### 4.2 Netlify 部署（静态站点首选）

**项目配置 `netlify.toml`：**
```toml
[build]
  command = "npm run build"
  publish = "dist"
  functions = "netlify/functions"

[build.environment]
  NODE_VERSION = "20"

# 重定向规则
[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# Headers
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

# 分支部署
[context.production]
  command = "npm run build:prod"

[context.deploy-preview]
  command = "npm run build:preview"
```

**Netlify Functions 示例：**
```javascript
// netlify/functions/hello.js
exports.handler = async (event, context) => {
  const { name = 'World' } = event.queryStringParameters;
  
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify({
      message: `Hello, ${name}!`,
      timestamp: new Date().toISOString(),
    }),
  };
};
```

**部署命令：**
```bash
# 安装 CLI
npm i -g netlify-cli

# 初始化项目
netlify init

# 部署（预览）
netlify deploy

# 部署到生产
netlify deploy --prod

# 本地开发（含 Functions）
netlify dev
```

### 4.3 Vercel vs Netlify 对比

```
| 特性              | Vercel          | Netlify         |
|-------------------|-----------------|-----------------|
| 最佳框架          | Next.js         | 任意静态框架     |
| Serverless        | Edge Functions  | Netlify Functions|
| Edge Computing    | ✅ 内置         | ✅ Edge Functions|
| 构建速度          | 极快            | 快              |
| 免费额度          | 100GB 带宽/月   | 100GB 带宽/月   |
| 表单处理          | 需第三方        | ✅ 内置         |
| A/B 测试          | ✅ 内置         | ✅ 内置         |
| 适合场景          | Next.js、SSR    | 静态站点、Jamstack|
```

### 4.4 其他部署平台

```
📌 Cloudflare Pages — 全球 CDN 最快，免费额度大
📌 Railway — 适合全栈应用，支持数据库
📌 Render — 类似 Heroku，支持 Docker
📌 Fly.io — 全球边缘部署，支持 Docker
📌 AWS Amplify — AWS 生态，适合重度云用户
```

---

## 📊 五、监控和日志

### 5.1 监控体系概览

```
应用监控 (APM)
├── 性能监控 — 响应时间、吞吐量、错误率
├── 基础设施监控 — CPU、内存、磁盘、网络
├── 日志管理 — 集中式日志收集和分析
├── 告警系统 — 异常自动通知
└── 用户体验监控 — 页面加载、交互性能
```

### 5.2 应用日志最佳实践

```javascript
// 使用 Winston 日志库
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'my-app',
    version: process.env.APP_VERSION,
  },
  transports: [
    // 控制台输出
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    // 错误日志文件
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
    // 所有日志文件
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 5242880,
      maxFiles: 5,
    }),
  ],
});

// 使用示例
logger.info('Server started', { port: 3000 });
logger.warn('High memory usage', { usage: '85%' });
logger.error('Database connection failed', { error: err.message, stack: err.stack });

// 请求日志中间件
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: Date.now() - start,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
    });
  });
  next();
});
```

### 5.3 健康检查端点

```javascript
// /health 端点
app.get('/health', async (req, res) => {
  const checks = {
    uptime: process.uptime(),
    timestamp: Date.now(),
    status: 'healthy',
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
      memory: {
        status: process.memoryUsage().heapUsed < 500 * 1024 * 1024 ? 'ok' : 'warning',
        heapUsed: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
      },
    },
  };

  const isHealthy = Object.values(checks.checks).every(c => c.status === 'ok');
  res.status(isHealthy ? 200 : 503).json(checks);
});
```

### 5.4 Docker 容器日志管理

```yaml
# docker-compose.yml 日志配置
services:
  app:
    image: my-app
    logging:
      driver: json-file
      options:
        max-size: "10m"    # 单个日志文件最大 10MB
        max-file: "3"      # 最多保留 3 个文件
        tag: "{{.Name}}"   # 日志标签

  # 或使用集中式日志
  app-fluentd:
    image: my-app
    logging:
      driver: fluentd
      options:
        fluentd-address: localhost:24224
        tag: "myapp.{{.Name}}"
```

### 5.5 常用监控工具

```
📊 应用性能监控 (APM)
├── Sentry        — 错误追踪和性能监控（推荐入门）
├── New Relic     — 全栈 APM
├── Datadog       — 企业级全栈监控
└── Grafana + Prometheus — 开源监控方案

📋 日志管理
├── ELK Stack     — Elasticsearch + Logstash + Kibana
├── Grafana Loki  — 轻量级日志聚合
├── Datadog Logs  — 云日志服务
└── Papertrail    — 简单的日志管理

🔔 告警和通知
├── PagerDuty     — 事件管理和告警
├── Slack/Discord — 通知集成
├── OpsGenie      — 告警管理
└── Grafana Alerting — 基于 Grafana 的告警

📈 用户体验监控
├── Vercel Analytics  — Web 性能分析
├── Google Analytics  — 用户行为分析
├── LogRocket         — 会话回放
└── Web Vitals        — Core Web Vitals 监控
```

### 5.6 Sentry 集成（推荐）

```javascript
// Sentry 初始化
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,  // 采集 10% 的性能数据
  profilesSampleRate: 0.1,
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Sentry.Integrations.Express({ app }),
  ],
});

// Express 错误处理中间件
app.use(Sentry.Handlers.errorHandler());
```

### 5.7 Prometheus + Grafana 监控

```javascript
// 使用 prom-client 暴露指标
const client = require('prom-client');

// 创建指标
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 5],
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
});

// 暴露 /metrics 端点
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.send(await client.register.metrics());
});
```

### 5.8 日志分析常用命令

```bash
# Docker 日志
docker logs --tail 100 -f app          # 实时最后100行
docker logs --since 1h app             # 最近1小时
docker logs app 2>&1 | grep ERROR      # 过滤错误

# 系统日志
journalctl -u docker -f               # Docker 服务日志
journalctl --since "2024-01-01" -p err  # 错误级别日志

# Nginx 日志分析
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head  # Top IP
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head  # Top URL
awk '$9 >= 500' access.log | wc -l    # 5xx 错误数
```

---

## 🛠️ 六、实用 Docker Compose 模板库

### 6.1 开发环境完整模板

```yaml
# docker-compose.dev.yml — 全栈开发环境
version: '3.8'

services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
      - "9229:9229"  # Node.js 调试端口
    environment:
      - NODE_ENV=development
    command: npm run dev

  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: dev
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  adminer:
    image: adminer
    ports:
      - "8080:8080"

volumes:
  pgdata:
```

### 6.2 数据库备份脚本

```bash
#!/bin/bash
# backup.sh — 自动备份 PostgreSQL

BACKUP_DIR="/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CONTAINER="myapp-db-1"

docker exec $CONTAINER pg_dump -U user myapp | gzip > "$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"

# 保留最近 7 天的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: backup_$TIMESTAMP.sql.gz"
```

---

## 📋 七、部署检查清单

### 部署前检查
- [ ] 所有测试通过
- [ ] 环境变量已配置
- [ ] 数据库迁移已执行
- [ ] 构建产物已验证
- [ ] SSL 证书有效
- [ ] DNS 记录正确
- [ ] 备份已完成

### 部署后验证
- [ ] 健康检查端点正常
- [ ] 核心功能可用
- [ ] 日志无异常错误
- [ ] 性能指标正常
- [ ] 监控告警已配置
- [ ] 回滚方案就绪

---

## 🧠 八、知识点总结

### 核心命令速查

```bash
# Docker
docker build -t app . && docker run -d -p 3000:3000 app
docker compose up -d && docker compose logs -f

# Vercel
vercel --prod

# Netlify
netlify deploy --prod

# GitHub Actions 触发
git push origin main  # 自动触发 CI/CD
```

### 学习路径建议

```
初学者路径：
1. 学会写 Dockerfile → 2. 使用 Docker Compose
→ 3. 配置 GitHub Actions → 4. 部署到 Vercel/Netlify
→ 5. 添加基础监控

进阶路径：
1. 多阶段构建优化 → 2. K8s 编排
→ 3. 完整 CI/CD Pipeline → 4. 云原生部署
→ 5. 全链路监控 → 6. GitOps 工作流
```

---

## 📚 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Vercel 文档](https://vercel.com/docs)
- [Netlify 文档](https://docs.netlify.com/)
- [Sentry 文档](https://docs.sentry.io/)
- [The Twelve-Factor App](https://12factor.net/)

---

## ✅ 今日学习总结

| 主题 | 状态 | 关键收获 |
|------|------|----------|
| Docker 容器化 | ✅ | 多阶段构建、.dockerignore、镜像优化 |
| Docker Compose | ✅ | 多服务编排、健康检查、多环境配置 |
| CI/CD 配置 | ✅ | GitHub Actions 完整流水线、GitLab CI |
| Vercel/Netlify | ✅ | 零配置部署、Serverless Functions |
| 监控和日志 | ✅ | Winston 日志、Sentry 错误追踪、Prometheus 指标 |

> 🎯 **下一步**：实际动手部署一个 Full-Stack 项目到 Vercel + Railway，并配置 Sentry 监控。
