---
title: Day 33 - React 性能优化
date: 2026-05-29
tags:
  - react
  - 性能优化
  - memo
  - useMemo
  - useCallback
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 33 - React 性能优化

## 📚 学习目标
- 理解 React 渲染机制
- 掌握 memo, useMemo, useCallback 的使用
- 学会识别和解决性能问题

## 🎯 核心概念

### 1. React 渲染机制

#### 渲染触发条件
- State 更新
- Props 变化
- 父组件重渲染
- Context 值变化

#### 渲染流程
```
触发 → 协调（Reconciliation）→ 提交（Commit）→ 渲染（Render）
```

### 2. React.memo

#### 基本用法
```typescript
// 普通组件：父组件重渲染时，子组件也会重渲染
function Child({ name }: { name: string }) {
  console.log('Child rendered');
  return <div>{name}</div>;
}

// 使用 memo：只有 props 变化时才重渲染
const Child = memo(function Child({ name }: { name: string }) {
  console.log('Child rendered');
  return <div>{name}</div>;
});
```

#### 自定义比较函数
```typescript
interface Props {
  user: User;
  onUpdate: (id: string) => void;
}

const UserCard = memo(function UserCard({ user, onUpdate }: Props) {
  return (
    <div onClick={() => onUpdate(user.id)}>
      {user.name}
    </div>
  );
}, (prevProps, nextProps) => {
  // 自定义比较逻辑
  return (
    prevProps.user.id === nextProps.user.id &&
    prevProps.user.name === nextProps.user.name
  );
});
```

### 3. useMemo

