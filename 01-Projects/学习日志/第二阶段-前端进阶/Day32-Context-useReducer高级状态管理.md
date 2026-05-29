---
title: Day 32 - Context + useReducer 高级状态管理
date: 2026-05-29
tags:
  - react
  - context
  - useReducer
  - 状态管理
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 32 - Context + useReducer 高级状态管理

## 📚 学习目标
- 理解 Context + useReducer 的组合模式
- 掌握复杂状态管理的实现
- 学会避免 Context 的性能问题

## 🎯 核心概念

### 1. useReducer 基础
`useReducer` 是 `useState` 的替代方案，适合复杂状态逻辑。

```typescript
// 定义 state 类型
interface State {
  count: number;
  loading: boolean;
  error: string | null;
}

// 定义 action 类型
type Action =
  | { type: 'INCREMENT' }
  | { type: 'DECREMENT' }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null };

// reducer 函数
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'INCREMENT':
      return { ...state, count: state.count + 1 };
    case 'DECREMENT':
      return { ...state, count: state.count - 1 };
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    default:
      return state;
  }
}

// 使用
const [state, dispatch] = useReducer(reducer, {
  count: 0,
  loading: false,
  error: null,
});

// 派发 action
dispatch({ type: 'INCREMENT' });
dispatch({ type: 'SET_LOADING', payload: true });
```

### 2. Context + useReducer 组合

#### 创建状态管理 Context
```typescript
// TodoContext.tsx
import { createContext, useContext, useReducer, ReactNode } from 'react';

// 定义类型
interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

interface TodoState {
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
}

type TodoAction =
  | { type: 'ADD_TODO'; payload: string }
  | { type: 'TOGGLE_TODO'; payload: string }
  | { type: 'DELETE_TODO'; payload: string }
  | { type: 'SET_FILTER'; payload: TodoState['filter'] };

// 初始状态
const initialState: TodoState = {
  todos: [],
  filter: 'all',
};

// Reducer
function todoReducer(state: TodoState, action: TodoAction): TodoState {
  switch (action.type) {
    case 'ADD_TODO':
      return {
        ...state,
        todos: [
          ...state.todos,
          {
            id: Date.now().toString(),
            text: action.payload,
            completed: false,
          },
        ],
      };
    case 'TOGGLE_TODO':
      return {
        ...state,
        todos: state.todos.map(todo =>
          todo.id === action.payload
            ? { ...todo, completed: !todo.completed }
            : todo
        ),
      };
    case 'DELETE_TODO':
      return {
        ...state,
        todos: state.todos.filter(todo => todo.id !== action.payload),
      };
    case 'SET_FILTER':
      return { ...state, filter: action.payload };
    default:
      return state;
  }
}

// Context 类型
interface TodoContextType {
  state: TodoState;
  dispatch: React.Dispatch<TodoAction>;
}

// 创建 Context
const TodoContext = createContext<TodoContextType | undefined>(undefined);

// Provider 组件
export function TodoProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(todoReducer, initialState);

  return (
    <TodoContext.Provider value={{ state, dispatch }}>
      {children}
    </TodoContext.Provider>
  );
}

// 自定义 Hook
export function useTodo() {
  const context = useContext(TodoContext);
  if (!context) {
    throw new Error('useTodo must be used within a TodoProvider');
  }
  return context;
}
```

### 3. 分离 Context 提高性能

#### 问题：Context 值变化导致所有消费者重渲染
```typescript
// 不好的做法：一个 Context 包含所有状态
const AppContext = createContext<{
  user: User;
  theme: Theme;
  todos: Todo[];
}>({...});
```

#### 解决：拆分多个 Context
```typescript
// UserContext.tsx
const UserContext = createContext<User | null>(null);
const UserDispatchContext = createContext<React.Dispatch<UserAction> | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, dispatch] = useReducer(userReducer, null);
  
  return (
    <UserContext.Provider value={user}>
      <UserDispatchContext.Provider value={dispatch}>
        {children}
      </UserDispatchContext.Provider>
    </UserContext.Provider>
  );
}

export function useUser() {
  const context = useContext(UserContext);
  if (!context) throw new Error('useUser must be used within UserProvider');
  return context;
}

export function useUserDispatch() {
  const context = useContext(UserDispatchContext);
  if (!context) throw new Error('useUserDispatch must be used within UserProvider');
  return context;
}
```

### 4. 异步操作处理

