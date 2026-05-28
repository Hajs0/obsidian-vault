# Day 5 - Next.js App Router 核心概念

> 学习日期：2026-05-29
> 状态：已完成 ✅

---

## 📚 一、App Router 核心概念

### 1. 文件系统路由

App Router 使用文件夹定义路由，特殊文件定义 UI：

```
app/
├── layout.tsx        # 根布局（必须）
├── page.tsx          # 首页 UI
├── loading.tsx       # 加载状态
├── error.tsx         # 错误处理
├── not-found.tsx     # 404 页面
├── dashboard/
│   ├── layout.tsx    # Dashboard 布局
│   ├── page.tsx      # /dashboard
│   └── settings/
│       └── page.tsx  # /dashboard/settings
└── blog/
    ├── page.tsx      # /blog
    └── [slug]/
        └── page.tsx  # /blog/:slug（动态路由）
```

### 2. 布局 (Layout)

布局在导航时保持状态，不会重新渲染：

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh">
      <body>
        <nav>导航栏</nav>
        {children}
      </body>
    </html>
  )
}

// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex">
      <aside>侧边栏</aside>
      <main>{children}</main>
    </div>
  )
}
```

### 3. 页面 (Page)

页面是路由的唯一默认导出组件：

```tsx
// app/page.tsx → /
export default function HomePage() {
  return <h1>首页</h1>
}

// app/dashboard/page.tsx → /dashboard
export default function DashboardPage() {
  return <h1>Dashboard</h1>
}
```

### 4. 加载状态 (Loading)

使用 React Suspense 实现即时加载 UI：

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
      <div className="h-4 bg-gray-200 rounded w-3/4"></div>
    </div>
  )
}
```

### 5. 错误处理 (Error)

错误组件必须是客户端组件：

```tsx
// app/dashboard/error.tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="text-center p-8">
      <h2>出错了！</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()}>重试</button>
    </div>
  )
}
```

### 6. 动态路由

```tsx
// app/blog/[slug]/page.tsx
export default function BlogPost({
  params,
}: {
  params: { slug: string }
}) {
  return <h1>文章：{params.slug}</h1>
}

// 生成静态参数
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json())
  return posts.map((post: { slug: string }) => ({
    slug: post.slug,
  }))
}
```

---

## 🔄 二、Pages Router vs App Router 对比

| 特性 | Pages Router | App Router |
|------|-------------|------------|
| **目录结构** | `pages/` 文件夹 | `app/` 文件夹 |
| **路由定义** | 文件即路由 | 文件夹即路由 |
| **布局** | 需手动 `_app.tsx` | 原生 `layout.tsx` 支持 |
| **数据获取** | `getServerSideProps` 等 | Server Components 直接 async/await |
| **流式渲染** | 不支持 | 原生支持 Streaming |
| **嵌套布局** | 需要第三方库 | 内置支持 |
| **加载状态** | 需手动实现 | `loading.tsx` 自动处理 |
| **错误边界** | 需手动配置 | `error.tsx` 声明式 |
| **客户端/服务端** | 默认客户端 | 默认服务端组件 |
| **缓存策略** | 有限 | 细粒度缓存控制 |

### 关键区别示例

**Pages Router 数据获取：**
```tsx
// pages/dashboard.tsx
export async function getServerSideProps() {
  const data = await fetch('https://api.example.com/data')
  const json = await data.json()
  return { props: { data: json } }
}

export default function Dashboard({ data }) {
  return <div>{data.title}</div>
}
```

**App Router 数据获取：**
```tsx
// app/dashboard/page.tsx
export default async function DashboardPage() {
  const data = await fetch('https://api.example.com/data', {
    cache: 'no-store' // 或 'force-cache'
  })
  const json = await data.json()
  
  return <div>{json.title}</div>
}
```

---

## 💡 三、高级特性

### 1. Server Components（默认）

```tsx
// 自动是 Server Component
export default async function UserProfile() {
  // 直接在组件中获取数据
  const user = await getUser()
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  )
}
```

### 2. Client Components

需要交互时使用 `'use client'`：

```tsx
'use client'

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)
  
  return (
    <button onClick={() => setCount(count + 1)}>
      点击了 {count} 次
    </button>
  )
}
```

### 3. 并行路由

同时渲染多个页面：

```
app/
├── layout.tsx
├── page.tsx
├── @analytics/
│   └── page.tsx
└── @team/
    └── page.tsx
```

```tsx
// app/layout.tsx
export default function Layout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode
  analytics: React.ReactNode
  team: React.ReactNode
}) {
  return (
    <div>
      {children}
      {analytics}
      {team}
    </div>
  )
}
```

### 4. 拦截路由

模态框等场景：

```
app/
├── feed/
│   └── page.tsx
├── photo/
│   └── [id]/
│       └── page.tsx
└── @modal/
    └── (.)photo/
        └── [id]/
            └── page.tsx  # 拦截 /photo/:id
```

---

## 🎯 四、最佳实践

1. **优先使用 Server Components** - 减少客户端 JavaScript
2. **按需使用 `'use client'`** - 只在需要交互时添加
3. **合理使用缓存** - `revalidate`、`cache: 'no-store'`
4. **错误边界要具体** - 在相关路由层级添加 `error.tsx`
5. **使用 Suspense 边界** - 提升用户体验

---

## 📝 五、常用代码片段

### Metadata API

```tsx
// app/page.tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: '我的页面',
  description: '页面描述',
}

export default function Page() {
  return <h1>Hello</h1>
}
```

### Route Handlers (API Routes)

```tsx
// app/api/users/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  const users = await getUsers()
  return NextResponse.json(users)
}

export async function POST(request: Request) {
  const body = await request.json()
  const newUser = await createUser(body)
  return NextResponse.json(newUser, { status: 201 })
}
```

### Middleware

```tsx
// middleware.ts (根目录)
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // 检查认证
  const token = request.cookies.get('token')
  
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
}
```

---

## 🔗 参考资源

- [Next.js 官方文档 - App Router](https://nextjs.org/docs/app)
- [App Router 课程](https://nextjs.org/learn/dashboard-app)
- [迁移指南](https://nextjs.org/docs/app/building-your-application/upgrading/app-router-migration)

---

## 📊 学习总结

### 掌握程度
- [x] 文件系统路由
- [x] Layout 嵌套
- [x] Loading/Error 处理
- [x] Server/Client Components
- [x] 动态路由与参数
- [ ] 并行路由（需深入）
- [ ] 拦截路由（需深入）

### 后续学习计划
1. 实践：创建一个带认证的 Dashboard 应用
2. 深入：Server Actions 和表单处理
3. 部署：Vercel 部署最佳实践

---

*笔记创建时间：2026-05-29*
*下次复习：2026-06-01*