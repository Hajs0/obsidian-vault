---
title: Day 35 - 第四周总结 + 实战练习
date: 2026-05-29
tags:
  - react
  - 总结
  - 实战
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 35 - 第四周总结 + 实战练习

## 📚 本周学习回顾

### Day 31: Custom Hooks 模式
**核心知识点：**
- Custom Hooks 是复用状态逻辑的最佳方式
- 命名必须以 `use` 开头
- 只能在函数组件或其他 Hooks 中调用

**常用 Hooks 收藏：**
- `useFetch` - 数据获取
- `useLocalStorage` - 本地存储
- `useDebounce` - 防抖
- `useWindowSize` - 窗口尺寸
- `useForm` - 表单管理

### Day 32: Context + useReducer 高级状态管理
**核心知识点：**
- `useReducer` 适合复杂状态逻辑
- Context + useReducer 组合实现全局状态管理
- 拆分 Context 避免不必要的重渲染
- 使用自定义 Hook 封装 Context 使用

**适用场景：**
- 中等复杂度的应用
- 需要共享状态的多个组件
- 不想引入外部状态管理库

### Day 33: React 性能优化
**核心知识点：**
- `React.memo` 缓存组件，避免不必要的重渲染
- `useMemo` 缓存计算结果
- `useCallback` 缓存函数引用
- 正确设置依赖数组是关键

**使用时机：**
- `memo`: 子组件接收复杂 props
- `useMemo`: 昂贵的计算、对象/数组缓存
- `useCallback`: 传递给 memo 组件的回调函数

### Day 34: 错误边界与 Suspense
**核心知识点：**
- 错误边界捕获子组件的渲染错误
- Suspense 处理异步加载状态
- use() Hook 简化数据获取
- 组合使用提供完整的异步处理方案

**使用场景：**
- 错误边界：防止局部错误影响整个应用
- Suspense：代码分割、数据获取
- use()：配合 Suspense 获取数据

## 🎯 实战练习：构建一个完整的待办应用

### 项目结构
```
todo-app/
├── src/
│   ├── components/
│   │   ├── TodoList.tsx
│   │   ├── TodoItem.tsx
│   │   ├── AddTodo.tsx
│   │   ├── FilterButtons.tsx
│   │   └── ErrorFallback.tsx
│   ├── hooks/
│   │   ├── useTodos.ts
│   │   └── useLocalStorage.ts
│   ├── context/
│   │   └── TodoContext.tsx
│   ├── App.tsx
│   └── main.tsx
├── package.json
└── tsconfig.json
```

### 1. 类型定义
```typescript
// types.ts
export interface Todo {
  id: string;
  text: string;
  completed: boolean;
  createdAt: Date;
}

export type FilterType = 'all' | 'active' | 'completed';

export interface TodoState {
  todos: Todo[];
  filter: FilterType;
}

export type TodoAction =
  | { type: 'ADD_TODO'; payload: string }
  | { type: 'TOGGLE_TODO'; payload: string }
  | { type: 'DELETE_TODO'; payload: string }
  | { type: 'EDIT_TODO'; payload: { id: string; text: string } }
  | { type: 'SET_FILTER'; payload: FilterType }
  | { type: 'CLEAR_COMPLETED' };
```

### 2. Reducer 实现
```typescript
// reducer.ts
import { Todo, TodoState, TodoAction } from './types';

export function todoReducer(state: TodoState, action: TodoAction): TodoState {
  switch (action.type) {
    case 'ADD_TODO':
      return {
        ...state,
        todos: [
          {
            id: Date.now().toString(),
            text: action.payload,
            completed: false,
            createdAt: new Date(),
          },
          ...state.todos,
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
    case 'EDIT_TODO':
      return {
        ...state,
        todos: state.todos.map(todo =>
          todo.id === action.payload.id
            ? { ...todo, text: action.payload.text }
            : todo
        ),
      };
    case 'SET_FILTER':
      return { ...state, filter: action.payload };
    case 'CLEAR_COMPLETED':
      return {
        ...state,
        todos: state.todos.filter(todo => !todo.completed),
      };
    default:
      return state;
  }
}
```

