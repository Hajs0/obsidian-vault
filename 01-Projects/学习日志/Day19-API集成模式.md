---
tags: [api, integration, fetch, react-query, api-client, day19]
created: 2026-05-30
day: 19
---

# Day 19 - API 集成模式

## 学习目标

- 理解前后端联调的核心模式
- 实现类型安全的 API 客户端
- 掌握错误处理和 Loading 状态管理
- 了解缓存策略 (SWR / React Query)
- 学习 API Client 设计模式

---

## 1. 前后端联调

### 1.1 典型的前后端交互流程

```
┌──────────┐     HTTP Request      ┌──────────┐
│          │ ───────────────────→  │          │
│  前端     │                       │  后端     │
│ React    │ ←───────────────────  │ Express  │
│          │     JSON Response     │          │
└──────────┘                       └──────────┘
     │                                   │
     │ Loading/Error/Success             │ 处理请求
     │ 状态管理                           │ 业务逻辑
     ▼                                   ▼
  用户界面                            数据库
```

### 1.2 联调要点

- **统一响应格式**: 前后端约定一致的数据结构
- **错误码规范**: 使用 HTTP 状态码 + 自定义错误码
- **接口文档**: Swagger/OpenAPI 或手动维护
- **环境变量**: 不同环境的 API 地址

---

## 2. Typed Fetch Wrapper (类型安全的请求封装)

### 2.1 基础实现

```typescript
interface ApiResponse<T> {
  data: T;
  count?: number;
}

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  async post<T>(endpoint: string, body: unknown): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }
}
```

### 2.2 完整功能 (见 src/lib/api-client.ts)

我们的 API 客户端实现包含:
- ✅ 泛型请求方法 (get/post/put/patch/delete)
- ✅ 请求参数序列化
- ✅ Token 自动注入
- ✅ 请求超时控制
- ✅ 自动重试
- ✅ 拦截器机制

---

## 3. 错误处理

### 3.1 错误类型

```typescript
// API 错误响应
interface ApiError {
  error: string;           // 用户友好的错误消息
  code?: string;           // 错误码 (如 'VALIDATION_ERROR')
  details?: Record<string, string[]>; // 字段级错误
  statusCode: number;      // HTTP 状态码
}
```

### 3.2 错误处理策略

```typescript
// 在组件中处理错误
async function handleApiCall() {
  try {
    const data = await apiClient.get('/tasks');
    setData(data);
  } catch (error) {
    if (isApiError(error)) {
      switch (error.statusCode) {
        case 400: // 验证错误 - 显示字段错误
          setFieldErrors(error.details);
          break;
        case 401: // 未授权 - 跳转登录
          navigate('/login');
          break;
        case 403: // 禁止 - 显示无权限提示
          showToast('无权限访问');
          break;
        case 404: // 不存在 - 显示 404 页面
          navigate('/404');
          break;
        case 500: // 服务器错误 - 显示通用错误
          showToast('服务器错误, 请稍后重试');
          break;
      }
    }
  }
}
```

### 3.3 全局错误处理 (拦截器)

```typescript
apiClient.addResponseInterceptor((response, data) => {
  // 日志记录
  if (!response.ok) {
    console.error('API Error:', data);
  }
  return data;
});

// 监听 401 事件
window.addEventListener('auth:unauthorized', () => {
  router.navigate('/login');
});
```

---

## 4. Loading 状态管理

### 4.1 useState 模式

```typescript
function useTasks() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  const fetchTasks = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const { data } = await tasksApi.list();
      setTasks(data);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setIsLoading(false);
    }
  };

  return { tasks, isLoading, error, refetch: fetchTasks };
}
```

### 4.2 useReducer 模式 (复杂状态)

