---
tags:
  - zustand
  - advanced
  - patterns
  - middleware
  - day11
created: 2026-05-30
day: 11
---

# Day 11: Zustand 进阶模式

## 1. Slices Pattern 详解

### 什么是 Slices Pattern？

当 Zustand store 变得庞大时，可以将其拆分为多个独立的 **slice**（切片）。每个 slice 管理自己的状态和动作，最终合并成一个完整的 store。

### 核心思路

```
store = counterSlice + todoSlice + historySlice
```

### 实现方式

```typescript
// 每个 slice 是一个函数，接收 set 和 get，返回部分状态+动作
function createCounterSlice(set) {
  return {
    count: 0,
    increment: () => set((state) => { state.count += 1 }),
    decrement: () => set((state) => { state.count -= 1 }),
  }
}

function createTodoSlice(set) {
  return {
    todos: [],
    addTodo: (text) => set((state) => { state.todos.push({ text, done: false }) }),
  }
}

// 合并
const useStore = create()((set, get) => ({
  ...createCounterSlice(set),
  ...createTodoSlice(set),
}))
```

### 类型安全的 Slice

使用 `satisfies Partial<Store>` 确保类型安全：

```typescript
function createCounterSlice(set: (fn: (state: Store) => void) => void) {
  return {
    count: 0,
    increment: () => set((state) => { state.count += 1 }),
  } satisfies Partial<Store>
}
```

### 优势

- **关注点分离**：每个 slice 独立管理自己的逻辑
- **可复用**：slice 可以在不同 store 间复用
- **可测试**：每个 slice 可以单独测试
- **团队协作**：不同成员可以并行开发不同 slice

---

## 2. Immer Middleware

### 为什么需要 Immer？

Redux/Zustand 要求不可变更新，手动编写嵌套更新很繁琐：

```typescript
// ❌ 手动不可变更新（痛苦）
set((state) => ({
  ...state,
  user: {
    ...state.user,
    address: {
      ...state.user.address,
      city: "Shanghai",
    },
  },
}))

// ✅ 使用 Immer（直接修改）
set((state) => {
  state.user.address.city = "Shanghai"
})
```

### 使用方式

```typescript
import { immer } from 'zustand/middleware/immer'

const useStore = create<Store>()(
  immer((set) => ({
    todos: [],
    addTodo: (text) => set((state) => {
      // 直接 push，Immer 自动处理不可变性
      state.todos.push({ id: nanoid(), text, done: false })
    }),
    toggleTodo: (id) => set((state) => {
      const todo = state.todos.find(t => t.id === id)
      if (todo) todo.done = !todo.done  // 直接修改！
    }),
  }))
)
```

### Immer 的工作原理

1. Immer 创建一个 **draft**（草稿）代理
2. 你在 draft 上做所有修改
3. Immer 自动计算最小化的不可变更新
4. 返回新的不可变状态

### 何时使用 Immer？

| 场景 | 推荐 |
|------|------|
| 简单的顶层更新 | 不需要 Immer |
| 嵌套对象更新 | ✅ 使用 Immer |
| 数组操作（push/splice） | ✅ 使用 Immer |
| 性能敏感的热路径 | 避免 Immer（有代理开销） |

---

## 3. Combine Middleware（组合多个中间件）

### 中间件栈

Zustand 支持嵌套使用多个中间件：

```typescript
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { devtools, subscribeWithSelector, persist } from 'zustand/middleware'

const useStore = create<Store>()(
  devtools(           // 最外层：DevTools 集成
    subscribeWithSelector(  // 订阅支持
      persist(        // 持久化
        immer(        // 最内层：Immer 不可变更新
          (set, get) => ({ ... })
        ),
        { name: 'my-store' }
      )
    ),
    { name: 'MyStore' }
  )
)
```

### 常用中间件组合

| 组合 | 用途 |
|------|------|
| `devtools(immer(fn))` | 开发调试 + 不可变更新 |
| `persist(immer(fn))` | 持久化 + 不可变更新 |
| `devtools(subscribeWithSelector(immer(fn)))` | 全功能（本项目使用） |
| `devtools(persist(immer(fn)))` | 调试 + 持久化 + 不可变更新 |

### 中间件执行顺序

```
action → devtools → subscribeWithSelector → immer → setState
```

---

## 4. Subscribe Pattern（组件外订阅状态）

### 基本订阅

```typescript
// 在组件外订阅整个 store
const unsub = useStore.subscribe((state) => {
  console.log('状态变化:', state)
})

// 取消订阅
unsub()
```

### 带 Selector 的订阅（subscribeWithSelector）

```typescript
// 只在 count 变化时触发
const unsub = useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log(`Count: ${prevCount} → ${count}`)
  }
)
```

### 典型应用场景

1. **日志记录**：状态变化时自动记录
2. **同步外部状态**：状态变化时更新 URL、localStorage
3. **副作用**：状态变化时触发 API 调用
4. **跨 store 通信**：一个 store 的变化触发另一个 store 的更新

```typescript
// 示例：自动同步到 localStorage
useStore.subscribe(
  (state) => state.todos,
  (todos) => {
    localStorage.setItem('todos', JSON.stringify(todos))
  }
)
```

---

## 5. Temporal Middleware（撤销/重做）

### 基本原理

撤销/重做需要维护一个历史栈：

```
past: [s0, s1, s2]  ←  可以撤销的状态
present: s3          ←  当前状态
future: [s4, s5]     ←  可以重做的状态
```

### 手动实现

