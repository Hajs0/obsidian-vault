# Day 5 - 后端 API 设计最佳实践

> 📅 日期：2026-05-29
> 🏷️ 标签：#后端 #API #REST #Next.js #ServerActions

---

## 目录

- [[#1. RESTful API 设计原则]]
- [[#2. Next.js API Routes]]
- [[#3. Server Actions]]
- [[#4. 错误处理]]
- [[#5. 完整代码示例]]
- [[#6. 总结与实践建议]]

---

## 1. RESTful API 设计原则

### 1.1 什么是 REST？

REST（Representational State Transfer）是一种架构风格，用于设计网络应用的 API。

### 1.2 核心原则

| 原则 | 说明 |
|------|------|
| **无状态** | 每个请求包含所有必要信息，服务器不存储客户端状态 |
| **统一接口** | 使用标准的 HTTP 方法（GET/POST/PUT/PATCH/DELETE） |
| **资源导向** | URL 代表资源，HTTP 方法代表操作 |
| **可缓存** | 响应应明确是否可缓存 |
| **分层系统** | 客户端无需知道是否直连服务器 |

### 1.3 URL 设计规范

```bash
# ✅ 好的设计
GET    /api/users              # 获取用户列表
GET    /api/users/123          # 获取特定用户
POST   /api/users              # 创建用户
PUT    /api/users/123          # 完整更新用户
PATCH  /api/users/123          # 部分更新用户
DELETE /api/users/123          # 删除用户

# ❌ 避免的设计
GET    /api/getUsers           # 不要使用动词
POST   /api/deleteUser/123     # 应该用 DELETE 方法
GET    /api/users/123/posts    # 嵌套资源保持简洁
```

### 1.4 HTTP 状态码

```
2xx - 成功
├── 200 OK                    # 成功（GET/PUT/PATCH）
├── 201 Created               # 创建成功（POST）
└── 204 No Content            # 删除成功（DELETE）

4xx - 客户端错误
├── 400 Bad Request           # 请求格式错误
├── 401 Unauthorized          # 未认证
├── 403 Forbidden             # 无权限
├── 404 Not Found             # 资源不存在
└── 422 Unprocessable Entity  # 验证失败

5xx - 服务器错误
└── 500 Internal Server Error # 服务器内部错误
```

### 1.5 查询参数设计

```bash
# 分页
GET /api/users?page=1&limit=20

# 排序
GET /api/users?sort=createdAt&order=desc

# 过滤
GET /api/users?role=admin&status=active

# 搜索
GET /api/users?q=john

# 字段选择
GET /api/users?fields=id,name,email
```

---

## 2. Next.js API Routes

### 2.1 Route Handlers (App Router)

Next.js 13+ 使用 `route.ts` 文件定义 API 端点。

#### 基本结构

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

// GET /api/users
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');

  try {
    const users = await getUsers({ page, limit });
    return NextResponse.json({
      success: true,
      data: users,
      pagination: { page, limit, total: users.length }
    });
  } catch (error) {
    return NextResponse.json(
      { success: false, error: '获取用户失败' },
      { status: 500 }
    );
  }
}

// POST /api/users
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // 验证请求体
    if (!body.name || !body.email) {
      return NextResponse.json(
        { success: false, error: '缺少必要字段' },
        { status: 400 }
      );
    }

    const newUser = await createUser(body);
    return NextResponse.json(
      { success: true, data: newUser },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      { success: false, error: '创建用户失败' },
      { status: 500 }
    );
  }
}
```

#### 动态路由参数

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';

interface Params {
  params: Promise<{ id: string }>;
}

// GET /api/users/123
export async function GET(request: NextRequest, { params }: Params) {
  const { id } = await params;

  const user = await getUserById(id);
  if (!user) {
    return NextResponse.json(
      { success: false, error: '用户不存在' },
      { status: 404 }
    );
  }

  return NextResponse.json({ success: true, data: user });
}

// PATCH /api/users/123
export async function PATCH(request: NextRequest, { params }: Params) {
  const { id } = await params;
  const body = await request.json();

  const updatedUser = await updateUser(id, body);
  return NextResponse.json({ success: true, data: updatedUser });
}

// DELETE /api/users/123
export async function DELETE(request: NextRequest, { params }: Params) {
  const { id } = await params;
  await deleteUser(id);
  return new NextResponse(null, { status: 204 });
}
```

### 2.2 中间件认证

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  // 保护 API 路由
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const token = request.headers.get('Authorization');

    if (!token) {
      return NextResponse.json(
        { success: false, error: '未提供认证令牌' },
        { status: 401 }
      );
    }

    // 验证 token 逻辑...
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/api/:path*'],
};
```

---

## 3. Server Actions

### 3.1 什么是 Server Actions？

Server Actions 是 Next.js 13+ 引入的服务端函数，可以直接在组件中调用，无需手动创建 API 端点。

### 3.2 定义 Server Action

```typescript
// app/actions/user.ts
'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';

// 使用 Zod 进行验证
const UserSchema = z.object({
  name: z.string().min(2, '姓名至少 2 个字符'),
  email: z.string().email('邮箱格式不正确'),
  role: z.enum(['user', 'admin']).default('user'),
});

export type FormState = {
  success: boolean;
  message: string;
  errors?: Record<string, string[]>;
};

export async function createUserAction(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  // 1. 解析和验证数据
  const validatedFields = UserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
    role: formData.get('role'),
  });

  if (!validatedFields.success) {
    return {
      success: false,
      message: '验证失败',
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  try {
    // 2. 执行数据库操作
    await db.user.create({ data: validatedFields.data });

    // 3. 重新验证缓存
    revalidatePath('/users');

    return { success: true, message: '用户创建成功' };
  } catch (error) {
    return { success: false, message: '创建失败，请稍后重试' };
  }
}
```

### 3.3 在组件中使用

```tsx
// app/users/create/page.tsx
'use client';

import { useActionState } from 'react';
import { createUserAction, type FormState } from '@/app/actions/user';

const initialState: FormState = {
  success: false,
  message: '',
};

export default function CreateUserPage() {
  const [state, formAction, isPending] = useActionState(
    createUserAction,
    initialState
  );

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="name">姓名</label>
        <input id="name" name="name" required />
        {state.errors?.name && (
          <p className="text-red-500">{state.errors.name[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="email">邮箱</label>
        <input id="email" name="email" type="email" required />
        {state.errors?.email && (
          <p className="text-red-500">{state.errors.email[0]}</p>
        )}
      </div>

      <button type="submit" disabled={isPending}>
        {isPending ? '提交中...' : '创建用户'}
      </button>

      {state.message && (
        <p className={state.success ? 'text-green-500' : 'text-red-500'}>
          {state.message}
        </p>
      )}
    </form>
  );
}
```

### 3.4 Server Actions vs API Routes

| 特性 | Server Actions | API Routes |
|------|---------------|------------|
| 使用场景 | 表单提交、数据变更 | 复杂查询、第三方集成 |
| 类型安全 | ✅ 内置 | 需手动维护 |
| 缓存管理 | ✅ 自动 revalidate | 需手动处理 |
| 客户端调用 | 直接调用函数 | fetch/axios |
| 适用框架 | React 专属 | 通用 |

---

## 4. 错误处理

### 4.1 统一错误响应格式

```typescript
// lib/errors.ts
export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code?: string
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(404, `${resource}不存在`, 'NOT_FOUND');
  }
}

export class ValidationError extends AppError {
  constructor(public errors: Record<string, string[]>) {
    super(400, '验证失败', 'VALIDATION_ERROR');
  }
}

export class UnauthorizedError extends AppError {
  constructor() {
    super(401, '未授权访问', 'UNAUTHORIZED');
  }
}
```

### 4.2 全局错误处理器

```typescript
// lib/api-handler.ts
import { NextRequest, NextResponse } from 'next/server';
import { AppError, ValidationError } from './errors';

type Handler = (
  req: NextRequest,
  context?: any
) => Promise<NextResponse>;

export function apiHandler(handler: Handler): Handler {
  return async (req: NextRequest, context?: any) => {
    try {
      return await handler(req, context);
    } catch (error) {
      console.error('API Error:', error);

      if (error instanceof ValidationError) {
        return NextResponse.json(
          {
            success: false,
            error: error.message,
            code: error.code,
            errors: error.errors,
          },
          { status: error.statusCode }
        );
      }

      if (error instanceof AppError) {
        return NextResponse.json(
          {
            success: false,
            error: error.message,
            code: error.code,
          },
          { status: error.statusCode }
        );
      }

      // 未知错误
      return NextResponse.json(
        {
          success: false,
          error: '服务器内部错误',
          code: 'INTERNAL_ERROR',
        },
        { status: 500 }
      );
    }
  };
}
```

### 4.3 使用示例

```typescript
// app/api/users/route.ts
import { apiHandler } from '@/lib/api-handler';
import { NotFoundError, ValidationError } from '@/lib/errors';

export const GET = apiHandler(async (req) => {
  const users = await db.user.findMany();

  return NextResponse.json({
    success: true,
    data: users,
  });
});

export const POST = apiHandler(async (req) => {
  const body = await req.json();

  // 自动触发错误处理
  if (!body.email) {
    throw new ValidationError({ email: ['邮箱为必填项'] });
  }

  const user = await db.user.create({ data: body });

  return NextResponse.json(
    { success: true, data: user },
    { status: 201 }
  );
});
```

---

## 5. 完整代码示例

### 5.1 项目结构

```
src/
├── app/
│   ├── api/
│   │   └── users/
│   │       ├── route.ts          # GET /api/users, POST /api/users
│   │       └── [id]/
│   │           └── route.ts      # GET/PATCH/DELETE /api/users/:id
│   └── users/
│       └── page.tsx              # 用户页面
├── actions/
│   └── user.ts                   # Server Actions
├── lib/
│   ├── errors.ts                 # 错误类定义
│   ├── api-handler.ts            # API 错误处理包装器
│   └── db.ts                     # 数据库连接
└── middleware.ts                   # 认证中间件
```

### 5.2 完整的用户 API

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { apiHandler } from '@/lib/api-handler';
import { ValidationError, NotFoundError } from '@/lib/errors';
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  role: z.enum(['user', 'admin']).default('user'),
});

const QuerySchema = z.object({
  page: z.coerce.number().default(1),
  limit: z.coerce.number().min(1).max(100).default(20),
  sort: z.enum(['name', 'email', 'createdAt']).default('createdAt'),
  order: z.enum(['asc', 'desc']).default('desc'),
  q: z.string().optional(),
});

// GET /api/users
export const GET = apiHandler(async (req: NextRequest) => {
  const searchParams = Object.fromEntries(req.nextUrl.searchParams);
  const query = QuerySchema.parse(searchParams);

  const where = query.q
    ? {
        OR: [
          { name: { contains: query.q, mode: 'insensitive' } },
          { email: { contains: query.q, mode: 'insensitive' } },
        ],
      }
    : {};

  const [users, total] = await Promise.all([
    db.user.findMany({
      where,
      orderBy: { [query.sort]: query.order },
      skip: (query.page - 1) * query.limit,
      take: query.limit,
    }),
    db.user.count({ where }),
  ]);

  return NextResponse.json({
    success: true,
    data: users,
    pagination: {
      page: query.page,
      limit: query.limit,
      total,
      totalPages: Math.ceil(total / query.limit),
    },
  });
});

// POST /api/users
export const POST = apiHandler(async (req: NextRequest) => {
  const body = await req.json();
  const validatedData = CreateUserSchema.parse(body);

  // 检查邮箱是否已存在
  const existingUser = await db.user.findUnique({
    where: { email: validatedData.email },
  });

  if (existingUser) {
    throw new ValidationError({ email: ['该邮箱已被注册'] });
  }

  const user = await db.user.create({ data: validatedData });

  return NextResponse.json(
    { success: true, data: user },
    { status: 201 }
  );
});
```

### 5.3 响应格式规范

```typescript
// 统一响应格式
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  code?: string;
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

---

## 6. 总结与实践建议

### 核心要点

1. **RESTful 设计**：资源导向、正确使用 HTTP 方法和状态码
2. **Next.js API Routes**：适合第三方集成和复杂查询
3. **Server Actions**：适合表单提交和数据变更操作
4. **错误处理**：统一错误格式，使用自定义错误类
5. **输入验证**：使用 Zod 等库进行运行时验证

### 最佳实践 Checklist

- [ ] URL 使用名词复数形式（`/users` 而非 `/user`）
- [ ] 正确使用 HTTP 状态码
- [ ] 统一响应格式 `{ success, data, error }`
- [ ] 输入验证（客户端 + 服务端）
- [ ] 错误处理中间件
- [ ] 分页、排序、过滤支持
- [ ] API 版本管理（如 `/api/v1/users`）
- [ ] 请求限流（Rate Limiting）
- [ ] CORS 配置
- [ ] 日志记录

### 推荐资源

- [Next.js API Routes 文档](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- [Server Actions 文档](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- [RESTful API 设计指南](https://restfulapi.net/)

---

## 今日收获

- 掌握了 RESTful API 的设计原则和 URL 规范
- 学会了使用 Next.js Route Handlers 创建 API
- 理解了 Server Actions 的使用场景和优势
- 实现了统一的错误处理机制
- 建立了完整的 API 响应格式规范

> 💡 **关键洞察**：Server Actions 和 API Routes 各有优势，Server Actions 适合表单操作，API Routes 适合复杂查询和第三方集成。根据场景选择合适的方案。
