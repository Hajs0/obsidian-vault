---
title: Day 57 - 后端 API 开发
date: 2026-05-29
tags:
  - 项目实战
  - 后端开发
  - api
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 57 - 后端 API 开发

## 📚 学习目标
- 实现 RESTful API
- 数据库操作
- 认证和授权

## 🎯 核心 API 实现

### 1. 数据库配置

#### Prisma Schema
```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// 用户模型
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String    @unique
  password      String
  image         String?
  role          Role      @default(USER)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  tasks         Task[]
  teamMembers   TeamMember[]
  comments      Comment[]
}

enum Role {
  USER
  ADMIN
}

// 任务模型
model Task {
  id          String     @id @default(cuid())
  title       String
  description String?
  status      TaskStatus @default(TODO)
  priority    Priority   @default(MEDIUM)
  dueDate     DateTime?
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt

  userId      String
  user        User       @relation(fields: [userId], references: [id])
  teamId      String?
  team        Team?      @relation(fields: [teamId], references: [id])
  tags        Tag[]
  comments    Comment[]
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  IN_REVIEW
  DONE
}

enum Priority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

// 团队模型
model Team {
  id          String       @id @default(cuid())
  name        String
  description String?
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  members     TeamMember[]
  tasks       Task[]
}

model TeamMember {
  id       String   @id @default(cuid())
  role     TeamRole @default(MEMBER)
  joinedAt DateTime @default(now())

  userId   String
  user     User     @relation(fields: [userId], references: [id])
  teamId   String
  team     Team     @relation(fields: [teamId], references: [id])

  @@unique([userId, teamId])
}

enum TeamRole {
  OWNER
  ADMIN
  MEMBER
}

// 标签模型
model Tag {
  id    String @id @default(cuid())
  name  String @unique
  color String?

  tasks Task[]
}

// 评论模型
model Comment {
  id        String   @id @default(cuid())
  content   String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  userId    String
  user      User     @relation(fields: [userId], references: [id])
  taskId    String
  task      Task     @relation(fields: [taskId], references: [id])
}
```

### 2. API 路由实现

#### 任务 API
```typescript
// src/app/api/tasks/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { prisma } from '@/lib/db';
import { z } from 'zod';

const createTaskSchema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().optional(),
  status: z.enum(['TODO', 'IN_PROGRESS', 'IN_REVIEW', 'DONE']).optional(),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).optional(),
  dueDate: z.string().datetime().optional(),
  teamId: z.string().optional(),
  tagIds: z.array(z.string()).optional(),
});

// GET /api/tasks
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: '未授权' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const priority = searchParams.get('priority');
    const teamId = searchParams.get('teamId');

    const where: any = {
      OR: [
        { userId: session.user.id },
        { team: { members: { some: { userId: session.user.id } } } },
      ],
    };

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (teamId) where.teamId = teamId;

    const tasks = await prisma.task.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, image: true } },
        team: { select: { id: true, name: true } },
        tags: true,
        _count: { select: { comments: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json(tasks);
  } catch (error) {
    console.error('获取任务失败:', error);
    return NextResponse.json({ error: '服务器错误' }, { status: 500 });
  }
}

// POST /api/tasks
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: '未授权' }, { status: 401 });
    }

    const body = await request.json();
    const validation = createTaskSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: '数据验证失败', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { title, description, status, priority, dueDate, teamId, tagIds } = validation.data;

    // 如果指定了团队，检查权限
    if (teamId) {
      const membership = await prisma.teamMember.findUnique({
        where: {
          userId_teamId: {
            userId: session.user.id,
            teamId,
          },
        },
      });

      if (!membership) {
        return NextResponse.json({ error: '无权访问此团队' }, { status: 403 });
      }
    }

    const task = await prisma.task.create({
      data: {
        title,
        description,
        status,
        priority,
        dueDate: dueDate ? new Date(dueDate) : null,
        userId: session.user.id,
        teamId,
        tags: tagIds ? { connect: tagIds.map((id) => ({ id })) } : undefined,
      },
      include: {
        user: { select: { id: true, name: true, image: true } },
        team: { select: { id: true, name: true } },
        tags: true,
      },
    });

    return NextResponse.json(task, { status: 201 });
  } catch (error) {
    console.error('创建任务失败:', error);
    return NextResponse.json({ error: '服务器错误' }, { status: 500 });
  }
}
```

