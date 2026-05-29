---
title: Day 58 - 测试与质量保障
date: 2026-05-29
tags:
  - 项目实战
  - 测试
  - 质量保障
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 58 - 测试与质量保障

## 📚 学习目标
- 编写单元测试
- 实现集成测试
- 进行 E2E 测试

## 🎯 测试策略

### 1. 单元测试

#### 工具函数测试
```typescript
// src/lib/utils.test.ts
import { describe, it, expect } from 'vitest';
import { cn, formatDate, truncate } from './utils';

describe('cn', () => {
  it('应该合并类名', () => {
    expect(cn('foo', 'bar')).toBe('foo bar');
  });

  it('应该处理条件类名', () => {
    expect(cn('foo', false && 'bar')).toBe('foo');
  });

  it('应该合并 Tailwind 类名', () => {
    expect(cn('px-2 py-1', 'px-4')).toBe('py-1 px-4');
  });
});

describe('formatDate', () => {
  it('应该格式化日期', () => {
    const date = new Date('2026-05-29');
    expect(formatDate(date)).toBe('2026年5月29日');
  });

  it('应该处理无效日期', () => {
    expect(formatDate(null)).toBe('-');
  });
});

describe('truncate', () => {
  it('应该截断长字符串', () => {
    expect(truncate('Hello World', 5)).toBe('Hello...');
  });

  it('应该不截断短字符串', () => {
    expect(truncate('Hi', 5)).toBe('Hi');
  });
});
```

#### 状态管理测试
```typescript
// src/stores/taskStore.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useTaskStore } from './taskStore';

// Mock fetch
global.fetch = vi.fn();

describe('TaskStore', () => {
  beforeEach(() => {
    useTaskStore.setState({ tasks: [], isLoading: false, error: null });
    vi.clearAllMocks();
  });

  describe('fetchTasks', () => {
    it('应该获取任务列表', async () => {
      const mockTasks = [
        { id: '1', title: '任务1', status: 'TODO' },
        { id: '2', title: '任务2', status: 'IN_PROGRESS' },
      ];

      (fetch as any).mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockTasks),
      });

      await useTaskStore.getState().fetchTasks();

      expect(useTaskStore.getState().tasks).toEqual(mockTasks);
      expect(useTaskStore.getState().isLoading).toBe(false);
    });

    it('应该处理获取失败', async () => {
      (fetch as any).mockRejectedValueOnce(new Error('Network error'));

      await useTaskStore.getState().fetchTasks();

      expect(useTaskStore.getState().error).toBe('获取任务失败');
      expect(useTaskStore.getState().isLoading).toBe(false);
    });
  });

  describe('createTask', () => {
    it('应该创建新任务', async () => {
      const newTask = { id: '3', title: '新任务', status: 'TODO' };

      (fetch as any).mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(newTask),
      });

      await useTaskStore.getState().createTask({ title: '新任务' });

      expect(useTaskStore.getState().tasks).toContainEqual(newTask);
    });
  });

  describe('moveTask', () => {
    it('应该移动任务状态', async () => {
      const initialTasks = [
        { id: '1', title: '任务1', status: 'TODO' },
      ];
      const updatedTask = { id: '1', title: '任务1', status: 'IN_PROGRESS' };

      useTaskStore.setState({ tasks: initialTasks });

      (fetch as any).mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(updatedTask),
      });

      await useTaskStore.getState().moveTask('1', 'IN_PROGRESS');

      expect(useTaskStore.getState().tasks[0].status).toBe('IN_PROGRESS');
    });
  });
});
```

### 2. 组件测试

#### 任务卡片测试
```typescript
// src/components/tasks/TaskCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TaskCard } from './TaskCard';

describe('TaskCard', () => {
  const mockTask = {
    id: '1',
    title: '测试任务',
    description: '测试描述',
    status: 'TODO',
    priority: 'MEDIUM',
    dueDate: '2026-06-01',
    assignee: { name: '张三' },
  };

  it('应该渲染任务信息', () => {
    render(
      <TaskCard
        task={mockTask}
        onStatusChange={() => {}}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );

    expect(screen.getByText('测试任务')).toBeInTheDocument();
    expect(screen.getByText('测试描述')).toBeInTheDocument();
    expect(screen.getByText('MEDIUM')).toBeInTheDocument();
  });

  it('应该显示截止日期', () => {
    render(
      <TaskCard
        task={mockTask}
        onStatusChange={() => {}}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );

    expect(screen.getByText(/2026/)).toBeInTheDocument();
  });

  it('应该显示负责人', () => {
    render(
      <TaskCard
        task={mockTask}
        onStatusChange={() => {}}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );

    expect(screen.getByText('张三')).toBeInTheDocument();
  });

  it('应该调用 onEdit', async () => {
    const user = userEvent.setup();
    const onEdit = vi.fn();

    render(
      <TaskCard
        task={mockTask}
        onStatusChange={() => {}}
        onEdit={onEdit}
        onDelete={() => {}}
      />
    );

    await user.click(screen.getByText('测试任务'));
    expect(onEdit).toHaveBeenCalledWith(mockTask);
  });
});
```

### 3. API 测试

