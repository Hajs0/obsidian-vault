# Day 8 - 状态管理方案

## 学习目标
- 掌握 Zustand 核心概念和使用
- 理解 Jotai 原子化状态
- 学习 React Query/SWR 数据获取
- 对比各状态管理方案
- 了解最佳实践

---

## 一、Zustand

### 1.1 核心概念

Zustand 是一个轻量级状态管理库，特点是：
- 极简 API
- 无需 Provider
- 自动优化渲染
- 支持中间件

### 1.2 基本使用

```typescript
// store/counterStore.ts
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

const useCounterStore = create<CounterState>()(
  devtools(
    persist(
      (set) => ({
        count: 0,
        increment: () => set((state) => ({ count: state.count + 1 })),
        decrement: () => set((state) => ({ count: state.count - 1 })),
        reset: () => set({ count: 0 }),
      }),
      { name: 'counter-storage' }
    )
  )
)

export default useCounterStore
```

### 1.3 在组件中使用

```typescript
// components/Counter.tsx
import useCounterStore from '../store/counterStore'

function Counter() {
  // 选择性订阅 - 只在 count 变化时重渲染
  const count = useCounterStore((state) => state.count)
  const increment = useCounterStore((state) => state.increment)
  const decrement = useCounterStore((state) => state.decrement)

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  )
}
```

### 1.4 异步操作

```typescript
interface UserState {
  user: User | null
  loading: boolean
  error: string | null
  fetchUser: (id: string) => Promise<void>
}

const useUserStore = create<UserState>((set) => ({
  user: null,
  loading: false,
  error: null,
  fetchUser: async (id) => {
    set({ loading: true, error: null })
    try {
      const user = await api.getUser(id)
      set({ user, loading: false })
    } catch (error) {
      set({ error: error.message, loading: false })
    }
  },
}))
```

### 1.5 中间件

```typescript
import { create } from 'zustand'
import { devtools, persist, subscribeWithSelector } from 'zustand/middleware'

const useStore = create(
  devtools(
    persist(
      subscribeWithSelector((set) => ({
        // state and actions
      })),
      { name: 'store-name' }
    )
  )
)

// subscribeWithSelector 允许订阅特定状态变化
useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log('Count changed:', prevCount, '->', count)
  }
)
```

---

## 二、Jotai

### 2.1 核心概念

Jotai 采用原子化（atomic）状态管理：
- **Atom**: 最小状态单元
- **Derived Atom**: 派生状态
- **Async Atom**: 异步状态
- 无 Provider 架构
- 自动优化渲染

### 2.2 基本使用

```typescript
// atoms/counterAtoms.ts
import { atom } from 'jotai'

// 基础 atom
export const countAtom = atom(0)

// 派生 atom (只读)
export const doubleCountAtom = atom((get) => get(countAtom) * 2)

// 派生 atom (读写)
export const decrementCountAtom = atom(
  (get) => get(countAtom),
  (get, set) => set(countAtom, get(countAtom) - 1)
)
```

### 2.3 在组件中使用

```typescript
// components/Counter.tsx
import { useAtom, useAtomValue } from 'jotai'
import { countAtom, doubleCountAtom } from '../atoms/counterAtoms'

function Counter() {
  const [count, setCount] = useAtom(countAtom)
  const doubleCount = useAtomValue(doubleCountAtom)

  return (
    <div>
      <p>Count: {count}</p>
      <p>Double: {doubleCount}</p>
      <button onClick={() => setCount((c) => c + 1)}>+</button>
    </div>
  )
}
```

### 2.4 异步 Atom

```typescript
// atoms/userAtoms.ts
import { atom } from 'jotai'

export const userIdAtom = atom<string | null>(null)

export const userAtom = atom(async (get) => {
  const userId = get(userIdAtom)
  if (!userId) return null
  
  const response = await fetch(`/api/users/${userId}`)
  return response.json()
})
```

### 2.5 Atom Family

```typescript
import { atomFamily } from 'jotai/utils'

// 根据参数创建 atom 家族
export const todoAtomFamily = atomFamily((id: string) =>
  atom(async () => {
    const response = await fetch(`/api/todos/${id}`)
    return response.json()
  })
)

// 使用
function TodoItem({ id }: { id: string }) {
  const todo = useAtomValue(todoAtomFamily(id))
  return <div>{todo?.title}</div>
}
```

