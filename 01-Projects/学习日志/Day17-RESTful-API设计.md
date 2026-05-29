---
tags: [api, rest, authentication, jwt, day17]
created: 2026-05-30
day: 17
---

# 📡 Day 17：RESTful API 设计 + JWT 认证

## 🎯 今日目标
- 掌握 RESTful API 设计原则
- 实现 JWT 认证系统
- 学习 API 文档和安全

---

## 🔥 RESTful API 设计原则

### 1. 资源命名规范

| 规则 | ✅ 正确 | ❌ 错误 |
|------|---------|---------|
| 使用名词 | `/users` | `/getUsers` |
| 复数形式 | `/tasks` | `/task` |
| 层级关系 | `/users/123/tasks` | `/getUserTasks?userId=123` |
| 小写+连字符 | `/task-items` | `/taskItems` |

### 2. HTTP 方法语义

| 方法 | 语义 | 幂等 | 示例 |
|------|------|------|------|
| GET | 获取资源 | ✅ | `GET /api/tasks` |
| POST | 创建资源 | ❌ | `POST /api/tasks` |
| PUT | 全量更新 | ✅ | `PUT /api/tasks/1` |
| PATCH | 部分更新 | ✅ | `PATCH /api/tasks/1` |
| DELETE | 删除资源 | ✅ | `DELETE /api/tasks/1` |

### 3. 状态码规范

```
2xx 成功:
  200 OK — GET/PUT/PATCH 成功
  201 Created — POST 创建成功
  204 No Content — DELETE 成功

4xx 客户端错误:
  400 Bad Request — 参数验证失败
  401 Unauthorized — 未认证
  403 Forbidden — 无权限
  404 Not Found — 资源不存在
  409 Conflict — 冲突（如重复创建）
  422 Unprocessable Entity — 业务逻辑错误
  429 Too Many Requests — 限流

5xx 服务端错误:
  500 Internal Server Error — 服务器异常
  502 Bad Gateway — 网关错误
  503 Service Unavailable — 服务不可用
```

### 4. 分页/过滤/排序

```typescript
// 分页
GET /api/tasks?page=1&limit=20

// 过滤
GET /api/tasks?status=todo&priority=high

// 排序
GET /api/tasks?sortBy=createdAt&order=desc

// 搜索
GET /api/tasks?search=keyword

// 响应格式
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

## 🔐 JWT 认证

### 1. JWT 结构

```
xxxxx.yyyyy.zzzzz
  |       |       |
  |       |       └─ 签名 (HMAC SHA256)
  |       └─ 载荷 (用户信息, 过期时间)
  └─ 头部 (算法, 类型)
```

### 2. Access Token + Refresh Token 模式

```
登录流程:
1. 用户提交 email + password
2. 服务端验证密码 (bcrypt.compare)
3. 返回 accessToken (15min) + refreshToken (7d)

请求流程:
1. 客户端携带 accessToken 请求 API
2. 服务端验证 token
3. 如果过期 → 客户端用 refreshToken 换新 token
4. refreshToken 也过期 → 重新登录
```

### 3. 密码安全 (bcrypt)

```typescript
import bcrypt from 'bcryptjs';

// 注册时哈希密码
const hashedPassword = await bcrypt.hash(password, 12); // salt rounds = 12

// 登录时验证
const isValid = await bcrypt.compare(password, hashedPassword);
```

### 4. 认证中间件

```typescript
export const requireAuth = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: '未认证' });
  
  try {
    const payload = jwt.verify(token, SECRET);
    req.user = payload;
    next();
  } catch {
    res.status(401).json({ error: 'Token 无效' });
  }
};
```

---

## 📊 REST vs GraphQL vs gRPC

| 特性 | REST | GraphQL | gRPC |
|------|------|---------|------|
| 协议 | HTTP | HTTP | HTTP/2 |
| 数据格式 | JSON | JSON | Protobuf |
| 灵活性 | 固定 | 按需查询 | 固定 |
| 学习曲线 | 低 | 中 | 高 |
| 适用场景 | CRUD | 复杂查询 | 微服务 |

---

## 💡 最佳实践

### API 设计清单
- [ ] 使用名词复数命名资源
- [ ] 正确使用 HTTP 方法
- [ ] 返回合适的状态码
- [ ] 实现分页（避免返回大量数据）
- [ ] 版本管理 (`/api/v1/`)
- [ ] 错误响应格式统一
- [ ] 请求/响应验证 (zod)
- [ ] 认证和授权
- [ ] Rate Limiting
- [ ] CORS 配置
- [ ] API 文档 (Swagger)

### 错误响应格式

```typescript
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数无效",
    "details": [
      { "field": "email", "message": "邮箱格式不正确" }
    ]
  }
}
```

---

## 🔗 关联知识
- Day 10: Server Actions（另一种 API 方式）
- Day 15: Express 进阶
- Day 16: 数据库操作（Prisma）

## ✅ 今日产出
- RESTful API 设计规范笔记
- JWT 认证系统实现
- 认证中间件
- API 文档

---

*REST 是一种架构风格，不是标准。理解其核心思想比遵循规则更重要。*