#### 单个任务 API
```typescript
// src/app/api/tasks/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { prisma } from '@/lib/db';
import { z } from 'zod';

const updateTaskSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  description: z.string().optional(),
  status: z.enum(['TODO', 'IN_PROGRESS', 'IN_REVIEW', 'DONE']).optional(),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).optional(),
  dueDate: z.string().datetime().optional(),
  tagIds: z.array(z.string()).optional(),
});

// GET /api/tasks/[id]
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: '未授权' }, { status: 401 });
    }

    const task = await prisma.task.findUnique({
      where: { id: params.id },
      include: {
        user: { select: { id: true, name: true, image: true } },
        team: { select: { id: true, name: true } },
        tags: true,
        comments: {
          include: {
            user: { select: { id: true, name: true, image: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!task) {
      return NextResponse.json({ error: '任务不存在' }, { status: 404 });
    }

    // 检查访问权限
    const hasAccess =
      task.userId === session.user.id ||
      (task.teamId &&
        (await prisma.teamMember.findUnique({
          where: {
            userId_teamId: {
              userId: session.user.id,
              teamId: task.teamId,
            },
          },
        })));

    if (!hasAccess) {
      return NextResponse.json({ error: '无权访问' }, { status: 403 });
    }

    return NextResponse.json(task);
  } catch (error) {
    console.error('获取任务失败:', error);
    return NextResponse.json({ error: '服务器错误' }, { status: 500 });
  }
}

// PATCH /api/tasks/[id]
export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: '未授权' }, { status: 401 });
    }

    const task = await prisma.task.findUnique({
      where: { id: params.id },
    });

    if (!task) {
      return NextResponse.json({ error: '任务不存在' }, { status: 404 });
    }

    // 检查编辑权限
    if (task.userId !== session.user.id) {
      return NextResponse.json({ error: '无权编辑' }, { status: 403 });
    }

    const body = await request.json();
    const validation = updateTaskSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        { error: '数据验证失败', details: validation.error.errors },
        { status: 400 }
      );
    }

    const { tagIds, ...data } = validation.data;

    const updatedTask = await prisma.task.update({
      where: { id: params.id },
      data: {
        ...data,
        dueDate: data.dueDate ? new Date(data.dueDate) : undefined,
        tags: tagIds ? { set: tagIds.map((id) => ({ id })) } : undefined,
      },
      include: {
        user: { select: { id: true, name: true, image: true } },
        team: { select: { id: true, name: true } },
        tags: true,
      },
    });

    return NextResponse.json(updatedTask);
  } catch (error) {
    console.error('更新任务失败:', error);
    return NextResponse.json({ error: '服务器错误' }, { status: 500 });
  }
}

// DELETE /api/tasks/[id]
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession();
    if (!session?.user) {
      return NextResponse.json({ error: '未授权' }, { status: 401 });
    }

    const task = await prisma.task.findUnique({
      where: { id: params.id },
    });

    if (!task) {
      return NextResponse.json({ error: '任务不存在' }, { status: 404 });
    }

    // 检查删除权限
    if (task.userId !== session.user.id) {
      return NextResponse.json({ error: '无权删除' }, { status: 403 });
    }

    await prisma.task.delete({
      where: { id: params.id },
    });

    return NextResponse.json({ message: '删除成功' });
  } catch (error) {
    console.error('删除任务失败:', error);
    return NextResponse.json({ error: '服务器错误' }, { status: 500 });
  }
}
```

### 3. 认证配置

#### NextAuth 配置
```typescript
// src/lib/auth.ts
import { NextAuthOptions } from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';
import CredentialsProvider from 'next-auth/providers/credentials';
import { prisma } from './db';
import { compare } from 'bcryptjs';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  session: {
    strategy: 'jwt',
  },
  pages: {
    signIn: '/login',
  },
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error('请输入邮箱和密码');
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        });

        if (!user || !user.password) {
          throw new Error('用户不存在');
        }

        const isPasswordValid = await compare(credentials.password, user.password);

        if (!isPasswordValid) {
          throw new Error('密码错误');
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          image: user.image,
        };
      },
    }),
  ],
  callbacks: {
    async session({ token, session }) {
      if (token) {
        session.user.id = token.id;
        session.user.name = token.name;
        session.user.email = token.email;
        session.user.image = token.picture;
      }
      return session;
    },
    async jwt({ token, user }) {
      const dbUser = await prisma.user.findUnique({
        where: { email: token.email! },
      });

      if (!dbUser) {
        if (user) {
          token.id = user?.id;
        }
        return token;
      }

      return {
        id: dbUser.id,
        name: dbUser.name,
        email: dbUser.email,
        picture: dbUser.image,
      };
    },
  },
};
```

## 📝 最佳实践

### 1. 数据验证
```typescript
// 好：使用 Zod 验证
const schema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().optional(),
});

const validation = schema.safeParse(body);
if (!validation.success) {
  return NextResponse.json({ error: validation.error.errors }, { status: 400 });
}

// 不好：手动验证
if (!body.title || body.title.length > 100) {
  return NextResponse.json({ error: '标题无效' }, { status: 400 });
}
```

### 2. 错误处理
```typescript
// 好：统一错误处理
try {
  // 业务逻辑
} catch (error) {
  console.error('操作失败:', error);
  return NextResponse.json({ error: '服务器错误' }, { status: 500 });
}

// 不好：暴露错误细节
try {
  // 业务逻辑
} catch (error) {
  return NextResponse.json({ error: error.message }, { status: 500 });
}
```

### 3. 权限检查
```typescript
// 好：检查权限
if (task.userId !== session.user.id) {
  return NextResponse.json({ error: '无权操作' }, { status: 403 });
}

// 不好：忽略权限
await prisma.task.delete({ where: { id: params.id } });
```

## 🎓 今日总结

**关键知识点：**
1. Prisma 数据库模型设计
2. RESTful API 实现
3. 数据验证（Zod）
4. 认证和授权（NextAuth）
5. 错误处理

**明日计划：**
- Day 58: 测试与质量保障
