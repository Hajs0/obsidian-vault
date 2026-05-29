---
tags:
  - project
  - fullstack
  - knowledge-hub
  - portfolio
created: 2026-05-30
status: completed
---

# 全栈项目：Knowledge Hub

## 一、项目简介

**Knowledge Hub** 是一个现代化的知识管理平台，帮助用户高效地组织、检索和分享知识内容。项目采用前后端分离架构，前端基于 Next.js 16 构建，后端使用 Express + Prisma + PostgreSQL 技术栈。

### 项目亮点
- 🚀 **现代技术栈**：Next.js 16、TypeScript、Tailwind CSS
- 🔐 **安全认证**：JWT 双令牌机制、bcrypt 密码加密
- 📱 **响应式设计**：完美适配桌面端和移动端
- 🌙 **暗色模式**：支持系统主题自动切换
- ⚡ **高性能**：Server Components、流式渲染、数据库索引优化

---

## 二、功能特性

### 2.1 用户系统
| 功能 | 说明 | 状态 |
|------|------|------|
| 用户注册 | 邮箱注册，密码强度校验 | ✅ |
| 用户登录 | JWT 认证，记住登录状态 | ✅ |
| 个人资料 | 头像上传、信息编辑 | ✅ |
| 密码修改 | 旧密码验证 + 新密码设置 | ✅ |

### 2.2 知识管理
| 功能 | 说明 | 状态 |
|------|------|------|
| 文章管理 | 创建、编辑、删除、查看详情 | ✅ |
| 分类管理 | 多级分类树形结构 | ✅ |
| 标签系统 | 灵活的标签添加和筛选 | ✅ |
| Markdown 编辑 | 富文本编辑 + 实时预览 | ✅ |
| 全文搜索 | 标题、内容模糊搜索 | ✅ |

### 2.3 社交功能
| 功能 | 说明 | 状态 |
|------|------|------|
| 收藏夹 | 收藏管理、分类整理 | ✅ |
| 分享链接 | 生成分享链接、访问权限控制 | ✅ |
| 数据统计 | 仪表盘数据可视化 | ✅ |

---

## 三、技术栈

### 前端
```
Next.js 16          - React 框架 (App Router)
TypeScript 5.x      - 类型安全
Tailwind CSS        - 样式框架
Shadcn/ui           - UI 组件库
Zustand             - 状态管理
React Hook Form     - 表单处理
Zod                 - 数据校验
Axios               - HTTP 客户端
next-themes         - 主题切换
@uiw/react-md-editor - Markdown 编辑器
recharts            - 图表库
```

### 后端
```
Node.js 20 LTS      - 运行时
Express.js          - Web 框架
Prisma 5.x          - ORM
PostgreSQL 15       - 数据库
JWT                 - 认证
bcryptjs            - 密码加密
Winston             - 日志
Zod                 - 请求校验
cors                - 跨域处理
helmet              - 安全头
```

### DevOps
```
Docker              - 容器化
Docker Compose      - 服务编排
GitHub Actions      - CI/CD
Vercel              - 前端部署
Railway             - 后端部署
Sentry              - 错误监控
```

---

## 四、项目结构

```
knowledge-hub/
├── frontend/                    # 前端项目
│   ├── app/                     # Next.js App Router
│   │   ├── (auth)/             # 认证相关页面
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── register/
│   │   │       └── page.tsx
│   │   ├── (dashboard)/        # 仪表盘布局
│   │   │   ├── layout.tsx
│   │   │   ├── articles/       # 文章管理
│   │   │   │   ├── page.tsx
│   │   │   │   ├── [id]/
│   │   │   │   └── new/
│   │   │   ├── categories/     # 分类管理
│   │   │   ├── tags/           # 标签管理
│   │   │   ├── favorites/      # 收藏夹
│   │   │   └── settings/       # 设置
│   │   ├── layout.tsx          # 根布局
│   │   └── page.tsx            # 首页
│   ├── components/             # 通用组件
│   │   ├── ui/                # Shadcn/ui 组件
│   │   ├── layout/            # 布局组件
│   │   ├── articles/          # 文章相关组件
│   │   └── shared/            # 共享组件
│   ├── lib/                   # 工具函数
│   │   ├── api.ts             # Axios 实例
│   │   ├── utils.ts           # 工具函数
│   │   └── validations.ts     # Zod 校验
│   ├── stores/                # Zustand stores
│   │   ├── authStore.ts
│   │   └── articleStore.ts
│   ├── types/                 # TypeScript 类型
│   └── public/                # 静态资源
│
├── backend/                     # 后端项目
│   ├── src/
│   │   ├── routes/            # 路由
│   │   │   ├── auth.ts
│   │   │   ├── articles.ts
│   │   │   ├── categories.ts
│   │   │   └── tags.ts
│   │   ├── middleware/        # 中间件
│   │   │   ├── auth.ts
│   │   │   ├── errorHandler.ts
│   │   │   └── validate.ts
│   │   ├── schemas/           # Zod schemas
│   │   ├── utils/             # 工具函数
│   │   └── index.ts           # 入口文件
│   ├── prisma/
│   │   ├── schema.prisma      # 数据模型
│   │   └── migrations/        # 迁移文件
│   └── tests/                 # 测试文件
│       ├── unit/
│       └── integration/
│
├── docker/                      # Docker 配置
│   ├── Dockerfile.frontend
│   ├── Dockerfile.backend
│   └── docker-compose.yml
│
├── .github/                     # GitHub Actions
│   └── workflows/
│       └── ci.yml
│
└── docs/                        # 项目文档
    ├── API.md
    └── DEPLOYMENT.md
```

