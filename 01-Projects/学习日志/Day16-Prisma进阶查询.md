---
tags: [prisma, orm, query, database, day16]
created: 2026-05-30
day: 16
---

# Day 16 - Prisma 进阶查询示例

## 📋 复杂查询示例

### 条件过滤与排序

```typescript
import { Prisma } from "@prisma/client";
import prisma from "./prisma";

// 复合条件查询
async function searchTasks(filters: {
  status?: string;
  priority?: string;
  userId?: number;
  keyword?: string;
}) {
  const where: Prisma.TaskWhereInput = {};

  if (filters.status) where.status = filters.status;
  if (filters.priority) where.priority = filters.priority;
  if (filters.userId) where.userId = filters.userId;

  // 模糊搜索（标题或描述）
  if (filters.keyword) {
    where.OR = [
      { title: { contains: filters.keyword } },
      { description: { contains: filters.keyword } },
    ];
  }

  return prisma.task.findMany({
    where,
    orderBy: [
      { priority: "desc" },   // 优先级高的排前面
      { dueDate: "asc" },     // 截止日期近的排前面
    ],
    include: {
      user: { select: { id: true, name: true } },
      tags: { include: { tag: true } },
    },
  });
}
```

### 关联查询

```typescript
// 查询用户及其任务统计
async function getUserWithStats(userId: number) {
  return prisma.user.findUnique({
    where: { id: userId },
    include: {
      tasks: {
        include: {
          tags: { include: { tag: true } },
        },
        orderBy: { createdAt: "desc" },
      },
      _count: {
        select: {
          tasks: true,
        },
      },
    },
  });
}

// 查询带标签的任务
async function getTasksByTag(tagName: string) {
  return prisma.task.findMany({
    where: {
      tags: {
        some: {
          tag: { name: tagName },
        },
      },
    },
    include: {
      user: { select: { name: true } },
      tags: { include: { tag: true } },
    },
  });
}
```

---

## 📄 分页查询

### Offset 分页（传统方式）

```typescript
// 适合：总页数不重要，数据量较小
async function getTasksOffset(page: number, pageSize: number) {
  const skip = (page - 1) * pageSize;

  const [tasks, total] = await prisma.$transaction([
    prisma.task.findMany({
      skip,
      take: pageSize,
      orderBy: { createdAt: "desc" },
      include: {
        user: { select: { id: true, name: true } },
      },
    }),
    prisma.task.count(),
  ]);

  return {
    data: tasks,
    pagination: {
      page,
      pageSize,
      total,
      totalPages: Math.ceil(total / pageSize),
    },
  };
}

// 使用示例
const result = await getTasksOffset(1, 10);
// { data: [...], pagination: { page: 1, pageSize: 10, total: 100, totalPages: 10 } }
```

### Cursor 分页（大数据量）

```typescript
// 适合：无限滚动，数据量大，不需要跳页
async function getTasksCursor(cursor?: number, take: number = 10) {
  const tasks = await prisma.task.findMany({
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    orderBy: { id: "asc" },
    include: {
      user: { select: { id: true, name: true } },
    },
  });

  const nextCursor = tasks.length === take ? tasks[tasks.length - 1].id : null;

  return {
    data: tasks,
    nextCursor,
  };
}

// 使用示例（无限滚动）
let cursor: number | undefined;
const allTasks = [];

while (true) {
  const result = await getTasksCursor(cursor, 10);
  allTasks.push(...result.data);
  if (!result.nextCursor) break;
  cursor = result.nextCursor;
}
```

---

## 📊 聚合查询

### Count, Sum, Avg

```typescript
// 基础聚合
async function getTaskStats() {
  const stats = await prisma.task.aggregate({
    _count: true,
    where: { status: { not: "CANCELLED" } },
  });

  return { totalTasks: stats._count };
}

// 按状态统计
async function getTaskCountByStatus() {
  const grouped = await prisma.task.groupBy({
    by: ["status"],
    _count: true,
    orderBy: { _count: { status: "desc" } },
  });

  return grouped;
  // [{ status: "TODO", _count: 5 }, { status: "DONE", _count: 3 }, ...]
}

// 按用户统计任务数量
async function getTaskCountByUser() {
  const grouped = await prisma.task.groupBy({
    by: ["userId"],
    _count: true,
    _max: { createdAt: true },
    orderBy: { _count: { userId: "desc" } },
  });

  // 关联用户信息
  const userIds = grouped.map((g) => g.userId);
  const users = await prisma.user.findMany({
    where: { id: { in: userIds } },
    select: { id: true, name: true },
  });

  const userMap = new Map(users.map((u) => [u.id, u.name]));

  return grouped.map((g) => ({
    userId: g.userId,
    userName: userMap.get(g.userId),
    taskCount: g._count,
    latestTask: g._max.createdAt,
  }));
}

// 按优先级和状态分组
async function getTaskByPriorityAndStatus() {
  const grouped = await prisma.task.groupBy({
    by: ["priority", "status"],
    _count: true,
    where: { status: { not: "CANCELLED" } },
  });

  return grouped;
  // [{ priority: "HIGH", status: "TODO", _count: 3 }, ...]
}
```

