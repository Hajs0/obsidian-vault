---
title: Day 51 - Middleware 与 ISR
date: 2026-05-29
tags:
  - nextjs
  - middleware
  - isr
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 51 - Middleware 与 ISR

## 📚 学习目标
- 理解 Next.js Middleware 的使用场景
- 掌握 ISR（增量静态再生）的实现
- 学会优化页面性能

## 🎯 核心概念

### 1. Middleware

#### 什么是 Middleware？
Middleware 在请求完成之前运行，可以：
- 重定向用户
- 修改请求/响应头
- 实现认证检查
- A/B 测试
- 地理位置重定向

#### 基本用法
```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // 获取 cookie
  const token = request.cookies.get('token');
  
  // 未登录用户重定向到登录页
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}

// 配置匹配路径
export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};
```

#### 常见用例

##### 认证检查
```typescript
export function middleware(request: NextRequest) {
  const token = request.cookies.get('token');
  const isAuthPage = request.nextUrl.pathname.startsWith('/login') || 
                     request.nextUrl.pathname.startsWith('/register');
  
  // 已登录用户访问登录页，重定向到仪表板
  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  // 未登录用户访问受保护页面，重定向到登录页
  if (!token && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}
```

##### 国际化
```typescript
export function middleware(request: NextRequest) {
  const locale = request.cookies.get('locale')?.value || 'zh-CN';
  const pathname = request.nextUrl.pathname;
  
  // 如果路径没有语言前缀，添加它
  if (!pathname.startsWith('/zh-CN') && !pathname.startsWith('/en')) {
    return NextResponse.redirect(
      new URL(`/${locale}${pathname}`, request.url)
    );
  }
  
  return NextResponse.next();
}
```

##### 限流
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const rateLimit = new Map<string, { count: number; timestamp: number }>();

export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api')) {
    const ip = request.ip || 'unknown';
    const now = Date.now();
    const windowMs = 60 * 1000; // 1 分钟
    const maxRequests = 100;
    
    const current = rateLimit.get(ip);
    
    if (!current || now - current.timestamp > windowMs) {
      rateLimit.set(ip, { count: 1, timestamp: now });
    } else if (current.count >= maxRequests) {
      return NextResponse.json(
        { error: 'Too many requests' },
        { status: 429 }
      );
    } else {
      current.count++;
    }
  }
  
  return NextResponse.next();
}
```

### 2. ISR（增量静态再生）

#### 什么是 ISR？
ISR 允许你在构建后更新静态页面，无需重新构建整个站点。

#### 基本用法
```typescript
// app/blog/[slug]/page.tsx
export const revalidate = 60; // 每 60 秒重新验证

export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(res => res.json());
  return posts.map((post) => ({
    slug: post.slug,
  }));
}

export default async function BlogPost({ params }) {
  const post = await fetch(`https://api.example.com/posts/${params.slug}`, {
    next: { revalidate: 60 },
  }).then(res => res.json());
  
  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  );
}
```

#### 按需重新验证
```typescript
// app/api/revalidate/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(request: NextRequest) {
  const { path, tag, secret } = await request.json();
  
  // 验证密钥
  if (secret !== process.env.REVALIDATION_SECRET) {
    return NextResponse.json({ error: 'Invalid secret' }, { status: 401 });
  }
  
  // 按路径重新验证
  if (path) {
    revalidatePath(path);
  }
  
  // 按标签重新验证
  if (tag) {
    revalidateTag(tag);
  }
  
  return NextResponse.json({ revalidated: true });
}
```

#### 使用标签
```typescript
// 数据获取
const posts = await fetch('https://api.example.com/posts', {
  next: { tags: ['posts'] },
}).then(res => res.json());

// 重新验证特定标签
revalidateTag('posts');
```

### 3. 静态生成 vs 服务器渲染

#### 静态生成（SSG）
```typescript
// 构建时生成
export default function StaticPage() {
  return <div>静态页面</div>;
}
```

#### 服务器渲染（SSR）
```typescript
// 每次请求时渲染
export const dynamic = 'force-dynamic';

