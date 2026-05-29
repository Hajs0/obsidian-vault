---
tags:
  - state-management
  - comparison
  - zustand
  - jotai
  - redux
  - recoil
  - day11
created: 2026-05-30
day: 11
---

# Day 11: 状态管理方案对比

## 综合对比表

| 特性 | Zustand | Jotai | Redux Toolkit | Recoil | MobX | Valtio |
|------|---------|-------|---------------|--------|------|--------|
| **包大小** | ~1KB | ~2KB | ~11KB | ~13KB | ~16KB | ~1.5KB |
| **学习曲线** | ⭐ 低 | ⭐ 低 | ⭐⭐⭐ 高 | ⭐⭐ 中 | ⭐⭐ 中 | ⭐ 低 |
| **TypeScript** | ✅ 优秀 | ✅ 优秀 | ✅ 优秀 | ⚠️ 一般 | ⚠️ 一般 | ✅ 良好 |
| **SSR 支持** | ✅ 原生支持 | ✅ 原生支持 | ✅ 需配置 | ⚠️ 实验性 | ✅ 需配置 | ✅ 需配置 |
| **DevTools** | ✅ Redux DevTools | ✅ React DevTools | ✅ 最佳 | ✅ React DevTools | ✅ 专用工具 | ✅ Redux DevTools |
| **API 风格** | Hook | 原子 | Action/Reducer | 原子 | 响应式 | 代理 |
| **中间件** | ✅ 丰富 | ✅ 有限 | ✅ 最丰富 | ❌ 无 | ✅ 插件 | ✅ 有限 |
| **Bundle 影响** | 极小 | 小 | 较大 | 大 | 较大 | 小 |
| **社区生态** | 🟢 活跃 | 🟢 活跃 | 🟢 最大 | 🟡 维护模式 | 🟢 稳定 | 🟡 较小 |
| **维护状态** | ✅ 活跃 | ✅ 活跃 | ✅ 活跃 | ⚠️ Meta 实验 | ✅ 活跃 | ✅ 活跃 |

---

## 各方案详解

### Zustand

**核心理念**：极简的状态管理，一个 `create` 函数搞定一切

```typescript
import { create } from 'zustand'

const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))
```

**优势**：
- 极小的包大小（~1KB）
- 零样板代码
- 不需要 Provider
- 丰富的中间件生态
- 优秀的 TypeScript 支持

**劣势**：
- 没有内置的 immutable 检查
- 复杂场景需要手动管理依赖

**适用场景**：
- 中小型项目
- 需要极简 API
- 从 Context API 迁移
- 对包大小敏感

---

### Jotai

**核心理念**：原子化状态管理，类似 Recoil 的精神继承者

```typescript
import { atom, useAtom } from 'jotai'

const countAtom = atom(0)
const doubleAtom = atom((get) => get(countAtom) * 2)

function Counter() {
  const [count, setCount] = useAtom(countAtom)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

**优势**：
- 原子化，自动优化渲染
- 派生状态非常优雅
- 底层状态（bottom-up）设计
- 与 React 并发特性兼容

**劣势**：
- 大量原子难以管理
- 调试不如 Redux 方便
- 缺少中间件系统

**适用场景**：
- 复杂的派生状态
- 状态需要细粒度控制
- 喜欢 Recoil 的原子模式
- React 并发渲染

---

### Redux Toolkit

**核心理念**：可预测的状态容器，企业级状态管理

```typescript
import { createSlice, configureStore } from '@reduxjs/toolkit'

const counterSlice = createSlice({
  name: 'counter',
  initialState: { value: 0 },
  reducers: {
    increment: (state) => { state.value += 1 },  // 内置 Immer
  },
})

const store = configureStore({ reducer: { counter: counterSlice.reducer } })
```

**优势**：
- 最成熟的生态
- 最佳 DevTools 支持
- 内置 Immer、Thunk、RTK Query
- 严格的状态管理模式
- 适合大型团队

**劣势**：
- 样板代码较多（虽然 RTK 已大幅简化）
- 学习曲线较陡
- 包大小较大

**适用场景**：
- 大型企业应用
- 需要严格的状态管理规范
- 复杂的异步逻辑
- 大团队协作

---

### Recoil

**核心理念**：Facebook 出品的原子化状态管理

```typescript
import { atom, selector, useRecoilState } from 'recoil'

const countState = atom({ key: 'count', default: 0 })
const doubleState = selector({
  key: 'double',
  get: ({ get }) => get(countState) * 2,
})
```

**优势**：
- 原子化设计
- 派生状态（selector）强大
- React DevTools 支持

**劣势**：
- Meta 已将其标记为实验性
- 包大小较大
- 性能不如预期
- 社区正在迁移到 Jotai

**适用场景**：
- ⚠️ 不推荐新项目使用
- 已有 Recoil 项目的维护

---

### MobX

**核心理念**：响应式状态管理，透明的响应式编程

```typescript
import { makeAutoObservable } from 'mobx'
import { observer } from 'mobx-react-lite'

class CounterStore {
  count = 0
  constructor() { makeAutoObservable(this) }
  increment() { this.count++ }
}

const store = new CounterStore()

const Counter = observer(() => (
  <button onClick={() => store.increment()}>{store.count}</button>
))
```

**优势**：
- 自动追踪依赖，精确更新
- 面向对象风格，适合 OOP 开发者
- 可变状态，无不可变性开销
- 性能优秀

**劣势**：
- 魔法般的响应式可能难以调试
- 学习成本（observable、computed、reaction）
- 与函数式编程风格不一致
- 需要装饰器或 makeAutoObservable

**适用场景**：
- 复杂的领域模型
- OOP 风格的团队
- 需要自动精确更新

---

### Valtio

**核心理念**：基于 Proxy 的可变状态管理

```typescript
import { proxy, useSnapshot } from 'valtio'

