# Day6 - 数据库设计与 Prisma ORM

> 📅 日期：2026-05-29
> 🏷️ 标签：#数据库 #Prisma #ORM #后端开发

---

## 1. 数据库设计原则

### 1.1 范式化设计（Normalization）

| 范式 | 规则 | 示例 |
|------|------|------|
| **1NF** | 字段原子性，不可再分 | 地址拆分为省、市、区 |
| **2NF** | 消除部分依赖（非主键字段完全依赖主键） | 订单表不应存储客户姓名 |
| **3NF** | 消除传递依赖（非主键字段不能相互依赖） | 学生表不存储系主任名 |

### 1.2 设计核心原则

```
✅ 命名规范
   - 表名：复数、小写下划线（users, order_items）
   - 字段名：小写下划线（created_at, user_id）
   - 主键：统一用 id（自增或 UUID）
   - 外键：表名_id（user_id, post_id）

✅ 每张表必备字段
   id        - 主键
   created_at - 创建时间
   updated_at - 更新时间

✅ 选择合适的数据类型
   - 枚举值用 enum
   - 金额用 Decimal，不用 Float
   - 手机号用 String，不用 BigInt

✅ 索引策略
   - 查询频繁的字段加索引
   - 外键字段加索引
   - 避免过度索引（影响写入性能）
```

### 1.3 反范式化（适度冗余）

```
场景：查询用户时经常需要统计帖子数量
方案：在 users 表中增加 post_count 字段，由应用层维护

权衡：读性能 ↑ vs 写复杂度 ↑
```

---

## 2. Prisma Schema 定义

### 2.1 基本结构

```prisma
// prisma/schema.prisma

// 数据源配置
datasource db {
  provider = "postgresql"  // 支持 postgresql, mysql, sqlite, sqlserver, mongodb
  url      = env("DATABASE_URL")
}

// 生成器配置
generator client {
  provider = "prisma-client-js"
}
```

### 2.2 模型定义

```prisma
// 用户模型
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  role      Role     @default(USER)
  posts     Post[]           // 一对多关系
  profile   Profile?         // 一对一关系
  tags      Tag[]            // 多对多关系（隐式中间表）
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")             // 映射到数据库表名
  @@index([email])           // 复合索引
}

// 帖子模型
model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  comments  Comment[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([authorId])
}

// 枚举类型
enum Role {
  USER
  ADMIN
  MODERATOR
}
```

### 2.3 字段属性速查

```
@id              - 主键
@default(value)  - 默认值（cuid(), uuid(), autoincrement(), now()）
@unique          - 唯一约束
@db.Text         - 数据库类型映射
@map("col_name") - 映射列名
@relation(...)   - 关系定义
```

---

## 3. CRUD 操作

### 3.1 初始化 Prisma Client

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],  // 日志级别
})
```

### 3.2 Create（创建）

```typescript
// 创建单条记录
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
  },
})

// 创建并关联记录（嵌套写入）
const userWithPosts = await prisma.user.create({
  data: {
    email: 'bob@example.com',
    name: 'Bob',
    posts: {
      create: [
        { title: '第一篇文章', content: 'Hello World' },
        { title: '第二篇文章', content: 'Prisma is great' },
      ],
    },
  },
  include: { posts: true },  // 返回关联数据
})

// 批量创建
const count = await prisma.user.createMany({
  data: [
    { email: 'user1@test.com', name: 'User1' },
    { email: 'user2@test.com', name: 'User2' },
  ],
  skipDuplicates: true,  // 跳过重复
})
```

### 3.3 Read（查询）

```typescript
// 查找单个（by ID）
const user = await prisma.user.findUnique({
  where: { id: 'some-id' },
})

// 查找多个
const users = await prisma.user.findMany({
  where: {
    role: 'USER',
    name: { contains: 'Ali', mode: 'insensitive' },
  },
  orderBy: { createdAt: 'desc' },
  take: 10,   // LIMIT
  skip: 0,    // OFFSET
})

// 分页查询
const page = 2
const pageSize = 20
const users = await prisma.user.findMany({
  skip: (page - 1) * pageSize,
  take: pageSize,
})

// 聚合查询
const stats = await prisma.post.aggregate({
  _count: true,
  _avg: { id: true },
  where: { published: true },
})

// 分组统计
const grouped = await prisma.post.groupBy({
  by: ['authorId'],
  _count: true,
  having: { authorId: { _count: { gt: 5 } } },
})
```

### 3.4 Update（更新）

```typescript
// 更新单条
const user = await prisma.user.update({
  where: { id: 'some-id' },
  data: { name: 'Alice Updated' },
})

// 更新多条
const count = await prisma.user.updateMany({
  where: { role: 'USER' },
  data: { role: 'MODERATOR' },
})

// 原子操作（自增/自减）
await prisma.post.update({
  where: { id: 'post-id' },
  data: { viewCount: { increment: 1 } },
  // 支持：increment, decrement, set, multiply, divide
})

// Upsert（存在更新，不存在创建）
const user = await prisma.user.upsert({
  where: { email: 'alice@example.com' },
  update: { name: 'Alice v2' },
  create: { email: 'alice@example.com', name: 'Alice' },
})
```

### 3.5 Delete（删除）

```typescript
// 删除单条
await prisma.user.delete({
  where: { id: 'some-id' },
})

