---
tags:
  - project
  - deployment
  - docker
  - day27
created: 2026-05-30
day: 27
---

# Day 27 - 全栈项目部署

## 部署架构设计

```
                    ┌─────────────────────────────────────┐
                    │            云服务器 (VPS)             │
                    │                                      │
  用户请求 ───────▶ │  ┌─────────┐    ┌─────────────────┐  │
   (HTTPS)          │  │  Nginx  │───▶│  Frontend (SPA) │  │
                    │  │  :80/443│    │  静态文件        │  │
                    │  └────┬────┘    └─────────────────┘  │
                    │       │                               │
                    │       │ /api/*                        │
                    │       ▼                               │
                    │  ┌─────────┐    ┌─────────────────┐  │
                    │  │ Backend │───▶│   PostgreSQL     │  │
                    │  │ :4000   │    │   :5432          │  │
                    │  └─────────┘    └─────────────────┘  │
                    │                                      │
                    │  ┌─────────┐                         │
                    │  │  Redis  │                         │
                    │  │  :6379  │                         │
                    │  └─────────┘                         │
                    └─────────────────────────────────────┘
```

---

## 1. 项目 Dockerfile

### 后端 Dockerfile

```dockerfile
# backend/Dockerfile
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./

# 开发环境
FROM base AS development
RUN npm ci
COPY . .
RUN npx prisma generate
EXPOSE 4000
CMD ["npm", "run", "dev"]

# 构建阶段
FROM base AS build
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npx prisma migrate deploy
RUN npm run build

# 生产环境
FROM node:20-alpine AS production
WORKDIR /app
RUN apk add --no-cache dumb-init

ENV NODE_ENV=production

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/package.json ./

RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup
USER appuser

EXPOSE 4000
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]
```

### 前端 Dockerfile

```dockerfile
# frontend/Dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 2. Docker Compose 生产配置

### docker-compose.yml

```yaml
# docker-compose.yml
version: "3.8"

services:
  # PostgreSQL 数据库
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # Redis 缓存
  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # 后端 API
  backend:
    build:
      context: ./backend
      target: production
    restart: always
    environment:
      NODE_ENV: production
      PORT: 4000
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      JWT_SECRET: ${JWT_SECRET}
      CORS_ORIGIN: ${FRONTEND_URL}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:4000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    networks:
      - app-network

  # 前端
  frontend:
    build:
      context: ./frontend
      target: production
    restart: always
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - app-network

  # Nginx 反向代理
  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - certbot_data:/var/www/certbot:ro
      - certbot_conf:/etc/letsencrypt:ro
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

  # Let's Encrypt SSL
  certbot:
    image: certbot/certbot
    volumes:
      - certbot_conf:/etc/letsencrypt
      - certbot_data:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:
  certbot_data:
  certbot_conf:

networks:
  app-network:
    driver: bridge
