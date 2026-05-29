---
tags: [database, prisma, orm, sql, day16]
created: 2026-05-30
day: 16
---

# Day 16 - 数据库设计与 Prisma ORM 进阶

## 📚 学习目标

- 掌握数据库设计的进阶概念（范式化、索引、查询优化、事务）
- 熟练使用 Prisma ORM 的高级特性
- 理解不同数据库引擎的差异

---

## 一、数据库设计进阶

### 1.1 范式化 vs 反范式化

**范式化 (Normalization)** 的目标是消除数据冗余：

| 范式 | 要求 | 示例 |
|------|------|------|
| 1NF | 每列原子性，不可再分 | 地址拆分为省、市、区 |
| 2NF | 满足1NF + 非主键列完全依赖主键 | 拆分多对多关系为中间表 |
| 3NF | 满足2NF + 非主键列不传递依赖 | 学生表不包含系主任信息 |
| BCNF | 每个决定因素都是候选键 | 更严格的3NF |

**反范式化 (Denormalization)** 有意引入冗余来提升读取性能：

```sql
-- 范式化设计：需要 JOIN 查询
SELECT o.id, u.name, p.title, o.quantity
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN products p ON o.product_id = p.id;

-- 反范式化：订单表冗余用户名，避免 JOIN
-- orders 表增加 user_name 字段
SELECT id, user_name, product_title, quantity FROM orders;
```

**何时反范式化？**
- 读多写少的场景（如报表、仪表盘）
- 频繁 JOIN 影响性能
- 数据一致性要求相对宽松

### 1.2 索引设计

索引是提升查询性能的关键，但会降低写入速度。

**B-tree 索引**（最常用，PostgreSQL/MySQL/SQLite 默认）：
```sql
-- 适用于等值查询、范围查询、排序
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- 复合索引（注意列顺序！）
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
-- 查询时遵循最左前缀原则：
-- ✅ WHERE user_id = 1
-- ✅ WHERE user_id = 1 AND status = 'TODO'
-- ❌ WHERE status = 'TODO'  （无法使用此索引）
```

**Hash 索引**（仅等值查询，PostgreSQL 支持）：
```sql
-- 适用于精确匹配，不支持范围查询
CREATE INDEX idx_users_email ON users USING hash (email);
-- ✅ WHERE email = 'test@example.com'
-- ❌ WHERE email LIKE 'test%'
```

**GIN 索引**（通用倒排索引，PostgreSQL 支持）：
```sql
-- 适用于全文搜索、JSON、数组字段
CREATE INDEX idx_tasks_desc_gin ON tasks USING gin (to_tsvector('english', description));

-- 查询时使用：
SELECT * FROM tasks
WHERE to_tsvector('english', description) @@ to_tsquery('english', 'design & database');
```

**Prisma 中的索引定义**：
```prisma
model Task {
  id       Int    @id @default(autoincrement())
  title    String
  status   String
  userId   Int

  // 单字段索引
  @@index([status])
  // 复合索引
  @@index([userId, status])
  // 唯一索引
  @@unique([userId, title])
}
```

### 1.3 查询优化

**使用 EXPLAIN 分析查询计划**：
```sql
-- PostgreSQL
EXPLAIN ANALYZE
SELECT t.*, u.name
FROM tasks t
JOIN users u ON t.user_id = u.id
WHERE t.status = 'TODO'
ORDER BY t.due_date;

-- 输出示例：
-- Sort (cost=100.5..101.0 rows=5)
--   -> Hash Join (cost=25.0..98.0 rows=5)
--         -> Seq Scan on tasks (cost=0..50 rows=5)
--         -> Hash (cost=20.0..20.0 rows=100)
--               -> Seq Scan on users
```

**N+1 问题及解决**：
```typescript
// ❌ N+1 问题：1次查询用户 + N次查询任务
const users = await prisma.user.findMany();
for (const user of users) {
  const tasks = await prisma.task.findMany({
    where: { userId: user.id },
  });
  // 总共执行 1 + N 条 SQL！
}

// ✅ 使用 include 预加载（JOIN 查询）
const users = await prisma.user.findMany({
  include: { tasks: true },
  // 生成一条包含 JOIN 的 SQL
});

// ✅ 使用 DataLoader 模式（批量查询）
// 将 N 次查询合并为 1 次 IN 查询
const userIds = users.map(u => u.id);
const allTasks = await prisma.task.findMany({
  where: { userId: { in: userIds } },
});
```

### 1.4 事务和并发

