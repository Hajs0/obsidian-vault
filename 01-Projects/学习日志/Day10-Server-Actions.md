---
title: Day10 - Server Actions 深入学习
tags:
  - nextjs
  - server-actions
  - react
  - rsc
created: 2026-05-30
day: 10
---

# Server Actions 深入学习

## 什么是 Server Actions？

Server Actions 是 Next.js 中用于服务端数据变更（mutation）的机制。本质上，它是一个运行在服务端的异步函数，客户端通过网络请求调用。

**核心概念：**
- Server Function：带有 `'use server'` 指令的异步函数，在服务端执行
- Server Action：用于表单提交和数据变更场景的 Server Function
- 底层使用 `POST` 方法，只有 POST 请求才能触发

**定义方式：**
```ts
// 方式1：文件顶部声明，文件内所有导出都是 Server Function
// app/actions.ts
'use server'
export async function createPost(formData: FormData) { ... }

// 方式2：函数内部声明
async function createPost(formData: FormData) {
  'use server'
  // ...
}
```

## 从表单调用 Server Actions

React 扩展了 `<form>` 元素的 `action` 属性，可以直接传入 Server Action：

```tsx
import { createPost } from '@/app/actions'

export function Form() {
  return (
    <form action={createPost}>
      <input type="text" name="title" />
      <button type="submit">创建</button>
    </form>
  )
}
```

**特点：**
- 表单提交时自动传入 `FormData` 对象
- Server Component 中的表单支持渐进增强——JS 未加载也能提交
- Client Component 中的表单会在 JS 加载前排队，加载后自动提交

## 从客户端组件调用

在 Client Component 中不能直接定义 Server Action，但可以 import 使用：

### useActionState

```tsx
'use client'
import { useActionState } from 'react'
import { createPost } from '@/app/actions'

export function Button() {
  const [state, action, pending] = useActionState(createPost, null)
  return (
    <button formAction={action}>
      {pending ? '提交中...' : '创建'}
    </button>
  )
}
```

`useActionState` 返回：
- `state`：action 返回的最新状态
- `action`：包装后的 action 函数
- `pending`：是否正在执行中

### useTransition

适合在事件处理器中手动控制 pending 状态：

```tsx
'use client'
import { useTransition } from 'react'
import { incrementLike } from './actions'

export default function LikeButton() {
  const [isPending, startTransition] = useTransition()

  return (
    <button onClick={() => {
      startTransition(async () => {
        await incrementLike()
      })
    }}>
      {isPending ? '处理中...' : '点赞'}
    </button>
  )
}
```

## 使用 Zod 进行验证

Server Action 中应该在服务端做数据验证：

```ts
'use server'
import { z } from 'zod'

const schema = z.object({
  title: z.string().min(1, '标题不能为空').max(100),
})

export async function createPost(prevState: any, formData: FormData) {
  const validated = schema.safeParse({
    title: formData.get('title'),
  })

  if (!validated.success) {
    return { errors: validated.error.flatten().fieldErrors }
  }

  // 执行数据变更...
}
```

## 错误处理模式

1. **返回错误对象**（推荐）：配合 `useActionState` 使用，返回错误状态给客户端
2. **抛出错误**：用 `throw new Error()`，会被最近的 error boundary 捕获
3. **try-catch**：在 action 内部捕获异常，返回友好的错误信息

```ts
export async function createPost(prevState: any, formData: FormData) {
  try {
    // 数据验证
    const validated = schema.safeParse({ title: formData.get('title') })
    if (!validated.success) {
      return { errors: validated.error.flatten().fieldErrors, success: false }
    }
    // 数据变更
    await db.insert(...)
    return { success: true, errors: {} }
  } catch (error) {
    return { success: false, errors: { _form: ['服务器错误'] } }
  }
}
```

## 数据重新验证

数据变更后需要刷新缓存，让 UI 显示最新数据：

### revalidatePath

```ts
import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  // 变更数据...
  revalidatePath('/posts')       // 重新验证特定路径
  revalidatePath('/')             // 重新验证首页
}
```

### revalidateTag

```ts
import { revalidateTag } from 'next/cache'

export async function createPost(formData: FormData) {
  // 变更数据...
  revalidateTag('posts')  // 重新验证带有 'posts' tag 的所有请求
}
```

### refresh (Next.js 16 新增)

```ts
import { refresh } from 'next/cache'

export async function updatePost(formData: FormData) {
  // 变更数据...
  refresh()  // 刷新客户端路由，确保 UI 反映最新状态
}
```

> 注意：`refresh()` 不会重新验证带 tag 的数据，需要配合 `revalidateTag` 使用。

### redirect

```ts
import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  // 变更数据...
  revalidatePath('/posts')
  redirect('/posts')  // redirect 会抛出异常，之后的代码不会执行
}
```

> ⚠️ `redirect` 会抛出框架控制流异常，必须在它之前调用 `revalidatePath`。

## Server Actions vs API Routes

| 特性 | Server Actions | API Routes |
|------|---------------|------------|
| 用途 | 服务端数据变更 | 通用 API 端点 |
| 调用方式 | 表单/事件处理器直接调用 | fetch/HTTP 客户端 |
| 返回值 | 直接返回给调用方 | HTTP Response |
| 缓存集成 | 自动配合 revalidate | 需手动处理 |
| 类型安全 | 端到端类型安全 | 需手动维护 |
| 渐进增强 | 支持（表单场景） | 不适用 |
| HTTP 方法 | 仅 POST | 支持所有方法 |

## 最佳实践与常见陷阱

### ✅ 最佳实践
1. **始终在 Server Action 中做身份验证和授权**——它们可以通过 POST 请求直接访问
2. **使用 Zod 等库在服务端验证输入**——不要信任客户端数据
3. **返回结构化的状态对象**——配合 `useActionState` 使用
4. **变更后调用 `revalidatePath` 或 `revalidateTag`**——确保 UI 同步
5. **将 `'use server'` 文件与组件分离**——保持清晰的关注点分离
6. **使用 `useTransition` 提供加载反馈**——提升用户体验

### ❌ 常见陷阱
1. **不要在 Client Component 中定义 Server Action**——必须通过 import 引入
2. **不要忘记 `revalidatePath`**——否则 UI 不会更新
3. **`redirect` 之后的代码不会执行**——要在 redirect 之前完成所有操作
4. **不要传入不可序列化的参数**——Server Action 的参数和返回值必须可序列化
5. **不要忽略错误处理**——未处理的错误会导致 500 错误
6. **Server Actions 不适合并行数据获取**——使用 Server Component 的数据获取或 Route Handler

## 总结

Server Actions 是 Next.js 中处理数据变更的首选方式，它提供了：
- 端到端类型安全
- 自动渐进增强
- 简洁的 API（无需手动创建 API 端点）
- 与缓存系统的深度集成

配合 `useActionState`、`useTransition`、Zod 验证和 `revalidatePath`，可以构建出类型安全、用户体验良好的全栈应用。