#### 使用 thunk 模式
```typescript
// types.ts
type AppAction =
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: Data[] }
  | { type: 'FETCH_ERROR'; payload: string }
  | { type: 'ADD_ITEM'; payload: Data }
  | { type: 'DELETE_ITEM'; payload: string };

// 异步 action creator
function fetchData(): ThunkAction {
  return async (dispatch) => {
    dispatch({ type: 'FETCH_START' });
    try {
      const response = await fetch('/api/data');
      const data = await response.json();
      dispatch({ type: 'FETCH_SUCCESS', payload: data });
    } catch (error) {
      dispatch({ type: 'FETCH_ERROR', payload: '加载失败' });
    }
  };
}

// 使用中间件
function useThunkReducer<S, A extends { type: string }>(
  reducer: React.Reducer<S, A>,
  initialState: S
) {
  const [state, dispatch] = useReducer(reducer, initialState);

  const enhancedDispatch = useCallback(
    (action: A | ((dispatch: React.Dispatch<A>) => Promise<void>)) => {
      if (typeof action === 'function') {
        return action(dispatch);
      }
      return dispatch(action);
    },
    [dispatch]
  );

  return [state, enhancedDispatch] as const;
}
```

## 🔧 实战练习

### 练习 1：购物车状态管理
```typescript
// CartContext.tsx
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: Omit<CartItem, 'quantity'> }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' };

function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingItem = state.items.find(item => item.id === action.payload.id);
      if (existingItem) {
        return {
          ...state,
          items: state.items.map(item =>
            item.id === action.payload.id
              ? { ...item, quantity: item.quantity + 1 }
              : item
          ),
          total: state.total + action.payload.price,
        };
      }
      return {
        ...state,
        items: [...state.items, { ...action.payload, quantity: 1 }],
        total: state.total + action.payload.price,
      };
    }
    case 'REMOVE_ITEM': {
      const item = state.items.find(item => item.id === action.payload);
      return {
        ...state,
        items: state.items.filter(item => item.id !== action.payload),
        total: state.total - (item ? item.price * item.quantity : 0),
      };
    }
    case 'UPDATE_QUANTITY': {
      const item = state.items.find(item => item.id === action.payload.id);
      if (!item) return state;
      const quantityDiff = action.payload.quantity - item.quantity;
      return {
        ...state,
        items: state.items.map(item =>
          item.id === action.payload.id
            ? { ...item, quantity: action.payload.quantity }
            : item
        ),
        total: state.total + item.price * quantityDiff,
      };
    }
    case 'CLEAR_CART':
      return { items: [], total: 0 };
    default:
      return state;
  }
}
```

### 练习 2：多步骤表单
```typescript
// FormContext.tsx
interface FormState {
  currentStep: number;
  data: {
    personal: { name: string; email: string };
    address: { city: string; street: string };
    payment: { cardNumber: string; expiry: string };
  };
  errors: Record<string, string>;
}

type FormAction =
  | { type: 'NEXT_STEP' }
  | { type: 'PREV_STEP' }
  | { type: 'UPDATE_DATA'; payload: { step: string; data: Record<string, string> } }
  | { type: 'SET_ERRORS'; payload: Record<string, string> }
  | { type: 'RESET' };
```

## 📝 最佳实践

### 1. 拆分 Context
```typescript
// 好：按功能拆分
const UserContext = createContext<User | null>(null);
const ThemeContext = createContext<Theme>('light');
const TodoContext = createContext<Todo[]>([]);

// 不好：一个大 Context 包含所有
const AppContext = createContext<{ user: User; theme: Theme; todos: Todo[] }>({...});
```

### 2. 使用 dispatch Context
```typescript
// 好：状态和 dispatch 分开
const StateContext = createContext<State>(initialState);
const DispatchContext = createContext<React.Dispatch<Action>>(() => {});

// 不好：只用一个 Context
const AppContext = createContext<{ state: State; dispatch: Dispatch }>({...});
```

### 3. 提供默认值
```typescript
// 好：有意义的默认值
const ThemeContext = createContext<Theme>('light');

// 不好：空值
const ThemeContext = createContext<Theme>(null as any);
```

### 4. 使用自定义 Hook
```typescript
// 好：封装 Context 使用
export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

// 不好：直接使用 useContext
const theme = useContext(ThemeContext);
```

## 🎓 今日总结

**关键知识点：**
1. `useReducer` 适合复杂状态逻辑
2. Context + useReducer 组合实现全局状态管理
3. 拆分 Context 避免不必要的重渲染
4. 使用自定义 Hook 封装 Context 使用

**适用场景：**
- 中等复杂度的应用
- 需要共享状态的多个组件
- 不想引入外部状态管理库

**局限性：**
- 性能优化需要手动拆分 Context
- 异步操作需要额外处理
- DevTools 支持不如 Redux

**明日计划：**
- Day 33: React 性能优化（memo, useMemo, useCallback）