### 2.6 与 Zustand 的区别

| 特性 | Jotai | Zustand |
|------|-------|---------|
| 状态结构 | 原子化（分散） | 单一 store（集中） |
| 适用场景 | 复杂依赖关系 | 简单全局状态 |
| 代码组织 | 按功能拆分 atom | 按模块拆分 store |
| 学习曲线 | 需理解原子化思维 | 直观简单 |

---

## 三、React Query (TanStack Query)

### 3.1 核心概念

React Query 专注于**服务端状态**管理：
- 自动缓存
- 后台刷新
- 乐观更新
- 分页/无限滚动
- 窗口焦点重新获取

### 3.2 基本配置

```typescript
// providers/QueryProvider.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 分钟
      gcTime: 10 * 60 * 1000,   // 10 分钟 (原 cacheTime)
      retry: 3,
      refetchOnWindowFocus: false,
    },
  },
})

export function QueryProvider({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )
}
```

### 3.3 查询数据

```typescript
import { useQuery } from '@tanstack/react-query'

interface User {
  id: string
  name: string
  email: string
}

// API 函数
const fetchUser = async (id: string): Promise<User> => {
  const response = await fetch(`/api/users/${id}`)
  if (!response.ok) throw new Error('Failed to fetch user')
  return response.json()
}

// 自定义 Hook
function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => fetchUser(id),
    enabled: !!id, // 条件查询
    staleTime: 5 * 60 * 1000,
  })
}

// 组件使用
function UserProfile({ userId }: { userId: string }) {
  const { data: user, isLoading, error } = useUser(userId)

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  )
}
```

### 3.4 修改数据 (Mutations)

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query'

function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (newUser: CreateUserInput) => {
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newUser),
      })
      if (!response.ok) throw new Error('Failed to create user')
      return response.json()
    },
    onSuccess: (data) => {
      // 失效相关查询，触发重新获取
      queryClient.invalidateQueries({ queryKey: ['users'] })
      
      // 或者直接更新缓存
      queryClient.setQueryData(['user', data.id], data)
    },
    onError: (error) => {
      console.error('Create user failed:', error)
    },
  })
}

function CreateUserForm() {
  const createUser = useCreateUser()

  const handleSubmit = (data: CreateUserInput) => {
    createUser.mutate(data)
  }

  return (
    <form onSubmit={handleSubmit}>
      {createUser.isPending && <p>Creating...</p>}
      {createUser.isError && <p>Error: {createUser.error.message}</p>}
      {/* form fields */}
    </form>
  )
}
```

### 3.5 乐观更新

```typescript
function useToggleTodo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (todoId: string) => {
      const response = await fetch(`/api/todos/${todoId}/toggle`, {
        method: 'PATCH',
      })
      return response.json()
    },
    onMutate: async (todoId) => {
      // 取消正在进行的查询
      await queryClient.cancelQueries({ queryKey: ['todos'] })

      // 保存之前的状态
      const previousTodos = queryClient.getQueryData(['todos'])

      // 乐观更新
      queryClient.setQueryData(['todos'], (old: Todo[]) =>
        old.map((todo) =>
          todo.id === todoId
            ? { ...todo, completed: !todo.completed }
            : todo
        )
      )

      return { previousTodos }
    },
    onError: (err, todoId, context) => {
      // 回滚
      queryClient.setQueryData(['todos'], context?.previousTodos)
    },
    onSettled: () => {
      // 无论成功失败都重新获取
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })
}
```

### 3.6 无限滚动

```typescript
import { useInfiniteQuery } from '@tanstack/react-query'

function useInfiniteTodos() {
  return useInfiniteQuery({
    queryKey: ['todos', 'infinite'],
    queryFn: async ({ pageParam = 0 }) => {
      const response = await fetch(`/api/todos?page=${pageParam}&limit=20`)
      return response.json()
    },
    getNextPageParam: (lastPage, pages) => {
      return lastPage.hasMore ? pages.length : undefined
    },
    initialPageParam: 0,
  })
}