```

### 环境变量文件

```bash
# .env
DB_NAME=myapp
DB_USER=appuser
DB_PASSWORD=your-strong-password-here
REDIS_PASSWORD=your-redis-password
JWT_SECRET=your-jwt-secret-at-least-32-chars
FRONTEND_URL=https://yourdomain.com
DOMAIN=yourdomain.com
```

```bash
# .env.example（提交到 Git）
DB_NAME=myapp
DB_USER=appuser
DB_PASSWORD=change_me
REDIS_PASSWORD=change_me
JWT_SECRET=change_me
FRONTEND_URL=http://localhost:3000
DOMAIN=localhost
```

---

## 3. Nginx 反向代理配置

### 主配置

```nginx
# nginx/nginx.conf
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'rt=$request_time';

    access_log /var/log/nginx/access.log main;

    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout 65;
    gzip            on;
    gzip_types      text/plain text/css application/json application/javascript text/xml;
    gzip_min_length 1000;

    include /etc/nginx/conf.d/*.conf;
}
```

### 站点配置

```nginx
# nginx/conf.d/app.conf
upstream backend {
    server backend:4000;
}

# HTTP -> HTTPS 重定向
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Let's Encrypt 验证
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS 主配置
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL 证书
    ssl_certificate     /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # SSL 安全设置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 前端静态文件
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 超时设置
        proxy_connect_timeout 10s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # 请求体大小限制
        client_max_body_size 10M;
    }

    # 健康检查端点
    location /health {
        proxy_pass http://backend/health;
        access_log off;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        proxy_pass http://frontend:80;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 4. GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ${{ github.repository }}

jobs:
  # ========== 测试 ==========
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      # 后端测试
      - name: 安装后端依赖
        working-directory: backend
        run: npm ci

      - name: 数据库迁移
        working-directory: backend
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test_user:test_pass@localhost:5432/test_db

      - name: 后端单元测试
        working-directory: backend
        run: npm run test:coverage
        env:
          DATABASE_URL: postgresql://test_user:test_pass@localhost:5432/test_db

      # 前端测试
      - name: 安装前端依赖
        working-directory: frontend
        run: npm ci

      - name: 前端测试
        working-directory: frontend
        run: npm run test:coverage

      # 上传覆盖率报告
      - name: 上传覆盖率
        uses: codecov/codecov-action@v4
        with:
          files: ./backend/coverage/lcov.info,./frontend/coverage/lcov.info

  # ========== 构建并推送镜像 ==========
  build:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    strategy:
      matrix:
        service: [backend, frontend]

    steps:
      - uses: actions/checkout@v4

      - name: 登录 Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 构建并推送镜像
        uses: docker/build-push-action@v5
        with:
          context: ./${{ matrix.service }}
          target: production
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-${{ matrix.service }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_PREFIX }}-${{ matrix.service }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ========== 部署到服务器 ==========
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: 部署到服务器
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/myapp
            git pull origin main

            # 登录镜像仓库
            echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

            # 拉取最新镜像
            docker compose pull

            # 数据库迁移
            docker compose run --rm backend npx prisma migrate deploy

            # 滚动更新（零停机）
            docker compose up -d --remove-orphans

            # 清理旧镜像
            docker image prune -f

            # 健康检查
            sleep 10
            curl -f http://localhost/health || exit 1
            echo "部署成功！"
```

---

## 5. SSL 证书 (Let's Encrypt)

### 首次申请证书

```bash
# 初始 nginx 配置（仅 HTTP，用于验证）
docker compose up -d nginx

# 申请证书
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com \
  -d www.yourdomain.com

# 重启 nginx 加载证书
docker compose restart nginx
```

### 自动续期

Certbot 容器已配置每 12 小时检查续期。可添加 cron 作为备份：

```bash
# 在宿主机添加 cron
0 3 * * * cd /opt/myapp && docker compose run --rm certbot renew && docker compose exec nginx nginx -s reload
```

---

## 6. 监控和日志

### 健康检查端点

```ts
// backend/src/routes/health.ts
import { Router } from 'express'
import { prisma } from '../lib/prisma'
import { redis } from '../lib/redis'

const router = Router()

router.get('/health', async (req, res) => {
  const checks: Record<string, string> = {}
  let healthy = true

  // 数据库检查
  try {
    await prisma.$queryRaw`SELECT 1`
    checks.database = 'ok'
  } catch {
    checks.database = 'error'
    healthy = false
  }

  // Redis 检查
  try {
    await redis.ping()
    checks.redis = 'ok'
  } catch {
    checks.redis = 'error'
    healthy = false
  }

  // 内存检查
  const memUsage = process.memoryUsage()
  const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024)
  checks.memory = `${heapUsedMB}MB`
  if (heapUsedMB > 512) healthy = false

  const status = healthy ? 200 : 503
  res.status(status).json({
    status: healthy ? 'healthy' : 'unhealthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks,
  })
})

export { router as healthRouter }
```

### Docker 日志管理

```yaml
# 在 docker-compose.yml 各服务中添加
services:
  backend:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### 常用运维命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f backend
docker compose logs --tail=100 nginx

# 进入容器调试
docker compose exec backend sh
docker compose exec db psql -U $DB_USER $DB_NAME

# 数据库备份
docker compose exec db pg_dump -U $DB_USER $DB_NAME > backup_$(date +%Y%m%d).sql

# 数据库恢复
cat backup.sql | docker compose exec -T db psql -U $DB_USER $DB_NAME

# 完整重启
docker compose down && docker compose up -d

# 查看资源使用
docker stats
```

### 简单监控脚本

```bash
#!/bin/bash
# monitor.sh - 添加到 crontab 每5分钟执行
HEALTH_URL="http://localhost/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$RESPONSE" != "200" ]; then
  echo "[$(date)] 服务异常: HTTP $RESPONSE" >> /var/log/app-monitor.log
  docker compose restart
  echo "[$(date)] 已重启服务" >> /var/log/app-monitor.log
fi
```

---

## 部署检查清单

- [ ] 环境变量配置完成（.env）
- [ ] 数据库迁移已执行
- [ ] SSL 证书已申请并配置
- [ ] 防火墙开放 80/443 端口
- [ ] DNS 解析已指向服务器 IP
- [ ] 健康检查返回 200
- [ ] CI/CD 流水线测试通过
- [ ] 数据库备份 cron 已设置
- [ ] 监控脚本已部署
- [ ] 日志轮转已配置

---

## 今日总结

- 设计了 Nginx + Docker Compose 部署架构
- 编写了后端和前端的多阶段 Dockerfile
- 配置了完整的 docker-compose.yml 生产环境
- 设置了 Nginx 反向代理和 SSL 证书
- 创建了 GitHub Actions CI/CD 流水线
- 实现了健康检查和日志监控
- 掌握了零停机部署和数据库备份策略