**ACID 特性**：
- **A (Atomicity)**：事务是原子的，要么全部成功，要么全部回滚
- **C (Consistency)**：事务前后数据库保持一致状态
- **I (Isolation)**：并发事务互不干扰
- **D (Durability)**：事务提交后数据持久化

**隔离级别**：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 | 说明 |
|----------|------|------------|------|------|
| READ UNCOMMITTED | ✅ | ✅ | ✅ | 最低隔离，几乎不用 |
| READ COMMITTED | ❌ | ✅ | ✅ | PostgreSQL 默认 |
| REPEATABLE READ | ❌ | ❌ | ✅ | MySQL 默认 |
| SERIALIZABLE | ❌ | ❌ | ❌ | 最高隔离，性能最低 |

**Prisma 中的事务**：
```typescript
// 方式一：交互式事务 (Interactive Transaction)
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({
    data: { email: "new@example.com", name: "新用户" },
  });

  const task = await tx.task.create({
    data: {
      title: "初始化任务",
      userId: user.id,
    },
  });

  // 如果任何一步失败，整个事务会回滚
  return { user, task };
});

// 方式二：批量事务 (Batch Transaction)
// 适用于简单的批量操作
const [user, tag] = await prisma.$transaction([
  prisma.user.create({ data: { email: "a@b.com", name: "A" } }),
  prisma.tag.create({ data: { name: "新标签" } }),
]);
```

---

## 二、Prisma ORM 进阶

### 2.1 复杂关系建模

**1:1 关系**：
```prisma
model User {
  id      Int      @id @default(autoincrement())
  email   String   @unique
  profile Profile?
}

model Profile {
  id     Int    @id @default(autoincrement())
  bio    String
  userId Int    @unique  // 唯一外键实现 1:1
  user   User   @relation(fields: [userId], references: [id])
}
```

**1:N 关系**：
```prisma
model User {
  id    Int    @id @default(autoincrement())
  tasks Task[] // 一对多
}

model Task {
  id     Int  @id @default(autoincrement())
  userId Int
  user   User @relation(fields: [userId], references: [id])
}
```

**M:N 关系（显式中间表）**：
```prisma
model Task {
  id   Int       @id @default(autoincrement())
  tags TaskTag[] // 通过中间表
}

model Tag {
  id    Int       @id @default(autoincrement())
  name  String    @unique
  tasks TaskTag[]
}

model TaskTag {
  id     Int  @id @default(autoincrement())
  taskId Int
  tagId  Int
  task   Task @relation(fields: [taskId], references: [id])
  tag    Tag  @relation(fields: [tagId], references: [id])

  @@unique([taskId, tagId]) // 防止重复关联
}
```

**自引用关系**（树形结构）：
```prisma
model Category {
  id       Int        @id @default(autoincrement())
  name     String
  parentId Int?
  parent   Category?  @relation("CategoryTree", fields: [parentId], references: [id])
  children Category[] @relation("CategoryTree")
}
```

### 2.2 嵌套写入 (Nested Writes)

```typescript
// 创建用户时同时创建任务和标签
const user = await prisma.user.create({
  data: {
    email: "new@example.com",
    name: "新用户",
    tasks: {
      create: [
        {
          title: "第一个任务",
          status: "TODO",
          tags: {
            create: [
              { tag: { create: { name: "紧急" } } },  // 创建新标签
              { tagId: 1 },                             // 使用已有标签
            ],
          },
        },
      ],
    },
  },
  include: { tasks: { include: { tags: { include: { tag: true } } } } },
});

// 更新时的嵌套操作
const updated = await prisma.task.update({
  where: { id: 1 },
  data: {
    title: "更新后的标题",
    tags: {
      deleteMany: {},                    // 删除所有现有关联
      create: [{ tagId: 2 }, { tagId: 3 }], // 创建新关联
    },
  },
});
```

### 2.3 事务 API ($transaction)

```typescript
// 场景：转账（经典的事务示例）
async function transferTask(fromUserId: number, toUserId: number, taskId: number) {
  return prisma.$transaction(async (tx) => {
    // 1. 验证任务属于原用户
    const task = await tx.task.findFirst({
      where: { id: taskId, userId: fromUserId },
    });
    if (!task) throw new Error("任务不存在或不属于该用户");

    // 2. 转移任务
    const updated = await tx.task.update({
      where: { id: taskId },
      data: { userId: toUserId },
    });

    // 3. 记录操作日志（可以创建一个 AuditLog 模型）
    // await tx.auditLog.create({ ... })

    return updated;
  }, {
    maxWait: 5000,  // 最大等待获取连接的时间
    timeout: 10000, // 事务最大执行时间
  });
}
```

### 2.4 原生 SQL ($queryRaw)