#### 缓存计算结果
```typescript
function TodoList({ todos, filter }: Props) {
  // 每次渲染都会重新计算
  const filteredTodos = todos.filter(todo => {
    if (filter === 'active') return !todo.completed;
    if (filter === 'completed') return todo.completed;
    return true;
  });

  // 使用 useMemo 缓存，只有 todos 或 filter 变化时才重新计算
  const filteredTodos = useMemo(() => {
    return todos.filter(todo => {
      if (filter === 'active') return !todo.completed;
      if (filter === 'completed') return todo.completed;
      return true;
    });
  }, [todos, filter]);

  return (
    <ul>
      {filteredTodos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

#### 缓存复杂对象
```typescript
function UserList({ users }: Props) {
  // 每次渲染都创建新对象，导致子组件重渲染
  const style = { color: 'red', fontSize: '16px' };

  // 使用 useMemo 缓存对象
  const style = useMemo(() => ({
    color: 'red',
    fontSize: '16px',
  }), []);

  return (
    <div style={style}>
      {users.map(user => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  );
}
```

### 4. useCallback

#### 缓存函数引用
```typescript
function Parent() {
  const [count, setCount] = useState(0);

  // 每次渲染都创建新函数
  const handleClick = () => {
    console.log('clicked');
  };

  // 使用 useCallback 缓存函数
  const handleClick = useCallback(() => {
    console.log('clicked');
  }, []);

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
      <Child onClick={handleClick} />
    </div>
  );
}

const Child = memo(function Child({ onClick }: { onClick: () => void }) {
  console.log('Child rendered');
  return <button onClick={onClick}>Click me</button>;
});
```

#### 带依赖的 useCallback
```typescript
function TodoList({ todos }: Props) {
  const [filter, setFilter] = useState('all');

  // 依赖 filter 变化
  const handleFilter = useCallback((newFilter: string) => {
    setFilter(newFilter);
    // 其他逻辑
  }, []);

  // 依赖 todos 和 filter
  const getFilteredTodos = useCallback(() => {
    return todos.filter(todo => {
      if (filter === 'active') return !todo.completed;
      if (filter === 'completed') return todo.completed;
      return true;
    });
  }, [todos, filter]);

  return (
    <div>
      <FilterButtons onFilter={handleFilter} />
      <TodoItems todos={getFilteredTodos()} />
    </div>
  );
}
```

### 5. 性能优化组合技

#### 完整示例
```typescript
interface Props {
  items: Item[];
  onSelect: (id: string) => void;
}

const OptimizedList = memo(function OptimizedList({ items, onSelect }: Props) {
  // 缓存排序结果
  const sortedItems = useMemo(() => {
    return [...items].sort((a, b) => a.name.localeCompare(b.name));
  }, [items]);

  // 缓存点击处理函数
  const handleSelect = useCallback((id: string) => {
    onSelect(id);
  }, [onSelect]);

  return (
    <ul>
      {sortedItems.map(item => (
        <ListItem
          key={item.id}
          item={item}
          onSelect={handleSelect}
        />
      ))}
    </ul>
  );
});

const ListItem = memo(function ListItem({
  item,
  onSelect,
}: {
  item: Item;
  onSelect: (id: string) => void;
}) {
  return (
    <li onClick={() => onSelect(item.id)}>
      {item.name}
    </li>
  );
});
```

## 🔧 性能分析工具

### 1. React DevTools Profiler
```typescript
// 开启 Profiler
import { Profiler } from 'react';

function onRender(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number,
) {
  console.log('Profiler:', {
    id,
    phase,
    actualDuration,
    baseDuration,
  });
}

function App() {
  return (
    <Profiler id="App" onRender={onRender}>
      <Main />
    </Profiler>
  );
}
```

### 2. 控制台日志
```typescript
function Component(props: Props) {
  console.log('Component rendered', props);
  // ...
}
```

### 3. why-did-you-render
```typescript
// 安装：npm install @welldone-software/why-did-you-render
import './wdyr';

const Component = React.memo(function Component(props: Props) {
  // ...
});
Component.whyDidYouRender = true;
```

## 📝 最佳实践

### 1. 不要过早优化
```typescript
// 不好：过度优化简单组件
const SimpleText = memo(function SimpleText({ text }: { text: string }) {
  return <span>{text}</span>;
});

// 好：只优化频繁渲染的复杂组件
const ComplexList = memo(function ComplexList({ items }: Props) {
  // 复杂渲染逻辑
});
```

### 2. 正确使用依赖数组
```typescript
// 不好：遗漏依赖
const handleClick = useCallback(() => {
  doSomething(value);
}, []); // value 未在依赖中

// 好：包含所有依赖
const handleClick = useCallback(() => {
  doSomething(value);
}, [value]);

// 不好：对象/数组作为依赖（每次都是新引用）
const options = { key: 'value' };
const result = useMemo(() => compute(options), [options]);

// 好：缓存对象
const options = useMemo(() => ({ key: 'value' }), []);
const result = useMemo(() => compute(options), [options]);
```

### 3. 避免内联对象和函数
```typescript
// 不好：每次渲染创建新对象
<Child style={{ color: 'red' }} onClick={() => {}} />

// 好：缓存对象和函数
const style = useMemo(() => ({ color: 'red' }), []);
const handleClick = useCallback(() => {}, []);
<Child style={style} onClick={handleClick} />
```

### 4. 使用 key 优化列表
```typescript
// 不好：使用 index 作为 key
{items.map((item, index) => (
  <ListItem key={index} item={item} />
))}

// 好：使用唯一 ID
{items.map(item => (
  <ListItem key={item.id} item={item} />
))}
```

## 🎓 今日总结

**关键知识点：**
1. `React.memo` 缓存组件，避免不必要的重渲染
2. `useMemo` 缓存计算结果
3. `useCallback` 缓存函数引用
4. 正确设置依赖数组是关键

**使用时机：**
- `memo`: 子组件接收复杂 props
- `useMemo`: 昂贵的计算、对象/数组缓存
- `useCallback`: 传递给 memo 组件的回调函数

**性能分析工具：**
- React DevTools Profiler
- 控制台日志
- why-did-you-render

**明日计划：**
- Day 34: 错误边界与 Suspense
