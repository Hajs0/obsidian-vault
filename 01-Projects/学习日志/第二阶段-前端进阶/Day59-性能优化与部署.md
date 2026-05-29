---
title: Day 59 - 性能优化与部署
date: 2026-05-29
tags:
  - 项目实战
  - 性能优化
  - 部署
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 59 - 性能优化与部署

## 📚 学习目标
- 优化应用性能
- 配置生产环境
- 部署应用上线

## 🎯 性能优化

### 1. 前端优化

#### 代码分割
```typescript
// 动态导入
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false,
});
```

#### 图片优化
```typescript
// 使用 Next.js Image
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={800}
  height={600}
  priority
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>
```

#### 字体优化
```typescript
// 使用 next/font
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
});
```

### 2. 后端优化

#### 数据库查询优化
```typescript
// 好：只查询需要的字段
const tasks = await prisma.task.findMany({
  select: {
    id: true,
    title: true,
    status: true,
    priority: true,
  },
});

// 不好：查询所有字段
const tasks = await prisma.task.findMany();
```

#### 缓存策略
```typescript
// 使用 Redis 缓存
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_URL!,
  token: process.env.UPSTASH_REDIS_TOKEN!,
});

async function getTasks(userId: string) {
  const cacheKey = `tasks:${userId}`;
  const cached = await redis.get(cacheKey);
  
  if (cached) {
    return cached;
  }
  
  const tasks = await prisma.task.findMany({
    where: { userId },
  });
  
  await redis.set(cacheKey, tasks, { ex: 60 }); // 缓存 60 秒
  
  return tasks;
}
```

### 3. Core Web Vitals 优化

#### LCP 优化
```typescript
// 预加载关键资源
<link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossOrigin="anonymous" />

// 使用 priority 属性
<Image src="/hero.jpg" alt="Hero" priority />
```

#### CLS 优化
```typescript
// 设置图片尺寸
<Image
  src="/image.jpg"
  alt="Image"
  width={400}
  height={300}
/>

// 使用 CSS contain
.card {
  contain: layout style paint;
}
```

## 🚀 部署配置

### 1. 环境变量

#### .env.production
```env
# 数据库
DATABASE_URL="postgresql://..."

# 认证
NEXTAUTH_SECRET="your-secret"
NEXTAUTH_URL="https://your-domain.com"

# Redis
UPSTASH_REDIS_URL="..."
UPSTASH_REDIS_TOKEN="..."

# 监控
SENTRY_DSN="..."
```

### 2. Next.js 配置

#### next.config.ts
```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // 输出配置
  output: 'standalone',
  
  // 图片优化
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
  
  // 压缩
  compress: true,
  
  // 严格模式
  reactStrictMode: true,
  
  // 实验性功能
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react'],
  },
};

export default nextConfig;
```

### 3. Vercel 部署

#### 部署步骤
```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署
vercel

# 生产环境部署
vercel --prod
```

#### 环境变量配置
```bash
# 添加环境变量
vercel env add DATABASE_URL
vercel env add NEXTAUTH_SECRET
vercel env add UPSTASH_REDIS_URL
```

### 4. 数据库迁移

#### Prisma 迁移
```bash
# 生成迁移
npx prisma migrate dev --name init

# 生产环境迁移
npx prisma migrate deploy

# 生成 Prisma Client
npx prisma generate
```

### 5. 监控配置

#### Sentry 集成
```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
  debug: false,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});
```

#### Analytics 集成
```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

## 📋 部署检查清单

### 部署前检查
- [ ] 环境变量配置完整
- [ ] 数据库迁移完成
- [ ] 构建成功无错误
- [ ] 测试通过
- [ ] 性能测试通过

### 部署后检查
- [ ] 应用正常访问
- [ ] 登录功能正常
- [ ] 数据库连接正常
- [ ] API 接口正常
- [ ] 监控报警配置

## 📝 最佳实践

### 1. 环境变量管理
```typescript
// 好：使用环境变量
const databaseUrl = process.env.DATABASE_URL;

// 不好：硬编码
const databaseUrl = 'postgresql://...';
```

### 2. 错误监控
```typescript
// 好：使用 Sentry
import * as Sentry from '@sentry/nextjs';

try {
  // 业务逻辑
} catch (error) {
  Sentry.captureException(error);
}

// 不好：忽略错误
try {
  // 业务逻辑
} catch (error) {
  console.error(error);
}
```

### 3. 性能监控
```typescript
// 好：使用 Vercel Analytics
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

// 不好：忽略性能
```

## 🎓 今日总结

**关键知识点：**
1. 前端优化：代码分割、图片优化、字体优化
2. 后端优化：数据库查询、缓存策略
3. Core Web Vitals 优化
4. Vercel 部署配置
5. 监控和报警

**明日计划：**
- Day 60: 项目总结与回顾
