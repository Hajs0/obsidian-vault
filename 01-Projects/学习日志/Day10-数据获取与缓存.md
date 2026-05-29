---
tags:
  - nextjs
  - data-fetching
  - caching
  - revalidation
  - streaming
  - suspense
created: 2026-05-30
day: 10
---

# Day 10: Next.js 16 数据获取与缓存

## 一、服务端数据获取（Server Components）

### 1.1 基本模式：async 组件 + fetch

Server Components 可以直接定义为 `async` 函数，在其中使用 `await fetch()` 获取数据：

```tsx
// app/blog/page.tsx
export default async function Page() {
  const data = await fetch('https://api.example.com/posts')
  const posts = await data.json()
  return (
    <ul>
      {posts.map((post: { id: string; title: string }) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

**关键特性：**
- Server Components 中的 fetch 请求**默认不缓存**（Next.js 16 新行为）
- 相同的 fetch 请求在同一组件树中会被**记忆化（memoized）**，避免重复请求
- 凭据和查询逻辑不会包含在客户端 bundle 中

### 1.2 使用 ORM 或数据库

```tsx
import { db, posts } from '@/lib/db'

export default async function Page() {
  const allPosts = await db.select().from(posts)
  return (
    <ul>
      {allPosts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 1.3 串行 vs 并行数据获取

**串行获取**（不推荐 — 后一个请求等待前一个完成）：

```tsx
export default async function Page({ params }: { params: Promise<{ username: string }> }) {
  const { username } = await params
  const artist = await getArtist(username)       // 等待
  const albums = await getAlbums(username)       // 再等待
  return <div>{artist.name}</div>
}
```

**并行获取**（推荐 — 使用 `Promise.all`）：

```tsx
export default async function Page({ params }: { params: Promise<{ username: string }> }) {
  const { username } = await params
  const artistData = getArtist(username)         // 立即发起
  const albumsData = getAlbums(username)         // 立即发起
  const [artist, albums] = await Promise.all([artistData, albumsData])
  return <div>{artist.name}</div>
}
```

> ⚠️ 注意：`params` 在 Next.js 16 中是 `Promise` 类型，需要 `await`。

### 1.4 React.cache 共享数据

使用 `React.cache` 包裹的函数在同一请求中只会执行一次：

```tsx
import { cache } from 'react'

export const getUser = cache(async () => {
  const res = await fetch('https://api.example.com/user')
  return res.json()
})
```

---

## 二、客户端数据获取（Client Components）

### 2.1 使用 React `use` API（推荐）

Server Component 获取数据但不 await，将 Promise 传给 Client Component：

```tsx
// page.tsx (Server Component)
import Posts from '@/components/Posts'
import { Suspense } from 'react'

export default function Page() {
  const posts = getPosts()  // 不要 await！
  return (
    <Suspense fallback={<div>加载中...</div>}>
      <Posts posts={posts} />
    </Suspense>
  )
}

// components/Posts.tsx (Client Component)
'use client'
import { use } from 'react'

export default function Posts({ posts }: { posts: Promise<{ id: string; title: string }[]> }) {
  const allPosts = use(posts)
  return (
    <ul>
      {allPosts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 2.2 useEffect + fetch 模式

```tsx
'use client'
import { useState, useEffect } from 'react'

interface Post {
  id: number
  title: string
  body: string
}

export default function PostList() {
  const [posts, setPosts] = useState<Post[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchPosts() {
      try {
        const res = await fetch('https://api.example.com/posts')
        if (!res.ok) throw new Error('请求失败')
        setPosts(await res.json())
      } catch (err) {
        setError(err instanceof Error ? err.message : '未知错误')
      } finally {
        setLoading(false)
      }
    }
    fetchPosts()
  }, [])

  if (loading) return <div>加载中...</div>
  if (error) return <div>错误: {error}</div>
  return <ul>{posts.map((p) => <li key={p.id}>{p.title}</li>)}</ul>
}
```

### 2.3 SWR / React Query（社区方案）

```tsx
'use client'
import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then((r) => r.json())

export default function BlogPage() {
  const { data, error, isLoading } = useSWR('https://api.example.com/blog', fetcher)
  if (isLoading) return <div>加载中...</div>
  if (error) return <div>错误: {error.message}</div>
  return (
    <ul>
      {data.map((post: { id: string; title: string }) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

---

## 三、Next.js 16 缓存行为

### 3.1 重大变化：默认不缓存 fetch

Next.js 16 中，`fetch` 请求**默认不缓存**，会在请求完成前阻塞页面渲染。

要缓存结果，使用 `use cache` 指令；要流式传输，使用 `<Suspense>`。

### 3.2 `use cache` 指令（新）

启用 Cache Components 后（`next.config.ts` 中设置 `cacheComponents: true`），使用 `use cache` 指令缓存数据或 UI：

**数据级缓存：**
```tsx
import { cacheLife } from 'next/cache'

export async function getUsers() {
  'use cache'
  cacheLife('hours')
  return db.query('SELECT * FROM users')
}
```

**UI 级缓存：**
```tsx
import { cacheLife } from 'next/cache'

export default async function Page() {
  'use cache'
  cacheLife('hours')
  const users = await db.query('SELECT * FROM users')
  return <ul>{users.map((u) => <li key={u.id}>{u.name}</li>)}</ul>
}
```

### 3.3 `cacheLife` 预设

| 预设 | stale | revalidate | expire |
|------|-------|------------|--------|
| `seconds` | 0 | 1s | 60s |
| `minutes` | 5m | 1m | 1h |
| `hours` | 5m | 1h | 1d |
| `days` | 5m | 1d | 1w |
| `weeks` | 5m | 1w | 30d |
| `max` | 5m | 30d | ~无限 |

自定义配置：
```tsx
'use cache'
cacheLife({
  stale: 3600,      // 1 小时后过期
  revalidate: 7200, // 2 小时后重新验证
  expire: 86400,    // 1 天后过期
})
```

### 3.4 旧模型对比（`cache: 'no-store'` vs `cache: 'force-cache'`）

> ⚠️ 以下是旧模型，在未启用 Cache Components 时使用：

| 选项 | 行为 |
|------|------|
| `cache: 'force-cache'` | 强制缓存，优先从缓存读取 |
| `cache: 'no-store'` | 不缓存，每次请求都重新获取 |

```tsx
// 旧模型（仍可用，但推荐迁移到 use cache）
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store'        // 每次请求都获取最新数据
})

const data = await fetch('https://api.example.com/data', {
  cache: 'force-cache'     // 优先使用缓存
})
```

---

## 四、重新验证策略

### 4.1 基于时间的重新验证

使用 `cacheLife` 控制缓存有效期：

```tsx
export async function getProducts() {
  'use cache'
  cacheLife('hours')  // 每小时重新验证
  return db.query('SELECT * FROM products')
}
```

### 4.2 按需重新验证

**`cacheTag` + `revalidateTag`（Stale-While-Revalidate）：**

```tsx
// 标记缓存
export async function getProducts() {
  'use cache'
  cacheTag('products')
  return db.query('SELECT * FROM products')
}

// 在 Server Action 或 Route Handler 中失效
import { revalidateTag } from 'next/cache'

export async function updateUser(id: string) {
  // 修改数据后...
  revalidateTag('products', 'max')  // 后台刷新，用户先看到旧内容
}
```

**`updateTag`（立即失效 — Read-Your-Own-Writes）：**

```tsx
import { updateTag } from 'next/cache'

export async function createPost(formData: FormData) {
  const post = await db.post.create({ data: { title: formData.get('title') } })
  updateTag('posts')  // 用户立即看到自己的更改
}
```

| | `updateTag` | `revalidateTag` |
|---|---|---|
| **使用位置** | 仅 Server Actions | Server Actions 和 Route Handlers |
| **行为** | 立即失效缓存 | Stale-while-revalidate |
| **场景** | 用户看到自己的更改 | 后台刷新，轻微延迟可接受 |

**`revalidatePath`（路径级失效）：**

```tsx
import { revalidatePath } from 'next/cache'

export async function updateUser(id: string) {
  revalidatePath('/profile')  // 失效整个路由的缓存
}
```

> 💡 推荐使用基于标签的重新验证（`revalidateTag`/`updateTag`），比基于路径的更精确。

---

## 五、Streaming 与 Suspense

### 5.1 `loading.js` 文件

在页面目录下创建 `loading.js`，自动将整个页面包裹在 `<Suspense>` 中：

```
app/blog/
├── loading.tsx    // 加载状态
└── page.tsx       // 页面内容
```

```tsx
// app/blog/loading.tsx
export default function Loading() {
  return <div>加载中...</div>
}
```

### 5.2 `<Suspense>` 细粒度控制

```tsx
import { Suspense } from 'react'

export default function BlogPage() {
  return (
    <div>
      <header>
        <h1>欢迎来到博客</h1>
      </header>
      <main>
        <Suspense fallback={<div>加载文章列表...</div>}>
          <BlogList />
        </Suspense>
      </main>
    </div>
  )
}

async function BlogList() {
  const res = await fetch('https://api.example.com/posts')
  const posts = await res.json()
  return (
    <ul>
      {posts.map((post: { id: string; title: string }) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 5.3 Partial Prerendering (PPR)

Cache Components 启用后的默认行为：
- **静态内容** → 编译时预渲染为 HTML shell
- **`use cache` 内容** → 预渲染后缓存
- **`<Suspense>` 内容** → 请求时流式传输

未被 `<Suspense>` 或 `use cache` 包裹的非确定性操作会报错：
> `Uncached data was accessed outside of <Suspense>`

---

## 六、Route Segment Config

### 6.1 `dynamic`

```tsx
export const dynamic = 'force-static'  // 强制静态
export const dynamic = 'force-dynamic' // 强制动态
export const dynamic = 'auto'          // 自动判断（默认）
```

### 6.2 `revalidate`

```tsx
export const revalidate = 3600  // 每小时重新验证（秒）
export const revalidate = false // 永不重新验证
export const revalidate = 0     // 不缓存
```

### 6.3 `fetchCache`

```tsx
export const fetchCache = 'default-cache'   // 默认缓存行为
export const fetchCache = 'only-cache'      // 只允许缓存请求
export const fetchCache = 'force-cache'     // 强制所有 fetch 缓存
export const fetchCache = 'force-no-store'  // 强制所有 fetch 不缓存
export const fetchCache = 'default-no-store' // 默认不缓存
export const fetchCache = 'only-no-store'   // 只允许不缓存
```

> 💡 在 Next.js 16 Cache Components 模型中，这些配置逐渐被 `use cache` + `cacheLife` 取代。

---

## 七、最佳实践与常见陷阱

### ✅ 最佳实践

1. **优先服务端获取**：敏感数据、需要 SEO 的内容在 Server Component 中获取
2. **使用 `<Suspense>` 包裹异步操作**：避免阻塞整个页面渲染
3. **并行获取数据**：使用 `Promise.all` 而非串行 `await`
4. **合理使用 `cacheLife`**：根据数据更新频率选择合适的预设
5. **优先标签级重新验证**：`revalidateTag` 比 `revalidatePath` 更精确
6. **为加载状态设计有意义的 UI**：使用骨架屏而非简单的 "Loading..."
7. **使用 `React.cache` 遵循请求去重**：同一请求中多次调用只执行一次

### ❌ 常见陷阱

1. **在 Server Component 中忘记 `<Suspense>`**：未缓存的数据获取会阻塞渲染
2. **在 `use cache` 中使用运行时 API**：`cookies()`、`headers()` 不能在缓存范围内直接使用
3. **在 Server Component 中使用 `'use client'`**：会导致不必要的客户端 bundle
4. **串行等待多个无依赖请求**：应该用 `Promise.all` 并行
5. **忘记 `params` 是 Promise**：Next.js 16 中 `params` 需要 `await`
6. **在 `use cache` 中使用非确定性操作**：`Math.random()`、`Date.now()` 需要用 `connection()` 延迟到请求时

### 📋 选择指南

| 场景 | 推荐方案 |
|------|---------|
| 静态内容 | `use cache` + `cacheLife` |
| 偶尔更新的内容 | `use cache` + `cacheTag` + `revalidateTag` |
| 用户特定数据 | `<Suspense>` + 运行时 API |
| 实时数据 | `<Suspense>` + `connection()` |
| 客户端交互数据 | `use()` API 或 SWR |

---

## 八、完整示例代码

见项目 `~/shadcn-learning/src/app/fetch-demo/page.tsx` 和 `~/shadcn-learning/src/components/client-fetch-demo.tsx`。