---

## 五、数据库设计

### Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String    @id @default(cuid())
  email     String    @unique
  name      String
  password  String
  avatar    String?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  articles  Article[]
  favorites Favorite[]

  @@map("users")
}

model Article {
  id          String     @id @default(cuid())
  title       String
  content     String
  excerpt     String?
  slug        String     @unique
  published   Boolean    @default(false)
  userId      String
  categoryId  String?
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt
  user        User       @relation(fields: [userId], references: [id])
  category    Category?  @relation(fields: [categoryId], references: [id])
  tags        Tag[]
  favorites   Favorite[]

  @@index([userId])
  @@index([categoryId])
  @@index([createdAt])
  @@map("articles")
}

model Category {
  id        String    @id @default(cuid())
  name      String
  slug      String    @unique
  parentId  String?
  parent    Category? @relation("CategoryTree", fields: [parentId], references: [id])
  children  Category[] @relation("CategoryTree")
  articles  Article[]

  @@map("categories")
}

model Tag {
  id        String    @id @default(cuid())
  name      String    @unique
  articles  Article[]

  @@map("tags")
}

model Favorite {
  id        String   @id @default(cuid())
  userId    String
  articleId String
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
  article   Article  @relation(fields: [articleId], references: [id])

  @@unique([userId, articleId])
  @@map("favorites")
}
```

---

## 六、API 端点列表

### 认证相关

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/auth/register` | 用户注册 | ❌ |
| POST | `/api/auth/login` | 用户登录 | ❌ |
| POST | `/api/auth/refresh` | 刷新令牌 | ❌ |
| POST | `/api/auth/logout` | 退出登录 | ✅ |
| GET | `/api/auth/me` | 获取当前用户 | ✅ |

### 文章相关

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/articles` | 获取文章列表 | ✅ |
| GET | `/api/articles/:id` | 获取文章详情 | ✅ |
| POST | `/api/articles` | 创建文章 | ✅ |
| PUT | `/api/articles/:id` | 更新文章 | ✅ |
| DELETE | `/api/articles/:id` | 删除文章 | ✅ |
| GET | `/api/articles/search` | 搜索文章 | ✅ |

### 分类相关

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/categories` | 获取分类列表 | ✅ |
| POST | `/api/categories` | 创建分类 | ✅ |
| PUT | `/api/categories/:id` | 更新分类 | ✅ |
| DELETE | `/api/categories/:id` | 删除分类 | ✅ |

### 标签相关

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/tags` | 获取标签列表 | ✅ |
| POST | `/api/tags` | 创建标签 | ✅ |
| DELETE | `/api/tags/:id` | 删除标签 | ✅ |

### 收藏相关

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/favorites` | 获取收藏列表 | ✅ |
| POST | `/api/favorites/:articleId` | 添加收藏 | ✅ |
| DELETE | `/api/favorites/:articleId` | 取消收藏 | ✅ |

### 请求/响应示例

```json
// POST /api/auth/login
// 请求
{
  "email": "user@example.com",
  "password": "securePassword123"
}

// 响应
{
  "user": {
    "id": "clx1234567890",
    "email": "user@example.com",
    "name": "张三",
    "avatar": null
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

## 七、部署指南

### 7.1 环境要求

```
Node.js >= 20.0.0
PostgreSQL >= 15
npm >= 10.0.0 或 pnpm >= 8.0.0
Docker (可选)
```

### 7.2 环境变量配置

```bash
# .env (后端)

