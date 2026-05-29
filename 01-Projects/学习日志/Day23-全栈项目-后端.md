---
tags: [project, backend, api, day23]
created: 2026-05-30
day: 23
---

# Day 23: 后端 API 开发记录

## 今日目标

搭建 Knowledge Hub 的后端 API 服务，使用 Express + Prisma + JWT 技术栈。

## 技术栈选择

- **Express.js**: 轻量级 Web 框架
- **Prisma**: 现代化 ORM
- **JWT**: 身份认证
- **Zod**: 数据验证
- **bcryptjs**: 密码加密

## 数据库设计

### 数据模型

```
User
├── id (主键)
├── email (唯一)
├── name
├── avatar
├── bio
└── createdAt

Article
├── id (主键)
├── title
├── content
├── excerpt
├── status (draft/published)
├── viewCount
├── createdAt
└── updatedAt

Category
├── id (主键)
├── name
├── slug (唯一)
└── description

Tag
├── id (主键)
├── name
└── slug (唯一)

ArticleTag (多对多关联)
├── articleId
└── tagId

ArticleLike (用户-文章唯一关联)
├── userId
└── articleId

Bookmark (用户-文章唯一关联)
├── userId
└── articleId
```

### 关系设计

- User 1:N Article (一对多)
- Category 1:N Article (一对多)
- Article N:M Tag (多对多，通过 ArticleTag)
- User N:M Article (通过 ArticleLike 和 Bookmark)

## API 端点设计

### 认证模块 (/api/auth)

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /register | 用户注册 |
| POST | /login | 用户登录 |
| POST | /refresh | 刷新令牌 |
| GET | /profile | 获取用户信息 |

### 文章模块 (/api/articles)

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | / | 获取文章列表（分页、搜索、筛选） |
| GET | /:id | 获取单篇文章 |
| POST | / | 创建文章 |
| PUT | /:id | 更新文章 |
| DELETE | /:id | 删除文章 |
| POST | /:id/like | 点赞文章 |
| POST | /:id/bookmark | 收藏文章 |

### 分类模块 (/api/categories)

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | / | 获取分类列表 |
| POST | / | 创建分类 |
| PUT | /:id | 更新分类 |
| DELETE | /:id | 删除分类 |

### 标签模块 (/api/tags)

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | / | 获取标签列表 |

### 统计模块 (/api/stats)

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /dashboard | 获取仪表盘统计数据 |

## 中间件设计

### 认证中间件 (auth.ts)

```typescript
// JWT 令牌验证
// 从 Authorization header 提取 token
// 验证 token 有效性
// 将用户信息附加到 request 对象
```

### 验证中间件 (validate.ts)

```typescript
// 使用 Zod schema 验证请求数据
// 支持 body、query、params 验证
// 返回格式化错误信息
```

### 错误处理中间件 (error-handler.ts)

```typescript
// 统一错误处理
// 区分业务错误和系统错误
// 返回标准错误响应格式
```

## 项目结构

```
knowledge-hub-api/
├── prisma/
│   ├── schema.prisma    # 数据库模型定义
│   └── seed.ts          # 种子数据
├── src/
│   ├── routes/
│   │   ├── auth.ts      # 认证路由
│   │   ├── articles.ts  # 文章路由
│   │   ├── categories.ts # 分类路由
│   │   ├── tags.ts      # 标签路由
│   │   └── stats.ts     # 统计路由
│   ├── middleware/
│   │   ├── auth.ts      # 认证中间件
│   │   ├── validate.ts  # 验证中间件
│   │   └── error-handler.ts # 错误处理
│   └── utils/
│       └── prisma.ts    # Prisma 客户端
├── package.json
├── tsconfig.json
└── .env
```

## 数据库迁移

使用 Prisma 进行数据库迁移：

```bash
# 创建迁移
npx prisma migrate dev --name init

# 应用迁移
npx prisma migrate deploy

# 生成客户端
npx prisma generate
```

## 种子数据

创建示例数据用于开发和测试：

- 管理员用户
- 示例分类（技术、生活、学习）
- 示例标签（JavaScript、TypeScript、React）
- 示例文章

## 今日收获

1. 设计了完整的数据库模型
2. 规划了 RESTful API 端点
3. 实现了认证和授权机制
4. 使用 Prisma 进行数据库迁移
5. 创建了种子数据用于开发

## 遇到的问题

- 数据库关系设计需要考虑查询性能
- JWT 令牌刷新机制需要仔细设计
- 分页和搜索功能需要优化

## 明日计划

- 前后端联调
- 数据获取和缓存策略
- 表单处理和验证