#### 任务 API 测试
```typescript
// src/app/api/tasks/route.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { createMocks } from 'node-mocks-http';
import { GET, POST } from './route';

// Mock Prisma
vi.mock('@/lib/db', () => ({
  prisma: {
    task: {
      findMany: vi.fn(),
      create: vi.fn(),
    },
  },
}));

// Mock NextAuth
vi.mock('next-auth', () => ({
  getServerSession: vi.fn(),
}));

describe('Tasks API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/tasks', () => {
    it('应该返回任务列表', async () => {
      const mockTasks = [
        { id: '1', title: '任务1' },
        { id: '2', title: '任务2' },
      ];

      const { getServerSession } = await import('next-auth');
      vi.mocked(getServerSession).mockResolvedValue({
        user: { id: '1', email: 'test@example.com' },
      });

      const { prisma } = await import('@/lib/db');
      vi.mocked(prisma.task.findMany).mockResolvedValue(mockTasks);

      const { req } = createMocks({ method: 'GET' });
      const response = await GET(req as any);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data).toEqual(mockTasks);
    });

    it('应该返回 401 未授权', async () => {
      const { getServerSession } = await import('next-auth');
      vi.mocked(getServerSession).mockResolvedValue(null);

      const { req } = createMocks({ method: 'GET' });
      const response = await GET(req as any);

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/tasks', () => {
    it('应该创建新任务', async () => {
      const newTask = { id: '3', title: '新任务' };

      const { getServerSession } = await import('next-auth');
      vi.mocked(getServerSession).mockResolvedValue({
        user: { id: '1', email: 'test@example.com' },
      });

      const { prisma } = await import('@/lib/db');
      vi.mocked(prisma.task.create).mockResolvedValue(newTask);

      const { req } = createMocks({
        method: 'POST',
        body: { title: '新任务' },
      });
      const response = await POST(req as any);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data).toEqual(newTask);
    });

    it('应该验证数据', async () => {
      const { getServerSession } = await import('next-auth');
      vi.mocked(getServerSession).mockResolvedValue({
        user: { id: '1', email: 'test@example.com' },
      });

      const { req } = createMocks({
        method: 'POST',
        body: { title: '' }, // 空标题
      });
      const response = await POST(req as any);

      expect(response.status).toBe(400);
    });
  });
});
```

### 4. E2E 测试

#### 任务管理 E2E 测试
```typescript
// e2e/tasks.spec.ts
import { test, expect } from '@playwright/test';

test.describe('任务管理', () => {
  test.beforeEach(async ({ page }) => {
    // 登录
    await page.goto('/login');
    await page.getByLabel('邮箱').fill('test@example.com');
    await page.getByLabel('密码').fill('password123');
    await page.getByRole('button', { name: '登录' }).click();
    await expect(page).toHaveURL('/dashboard');
  });

  test('应该显示任务列表', async ({ page }) => {
    await page.goto('/tasks');
    
    await expect(page.getByRole('heading', { name: '任务管理' })).toBeVisible();
    await expect(page.getByText('待办')).toBeVisible();
    await expect(page.getByText('进行中')).toBeVisible();
  });

  test('应该创建新任务', async ({ page }) => {
    await page.goto('/tasks');
    
    await page.getByRole('button', { name: '创建任务' }).click();
    
    await page.getByLabel('标题').fill('新任务');
    await page.getByLabel('描述').fill('任务描述');
    
    await page.getByRole('button', { name: '保存' }).click();
    
    await expect(page.getByText('新任务')).toBeVisible();
  });

  test('应该拖拽任务', async ({ page }) => {
    await page.goto('/tasks');
    
    const task = page.getByText('测试任务');
    const targetColumn = page.getByText('进行中');
    
    await task.dragTo(targetColumn);
    
    await expect(page.locator('[data-status="IN_PROGRESS"]').getByText('测试任务')).toBeVisible();
  });

  test('应该删除任务', async ({ page }) => {
    await page.goto('/tasks');
    
    const taskCard = page.getByText('测试任务').locator('..');
    await taskCard.getByRole('button', { name: '更多' }).click();
    await page.getByRole('menuitem', { name: '删除' }).click();
    
    await page.getByRole('button', { name: '确认' }).click();
    
    await expect(page.getByText('测试任务')).not.toBeVisible();
  });
});
```

## 📝 最佳实践

### 1. 测试金字塔
```
       E2E 测试 (10%)
      /              \
   集成测试 (20%)
  /                  \
单元测试 (70%)
```

### 2. 测试命名
```typescript
// 好：描述行为
describe('TaskStore', () => {
  describe('fetchTasks', () => {
    it('应该获取任务列表', async () => { ... });
    it('应该处理获取失败', async () => { ... });
  });
});

// 不好：描述实现
describe('TaskStore', () => {
  it('test1', () => { ... });
  it('test2', () => { ... });
});
```

### 3. 测试隔离
```typescript
// 好：每个测试独立
beforeEach(() => {
  useTaskStore.setState({ tasks: [], isLoading: false, error: null });
  vi.clearAllMocks();
});

// 不好：测试依赖
let tasks = [];
it('test1', () => { tasks.push(1); });
it('test2', () => { expect(tasks.length).toBe(1); });
```

## 🎓 今日总结

**关键知识点：**
1. 单元测试：工具函数、状态管理
2. 组件测试：React Testing Library
3. API 测试：Mock 和断言
4. E2E 测试：Playwright

**明日计划：**
- Day 59: 性能优化与部署