```typescript
// 当 Prisma 的查询能力不够时，使用原生 SQL
const tasks = await prisma.$queryRaw`
  SELECT t.*, u.name as user_name,
         COUNT(tt.id) as tag_count
  FROM tasks t
  JOIN users u ON t.user_id = u.id
  LEFT JOIN task_tags tt ON t.id = tt.task_id
  GROUP BY t.id
  ORDER BY tag_count DESC
`;

// 带参数的查询（防 SQL 注入）
const status = "TODO";
const results = await prisma.$queryRaw`
  SELECT * FROM tasks WHERE status = ${status}
`;

// 执行 INSERT/UPDATE/DELETE
await prisma.$executeRaw`
  UPDATE tasks SET status = 'OVERDUE'
  WHERE due_date < datetime('now') AND status != 'DONE'
`;
```

### 2.5 中间件 (Prisma Middleware)

```typescript
import { Prisma } from "@prisma/client";

// 审计日志中间件
const auditMiddleware: Prisma.Middleware = async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();

  console.log(`[Prisma] ${params.model}.${params.action} took ${after - before}ms`);

  return result;
};

// 软删除中间件
const softDeleteMiddleware: Prisma.Middleware = async (params, next) => {
  if (params.model === "Task") {
    if (params.action === "delete") {
      // 将 delete 转换为 update（软删除）
      params.action = "update";
      params.args.data = { status: "DELETED" };
    }
    if (params.action === "findMany") {
      // 自动过滤已删除的记录
      if (!params.args.where) params.args.where = {};
      params.args.where.status = { not: "DELETED" };
    }
  }
  return next(params);
};

prisma.$use(auditMiddleware);
prisma.$use(softDeleteMiddleware);
```

### 2.6 数据库迁移

```bash
# 开发环境 - 创建并应用迁移
npx prisma migrate dev --name add_priority_field

# 生产环境 - 应用迁移（不会重置数据）
npx prisma migrate deploy

# 推送 schema 变更到数据库（不创建迁移文件，适合原型开发）
npx prisma db push

# 重置数据库（开发环境）
npx prisma migrate reset

# 查看迁移状态
npx prisma migrate status

# 生成 Prisma Client
npx prisma generate
```

### 2.7 数据填充 (Seeding)

在 `package.json` 中配置：
```json
{
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

运行种子数据：
```bash
npx prisma db seed
```

### 2.8 性能优化

**select vs include**：
```typescript
// include: 加载关联数据（类似 JOIN）
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: { tasks: true },  // 加载所有任务字段
});

// select: 精确选择需要的字段（减少数据传输）
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: {
    id: true,
    name: true,
    tasks: {
      select: { id: true, title: true, status: true },
      where: { status: "TODO" },
    },
  },
});
```

**分页**：
```typescript
// Offset 分页（传统方式）
const page1 = await prisma.task.findMany({
  skip: 0,
  take: 10,
  orderBy: { createdAt: "desc" },
});

// Cursor 分页（大数据量更高效）
const firstPage = await prisma.task.findMany({
  take: 10,
  orderBy: { id: "asc" },
});

const nextPage = await prisma.task.findMany({
  take: 10,
  skip: 1,  // 跳过 cursor 本身
  cursor: { id: firstPage[firstPage.length - 1].id },
  orderBy: { id: "asc" },
});
```

---

## 三、数据库对比

| 特性 | SQLite | PostgreSQL | MySQL |
|------|--------|------------|-------|
| 适用场景 | 开发/嵌入式/小型应用 | 企业级应用 | Web 应用 |
| 并发能力 | 低（文件锁） | 高（MVCC） | 中（行级锁） |
| JSON 支持 | 基础 | 优秀（JSONB） | 良好 |
| 全文搜索 | FTS5 扩展 | 内置 tsvector | 内置 FULLTEXT |
| 数组类型 | ❌ | ✅ | ❌ |
| 连接数 | 单文件 | 数百~数千 | 数百~数千 |
| Prisma 兼容 | ✅ | ✅ 最佳 | ✅ |

**推荐**：开发用 SQLite，生产用 PostgreSQL

---

## 🔗 相关资源

- [Prisma 官方文档](https://www.prisma.io/docs)
- [Prisma Schema Reference](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference)
- [PostgreSQL EXPLAIN 文档](https://www.postgresql.org/docs/current/using-explain.html)
- [数据库范式化 - Wikipedia](https://zh.wikipedia.org/wiki/%E6%95%B0%E6%8D%AE%E5%BA%93%E8%A7%84%E8%8C%83%E5%8C%96)
