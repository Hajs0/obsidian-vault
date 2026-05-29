---
tags: [project, frontend, integration, day24]
created: 2026-05-31
day: 24
---

# Day 24: 前后端联调记录

## 今日目标

完成前端与后端 API 的集成，实现数据获取、缓存和表单处理。

## 技术方案

### 数据获取

使用 React Query 进行数据获取和缓存：

```typescript
// 使用 useQuery 获取数据
const { data, isLoading, error } = useQuery({
  queryKey: ['articles'],
  queryFn: () => fetch('/api/articles').then(res => res.json()),
  staleTime: 5 * 60 * 1000, // 5 分钟
})
```

### 缓存策略

1. **Stale-While-Revalidate**: 数据在后台更新
2. **自动重新验证**: 窗口聚焦时自动刷新
3. **乐观更新**: 立即更新 UI，后台同步

### 表单处理

使用 React Hook Form + Zod 进行表单处理：

```typescript
const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(schema)
})
```

## API 集成

### 认证流程

1. 用户登录 → 获取 access_token 和 refresh_token
2. 存储 token 到 localStorage
3. 请求时自动添加 Authorization header
4. Token 过期时自动刷新

### 文章列表

```typescript
// 获取文章列表
const fetchArticles = async (params: ArticleParams) => {
  const response = await api.get('/articles', { params })
  return response.data
}

// 使用 React Query
const { data: articles } = useQuery({
  queryKey: ['articles', filters],
  queryFn: () => fetchArticles(filters)
})
```

### 文章详情

```typescript
// 获取文章详情
const { data: article } = useQuery({
  queryKey: ['article', id],
  queryFn: () => fetchArticle(id)
})
```

## 状态管理

### 全局状态

使用 Zustand 管理全局状态：

```typescript
const useAuthStore = create((set) => ({
  user: null,
  token: null,
  setAuth: (user, token) => set({ user, token }),
  logout: () => set({ user: null, token: null })
}))
```

### 服务端状态

使用 React Query 管理服务端状态：

- 文章列表
- 分类列表
- 标签列表
- 用户信息

## 错误处理

### 全局错误处理

```typescript
// Axios 拦截器
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token 过期，尝试刷新
      refreshToken()
    }
    return Promise.reject(error)
  }
)
```

### 表单错误

```typescript
// 显示表单错误
{errors.email && <span>{errors.email.message}</span>}
```

## 性能优化

### 请求优化

1. **防抖搜索**: 搜索输入时延迟请求
2. **分页加载**: 避免一次性加载所有数据
3. **缓存策略**: 减少重复请求

### 渲染优化

1. **虚拟列表**: 大量数据时使用虚拟滚动
2. **懒加载**: 路由和组件懒加载
3. **代码分割**: 按需加载代码

## 联调过程

### 问题 1: CORS 错误

**问题**: 前端无法访问后端 API
**解决**: 后端添加 CORS 中间件

### 问题 2: Token 过期处理

**问题**: Token 过期后用户需要重新登录
**解决**: 实现自动刷新 token 机制

### 问题 3: 数据格式不一致

**问题**: 前后端数据格式不匹配
**解决**: 定义统一的 API 响应格式

## 今日收获

1. 完成了前后端 API 集成
2. 实现了数据缓存策略
3. 处理了表单验证和提交
4. 优化了数据获取性能
5. 解决了联调中的各种问题

## 遇到的问题

- CORS 配置需要仔细处理
- Token 刷新机制需要测试
- 数据缓存策略需要平衡

## 明日计划

- 测试策略制定
- 性能优化
- UI 打磨
