---
title: Day 34 - 错误边界与 Suspense
date: 2026-05-29
tags:
  - react
  - 错误边界
  - suspense
  - 异步
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 34 - 错误边界与 Suspense

## 📚 学习目标
- 理解错误边界的概念和实现
- 掌握 Suspense 的使用场景
- 学会优雅处理异步加载和错误

## 🎯 核心概念

### 1. 错误边界（Error Boundary）

#### 什么是错误边界？
错误边界是 React 组件，可以捕获并打印发生在其子组件树任何位置的 JavaScript 错误。

#### 实现错误边界
```typescript
// ErrorBoundary.tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    this.props.onError?.(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }
      return (
        <div className="error-boundary">
          <h2>出错了</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            重试
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

#### 使用错误边界
```typescript
// App.tsx
function App() {
  return (
    <ErrorBoundary fallback={<ErrorFallback />}>
      <Header />
      <Main />
      <Footer />
    </ErrorBoundary>
  );
}

function ErrorFallback() {
  return (
    <div className="error-fallback">
      <h1>应用出错了</h1>
      <p>请刷新页面重试</p>
      <button onClick={() => window.location.reload()}>刷新</button>
    </div>
  );
}
```

#### 自定义错误处理
```typescript
// 特定组件的错误处理
function UserProfile({ userId }: Props) {
  return (
    <ErrorBoundary
      fallback={<div>加载用户信息失败</div>}
      onError={(error) => {
        // 上报错误到监控系统
        reportError(error, { userId });
      }}
    >
      <UserDetails userId={userId} />
    </ErrorBoundary>
  );
}
```

### 2. Suspense

#### 基本用法
```typescript
// 使用 Suspense 包裹异步组件
function App() {
  return (
    <Suspense fallback={<Loading />}>
      <UserProfile />
    </Suspense>
  );
}

// 异步组件使用 use()
function UserProfile() {
  const user = use(fetchUser());
  return <div>{user.name}</div>;
}
```

#### 与 React.lazy 结合
```typescript
// 代码分割
const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyComponent />
    </Suspense>
  );
}
```

#### 数据获取模式
```typescript
// 使用 Suspense 获取数据
function UserProfile({ userId }: Props) {
  const user = use(fetchUser(userId));
  const posts = use(fetchPosts(userId));

  return (
    <div>
      <h1>{user.name}</h1>
      <PostList posts={posts} />
    </div>
  );
}

// 父组件
function App() {
  return (
    <Suspense fallback={<Loading />}>
      <UserProfile userId="123" />
    </Suspense>
  );
}
```

### 3. 错误边界 + Suspense 组合

#### 完整的异步处理方案
```typescript
// AsyncBoundary.tsx
import { Suspense, Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  loadingFallback?: ReactNode;
  errorFallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class AsyncBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.props.onError?.(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.errorFallback || (
        <div>
          <h2>加载失败</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            重试
          </button>
        </div>
      );
    }

    return (
      <Suspense fallback={this.props.loadingFallback || <Loading />}>
        {this.props.children}
      </Suspense>
    );
  }
}

// 使用
function App() {
  return (
    <AsyncBoundary
      loadingFallback={<Skeleton />}
      errorFallback={<ErrorCard />}
    >
      <UserProfile />
    </AsyncBoundary>
  );
}
```

### 4. 使用 use() Hook

#### 数据获取
```typescript
// api.ts
export async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) throw new Error('Failed to fetch user');
  return response.json();
}

// UserProfile.tsx
import { use } from 'react';

export function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