### 3. Context 实现
```typescript
// TodoContext.tsx
import { createContext, useContext, useReducer, useMemo, ReactNode } from 'react';
import { TodoState, TodoAction, FilterType, Todo } from './types';
import { todoReducer } from './reducer';
import { useLocalStorage } from '../hooks/useLocalStorage';

interface TodoContextType {
  state: TodoState;
  dispatch: React.Dispatch<TodoAction>;
  filteredTodos: Todo[];
  stats: {
    total: number;
    active: number;
    completed: number;
  };
}

const TodoContext = createContext<TodoContextType | undefined>(undefined);

export function TodoProvider({ children }: { children: ReactNode }) {
  const [savedTodos, setSavedTodos] = useLocalStorage<Todo[]>('todos', []);
  
  const [state, dispatch] = useReducer(todoReducer, {
    todos: savedTodos,
    filter: 'all',
  });

  // 保存到 localStorage
  useMemo(() => {
    setSavedTodos(state.todos);
  }, [state.todos, setSavedTodos]);

  // 计算过滤后的 todos
  const filteredTodos = useMemo(() => {
    switch (state.filter) {
      case 'active':
        return state.todos.filter(todo => !todo.completed);
      case 'completed':
        return state.todos.filter(todo => todo.completed);
      default:
        return state.todos;
    }
  }, [state.todos, state.filter]);

  // 计算统计信息
  const stats = useMemo(() => ({
    total: state.todos.length,
    active: state.todos.filter(todo => !todo.completed).length,
    completed: state.todos.filter(todo => todo.completed).length,
  }), [state.todos]);

  const value = useMemo(() => ({
    state,
    dispatch,
    filteredTodos,
    stats,
  }), [state, filteredTodos, stats]);

  return (
    <TodoContext.Provider value={value}>
      {children}
    </TodoContext.Provider>
  );
}

export function useTodo() {
  const context = useContext(TodoContext);
  if (!context) {
    throw new Error('useTodo must be used within a TodoProvider');
  }
  return context;
}
```

### 4. 组件实现

#### TodoItem 组件
```typescript
// TodoItem.tsx
import { memo, useState, useCallback } from 'react';
import { Todo } from '../types';

interface Props {
  todo: Todo;
  onToggle: (id: string) => void;
  onDelete: (id: string) => void;
  onEdit: (id: string, text: string) => void;
}

export const TodoItem = memo(function TodoItem({ todo, onToggle, onDelete, onEdit }: Props) {
  const [isEditing, setIsEditing] = useState(false);
  const [editText, setEditText] = useState(todo.text);

  const handleToggle = useCallback(() => {
    onToggle(todo.id);
  }, [todo.id, onToggle]);

  const handleDelete = useCallback(() => {
    onDelete(todo.id);
  }, [todo.id, onDelete]);

  const handleEdit = useCallback(() => {
    if (editText.trim()) {
      onEdit(todo.id, editText.trim());
      setIsEditing(false);
    }
  }, [todo.id, editText, onEdit]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleEdit();
    } else if (e.key === 'Escape') {
      setEditText(todo.text);
      setIsEditing(false);
    }
  }, [handleEdit, todo.text]);

  return (
    <div className={`todo-item ${todo.completed ? 'completed' : ''}`}>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={handleToggle}
      />
      {isEditing ? (
        <input
          type="text"
          value={editText}
          onChange={(e) => setEditText(e.target.value)}
          onBlur={handleEdit}
          onKeyDown={handleKeyDown}
          autoFocus
        />
      ) : (
        <span onDoubleClick={() => setIsEditing(true)}>
          {todo.text}
        </span>
      )}
      <button onClick={handleDelete}>删除</button>
    </div>
  );
});
```

#### AddTodo 组件
```typescript
// AddTodo.tsx
import { useState, useCallback, memo } from 'react';

interface Props {
  onAdd: (text: string) => void;
}

export const AddTodo = memo(function AddTodo({ onAdd }: Props) {
  const [text, setText] = useState('');

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault();
    if (text.trim()) {
      onAdd(text.trim());
      setText('');
    }
  }, [text, onAdd]);

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="添加新任务..."
      />
      <button type="submit">添加</button>
    </form>
  );
});
```