export default async function DynamicPage() {
  const data = await fetchData();
  return <div>{data}</div>;
}
```

#### ISR
```typescript
// 构建时生成，按需重新验证
export const revalidate = 60;

export default async function ISRPage() {
  const data = await fetchData();
  return <div>{data}</div>;
}
```

## 🔧 实战练习

### 练习 1：认证中间件
```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const protectedRoutes = ['/dashboard', '/profile', '/settings'];
const authRoutes = ['/login', '/register'];

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const pathname = request.nextUrl.pathname;
  
  const isProtectedRoute = protectedRoutes.some(route => 
    pathname.startsWith(route)
  );
  const isAuthRoute = authRoutes.some(route => 
    pathname.startsWith(route)
  );
  
  // 未登录用户访问受保护页面
  if (!token && isProtectedRoute) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('from', pathname);
    return NextResponse.redirect(loginUrl);
  }
  
  // 已登录用户访问登录页
  if (token && isAuthRoute) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/profile/:path*', '/settings/:path*', '/login', '/register'],
};
```

### 练习 2：ISR 博客页面
```typescript
// app/blog/[slug]/page.tsx
import { notFound } from 'next/navigation';

export const revalidate = 60;

export async function generateStaticParams() {
  const posts = await fetch(`${process.env.API_URL}/posts`).then(res => res.json());
  return posts.map((post) => ({
    slug: post.slug,
  }));
}

async function getPost(slug: string) {
  const res = await fetch(`${process.env.API_URL}/posts/${slug}`, {
    next: { tags: [`post-${slug}`] },
  });
  
  if (!res.ok) {
    return null;
  }
  
  return res.json();
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug);
  
  if (!post) {
    notFound();
  }
  
  return (
    <article className="max-w-2xl mx-auto py-8">
      <h1 className="text-3xl font-bold mb-4">{post.title}</h1>
      <time className="text-gray-500">{post.date}</time>
      <div className="mt-8 prose">{post.content}</div>
    </article>
  );
}
```

### 练习 3：动态路由缓存
```typescript
// app/products/[id]/page.tsx
export const revalidate = 3600; // 1 小时

async function getProduct(id: string) {
  const res = await fetch(`${process.env.API_URL}/products/${id}`, {
    next: { 
      revalidate: 3600,
      tags: [`product-${id}`],
    },
  });
  
  if (!res.ok) {
    throw new Error('Failed to fetch product');
  }
  
  return res.json();
}

export default async function ProductPage({ params }: { params: { id: string } }) {
  const product = await getProduct(params.id);
  
  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <span className="text-2xl font-bold">${product.price}</span>
    </div>
  );
}
```

## 📝 最佳实践

### 1. 合理使用 Middleware
```typescript
// 好：轻量级操作
export function middleware(request: NextRequest) {
  // 简单的重定向
  if (condition) {
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

// 不好：重操作
export async function middleware(request: NextRequest) {
  // 不要在 middleware 中进行数据库查询
  const user = await db.user.findUnique(...);
}
```

### 2. 合理设置 revalidate
```typescript
// 好：根据数据更新频率设置
export const revalidate = 60; // 频繁更新
export const revalidate = 3600; // 不频繁更新

// 不好：所有页面相同设置
export const revalidate = 60;
```

### 3. 使用标签进行精确缓存
```typescript
// 好：使用标签
fetch(url, { next: { tags: ['posts', 'blog'] } });
revalidateTag('posts');

// 不好：重新验证整个路径
revalidatePath('/blog');
```

## 🎓 今日总结

**关键知识点：**
1. Middleware 在请求完成之前运行
2. ISR 允许静态页面按需更新
3. 使用标签进行精确缓存控制
4. 按需重新验证提高性能

**明日计划：**
- Day 52: Streaming SSR
