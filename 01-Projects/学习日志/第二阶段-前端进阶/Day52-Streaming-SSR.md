---
title: Day 52 - Streaming SSR
date: 2026-05-29
tags:
  - nextjs
  - streaming
  - ssr
  - suspense
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 52 - Streaming SSR

## 📚 学习目标
- 理解 Streaming SSR 的优势
- 掌握 Suspense 在 SSR 中的使用
- 学会优化首屏加载时间

## 🎯 核心概念

### 1. 什么是 Streaming SSR？

#### 传统 SSR vs Streaming SSR
```
传统 SSR：
服务器获取所有数据 → 生成完整 HTML → 发送到客户端 → 水合

Streaming SSR：
服务器开始生成 HTML → 流式发送 → 客户端逐步渲染 → 数据到达后更新
```

#### 优势
- 更快的首字节时间（TTFB）
- 更快的首屏加载时间
- 更好的用户体验
- 渐进式渲染

### 2. 使用 Suspense

#### 基本用法
```typescript
import { Suspense } from 'react';

function App() {
  return (
    <div>
      <Header />
      <Suspense fallback={<Loading />}>
        <SlowComponent />
      </Suspense>
      <Footer />
    </div>
  );
}
```

#### 多个 Suspense 边界
```typescript
function Dashboard() {
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>
      
      <div className="grid grid-cols-2 gap-4">
        <Suspense fallback={<ChartSkeleton />}>
          <Chart />
        </Suspense>
        
        <Suspense fallback={<TableSkeleton />}>
          <Table />
        </Suspense>
      </div>
    </div>
  );
}
```

### 3. 异步组件

#### 使用 async/await
```typescript
// app/dashboard/page.tsx
async function getData() {
  const res = await fetch('https://api.example.com/data');
  return res.json();
}

export default async function Dashboard() {
  const data = await getData();
  
  return (
    <div>
      <h1>Dashboard</h1>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
}
```

#### 使用 use() Hook
```typescript
'use client';

import { use, Suspense } from 'react';

function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

export function ProfilePage() {
  const userPromise = fetchUser();
  
  return (
    <Suspense fallback={<Loading />}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### 4. 加载状态

#### 使用 loading.tsx
```typescript
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
      <div className="space-y-3">
        <div className="h-4 bg-gray-200 rounded"></div>
        <div className="h-4 bg-gray-200 rounded w-5/6"></div>
        <div className="h-4 bg-gray-200 rounded w-4/6"></div>
      </div>
    </div>
  );
}
```

#### 使用 Suspense 边界
```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { Stats, Chart, Table } from './components';

export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
      
      <Suspense fallback={<ChartSkeleton />}>
        <Chart />
      </Suspense>
      
      <Suspense fallback={<TableSkeleton />}>
        <Table />
      </Suspense>
    </div>
  );
}
```

### 5. 错误处理

#### 使用 error.tsx
```typescript
// app/dashboard/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="text-center py-10">
      <h2 className="text-2xl font-bold mb-4">出错了！</h2>
      <p className="text-gray-600 mb-4">{error.message}</p>
      <button
        onClick={reset}
        className="bg-blue-500 text-white px-4 py-2 rounded"
      >
        重试
      </button>
    </div>
  );
}
```

### 6. 性能优化

#### 并行数据获取
```typescript
// 好：并行获取
async function getData() {
  const [users, posts, comments] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchComments(),
  ]);
  
  return { users, posts, comments };
}

// 不好：串行获取
async function getData() {
  const users = await fetchUsers();
  const posts = await fetchPosts();
  const comments = await fetchComments();
  
  return { users, posts, comments };
}
```

#### 流式数据获取
```typescript
// 流式获取
async function* getStreamData() {
  const response = await fetch('https://api.example.com/stream');
  const reader = response.body?.getReader();
  
  while (true) {
    const { done, value } = await reader!.read();
    if (done) break;
    yield value;
  }
}
```

## 🔧 实战练习

### 练习 1：流式仪表板
```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react';

async function Stats() {
  const stats = await fetchStats();
  return (
    <div className="grid grid-cols-4 gap-4">
      <StatCard title="用户" value={stats.users} />
      <StatCard title="订单" value={stats.orders} />
      <StatCard title="收入" value={stats.revenue} />
      <StatCard title="转化" value={stats.conversion} />
    </div>
  );
}

async function RecentOrders() {
  const orders = await fetchRecentOrders();
  return (
    <div>
      {orders.map(order => (
        <OrderCard key={order.id} order={order} />
      ))}
    </div>
  );
}