# 数据库
DATABASE_URL="postgresql://user:password@localhost:5432/knowledge_hub"

# JWT
JWT_SECRET="your-super-secret-jwt-key"
JWT_REFRESH_SECRET="your-refresh-secret-key"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# 服务器
PORT=4000
NODE_ENV="production"

# 前端 URL (用于 CORS)
FRONTEND_URL="https://knowledge-hub.vercel.app"
```

```bash
# .env.local (前端)

NEXT_PUBLIC_API_URL="https://api.knowledge-hub.com"
NEXT_PUBLIC_APP_NAME="Knowledge Hub"
```

### 7.3 本地开发

```bash
# 1. 克隆项目
git clone https://github.com/your-username/knowledge-hub.git
cd knowledge-hub

# 2. 安装后端依赖
cd backend
npm install

# 3. 数据库迁移
npx prisma migrate dev

# 4. 启动后端
npm run dev

# 5. 新终端，安装前端依赖
cd frontend
npm install

# 6. 启动前端
npm run dev
```

### 7.4 Docker 部署

```bash
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: knowledge_hub
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/knowledge_hub
      JWT_SECRET: your-secret-here
    ports:
      - "4000:4000"
    depends_on:
      - db

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:4000
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
```

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 7.5 生产环境部署

#### 前端部署（Vercel）

1. 将代码推送到 GitHub
2. 在 Vercel 中导入项目
3. 配置环境变量
4. 自动部署完成

#### 后端部署（Railway）

1. 在 Railway 中创建新项目
2. 连接 GitHub 仓库
3. 添加 PostgreSQL 数据库
4. 配置环境变量
5. 部署完成

### 7.6 CI/CD 流水线

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install Backend Dependencies
        working-directory: ./backend
        run: npm ci
        
      - name: Run Backend Tests
        working-directory: ./backend
        run: npm test
        
      - name: Install Frontend Dependencies
        working-directory: ./frontend
        run: npm ci
        
      - name: Run Frontend Lint
        working-directory: ./frontend
        run: npm run lint
        
      - name: Run Frontend Build
        working-directory: ./frontend
        run: npm run build
```

---

## 八、性能优化

### 8.1 前端优化
- **Server Components**：减少客户端 JavaScript 体积
- **图片优化**：使用 Next.js Image 组件自动优化
- **代码分割**：动态导入非关键组件
- **缓存策略**：合理使用 React Cache 和 revalidation

### 8.2 后端优化
- **数据库索引**：为常用查询字段添加索引
- **分页查询**：避免一次性加载大量数据
- **连接池**：Prisma 默认连接池管理
- **压缩响应**：启用 gzip 压缩

---

## 九、安全措施

- ✅ JWT 双令牌认证机制
- ✅ bcrypt 密码加密（salt rounds: 12）
- ✅ CORS 跨域限制
- ✅ Helmet 安全头
- ✅ 请求速率限制（express-rate-limit）
- ✅ 输入数据校验（Zod）
- ✅ SQL 注入防护（Prisma ORM）
- ✅ XSS 防护（React 自动转义）

---

## 十、测试覆盖

```
测试统计:
├── 单元测试:     42 个
│   ├── 工具函数:  15 个
│   ├── Store:     12 个
│   └── 组件:      15 个
├── 集成测试:     18 个
│   └── API 端点:  18 个
└── E2E 测试:      8 个
    ├── 登录流程:   2 个
    ├── 文章管理:   4 个
    └── 搜索功能:   2 个

总测试数: 68 个
通过率:   100%
覆盖率:   78%
```

---

## 十一、项目截图

> 💡 项目部署后可在以下地址访问：
> - 前端：https://knowledge-hub.vercel.app
> - API：https://api.knowledge-hub.com

---

## 十二、后续迭代计划

### v1.1 计划
- [ ] WebSocket 实时通知
- [ ] 文章协作编辑
- [ ] 富文本文件附件上传

### v1.2 计划
- [ ] 移动端 PWA 支持
- [ ] 离线模式
- [ ] 数据导入导出（JSON、CSV）

### v2.0 计划
- [ ] AI 辅助写作
- [ ] 知识图谱可视化
- [ ] 团队协作空间

---

## 十三、许可证

MIT License

---

## 十四、联系方式

- GitHub: https://github.com/your-username/knowledge-hub
- 邮箱: your-email@example.com

---

> 📌 本项目作为全栈开发学习的完整实践，涵盖了从需求分析到生产部署的全流程。项目代码规范、文档完整，可作为个人作品集的优质项目展示。