```typescript
interface HistoryState {
  past: number[]
  canUndo: boolean
  canRedo: boolean
}

const createHistorySlice = (set, get) => ({
  past: [0],
  canUndo: false,
  canRedo: false,
  undo: () => {
    const { past } = get()
    if (past.length > 1) {
      set((state) => {
        state.past.pop()
        state.count = state.past[state.past.length - 1]
        state.canUndo = state.past.length > 1
        state.canRedo = true
      })
    }
  },
  redo: () => {
    set((state) => {
      state.count += 1
      state.past.push(state.count)
      state.canRedo = false
      state.canUndo = true
    })
  },
})
```

### 使用第三方库

对于生产环境，推荐使用 `zundo` 库：

```typescript
import { temporal } from 'zundo'

const useStore = create<Store>()(
  temporal(
    immer((set) => ({ ... })),
    { limit: 100 }  // 最多保存 100 步历史
  )
)

// 使用
const { undo, redo, pastStates, futureStates } = useStore.temporal.getState()
```

---

## 6. Testing Zustand Stores

### 单元测试

```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { useStore } from './store'

describe('Zustand Store', () => {
  beforeEach(() => {
    // 每次测试前重置 store
    useStore.setState({
      count: 0,
      todos: [],
      past: [0],
      canUndo: false,
      canRedo: false,
    })
  })

  it('increment 增加 count', () => {
    useStore.getState().increment()
    expect(useStore.getState().count).toBe(1)
  })

  it('addTodo 添加 todo', () => {
    useStore.getState().addTodo('测试任务')
    expect(useStore.getState().todos).toHaveLength(1)
    expect(useStore.getState().todos[0].text).toBe('测试任务')
  })

  it('toggleTodo 切换完成状态', () => {
    useStore.getState().addTodo('测试')
    const todoId = useStore.getState().todos[0].id
    useStore.getState().toggleTodo(todoId)
    expect(useStore.getState().todos[0].done).toBe(true)
  })
})
```

### 测试技巧

1. **直接调用 `getState()`**：不需要渲染组件
2. **使用 `setState()` 重置**：确保测试隔离
3. **测试中间件**：验证 Immer 的不可变更新是否正确

```typescript
// 测试不可变性
it('toggleTodo 不修改原始对象引用', () => {
  useStore.getState().addTodo('测试')
  const todoBefore = useStore.getState().todos[0]
  useStore.getState().toggleTodo(todoBefore.id)
  const todoAfter = useStore.getState().todos[0]
  expect(todoBefore).not.toBe(todoAfter)  // 新对象引用
  expect(todoAfter.done).toBe(true)
})
```

---

## 7. Performance Optimization

### Selector 模式

```typescript
// ❌ 不好：订阅整个 store，任何变化都重渲染
const store = useStore()

// ✅ 好：只订阅需要的字段
const count = useStore((state) => state.count)

// ✅ 好：使用 shallow 比较返回对象
import { useShallow } from 'zustand/react/shallow'
const { count, filter } = useStore(
  useShallow((state) => ({ count: state.count, filter: state.filter }))
)
```

### 派生状态

```typescript
// ✅ 在 selector 中计算派生值，避免额外的 state
const activeTodoCount = useStore(
  (state) => state.todos.filter(t => !t.done).length
)
```

### 避免不必要的依赖

```typescript
// ❌ 不好：函数在每次渲染时创建新引用
const Component = () => {
  const todos = useStore((state) =>
    state.todos.filter(t => t.text.includes(search))
  )
}

// ✅ 好：将 search 提取出来，在组件外比较
const Component = () => {
  const [search, setSearch] = useState('')
  const todos = useStore((state) => state.todos)
  const filtered = todos.filter(t => t.text.includes(search))
}
```

### Zustand vs Context API 性能

| 特性 | Zustand | Context API |
|------|---------|-------------|
| 粒度控制 | ✅ selector 精确订阅 | ❌ 整个 context 重渲染 |
| 组件外访问 | ✅ 直接调用 | ❌ 需要 Provider |
| 中间件 | ✅ 丰富的中间件 | ❌ 需要自己实现 |
| DevTools | ✅ Redux DevTools | ❌ 无 |
| 包大小 | ~1KB | 0KB（内置） |

---

## 8. 与 Server Actions 配合使用

### 基本模式

```typescript
// store.ts - 客户端状态管理
const useStore = create((set) => ({
  items: [],
  loading: false,
  fetchItems: async () => {
    set({ loading: true })
    const items = await getItems()  // Server Action
    set({ items, loading: false })
  },
  addItem: async (text) => {
    const newItem = await createItem(text)  // Server Action
    set((state) => ({ items: [...state.items, newItem] }))
  },
}))
```

### Optimistic Update（乐观更新）

```typescript
const useStore = create((set, get) => ({
  todos: [],
  toggleTodo: async (id) => {
    // 1. 先乐观更新 UI
    const prev = get().todos
    set((state) => ({
      todos: state.todos.map(t =>
        t.id === id ? { ...t, done: !t.done } : t
      )
    }))

    try {
      // 2. 再发送 Server Action
      await updateTodoOnServer(id)
    } catch {
      // 3. 失败则回滚
      set({ todos: prev })
    }
  },
}))
```

### 与 React Query/SWR 的分工

| 职责 | 工具 |
|------|------|
| 服务端数据获取/缓存 | React Query / SWR |
| 客户端 UI 状态 | Zustand |
| 表单状态 | React Hook Form |
| URL 状态 | Next.js router |

---

## 关键要点

1. **Slices Pattern** 让大型 store 保持整洁和可维护
2. **Immer** 让嵌套更新变得简单，但有轻微性能开销
3. **中间件组合** 提供强大的功能扩展能力
4. **Subscribe** 模式支持组件外的副作用和状态同步
5. **Selector 模式** 是性能优化的关键
6. **乐观更新** 结合 Server Actions 提供最佳用户体验
