# Day 5 - React Server Components (RSC) 学习笔记

📅 日期：2026-05-29
🏷️ 标签：#React #RSC #Next.js #性能优化

---

## 一、核心概念

### 1.1 什么是 React Server Components？

React Server Components (RSC) 是 React 18+ 引入的一种新组件模型，允许组件**在服务器端渲染并直接发送到客户端**，无需将组件的 JavaScript 代码发送到浏览器。

### 1.2 Server Components vs Client Components

| 特性 | Server Components | Client Components |
|------|------------------|-------------------|
| 运行环境 | 仅在服务器端运行 | 服务器预渲染 + 客户端运行 |
| `"use client"` 指令 | ❌ 不需要 | ✅ 必须在文件顶部声明 |
| 可以访问后端资源 | ✅ 直接访问数据库、文件系统 | ❌ 只能通过 API 访问 |
| 可以使用 React Hooks | ❌ 不能用 useState/useEffect 等 | ✅ 可以使用所有 Hooks |
| 可以绑定事件处理器 | ❌ 不能 | ✅ 可以 (onClick, onChange 等) |
| 发送到客户端的 JS | ❌ 不发送（零 Bundle） | ✅ 发送到客户端 |
| 可以导入 Client 组件 | ✅ 可以导入 | ❌ 不能导入 Server Components |

### 1.3 关键规则

```
✅ Server Components 可以导入 Client Components
✅ Server Components 可以导入其他 Server Components
❌ Client Components 不能导入 Server Components
❌ Client Components 中不能直接访问服务器资源
```

---

## 二、代码示例

### 2.1 Server Component（默认）

```tsx
// app/page.tsx (Server Component - 默认)
import { db } from '@/lib/database'
import ClientButton from './ClientButton'

// ✅ 可以直接访问数据库
async function getData() {
  const posts = await db.post.findMany()
  return posts
}

export default async function HomePage() {
  const posts = await getData()

  return (
    <div>
      <h1>文章列表</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.content}</p>
        </article>
      ))}
      {/* ✅ 可以嵌套 Client Component */}
      <ClientButton />
    </div>
  )
}
```

### 2.2 Client Component

```tsx
// app/ClientButton.tsx
'use client' // ✅ 必须在文件顶部声明

import { useState } from 'react'

export default function ClientButton() {
  const [count, setCount] = useState(0)

  return (
    <button onClick={() => setCount(c => c + 1)}>
      点击次数: {count}
    </button>
  )
}
```

### 2.3 带 Props 的组件组合

```tsx
// ServerComponent.tsx
import ClientInteractive from './ClientInteractive'

export default async function ServerComponent() {
  const data = await fetchData()

  return (
    <div>
      {/* ✅ 将服务器获取的数据作为 props 传给 Client Component */}
      <ClientInteractive initialData={data} />
    </div>
  )
}

// ClientInteractive.tsx
'use client'

import { useState } from 'react'

interface Props {
  initialData: DataType
}

export default function ClientInteractive({ initialData }: Props) {
  const [data, setData] = useState(initialData)

  return <div>{/* 使用 data */}</div>
}
```

---

## 三、数据获取模式

### 3.1 直接在 Server Component 中获取数据

```tsx
// ✅ 推荐：直接在 Server Component 中 async/await
export default async function UserProfile({ userId }: { userId: string }) {
  // 直接访问数据库，无需 API 层
  const user = await db.user.findUnique({ where: { id: userId } })
  const posts = await db.post.findMany({ where: { authorId: userId } })

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
      <PostList posts={posts} />
    </div>
  )
}
```

### 3.2 并行数据获取

```tsx
// ❌ 错误：串行请求（瀑布式）
export default async function Dashboard() {
  const user = await getUser()      // 等待...
  const posts = await getPosts()    // 再等待...
  const stats = await getStats()    // 又等待...
  return <DashboardView user={user} posts={posts} stats={stats} />
}

// ✅ 正确：并行请求
export default async function Dashboard() {
  const [user, posts, stats] = await Promise.all([
    getUser(),
    getPosts(),
    getStats()
  ])
  return <DashboardView user={user} posts={posts} stats={stats} />
}
```

### 3.3 使用 fetch() 并利用 React 缓存

```tsx
export default async function PostsPage() {
  // React 自动去重和缓存相同的 fetch 请求
  const posts = await fetch('https://api.example.com/posts', {
    next: { revalidate: 3600 } // ISR: 每小时重新验证
  }).then(r => r.json())

  return <PostList posts={posts} />
}
```

### 3.4 Server Actions（表单处理）

```tsx
// app/actions.ts
'use server'

import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string
  const content = formData.get('content') as string

  await db.post.create({ data: { title, content } })

  revalidatePath('/posts') // 刷新缓存
}

// app/create-post/page.tsx (Server Component)
import { createPost } from '@/app/actions'

export default function CreatePostPage() {
  return (
    <form action={createPost}>
      <input name="title" placeholder="标题" required />
      <textarea name="content" placeholder="内容" required />
      <button type="submit">发布</button>
    </form>
  )
}
```

---

## 四、性能优化策略

### 4.1 减少客户端 Bundle 大小