const state = proxy({ count: 0, text: 'hello' })

function Counter() {
  const snap = useSnapshot(state)
  return (
    <div>
      <p>{snap.count}</p>
      <button onClick={() => { state.count++ }}>+1</button>
    </div>
  )
}
```

**优势**：
- 最简单的 API
- 直接修改状态
- 极小的包大小
- 自动精确更新

**劣势**：
- 社区较小
- 调试工具有限
- Proxy 兼容性（IE11 不支持）

**适用场景**：
- 小型项目
- 喜欢可变风格
- 快速原型开发

---

## 何时使用哪个？

### 决策流程图

```
你的项目规模？
├── 小型/中型
│   ├── 需要最简 API → Zustand ✅
│   ├── 喜欢原子模式 → Jotai ✅
│   └── 喜欢可变风格 → Valtio ✅
├── 大型企业级
│   ├── 需要严格规范 → Redux Toolkit ✅
│   ├── 需要响应式 → MobX ✅
│   └── 需要原子化 → Jotai ✅
└── 已有项目迁移
    ├── 从 Redux 迁移 → Redux Toolkit
    ├── 从 Recoil 迁移 → Jotai
    ├── 从 Context API → Zustand ✅
    └── 从 MobX 迁移 → MobX 6 或 Valtio
```

### 场景推荐

| 场景 | 推荐 | 原因 |
|------|------|------|
| 个人项目/快速原型 | Zustand | 最少代码，最快上手 |
| 中型 SPA | Zustand 或 Jotai | 平衡简洁和功能 |
| 大型企业应用 | Redux Toolkit | 生态最完善，规范最严格 |
| 复杂派生状态 | Jotai | 原子化 + 自动追踪 |
| 实时协作应用 | MobX | 响应式 + 自动更新 |
| 移动端 React Native | Zustand | 轻量，无 Provider |
| 需要时间旅行调试 | Redux Toolkit | 最佳 DevTools |
| 与 GraphQL 集成 | MobX 或 Apollo Client | 响应式匹配 |

---

## Migration Guide: Context API → Zustand

### Step 1: 分析现有 Context

```typescript
// ❌ 之前：Context API
interface AppState {
  user: User | null
  theme: 'light' | 'dark'
  setUser: (user: User | null) => void
  toggleTheme: () => void
}

const AppContext = createContext<AppState | null>(null)

export function AppProvider({ children }) {
  const [user, setUser] = useState<User | null>(null)
  const [theme, setTheme] = useState<'light' | 'dark'>('light')

  const value = useMemo(() => ({
    user,
    theme,
    setUser,
    toggleTheme: () => setTheme(t => t === 'light' ? 'dark' : 'light'),
  }), [user, theme])

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp must be within AppProvider')
  return ctx
}
```

### Step 2: 创建 Zustand Store

```typescript
// ✅ 之后：Zustand
import { create } from 'zustand'

interface AppStore {
  user: User | null
  theme: 'light' | 'dark'
  setUser: (user: User | null) => void
  toggleTheme: () => void
}

export const useAppStore = create<AppStore>((set) => ({
  user: null,
  theme: 'light',
  setUser: (user) => set({ user }),
  toggleTheme: () => set((state) => ({
    theme: state.theme === 'light' ? 'dark' : 'light',
  })),
}))
```

### Step 3: 替换所有使用点

```typescript
// ❌ 之前
const { user, theme, toggleTheme } = useApp()

// ✅ 之后
const user = useAppStore((state) => state.user)
const theme = useAppStore((state) => state.theme)
const toggleTheme = useAppStore((state) => state.toggleTheme)

// 或者使用 useShallow（当需要多个字段时）
const { user, theme } = useAppStore(
  useShallow((state) => ({ user: state.user, theme: state.theme }))
)
```

### Step 4: 删除 Provider

```typescript
// ❌ 之前：需要包裹 Provider
function App() {
  return (
    <AppProvider>
      <MyApp />
    </AppProvider>
  )
}

// ✅ 之后：无需 Provider
function App() {
  return <MyApp />
}
```

### Step 5: 处理 SSR（如果需要）

```typescript
// Next.js App Router 中使用
'use client'

import { useAppStore } from '@/stores/app'

// Zustand 在 SSR 中天然安全，因为 store 在客户端创建
// 如果需要服务端初始化：
export function useHydrate(initialState: Partial<AppStore>) {
  useAppStore.setState(initialState)
}
```

### 迁移检查清单

- [ ] 分析所有 Context 使用点
- [ ] 创建对应的 Zustand store
- [ ] 替换 `useContext` → `useStore`
- [ ] 添加精确的 selector 优化
- [ ] 删除 Provider 包裹
- [ ] 测试 SSR 兼容性
- [ ] 运行 TypeScript 检查
- [ ] 测试组件渲染次数（应该减少）

---

## 关键要点

1. **没有银弹**：每个方案都有其最佳适用场景
2. **Zustand** 是大多数项目的最佳起点（简单 + 轻量 + 功能足够）
3. **Redux Toolkit** 仍然是大型团队的最佳选择
4. **Jotai** 是 Recoil 的精神继承者
5. **MobX** 适合 OOP 风格和复杂领域模型
6. **从 Context API 迁移到 Zustand** 是最平滑的升级路径
7. **包大小很重要**：Zustand ~1KB vs Redux Toolkit ~11KB