function TodoList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteTodos()

  return (
    <div>
      {data?.pages.map((page) =>
        page.todos.map((todo: Todo) => (
          <TodoItem key={todo.id} todo={todo} />
        ))
      )}
      {hasNextPage && (
        <button
          onClick={() => fetchNextPage()}
          disabled={isFetchingNextPage}
        >
          {isFetchingNextPage ? 'Loading...' : 'Load More'}
        </button>
      )}
    </div>
  )
}
```

---

## 四、SWR

### 4.1 核心概念

SWR 是 Vercel 出品的数据获取库，名字来自 stale-while-revalidate 策略：
- 先返回缓存数据
- 后台重新验证
- 更新缓存

### 4.2 基本使用

```typescript
import useSWR from 'swr'

// 全局 fetcher
const fetcher = (url: string) => fetch(url).then((r) => r.json())

function useUser(id: string) {
  return useSWR(`/api/users/${id}`, fetcher, {
    revalidateOnFocus: false,
    dedupingInterval: 60000, // 1 分钟内去重
  })
}

function UserProfile({ userId }: { userId: string }) {
  const { data: user, error, isLoading } = useUser(userId)

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error</div>

  return <div>{user.name}</div>
}
```

### 4.3 SWR vs React Query

| 特性 | SWR | React Query |
|------|-----|-------------|
| 包大小 | ~4KB | ~13KB |
| 服务端渲染 | 支持 | 支持 |
| 离线支持 | 有限 | 完整 |
| 开发者工具 | 有 | 更完善 |
| 社区活跃度 | 高 | 更高 |
| 学习曲线 | 简单 | 中等 |

---

## 五、状态管理对比

### 5.1 按状态类型选择

```
┌─────────────────────────────────────────────────────────┐
│                    状态类型                               │
├─────────────────────────────────────────────────────────┤
│  客户端状态 (UI state)                                   │
│  ├── 简单全局状态 → Zustand / Jotai                      │
│  ├── 复杂表单状态 → React Hook Form / Formik             │
│  └── URL 状态 → React Router / Next Router              │
│                                                         │
│  服务端状态 (Server state)                               │
│  ├── 通用数据获取 → React Query / SWR                    │
│  ├── GraphQL → Apollo Client / urql                     │
│  └── 实时数据 → Socket.io / Supabase Realtime           │
└─────────────────────────────────────────────────────────┘
```

### 5.2 详细对比

| 方案 | 类型 | 包大小 | 适用场景 | 学习曲线 |
|------|------|--------|----------|----------|
| Zustand | 客户端 | ~1KB | 中小项目全局状态 | 低 |
| Jotai | 客户端 | ~2KB | 复杂依赖状态 | 中 |
| Redux Toolkit | 客户端 | ~11KB | 大型项目 | 高 |
| React Query | 服务端 | ~13KB | 数据获取/缓存 | 中 |
| SWR | 服务端 | ~4KB | 轻量数据获取 | 低 |
| Context API | 客户端 | 0KB | 简单共享状态 | 低 |

### 5.3 推荐组合

```
小型项目: Context API + useReducer
中型项目: Zustand + React Query
大型项目: Zustand/Jotai + React Query + 按需引入其他库
```

---

## 六、最佳实践

### 6.1 状态分类原则

```typescript
// ❌ 错误：把服务端状态放客户端 store
const useStore = create((set) => ({
  users: [],
  fetchUsers: async () => {
    const users = await api.getUsers()
    set({ users })
  }
}))

// ✅ 正确：使用 React Query 管理服务端状态
function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.getUsers(),
  })
}
```

### 6.2 Zustand 最佳实践

```typescript
// 1. 拆分 store
// store/useAuthStore.ts
export const useAuthStore = create((set) => ({
  user: null,
  login: async (credentials) => { /* ... */ },
  logout: () => set({ user: null }),
}))

// store/useCartStore.ts
export const useCartStore = create((set, get) => ({
  items: [],
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),
  removeItem: (id) => set((state) => ({
    items: state.items.filter(item => item.id !== id)
  })),
  // 计算属性在 selector 中处理
  get total() {
    return get().items.reduce((sum, item) => sum + item.price, 0)
  }
}))