async function Chart() {
  const data = await fetchChartData();
  return <LineChart data={data} />;
}

export default function Dashboard() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">仪表板</h1>
      
      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
      
      <div className="grid grid-cols-2 gap-6">
        <Suspense fallback={<ChartSkeleton />}>
          <Chart />
        </Suspense>
        
        <Suspense fallback={<OrdersSkeleton />}>
          <RecentOrders />
        </Suspense>
      </div>
    </div>
  );
}
```

### 练习 2：流式文章页面
```typescript
// app/blog/[slug]/page.tsx
import { Suspense } from 'react';

async function Article({ slug }: { slug: string }) {
  const article = await fetchArticle(slug);
  
  return (
    <article className="prose">
      <h1>{article.title}</h1>
      <time>{article.date}</time>
      <div dangerouslySetInnerHTML={{ __html: article.content }} />
    </article>
  );
}

async function Comments({ articleId }: { articleId: string }) {
  const comments = await fetchComments(articleId);
  
  return (
    <div>
      <h2>评论 ({comments.length})</h2>
      {comments.map(comment => (
        <CommentCard key={comment.id} comment={comment} />
      ))}
    </div>
  );
}

async function RelatedPosts({ articleId }: { articleId: string }) {
  const posts = await fetchRelatedPosts(articleId);
  
  return (
    <div>
      <h2>相关文章</h2>
      {posts.map(post => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const article = await fetchArticle(params.slug);
  
  return (
    <div className="max-w-4xl mx-auto py-8">
      <Suspense fallback={<ArticleSkeleton />}>
        <Article slug={params.slug} />
      </Suspense>
      
      <div className="mt-8 grid grid-cols-3 gap-8">
        <div className="col-span-2">
          <Suspense fallback={<CommentsSkeleton />}>
            <Comments articleId={article.id} />
          </Suspense>
        </div>
        
        <div>
          <Suspense fallback={<RelatedSkeleton />}>
            <RelatedPosts articleId={article.id} />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
```

### 练习 3：流式搜索页面
```typescript
// app/search/page.tsx
import { Suspense } from 'react';

async function SearchResults({ query }: { query: string }) {
  const results = await search(query);
  
  if (results.length === 0) {
    return <div>没有找到相关结果</div>;
  }
  
  return (
    <div>
      {results.map(result => (
        <SearchResultCard key={result.id} result={result} />
      ))}
    </div>
  );
}

async function SearchSuggestions({ query }: { query: string }) {
  const suggestions = await getSuggestions(query);
  
  return (
    <div>
      <h3>搜索建议</h3>
      {suggestions.map(suggestion => (
        <div key={suggestion}>{suggestion}</div>
      ))}
    </div>
  );
}

export default function SearchPage({ 
  searchParams 
}: { 
  searchParams: { q: string } 
}) {
  const query = searchParams.q;
  
  return (
    <div>
      <h1>搜索结果：{query}</h1>
      
      <div className="grid grid-cols-4 gap-8">
        <div className="col-span-3">
          <Suspense fallback={<ResultsSkeleton />}>
            <SearchResults query={query} />
          </Suspense>
        </div>
        
        <div>
          <Suspense fallback={<SuggestionsSkeleton />}>
            <SearchSuggestions query={query} />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
```

## 📝 最佳实践

### 1. 合理设置 Suspense 边界
```typescript
// 好：按功能划分
<Suspense fallback={<HeaderSkeleton />}>
  <Header />
</Suspense>
<Suspense fallback={<ContentSkeleton />}>
  <Content />
</Suspense>

// 不好：整个页面一个边界
<Suspense fallback={<FullPageSkeleton />}>
  <Header />
  <Content />
</Suspense>
```

### 2. 使用骨架屏
```typescript
// 好：骨架屏
<Suspense fallback={<CardSkeleton />}>
  <Card />
</Suspense>

// 不好：加载文字
<Suspense fallback={<div>加载中...</div>}>
  <Card />
</Suspense>
```

### 3. 并行数据获取
```typescript
// 好：并行
const [data1, data2] = await Promise.all([
  fetchData1(),
  fetchData2(),
]);

// 不好：串行
const data1 = await fetchData1();
const data2 = await fetchData2();
```

## 🎓 今日总结

**关键知识点：**
1. Streaming SSR 提高首屏加载速度
2. Suspense 实现流式渲染
3. loading.tsx 和 error.tsx 处理状态
4. 并行数据获取优化性能

**明日计划：**
- Day 53: PWA 实现