```typescript
type State<T> = {
  data: T | null;
  isLoading: boolean;
  error: ApiError | null;
};

type Action<T> =
  | { type: 'LOADING' }
  | { type: 'SUCCESS'; payload: T }
  | { type: 'ERROR'; payload: ApiError }
  | { type: 'RESET' };

function fetchReducer<T>(state: State<T>, action: Action<T>): State<T> {
  switch (action.type) {
    case 'LOADING':
      return { ...state, isLoading: true, error: null };
    case 'SUCCESS':
      return { data: action.payload, isLoading: false, error: null };
    case 'ERROR':
      return { ...state, isLoading: false, error: action.payload };
    case 'RESET':
      return { data: null, isLoading: false, error: null };
  }
}
```

### 4.3 乐观更新 (Optimistic Updates)

```typescript
function useToggleTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (task: Task) =>
      tasksApi.update(task.id, {
        status: task.status === 'done' ? 'todo' : 'done',
      }),

    // 乐观更新: 先更新 UI, 再发请求
    onMutate: async (task) => {
      await queryClient.cancelQueries({ queryKey: ['tasks'] });
      const previous = queryClient.getQueryData(['tasks']);
      queryClient.setQueryData(['tasks'], (old: Task[]) =>
        old.map((t) =>
          t.id === task.id
            ? { ...t, status: t.status === 'done' ? 'todo' : 'done' }
            : t
        )
      );
      return { previous };
    },

    // 回滚
    onError: (_err, _task, context) => {
      queryClient.setQueryData(['tasks'], context?.previous);
    },

    // 重新获取
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
    },
  });
}
```

---

## 5. 缓存策略

### 5.1 SWR (Stale-While-Revalidate)

```typescript
import useSWR from 'swr';

const fetcher = (url: string) =>
  apiClient.get(url);

function TaskList() {
  const { data, error, isLoading, mutate } = useSWR(
    '/api/tasks',
    fetcher,
    {
      revalidateOnFocus: true,   // 窗口聚焦时重新获取
      revalidateOnReconnect: true, // 断网重连时重新获取
      refreshInterval: 30000,     // 每 30 秒刷新
      dedupingInterval: 2000,     // 2 秒内去重
    }
  );

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  return <TaskTable tasks={data} />;
}
```

### 5.2 React Query (TanStack Query)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// 查询
function useTasks(filters?: TaskFilters) {
  return useQuery({
    queryKey: ['tasks', filters],
    queryFn: () => tasksApi.list(filters),
    staleTime: 5 * 60 * 1000,     // 5 分钟内认为数据新鲜
    gcTime: 10 * 60 * 1000,       // 10 分钟后清除缓存
    retry: 3,                       // 重试 3 次
    refetchOnWindowFocus: true,
  });
}

// 变更
function useCreateTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateTaskInput) => tasksApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
    },
  });
}
```

### 5.3 缓存策略对比

| 策略 | SWR | React Query |
|------|-----|-------------|
| 包大小 | ~4KB | ~13KB |
| 学习曲线 | 低 | 中 |
| 功能 | 基础缓存 | 完整方案 |
| 适用场景 | 简单应用 | 复杂应用 |

---

## 6. API Client 设计模式

### 6.1 Repository Pattern

将数据访问逻辑封装在 Repository 中:

```typescript
// Repository 层 - 处理 API 调用
class TaskRepository {
  async findAll(filters?: TaskFilters): Promise<Task[]> {
    const { data } = await apiClient.get<ApiResponse<Task[]>>('/tasks', {
      params: filters as Record<string, string>,
    });
    return data;
  }

  async findById(id: string): Promise<Task> {
    const { data } = await apiClient.get<ApiResponse<Task>>(`/tasks/${id}`);
    return data;
  }

  async create(input: CreateTaskInput): Promise<Task> {
    const { data } = await apiClient.post<ApiResponse<Task>>('/tasks', input);
    return data;
  }

  async update(id: string, input: UpdateTaskInput): Promise<Task> {
    const { data } = await apiClient.put<ApiResponse<Task>>(
      `/tasks/${id}`,
      input
    );
    return data;
  }

  async delete(id: string): Promise<void> {
    await apiClient.delete(`/tasks/${id}`);
  }
}

export const taskRepository = new TaskRepository();
```

### 6.2 Service Layer

Service 层组合 Repository 和业务逻辑:

```typescript
class TaskService {
  constructor(private repository: TaskRepository) {}

