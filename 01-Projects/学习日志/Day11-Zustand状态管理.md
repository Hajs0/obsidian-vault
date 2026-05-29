---
tags:
  - zustand
  - state-management
  - react
  - nextjs
  - day11
created: 2026-05-30
day: 11
---

# Day 11 - Zustand 状态管理

## 什么是 Zustand？

Zustand（德语"状态"）是一个轻量级的 React 状态管理库，由 Poimandres 团队（Jotai、React Spring 等的作者）开发。

**核心特点：**
- 体积仅约 **1KB**（gzip），极其轻量
- 基于 **Hooks** API，简洁直观
- **无需 Provider**，不像 Redux/Context 需要包裹组件树
- 支持 **TypeScript**，类型推导优秀
- 支持 **中间件**（persist、devtools、immer 等）

---

## 为什么选择 Zustand 而不是 Redux / Context？

| 痛点 | Redux | Context | Zustand |
|------|-------|---------|---------|
| 样板代码 | 多（action/reducer/store） | 少但需 Provider | **极少** |
| 需要 Provider | ✅ | ✅ | ❌ 不需要 |
| 重渲染优化 | 需要手动 selector | 任何变化全重渲染 | **自动 selector 优化** |
| 异步处理 | 需要 thunk/saga | 不支持 | **直接 async/await** |
| 学习曲线 | 高 | 低 | **低** |
| 中间件生态 | 丰富 | 无 | **丰富（persist/devtools/immer）** |
| 体积 | ~11KB | React 内置 | **~1KB** |

**核心优势：**
1. **无 Provider**：Store 是独立的，不需要包裹 `<Provider>`
2. **无 Boilerplate**：一个 `create` 调用搞定一切
3. **Selector 优化**：只订阅需要的状态，精确重渲染
4. **多 Store 支持**：可以自由拆分多个独立 Store

---

## 核心概念

### 1. `create` - 创建 Store

```typescript
import { create } from 'zustand'

interface BearState {
  bears: number
  increase: () => void
}

const useBearStore = create<BearState>((set) => ({
  bears: 0,
  increase: () => set((state) => ({ bears: state.bears + 1 })),
}))
```

### 2. Store 的三个核心 API

- **`getState()`** - 获取当前状态（不触发重渲染）
- **`setState()`** - 直接设置状态（不触发重渲染）
- **`subscribe()`** - 订阅状态变化（React 外部使用）

### 3. Selector - 选择性订阅

```typescript
// ✅ 好：只在 bears 变化时重渲染
const bears = useBearStore((state) => state.bears)

// ❌ 差：任何状态变化都重渲染
const store = useBearStore()

// ✅ 使用 shallow 比较对象
import { shallow } from 'zustand/shallow'
const { bears, fish } = useBearStore(
  (state) => ({ bears: state.bears, fish: state.fish }),
  shallow
)
```

---

## 基本用法

### 创建 Store

```typescript
// store/counterStore.ts
import { create } from 'zustand'

interface CounterStore {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

export const useCounterStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
  decrement: () => set((s) => ({ count: s.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

### 在组件中使用

```tsx
'use client'

function Counter() {
  const count = useCounterStore((s) => s.count)
  const increment = useCounterStore((s) => s.increment)

  return (
    <div>
      <p>{count}</p>
      <button onClick={increment}>+1</button>
    </div>
  )
}
```

---

## 高级模式

### 1. 中间件（Middleware）

Zustand 的中间件通过包装 `create` 的 `setState`/`getState`/`store` 来扩展功能。

#### persist - 持久化存储

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({
      theme: 'dark',
      setTheme: (theme: string) => set({ theme }),
    }),
    {
      name: 'app-storage', // localStorage 的 key
      // partialize: (state) => ({ theme: state.theme }), // 只持久化部分状态
    }
  )
)
```

#### devtools - Redux DevTools 集成

```typescript
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

const useStore = create(
  devtools(
    (set) => ({
      count: 0,
      increment: () => set((s) => ({ count: s.count + 1 }), false, 'increment'),
    }),
    { name: 'CounterStore' } // DevTools 中显示的名称
  )
)
```

#### immer - 简化嵌套更新

```typescript
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

const useStore = create(
  immer((set) => ({
    user: { name: 'Alice', address: { city: 'Beijing' } },
    updateCity: (city: string) =>
      set((state) => {
        state.user.address.city = city // 可以直接修改！
      }),
  }))
)
```

#### 组合多个中间件