// App.tsx
function App() {
  const userPromise = fetchUser('123');
  
  return (
    <Suspense fallback={<Loading />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

#### 与 Context 结合
```typescript
// UserContext.tsx
const UserContext = createContext<Promise<User> | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const userPromise = useMemo(() => fetchUser('123'), []);
  
  return (
    <UserContext.Provider value={userPromise}>
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  const userPromise = useContext(UserContext);
  if (!userPromise) throw new Error('useUser must be used within UserProvider');
  return use(userPromise);
}

// 使用
function UserProfile() {
  const user = useUser();
  return <div>{user.name}</div>;
}

function App() {
  return (
    <UserProvider>
      <Suspense fallback={<Loading />}>
        <UserProfile />
      </Suspense>
    </UserProvider>
  );
}
```

## 🔧 实战练习

### 练习 1：带重试的错误边界
```typescript
// RetryErrorBoundary.tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  maxRetries?: number;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  retryCount: number;
}

export class RetryErrorBoundary extends Component<Props, State> {
  static defaultProps = {
    maxRetries: 3,
  };

  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null, retryCount: 0 };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught:', error, errorInfo);
  }

  handleRetry = () => {
    if (this.state.retryCount < (this.props.maxRetries || 3)) {
      this.setState(prevState => ({
        hasError: false,
        error: null,
        retryCount: prevState.retryCount + 1,
      }));
    }
  };

  render() {
    if (this.state.hasError) {
      const canRetry = this.state.retryCount < (this.props.maxRetries || 3);
      
      return this.props.fallback || (
        <div>
          <h2>出错了</h2>
          <p>{this.state.error?.message}</p>
          {canRetry && (
            <button onClick={this.handleRetry}>
              重试 ({this.state.retryCount}/{this.props.maxRetries})
            </button>
          )}
        </div>
      );
    }

    return this.props.children;
  }
}
```

### 练习 2：Suspense 图片加载
```typescript
// SuspenseImage.tsx
import { use } from 'react';

const imageCache = new Map<string, Promise<void>>();

function preloadImage(src: string): Promise<void> {
  if (imageCache.has(src)) {
    return imageCache.get(src)!;
  }

  const promise = new Promise<void>((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve();
    img.onerror = reject;
    img.src = src;
  });

  imageCache.set(src, promise);
  return promise;
}

export function SuspenseImage({ src, alt, ...props }: React.ImgHTMLAttributes<HTMLImageElement>) {
  use(preloadImage(src!));
  return <img src={src} alt={alt} {...props} />;
}

// 使用
function App() {
  return (
    <Suspense fallback={<ImageSkeleton />}>
      <SuspenseImage src="/large-image.jpg" alt="Large image" />
    </Suspense>
  );
}
```

## 📝 最佳实践

### 1. 错误边界放置位置
```typescript
// 好：在路由级别放置
function App() {
  return (
    <ErrorBoundary fallback={<GlobalError />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/profile" element={
          <ErrorBoundary fallback={<ProfileError />}>
            <Profile />
          </ErrorBoundary>
        } />
      </Routes>
    </ErrorBoundary>
  );
}
```

### 2. 提供有意义的错误信息
```typescript
// 好：用户友好的错误信息
<ErrorBoundary
  fallback={
    <div>
      <h2>无法加载此内容</h2>
      <p>请检查网络连接后重试</p>
    </div>
  }
>
  <Content />
</ErrorBoundary>

// 不好：技术性错误信息
<ErrorBoundary
  fallback={<div>Error: {error.message}</div>}
>
  <Content />
</ErrorBoundary>
```

### 3. 错误上报
```typescript
<ErrorBoundary
  onError={(error, errorInfo) => {
    // 上报到监控系统
    errorReportingService.captureException(error, {
      componentStack: errorInfo.componentStack,
    });
  }}
>
  <App />
</ErrorBoundary>
```

### 4. Suspense 粒度控制
```typescript
// 好：细粒度的 Suspense
function Dashboard() {
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>
      <Suspense fallback={<ContentSkeleton />}>
        <Content />
      </Suspense>
      <Suspense fallback={<SidebarSkeleton />}>
        <Sidebar />
      </Suspense>
    </div>
  );
}

// 不好：整个页面一个 Suspense
function Dashboard() {
  return (
    <Suspense fallback={<FullPageLoading />}>
      <Header />
      <Content />
      <Sidebar />
    </Suspense>
  );
}
```

## 🎓 今日总结

**关键知识点：**
1. 错误边界捕获子组件的渲染错误
2. Suspense 处理异步加载状态
3. use() Hook 简化数据获取
4. 组合使用提供完整的异步处理方案

**使用场景：**
- 错误边界：防止局部错误影响整个应用
- Suspense：代码分割、数据获取
- use()：配合 Suspense 获取数据

**注意事项：**
- 错误边界不捕获事件处理器中的错误
- 错误边界不捕获异步代码中的错误
- Suspense 需要配合支持它的数据源使用

**明日计划：**
- Day 35: 周总结 + 实战练习
