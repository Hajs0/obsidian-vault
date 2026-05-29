---
tags:
  - nextjs
  - server-actions
  - data-fetching
  - caching
  - revalidation
  - route-handlers
  - 学习日志
created: 2026-05-30
day: 10
---

# Day 10 - 学习总结

> 日期：2026-05-30
> 主题：Server Actions、数据获取、缓存与重新验证

---

## 一、今日学习内容

### 1. Server Actions（服务器操作）

Server Actions 是 Next.js 14+ 引入的服务端函数，允许直接在组件中调用服务端逻辑，无需手动创建 API 端点。

```tsx
// 声明方式
async function createPost(formData: FormData) {
  'use server'
  // 服务端逻辑
  const title = formData.get('title')
  await db.posts.create({ title })
}

// 在组件中使用
<form action={createPost}>
  <input name="title" />
  <button type="submit">提交</button>
</form>
```

**核心特性：**
- 自动处理序列化和反序列化
- 与表单原生集成（渐进增强）
- 支持 `useTransition` 实现乐观更新
- 可在 Server Components 和 Client Components 中使用

### 2. 数据获取模式

```tsx
// Server Component 中直接 async 获取
async function getData() {
  const res = await fetch('https://api.example.com/data')
  return res.json()
}

// 使用 unstable_cache 缓存数据
import { unstable_cache } from 'next/cache'
const getCachedData = unstable_cache(
  async () => getData(),
  ['my-data'],
  { revalidate: 3600, tags: ['data'] }
)
```

### 3. 缓存与重新验证

| 策略 | 方式 | 场景 |
|------|------|------|
| **基于时间** | `revalidate: N` | N 秒后重新验证 |
| **按需触发** | `revalidateTag()` / `revalidatePath()` | 事件驱动的更新 |
| **强制动态** | `cache: 'no-store'` | 每次请求都获取新数据 |

```tsx
// 按需重新验证
import { revalidateTag } from 'next/cache'

async function updatePost() {
  'use server'
  await db.posts.update(...)
  revalidateTag('posts')  // 清除带 'posts' 标签的缓存
}
```

### 4. Route Handlers（路由处理器）

在 `app/` 目录下通过 `route.ts` 定义 API 端点，支持标准 Web Request/Response API：

```tsx
// app/api/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ message: 'Hello' })
}

export async function POST(request: Request) {
  const body = await request.json()
  return NextResponse.json({ received: body })
}
```

**关键要点：**
- Route Handlers 不能与 `page.js` 在同一路径层级共存
- GET 默认不缓存，可用 `force-static` 选择性缓存
- 支持所有 HTTP 方法：GET、POST、PUT、PATCH、DELETE、HEAD、OPTIONS

---

## 二、Server Actions vs API Routes 对比

| 特性 | Server Actions | API Routes (Route Handlers) |
|------|---------------|---------------------------|
| **定义方式** | `'use server'` 指令 | `route.ts` 文件 |
| **调用方式** | 直接函数调用 | HTTP 请求 (fetch) |
| **类型安全** | 自动推导 | 需手动定义 |
| **适用场景** | 表单提交、数据变更 | 第三方 API、Webhook |
| **客户端使用** | React 原生集成 | 需要 fetch/axios |
| **序列化** | 自动处理 | 需手动 JSON 序列化 |
| **错误处理** | try/catch + error boundary | HTTP 状态码 |

**选择建议：**
- 数据写入操作 → Server Actions
- 读取数据供前端使用 → Server Components 直接获取
- 需要暴露 API 给外部 → Route Handlers
- Webhook 回调 → Route Handlers

---

## 三、与 Days 1-9 的知识串联

### Day 5 - App Router 基础
今日学习的 Route Handlers 是 App Router 路由系统的一部分。Day 5 学习了 `page.tsx`、`layout.tsx` 等 UI 文件，今天补全了 `route.ts` 这个 API 层文件，形成完整的路由知识体系。

### Day 6-7 - React Server Components
Server Actions 与 RSC 深度绑定——Server Components 可以直接 `await` 调用异步函数获取数据，Server Actions 则提供了安全的服务端写入通道。两者配合实现了全栈 React 的开发模式。

### Day 9 - 性能优化
缓存策略是 Day 9 性能优化主题的延伸：
- `revalidate` 时间控制 → 减少 TTFB
- `revalidateTag` 按需失效 → 保证数据新鲜度与性能平衡
- Route Handlers 的 `force-static` → 静态化 API 响应，提升 LCP

**知识图谱：**
```
Day 5 (App Router) → Day 6-7 (RSC) → Day 10 (Server Actions + Route Handlers)
                                          ↓
Day 9 (性能优化) ← 缓存策略 ←→ 数据获取模式
```

---

## 四、练习项目状态

- [x] shadcn/ui 组件库集成完成
- [x] App Router 基础路由搭建完成
- [x] Route Handlers demo 实现（`/api-demo` 端点）
- [ ] Server Actions 表单集成（待完成）
- [ ] 缓存策略实战（待完成）

---

## 五、下一步计划

### Day 11 - Zustand 状态管理

| 内容 | 说明 |
|------|------|
| Zustand 核心概念 | store、selector、actions |
| 与 React Server Components 的配合 | 客户端状态边界 |
| 中间件 | persist、devtools |
| 对比 Redux Toolkit / Jotai | 适用场景分析 |

**学习目标：**
1. 理解何时需要客户端状态管理（RSC 不能用）
2. 掌握 Zustand 的 minimal API 设计哲学
3. 在项目中实现购物车/主题切换的全局状态

---

## 六、今日收获

> 🎯 **核心认知：** Next.js 的数据层是一个分层架构——Server Components 负责读取、Server Actions 负责写入、Route Handlers 负责对外暴露。理解这三者的职责边界，是掌握 Next.js 全栈开发的关键。