```typescript
import { create } from 'zustand'
import { persist, devtools } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'

const useStore = create(
  devtools(
    persist(
      immer((set) => ({
        // ...state and actions
      })),
      { name: 'store' }
    )
  )
)
```

### 2. Slices 模式 - 拆分大型 Store

当 Store 变大时，可以按功能模块拆分为 Slices：

```typescript
// slices/todoSlice.ts
import { StateCreator } from 'zustand'

export interface TodoSlice {
  todos: string[]
  addTodo: (todo: string) => void
}

export const createTodoSlice: StateCreator<
  TodoSlice & UserSlice,  // 完整类型
  [],                      // 中间件类型
  [],                      // 自定义 API 类型
  TodoSlice                // 当前 slice 类型
> = (set) => ({
  todos: [],
  addTodo: (todo) => set((s) => ({ todos: [...s.todos, todo] })),
})

// slices/userSlice.ts
export interface UserSlice {
  username: string
  setUsername: (name: string) => void
}

export const createUserSlice: StateCreator<UserSlice & TodoSlice, [], [], UserSlice> = (set) => ({
  username: '',
  setUsername: (name) => set({ username: name }),
})

// store/index.ts
import { create } from 'zustand'
import { createTodoSlice, TodoSlice } from './slices/todoSlice'
import { createUserSlice, UserSlice } from './slices/userSlice'

export const useStore = create<TodoSlice & UserSlice>()((...a) => ({
  ...createTodoSlice(...a),
  ...createUserSlice(...a),
}))
```

### 3. 异步 Actions

```typescript
const useUserStore = create((set) => ({
  users: [],
  loading: false,
  error: null,
  
  fetchUsers: async () => {
    set({ loading: true, error: null })
    try {
      const res = await fetch('/api/users')
      const users = await res.json()
      set({ users, loading: false })
    } catch (error) {
      set({ error: (error as Error).message, loading: false })
    }
  },
}))
```

### 4. 在 React 外部订阅

```typescript
const unsub = useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log(`count changed: ${prevCount} -> ${count}`)
  },
  { equalityFn: (a, b) => a === b } // 可选的比较函数
)

// 取消订阅
unsub()
```

### 5. Transient Updates - 不触发重渲染

```typescript
// 读取状态不触发重渲染
const currentCount = useStore.getState().count

// 直接设置状态不触发重渲染
useStore.setState({ count: 100 })

// 适用于频繁更新的场景（如动画、鼠标位置）
document.addEventListener('mousemove', (e) => {
  useStore.setState({ mouseX: e.clientX, mouseY: e.clientY })
})
```

---

## Zustand vs Jotai vs Redux Toolkit 对比

| 特性 | Zustand | Jotai | Redux Toolkit |
|------|---------|-------|---------------|
| **模型** | 单一 Store（可多 Store） | 原子化（Atom） | 单一 Store |
| **体积** | ~1KB | ~2KB | ~11KB |
| **学习曲线** | 低 | 低 | 中-高 |
| **样板代码** | 极少 | 极少 | 中等 |
| **需要 Provider** | ❌ | 需要 Provider（可选） | ✅ 需要 |
| **DevTools** | ✅ 支持 | ✅ 支持 | ✅ 完善 |
| **持久化** | ✅ 中间件 | ✅ 工具 | ✅ 需配置 |
| **SSR 支持** | 需要额外处理 | ✅ 原生支持 | ✅ 支持 |
| **适用场景** | 中大型状态管理 | 细粒度派生状态 | 大型复杂应用 |
| **React 19 兼容** | ✅ | ✅ | ✅ |
| **选择器优化** | 手动 selector | 自动依赖追踪 | 手动 selector |
| **TypeScript** | ✅ 优秀 | ✅ 优秀 | ✅ 优秀 |

**选择建议：**
- **Zustand**：需要简单、轻量的状态管理，不想写样板代码
- **Jotai**：状态之间有大量派生关系，喜欢原子化思维
- **Redux Toolkit**：大型团队协作，需要完善的 DevTools 和中间件生态

---

## Zustand 在 Next.js 16 中的使用

### SSR 注意事项

Next.js App Router 中，服务端组件和客户端组件的边界很重要：

```typescript
// ✅ 正确：Store 定义在单独文件中，组件标记 'use client'
// store/useStore.ts
'use client'
import { create } from 'zustand'
export const useStore = create((set) => ({ count: 0 }))

// components/Counter.tsx
'use client'
import { useStore } from '@/store/useStore'
export function Counter() {
  const count = useStore((s) => s.count)
  return <p>{count}</p>
}
```