```
传统 React App:
┌─────────────────────────────────────┐
│  所有组件代码 → 发送到客户端          │
│  包含：UI组件 + 数据获取 + 业务逻辑    │
│  Bundle Size: 大                     │
└─────────────────────────────────────┘

RSC 模式:
┌─────────────────────────────────────┐
│  Server Components → 仅在服务器运行   │
│  Client Components → 发送到客户端     │
│  Bundle Size: 小（只发送交互部分）     │
└─────────────────────────────────────┘
```

### 4.2 Streaming（流式渲染）

```tsx
import { Suspense } from 'react'

export default function Page() {
  return (
    <div>
      <h1>我的页面</h1>

      {/* 立即显示：Server Component */}
      <StaticHeader />

      {/* 流式加载：先显示 Loading，再替换为实际内容 */}
      <Suspense fallback={<Skeleton />}>
        <SlowDataComponent />
      </Suspense>

      <Suspense fallback={<CommentsSkeleton />}>
        <Comments />
      </Suspense>
    </div>
  )
}
```

### 4.3 组件边界策略

```
原则：尽可能在 Server Component 中工作，仅在需要交互时使用 Client Component

推荐的组件树结构：

[Server] Layout
├── [Server] Header (静态内容)
├── [Server] 数据获取逻辑
│   ├── [Client] SearchInput (需要 onChange)
│   ├── [Client] FilterDropdown (需要 useState)
│   └── [Server] DataDisplay (纯展示)
└── [Server] Footer

关键：将 Client 边界推向叶子节点
```

### 4.4 避免不必要的客户端边界

```tsx
// ❌ 错误：整个组件标记为 Client
'use client'
export default function UserCard({ user }) {
  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      <FollowButton userId={user.id} />
    </div>
  )
}

// ✅ 正确：只将交互部分标记为 Client
// UserCard.tsx (Server Component)
import FollowButton from './FollowButton'

export default function UserCard({ user }) {
  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      <FollowButton userId={user.id} />
    </div>
  )
}

// FollowButton.tsx
'use client'
export default function FollowButton({ userId }) {
  const [following, setFollowing] = useState(false)
  return <button onClick={() => setFollowing(!following)}>
    {following ? '已关注' : '关注'}
  </button>
}
```

---

## 五、常见模式与最佳实践

### 5.1 Layout 模式

```tsx
// app/layout.tsx (Server Component)
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Navigation />  {/* Server Component */}
        <main>{children}</main>
        <Footer />      {/* Server Component */}
      </body>
    </html>
  )
}
```

### 5.2 组件组合模式（Composition Pattern）

```tsx
// Server Component 提供数据，Client Component 提供交互
// Card.tsx (Server)
export default async function Card({ id }) {
  const data = await getData(id)
  return (
    <div className="card">
      <h2>{data.title}</h2>
      <p>{data.description}</p>
    </div>
  )
}

// CardContainer.tsx (Client - 需要拖拽/排序)
'use client'
export default function CardContainer({ children }) {
  const [cards, setCards] = useState(children)
  // 实现拖拽排序逻辑
  return <SortableContainer items={cards} />
}

// 使用方式
<CardContainer>
  <Card id={1} />  {/* Server Component 作为 children 传入 */}
  <Card id={2} />
</CardContainer>
```

---

## 六、常见问题 FAQ

### Q1: `"use client"` 是否意味着组件只在客户端运行？
**不是。** 带有 `"use client"` 的组件仍然会在服务器端预渲染（SSR），但它的 JavaScript 也会发送到客户端，在客户端"激活"（hydrate）并处理交互。

### Q2: Server Component 可以返回 JSX 以外的内容吗？
**不能。** Server Component 必须返回 JSX。它不能返回 JSON 或其他格式。

### Q3: 如何在 Server Component 中处理错误？
```tsx
// 使用 error.tsx (Next.js App Router)
// app/posts/error.tsx
'use client'

export default function Error({ error, reset }) {
  return (
    <div>
      <h2>出错了！</h2>
      <button onClick={() => reset()}>重试</button>
    </div>
  )
}
```

### Q4: RSC 与 SSR 有什么区别？
- **SSR (Server-Side Rendering)**：在服务器上将 React 组件渲染为 HTML，然后发送到客户端，客户端需要下载所有 JS 并 hydrate
- **RSC**：Server Components 的 JS 永远不会发送到客户端，只有 Client Components 的 JS 会被发送

---

## 七、总结

| 要点 | 说明 |
|------|------|
| 默认 Server | 在 App Router 中，组件默认是 Server Components |
| 按需 Client | 只在需要交互时添加 `'use client'` |
| 边界位置 | 将客户端边界推向组件树的叶子节点 |
| 数据获取 | Server Components 可以直接访问后端资源 |
| 性能优势 | 更小的 Bundle、更快的首屏、流式渲染 |
| 组合模式 | Server Component 可以将 Client Component 作为 children |

---

## 八、参考资源

- [React 官方文档 - Server Components](https://react.dev/reference/rsc/server-components)
- [Next.js App Router 文档](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [Dan Abramov - RSC From Scratch](https://github.com/reactwg/server-components)
- [Next.js Learn Course](https://nextjs.org/learn)

---

> 💡 **核心记忆点**：Server Components 是默认的，Client Components 是按需的。将 `'use client'` 边界推向叶子节点，最大化服务器端渲染的优势。
