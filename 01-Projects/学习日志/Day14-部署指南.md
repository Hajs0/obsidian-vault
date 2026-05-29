---
tags:
  - deployment
  - docker
  - vercel
  - day14
created: 2026-05-30
day: 14
---

# 🚀 TaskFlow 部署指南

## 一、Docker 部署

### 1.1 项目结构

```
shadcn-learning/
├── Dockerfile          # 多阶段构建配置
├── docker-compose.yml  # 编排配置
├── .dockerignore       # 排除无关文件
└── ...
```

### 1.2 Dockerfile 多阶段构建说明

| 阶段 | 作用 | 关键操作 |
|------|------|----------|
| `deps` | 安装依赖 | `npm ci`，利用缓存只在 package.json 变化时重新安装 |
| `builder` | 构建应用 | 复制源码，执行 `next build` |
| `runner` | 运行时 | 只复制构建产物，最小化镜像体积 |

### 1.3 构建与运行

```bash
# 构建镜像
docker build -t taskflow .

# 运行容器
docker run -p 3000:3000 taskflow

# 或使用 docker-compose
docker compose up -d

# 查看日志
docker compose logs -f

# 停止服务
docker compose down
```

### 1.4 生产环境优化

- 使用 `node:20-alpine` 减小基础镜像体积
- 非 root 用户运行（`nextjs:nodejs`）
- 多阶段构建只复制运行时必要文件
- 启用 `.next/standalone` 模式（需在 `next.config.ts` 中设置 `output: "standalone"`）

### 1.5 Standalone 模式配置

在 `next.config.ts` 中添加：

```typescript
const nextConfig: NextConfig = {
  output: "standalone",
};
```

---

## 二、Vercel 部署

### 2.1 一键部署

1. 将代码推送到 GitHub/GitLab/Bitbucket
2. 访问 [vercel.com](https://vercel.com) 并登录
3. 点击 **"New Project"**
4. 选择仓库，Vercel 自动检测 Next.js 并配置构建设置
5. 点击 **"Deploy"**

### 2.2 Vercel CLI 部署

```bash
# 安装 Vercel CLI
npm i -g vercel

# 首次部署（会引导配置）
vercel

# 生产环境部署
vercel --prod
```

### 2.3 Vercel 项目设置

| 配置项 | 值 |
|--------|------|
| Framework Preset | Next.js |
| Build Command | `next build` |
| Output Directory | `.next` |
| Node.js Version | 20.x |
| Install Command | `npm install` |

### 2.4 自动部署

- 推送到 `main` 分支 → 自动部署到生产环境
- 推送到其他分支 / PR → 自动创建预览部署
- 支持 GitHub Commit 状态检查

---

## 三、环境变量配置

### 3.1 常用环境变量

```bash
# .env.local（本地开发）
NEXT_PUBLIC_APP_URL=http://localhost:3000
DATABASE_URL=postgresql://user:password@localhost:5432/taskflow

# .env.production（生产环境）
NEXT_PUBLIC_APP_URL=https://taskflow.vercel.app
DATABASE_URL=postgresql://...
```

### 3.2 环境变量管理

| 方式 | 适用场景 |
|------|----------|
| `.env.local` | 本地开发，不提交到 Git |
| `.env.development` | 开发环境默认值，可提交 |
| `.env.production` | 生产环境默认值，可提交 |
| Vercel Dashboard | 生产环境敏感变量 |
| Docker Compose `environment` | 容器环境变量 |

### 3.3 安全注意事项

- ⚠️ **永远不要**把密钥提交到 Git
- 使用 `.gitignore` 排除 `.env*.local`
- 在 Vercel 中通过 Dashboard 管理生产环境密钥
- Docker 中使用 `--env-file` 参数加载环境变量

```bash
# Docker 使用 env 文件
docker run --env-file .env.local -p 3000:3000 taskflow
```

---

## 四、性能优化清单

### 4.1 构建优化

- [ ] 启用 Next.js standalone 输出模式
- [ ] 配置 `output: "standalone"` 减少部署包大小
- [ ] 使用 `npm ci` 而非 `npm install` 确保依赖版本一致
- [ ] Docker 层缓存：先复制 `package.json`，再安装依赖，最后复制源码

### 4.2 运行时优化

- [ ] 启用图片优化（Next.js `<Image>` 组件）
- [ ] 使用 `React.memo()` 减少不必要的重渲染
- [ ] Zustand selectors 精准订阅，避免全量状态更新
- [ ] 路由级别代码分割（Next.js 自动处理）

### 4.3 网络优化

- [ ] 启用 Gzip/Brotli 压缩
- [ ] 配置 CDN 缓存静态资源
- [ ] 使用 `next/font` 优化字体加载
- [ ] 预加载关键资源（`<link rel="preload">`）

### 4.4 监控与日志

- [ ] 集成 Vercel Analytics 监控 Web Vitals
- [ ] 配置错误追踪（Sentry / LogRocket）
- [ ] Docker 健康检查配置

```yaml
# docker-compose.yml 健康检查示例
services:
  app:
    build: .
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## 五、部署检查清单

部署前确认以下事项：

- [ ] `npm run build` 本地构建成功
- [ ] 环境变量已正确配置
- [ ] TypeScript 编译无错误
- [ ] ESLint 检查通过
- [ ] 核心功能手动测试通过
- [ ] 单元测试全部通过（`npx vitest run`）
- [ ] `.gitignore` 包含 `node_modules`、`.next`、`.env*.local`

---

> 📌 **下一步**: Day 15 将引入数据库，届时需要额外配置 `DATABASE_URL` 等数据库相关环境变量。