#### FilterButtons 组件
```typescript
// FilterButtons.tsx
import { memo, useCallback } from 'react';
import { FilterType } from '../types';

interface Props {
  currentFilter: FilterType;
  onFilter: (filter: FilterType) => void;
  stats: {
    total: number;
    active: number;
    completed: number;
  };
}

export const FilterButtons = memo(function FilterButtons({ 
  currentFilter, 
  onFilter, 
  stats 
}: Props) {
  const handleFilter = useCallback((filter: FilterType) => {
    onFilter(filter);
  }, [onFilter]);

  return (
    <div className="filter-buttons">
      <span>{stats.active} 个待办</span>
      <div>
        <button
          className={currentFilter === 'all' ? 'active' : ''}
          onClick={() => handleFilter('all')}
        >
          全部
        </button>
        <button
          className={currentFilter === 'active' ? 'active' : ''}
          onClick={() => handleFilter('active')}
        >
          进行中
        </button>
        <button
          className={currentFilter === 'completed' ? 'active' : ''}
          onClick={() => handleFilter('completed')}
        >
          已完成
        </button>
      </div>
      {stats.completed > 0 && (
        <button onClick={() => onFilter('completed')}>
          清除已完成
        </button>
      )}
    </div>
  );
});
```

### 5. App 组件
```typescript
// App.tsx
import { ErrorBoundary } from './components/ErrorBoundary';
import { TodoProvider } from './context/TodoContext';
import { TodoList } from './components/TodoList';
import { AddTodo } from './components/AddTodo';
import { FilterButtons } from './components/FilterButtons';
import { useTodo } from './context/TodoContext';

function TodoApp() {
  const { state, dispatch, filteredTodos, stats } = useTodo();

  const handleAdd = (text: string) => {
    dispatch({ type: 'ADD_TODO', payload: text });
  };

  const handleToggle = (id: string) => {
    dispatch({ type: 'TOGGLE_TODO', payload: id });
  };

  const handleDelete = (id: string) => {
    dispatch({ type: 'DELETE_TODO', payload: id });
  };

  const handleEdit = (id: string, text: string) => {
    dispatch({ type: 'EDIT_TODO', payload: { id, text } });
  };

  const handleFilter = (filter: 'all' | 'active' | 'completed') => {
    dispatch({ type: 'SET_FILTER', payload: filter });
  };

  return (
    <div className="todo-app">
      <h1>待办事项</h1>
      <AddTodo onAdd={handleAdd} />
      <FilterButtons
        currentFilter={state.filter}
        onFilter={handleFilter}
        stats={stats}
      />
      <TodoList
        todos={filteredTodos}
        onToggle={handleToggle}
        onDelete={handleDelete}
        onEdit={handleEdit}
      />
    </div>
  );
}

export default function App() {
  return (
    <ErrorBoundary fallback={<div>应用出错了，请刷新页面</div>}>
      <TodoProvider>
        <TodoApp />
      </TodoProvider>
    </ErrorBoundary>
  );
}
```

## 📝 本周学习总结

### 掌握的核心技能
1. **Custom Hooks** - 复用状态逻辑的最佳实践
2. **Context + useReducer** - 中等复杂度的状态管理方案
3. **性能优化** - memo, useMemo, useCallback 的正确使用
4. **错误处理** - 错误边界和 Suspense 的组合使用

### 实战项目收获
通过构建待办应用，实践了本周学习的所有知识点：
- 使用 Custom Hooks 封装 localStorage 逻辑
- 使用 Context + useReducer 管理全局状态
- 使用 memo 优化组件渲染性能
- 使用 ErrorBoundary 处理错误

### 下周预告
**第五周：动画与交互**
- Day 36: Framer Motion 入门
- Day 37: 页面过渡动画
- Day 38: 手势与拖拽交互
- Day 39: 滚动动画
- Day 40: 周总结 + 动画实战