// 删除多条
const count = await prisma.user.deleteMany({
  where: { role: 'USER' },
})
```

---

## 4. 关系查询

### 4.1 关系类型定义

```prisma
// 一对一
model User {
  id      String   @id @default(cuid())
  profile Profile?
}
model Profile {
  id     String @id @default(cuid())
  bio    String?
  user   User   @relation(fields: [userId], references: [id])
  userId String @unique  // 一对一：必须加 @unique
}

// 一对多
model User {
  id    String @id @default(cuid())
  posts Post[]
}
model Post {
  id       String @id @default(cuid())
  author   User   @relation(fields: [authorId], references: [id])
  authorId String
}

// 多对多（隐式中间表）
model Post {
  id   String @id @default(cuid())
  tags Tag[]
}
model Tag {
  id    String @id @default(cuid())
  name  String @unique
  posts Post[]
}

// 多对多（显式中间表 - 可加额外字段）
model Post {
  id       String       @id @default(cuid())
  tags     PostTag[]
}
model Tag {
  id       String       @id @default(cuid())
  posts    PostTag[]
}
model PostTag {
  post     Post   @relation(fields: [postId], references: [id])
  postId   String
  tag      Tag    @relation(fields: [tagId], references: [id])
  tagId    String
  assignedAt DateTime @default(now())  // 额外字段

  @@id([postId, tagId])  // 复合主键
}
```

### 4.2 关系查询 API

```typescript
// Include：加载关联数据
const userWithPosts = await prisma.user.findUnique({
  where: { id: 'some-id' },
  include: {
    posts: true,
    profile: true,
    _count: { select: { posts: true } },
  },
})

// Select：精确选择字段
const user = await prisma.user.findUnique({
  where: { id: 'some-id' },
  select: {
    id: true,
    name: true,
    posts: {
      where: { published: true },
      select: { id: true, title: true },
      orderBy: { createdAt: 'desc' },
      take: 5,
    },
  },
})

// 嵌套过滤
const users = await prisma.user.findMany({
  where: {
    posts: {
      some: { published: true, title: { contains: 'Prisma' } },
      // some: 至少一个匹配
      // every: 全部匹配
      // none: 没有一个匹配
    },
  },
})
```

---

## 5. 数据迁移

### 5.1 迁移工作流

```bash
# 1. 初始化 Prisma
npx prisma init

# 2. 创建迁移（修改 schema 后）
npx prisma migrate dev --name add_user_bio
# 生成 SQL -> 执行迁移 -> 重新生成 Client

# 3. 应用到生产环境
npx prisma migrate deploy

# 4. 查看迁移状态
npx prisma migrate status

# 5. 重置数据库（⚠️ 会清空数据）
npx prisma migrate reset
```

### 5.2 迁移文件结构

```
prisma/
├── schema.prisma
└── migrations/
    ├── 20260529_init/
    │   └── migration.sql
    ├── 20260529_add_user_bio/
    │   └── migration.sql
    └── migration_lock.toml
```

### 5.3 Prisma Studio（可视化）

```bash
# 打开浏览器可视化管理数据
npx prisma studio
```

### 5.4 种子数据

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
  await prisma.user.createMany({
    data: [
      { email: 'admin@test.com', name: 'Admin', role: 'ADMIN' },
      { email: 'user@test.com', name: 'User', role: 'USER' },
    ],
  })
}

main().finally(() => prisma.$disconnect())
```

```json
// package.json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

```bash
npx prisma db seed
```

---

## 6. 实战：博客系统完整示例

```prisma
// schema.prisma - 博客系统
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        String    @id @default(cuid())
  email     String    @unique
  name      String?
  avatar    String?
  role      Role      @default(USER)
  posts     Post[]
  comments  Comment[]
  profile   Profile?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt

  @@map("users")
}

model Profile {
  id     String  @id @default(cuid())
  bio    String?
  user   User    @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId String  @unique

  @@map("profiles")
}

model Post {
  id          String    @id @default(cuid())
  title       String
  slug        String    @unique
  content     String?   @db.Text
  published   Boolean   @default(false)
  publishedAt DateTime?
  author      User      @relation(fields: [authorId], references: [id])
  authorId    String
  comments    Comment[]
  tags        Tag[]
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  @@index([authorId])
  @@index([published])
  @@index([slug])
  @@map("posts")
}

model Comment {
  id        String   @id @default(cuid())
  content   String
  post      Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  postId    String
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())

  @@index([postId])
  @@map("comments")
}

model Tag {
  id    String @id @default(cuid())
  name  String @unique
  posts Post[]

  @@map("tags")
}

enum Role {
  USER
  ADMIN
  MODERATOR
}
```

---

## 7. 最佳实践速记

```
🔒 安全
   - 永远用环境变量存 DATABASE_URL
   - 生产环境禁用 prisma migrate reset
   - 使用中间件做软删除

⚡ 性能
   - 用 select 代替 include 减少数据传输
   - 批量操作用 createMany/updateMany
   - 避免 N+1：用 include 或 dataloader

🧪 测试
   - 测试环境用 SQLite
   - 每次测试前重置数据库
   - 用工厂函数生成测试数据
```

---

## 明日计划

- [ ] 实战练习：搭建一个完整的博客 API
- [ ] 学习 Prisma 中间件（软删除、自动审计）
- [ ] 探索数据库事务（$transaction）