---

## 🔍 全文搜索

### SQLite 全文搜索

```typescript
// SQLite 使用 LIKE 进行简单搜索
async function searchTasksSQLite(keyword: string) {
  return prisma.task.findMany({
    where: {
      OR: [
        { title: { contains: keyword } },
        { description: { contains: keyword } },
      ],
    },
    include: {
      user: { select: { name: true } },
      tags: { include: { tag: true } },
    },
  });
}

// 使用原生 SQL 实现更高级的搜索
async function searchTasksRawSQLite(keyword: string) {
  return prisma.$queryRaw`
    SELECT t.*, u.name as user_name
    FROM tasks t
    JOIN users u ON t.user_id = u.id
    WHERE t.title LIKE ${`%${keyword}%`}
       OR t.description LIKE ${`%${keyword}%`}
    ORDER BY
      CASE
        WHEN t.title LIKE ${`%${keyword}%`} THEN 0
        ELSE 1
      END,
      t.created_at DESC
  `;
}
```

### PostgreSQL 全文搜索

```typescript
// PostgreSQL 原生全文搜索（需要先创建索引）
// CREATE INDEX idx_tasks_fts ON tasks
//   USING gin (to_tsvector('english', title || ' ' || COALESCE(description, '')));

async function searchTasksPostgres(keyword: string) {
  return prisma.$queryRaw`
    SELECT t.*,
           ts_rank(to_tsvector('english', t.title || ' ' || COALESCE(t.description, '')),
                   plainto_tsquery('english', ${keyword})) as rank
    FROM tasks t
    WHERE to_tsvector('english', t.title || ' ' || COALESCE(t.description, ''))
          @@ plainto_tsquery('english', ${keyword})
    ORDER BY rank DESC
  `;
}

// 支持模糊匹配 + 权重
async function searchTasksWeighted(keyword: string) {
  return prisma.$queryRaw`
    SELECT t.*,
           setweight(to_tsvector('english', t.title), 'A') ||
           setweight(to_tsvector('english', COALESCE(t.description, '')), 'B')
             as document,
           ts_rank(
             setweight(to_tsvector('english', t.title), 'A') ||
             setweight(to_tsvector('english', COALESCE(t.description, '')), 'B'),
             plainto_tsquery('english', ${keyword})
           ) as rank
    FROM tasks t
    WHERE to_tsvector('english', t.title || ' ' || COALESCE(t.description, ''))
          @@ plainto_tsquery('english', ${keyword})
    ORDER BY rank DESC
    LIMIT 20
  `;
}
```

---

## 🛠 实用工具函数

```typescript
// 通用分页参数构建
function buildPagination(page: number, pageSize: number) {
  return {
    skip: (page - 1) * pageSize,
    take: pageSize,
  };
}

// 通用排序参数构建
function buildOrderBy(
  sortBy: string,
  order: "asc" | "desc" = "desc"
): Record<string, "asc" | "desc"> {
  return { [sortBy]: order };
}

// 组合查询构建器
async function advancedTaskQuery(options: {
  filters?: Prisma.TaskWhereInput;
  page?: number;
  pageSize?: number;
  sortBy?: string;
  order?: "asc" | "desc";
  include?: Prisma.TaskInclude;
}) {
  const { filters, page = 1, pageSize = 10, sortBy = "createdAt", order = "desc", include } = options;

  const [data, total] = await prisma.$transaction([
    prisma.task.findMany({
      where: filters,
      ...buildPagination(page, pageSize),
      orderBy: buildOrderBy(sortBy, order),
      include,
    }),
    prisma.task.count({ where: filters }),
  ]);

  return {
    data,
    pagination: {
      page,
      pageSize,
      total,
      totalPages: Math.ceil(total / pageSize),
      hasMore: page * pageSize < total,
    },
  };
}
```