  async getDashboardTasks() {
    const tasks = await this.repository.findAll();
    return {
      todo: tasks.filter((t) => t.status === 'todo'),
      inProgress: tasks.filter((t) => t.status === 'in_progress'),
      done: tasks.filter((t) => t.status === 'done'),
      highPriority: tasks.filter(
        (t) => t.priority === 'high' && t.status !== 'done'
      ),
    };
  }

  async moveToNextStage(taskId: string) {
    const task = await this.repository.findById(taskId);
    const nextStatus: Record<string, TaskStatus> = {
      todo: 'in_progress',
      in_progress: 'done',
      done: 'todo',
    };
    return this.repository.update(taskId, {
      status: nextStatus[task.status],
    });
  }
}

export const taskService = new TaskService(taskRepository);
```

### 6.3 分层架构

```
┌─────────────────────────────┐
│        UI Components        │  ← React 组件
├─────────────────────────────┤
│          Hooks              │  ← useQuery, 自定义 hooks
├─────────────────────────────┤
│        Service Layer        │  ← 业务逻辑
├─────────────────────────────┤
│       Repository Layer      │  ← 数据访问
├─────────────────────────────┤
│        API Client           │  ← HTTP 请求
├─────────────────────────────┤
│      Express Backend        │  ← 后端 API
└─────────────────────────────┘
```

---

## 7. 微服务 API 网关

### 7.1 什么是 API 网关

```
                    ┌─────────────────┐
                    │   API Gateway   │
Client ───────────→ │  /auth/*  ──────→ Auth Service
                    │  /tasks/* ──────→ Task Service
                    │  /users/* ──────→ User Service
                    └─────────────────┘
```

### 7.2 网关职责

- **路由**: 将请求分发到对应微服务
- **认证**: 统一的 JWT 验证
- **限流**: 防止 API 被滥用
- **日志**: 统一的请求日志
- **缓存**: 减少后端压力
- **转换**: 请求/响应格式转换

### 7.3 常见网关方案

| 方案 | 特点 |
|------|------|
| **Nginx** | 轻量, 高性能 |
| **Kong** | 功能丰富, 插件生态 |
| **Express Gateway** | Node.js 生态 |
| **AWS API Gateway** | 云托管, Serverless |

### 7.4 前端对接网关

前端通常只和网关通信, 不直接调用微服务:

```typescript
// 前端只配置网关地址
const apiClient = new ApiClient('https://api.example.com');

// 网关负责路由到正确的微服务
// GET /api/tasks → Task Service
// POST /api/auth/login → Auth Service
```

---

## 8. 最佳实践总结

### 8.1 API 客户端

- ✅ 使用 TypeScript 泛型确保类型安全
- ✅ 统一错误处理和错误格式
- ✅ Token 自动管理和刷新
- ✅ 请求超时和重试机制
- ✅ 拦截器用于日志、认证等

### 8.2 状态管理

- ✅ 区分 loading / error / success 状态
- ✅ 使用乐观更新提升用户体验
- ✅ 缓存策略减少不必要的请求

### 8.3 错误处理

- ✅ 区分网络错误和业务错误
- ✅ 用户友好的错误消息
- ✅ 自动重试 (幂等请求)

---

## 9. 项目中的实现

```
src/lib/
└── api-client.ts
    ├── TokenManager        ← Token 存储和管理
    ├── ApiClient           ← 核心 HTTP 客户端
    │   ├── get/post/put/delete  ← HTTP 方法
    │   ├── Request Interceptors ← 请求拦截
    │   └── Response Interceptors ← 响应拦截
    ├── authApi             ← 认证相关 API
    └── tasksApi            ← 任务相关 API
```

---

## 10. 今日练习

1. ✅ 实现 API 客户端 (src/lib/api-client.ts)
2. 🔄 在组件中使用 api-client
3. 🔄 添加请求/响应拦截器
4. 🔄 实现 SWR 或 React Query 缓存

---

## 明日计划

- Day 20: 前端测试 - React 组件测试、Hook 测试