// 2. 使用 selector 避免不必要的重渲染
function CartCount() {
  const count = useCartStore((state) => state.items.length)
  return <span>{count}</span>
}

// 3. 持久化重要状态
const useSettingsStore = create(
  persist(
    (set) => ({
      theme: 'light',
      language: 'zh',
      setTheme: (theme) => set({ theme }),
    }),
    { name: 'settings' }
  )
)
```

### 6.3 React Query 最佳实践

```typescript
// 1. 使用自定义 Hook 封装查询
function useTodos(filters?: TodoFilters) {
  return useQuery({
    queryKey: ['todos', filters],
    queryFn: () => api.getTodos(filters),
    staleTime: 5 * 60 * 1000,
  })
}

// 2. 预取数据
function TodoList() {
  const queryClient = useQueryClient()

  const prefetchTodo = (id: string) => {
    queryClient.prefetchQuery({
      queryKey: ['todo', id],
      queryFn: () => api.getTodo(id),
      staleTime: 60 * 1000,
    })
  }

  return (
    <div>
      {todos.map((todo) => (
        <div
          key={todo.id}
          onMouseEnter={() => prefetchTodo(todo.id)}
        >
          {todo.title}
        </div>
      ))}
    </div>
  )
}

// 3. 错误边界处理
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ErrorBoundary fallback={<ErrorPage />}>
        <AppRoutes />
      </ErrorBoundary>
    </QueryClientProvider>
  )
}
```

### 6.4 通用建议

1. **保持状态最小化** - 只存储必要数据
2. **派生状态优于存储** - 能计算的就不要存储
3. **状态靠近使用处** - 不要过早提升状态
4. **避免冗余状态** - 单一数据源
5. **合理使用 memo** - 配合状态管理优化性能

---

## 七、实战示例：Todo 应用

```typescript
// 完整示例：结合 Zustand + React Query

// 1. 类型定义
interface Todo {
  id: string
  title: string
  completed: boolean
}

// 2. 服务端状态 - React Query
function useTodos() {
  return useQuery({
    queryKey: ['todos'],
    queryFn: api.getTodos,
  })
}

function useCreateTodo() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: api.createTodo,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })
}

// 3. 客户端状态 - Zustand
interface TodoFilterState {
  filter: 'all' | 'active' | 'completed'
  setFilter: (filter: TodoFilterState['filter']) => void
  searchQuery: string
  setSearchQuery: (query: string) => void
}

const useTodoFilterStore = create<TodoFilterState>((set) => ({
  filter: 'all',
  setFilter: (filter) => set({ filter }),
  searchQuery: '',
  setSearchQuery: (searchQuery) => set({ searchQuery }),
}))

// 4. 组件
function TodoApp() {
  const { data: todos = [] } = useTodos()
  const { filter, searchQuery } = useTodoFilterStore()

  const filteredTodos = todos
    .filter((todo) => {
      if (filter === 'active') return !todo.completed
      if (filter === 'completed') return todo.completed
      return true
    })
    .filter((todo) =>
      todo.title.toLowerCase().includes(searchQuery.toLowerCase())
    )

  return (
    <div>
      <TodoFilters />
      <TodoInput />
      <TodoList todos={filteredTodos} />
    </div>
  )
}
```

---

## 总结

| 场景 | 推荐方案 |
|------|----------|
| 服务端数据 | React Query / SWR |
| 全局客户端状态 | Zustand |
| 复杂原子状态 | Jotai |
| 简单共享状态 | Context API |
| URL 状态 | useSearchParams |
| 表单状态 | React Hook Form |

**核心原则**: 服务端状态用 React Query，客户端状态按复杂度选择 Zustand 或 Jotai。

---

## 学习资源

- [Zustand 官方文档](https://zustand-demo.pmnd.rs/)
- [Jotai 官方文档](https://jotai.org/)
- [TanStack Query 文档](https://tanstack.com/query/latest)
- [SWR 文�](https://swr.vercel.app/)

---

**日期**: Day 8
**主题**: 状态管理方案
**下次复习**: ____