### 客户端专用 Store

由于 Zustand 依赖 `useState`/`useEffect`，Store 必须在客户端使用：

```typescript
// 避免 SSR 水合错误的方式：

// 方法1：组件级别 'use client'
'use client'
import { useStore } from '@/store/useStore'

// 方法2：使用 useEffect 延迟读取
'use client'
import { useEffect, useState } from 'react'
import { useStore } from '@/store/useStore'

function HydratedCounter() {
  const [mounted, setMounted] = useState(false)
  const count = useStore((s) => s.count)
  
  useEffect(() => setMounted(true), [])
  
  if (!mounted) return <p>Loading...</p>
  return <p>{count}</p>
}

// 方法3：使用 Zustand 的 persist + skipHydration
import { persist } from 'zustand/middleware'

const useStore = create(
  persist(
    (set) => ({ count: 0 }),
    {
      name: 'store',
      skipHydration: true, // 跳过 SSR 水合
    }
  )
)

// 在客户端手动水合
useStore.persist.rehydrate()
```

### 服务端数据到客户端 Store

```typescript
// Server Component
async function Page() {
  const data = await fetchDataFromDB()
  return <ClientComponent initialData={data} />
}

// Client Component
'use client'
import { useEffect } from 'react'
import { useStore } from '@/store/useStore'

function ClientComponent({ initialData }) {
  useEffect(() => {
    useStore.setState({ data: initialData })
  }, [initialData])
  
  return <div>{/* ... */}</div>
}
```

---

## 最佳实践

### ✅ 推荐

1. **使用 Selector**：始终使用 selector 避免不必要的重渲染
   ```typescript
   const count = useStore((s) => s.count) // ✅
   ```

2. **拆分 Store**：大型应用按功能模块拆分多个 Store
   ```typescript
   const useAuthStore = create(...)
   const useCartStore = create(...)
   ```

3. **使用 shallow 比较**：选择多个值时使用 shallow
   ```typescript
   import { shallow } from 'zustand/shallow'
   const { a, b } = useStore((s) => ({ a: s.a, b: s.b }), shallow)
   ```

4. **Action 和 State 分离**：把 action 和 state 放在一起（Zustand 推荐方式）

5. **使用 TypeScript**：为 Store 提供完整的类型定义

### ❌ 避免

1. **不要解构整个 Store**
   ```typescript
   const { count, name, todos } = useStore() // ❌ 任何变化都重渲染
   ```

2. **不要在渲染中调用 setState**
   ```typescript
   function Bad() {
     const store = useStore()
     store.setState({ x: 1 }) // ❌ 会导致无限循环
     return <div>{store.x}</div>
   }
   ```

3. **不要忘记 persist 的序列化问题**
   ```typescript
   // 函数、Symbol 等不能被序列化到 localStorage
   const useStore = create(persist(
     (set) => ({
       data: { fn: () => {} }, // ❌ 函数不会被持久化
     }),
     { name: 'store' }
   ))
   ```

4. **不要混用 React Context 和 Zustand**
   ```typescript
   // ❌ 不需要 Provider
   <StoreProvider>
     <App />
   </StoreProvider>
   ```

---

## 常见问题

### Q: Zustand 和 React 19 兼容吗？
A: 完全兼容。Zustand v5 已全面支持 React 19。

### Q: 如何在 Next.js 中避免水合错误？
A: 确保 Store 只在客户端组件中使用，或使用 `skipHydration` + 手动 `rehydrate()`。

### Q: 什么时候用多个 Store 而不是一个大 Store？
A: 当状态之间没有关联时，拆分为多个 Store 更清晰。比如 `useAuthStore`、`useCartStore`、`useThemeStore`。

### Q: persist 中间件支持哪些存储？
A: 默认 `localStorage`，可以自定义为 `sessionStorage`、`AsyncStorage`（React Native）或任何实现 `StateStorage` 接口的对象。

---

## 今日练习

- [x] 创建 Todo List Store（含 persist + devtools）
- [x] 实现完整 CRUD 操作
- [x] 实现过滤功能（全部/进行中/已完成）
- [x] 集成 Shadcn/ui 组件

## 参考资源

- [Zustand 官方文档](https://zustand-demo.pmnd.rs/)
- [GitHub - pmndrs/zustand](https://github.com/pmndrs/zustand)
- [Zustand Best Practices](https://docs.pmnd.rs/zustand/guides/practice)
