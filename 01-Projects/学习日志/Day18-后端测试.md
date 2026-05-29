---
tags: [testing, vitest, api, supertest, day18]
created: 2026-05-30
day: 18
---

# Day 18 - 后端 API 测试

## 学习目标

- 理解后端测试策略 (单元测试、集成测试、E2E)
- 使用 Vitest 配置测试环境
- 使用 Supertest 测试 Express 路由
- 掌握 Mock 和 Stub 技巧
- 了解测试覆盖率

---

## 1. 后端测试策略

### 测试金字塔

```
        /  E2E  \        ← 少量, 慢, 高信心
       /  集成测试 \      ← 适中, API 路由测试
      /  单元测试    \    ← 大量, 快, 独立
     ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

### 1.1 单元测试 (Unit Tests)

测试独立的函数和类, 不依赖外部资源。

```typescript
// 测试纯函数 / 工具函数
import { describe, it, expect } from 'vitest';

function formatTaskTitle(title: string): string {
  return title.trim().slice(0, 200);
}

describe('formatTaskTitle', () => {
  it('去除首尾空格', () => {
    expect(formatTaskTitle('  hello  ')).toBe('hello');
  });

  it('截断超过200字符的标题', () => {
    const longTitle = 'a'.repeat(300);
    expect(formatTaskTitle(longTitle)).toHaveLength(200);
  });
});
```

**单元测试的对象:**
- 工具函数 (utils)
- 业务逻辑 (services)
- 数据转换
- 验证逻辑

### 1.2 集成测试 (Integration Tests)

测试多个模块协作, 特别是 API 路由。

```typescript
import request from 'supertest';
import app from '../app.js';

describe('POST /api/tasks', () => {
  it('创建任务成功', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: '测试任务' });

    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty('id');
  });
});
```

**集成测试的对象:**
- API 路由
- 数据库操作
- 中间件链
- 外部服务交互

### 1.3 E2E 测试 (End-to-End)

模拟真实用户操作, 测试完整流程。

- **工具:** Playwright, Cypress, Puppeteer
- **范围:** 整个应用栈 (前端 → API → 数据库)
- **优点:** 最接近真实场景
- **缺点:** 慢, 易碎, 维护成本高

---

## 2. Vitest 配置

### 2.1 安装

```bash
cd express-api
npm install -D vitest supertest @types/supertest
```

### 2.2 vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts', 'src/**/*.spec.ts'],
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts'],
    },
    testTimeout: 10000,
    env: {
      NODE_ENV: 'test',
    },
  },
});
```

### 2.3 添加测试脚本

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

---

## 3. Supertest 测试 Express 路由

### 3.1 核心概念

Supertest 不需要启动真实服务器, 它直接绑定到 Express app 实例。

```typescript
import request from 'supertest';
import app from '../app.js';

// GET 请求
const res = await request(app).get('/api/tasks');
expect(res.status).toBe(200);

// POST 请求
const res = await request(app)
  .post('/api/tasks')
  .send({ title: '新任务' })
  .set('Content-Type', 'application/json');

// 设置请求头
const res = await request(app)
  .get('/api/protected')
  .set('Authorization', 'Bearer token123');
```

### 3.2 测试模式

```typescript
describe('Tasks API', () => {
  // 测试前准备数据
  beforeEach(async () => {
    // 清空数据库 / 重置状态
  });

  // 成功场景
  it('创建成功', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send(validData);
    expect(res.status).toBe(201);
  });

  // 错误场景
  it('验证失败', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: '' });  // 无效数据
    expect(res.status).toBe(400);
  });

  // 不存在
  it('资源不存在', async () => {
    const res = await request(app)
      .get('/api/tasks/nonexistent');
    expect(res.status).toBe(404);
  });
});
```

### 3.3 应用与服务器分离

为了测试, 需要将 Express app 和服务器启动分离:

```typescript
// app.ts - 只导出 app, 不启动服务器
const app = express();
// ... 配置中间件和路由
export default app;

// index.ts - 启动服务器
import app from './app.js';
app.listen(PORT, () => console.log('Server started'));
```

---

## 4. 测试数据库 (隔离测试数据)

### 4.1 策略对比

| 策略 | 优点 | 缺点 |
|------|------|------|
| 内存数据库 | 快, 无需清理 | 与生产不一致 |
| 测试数据库 | 真实环境 | 需要清理和迁移 |
| 事务回滚 | 数据干净 | 复杂, 可能有并发问题 |

### 4.2 内存存储 (当前项目)

我们的 express-api 使用内存存储, 测试时可以在 `beforeEach` 中重置:

```typescript
beforeEach(() => {
  taskStore.reset(); // 需要在 store 中实现
});
```

### 4.3 测试数据库 (Prisma)

```typescript
// 使用测试专用数据库
beforeAll(async () => {
  // 运行迁移
  await prisma.$executeRaw`TRUNCATE TABLE "Task" CASCADE`;
});

afterEach(async () => {
  // 清理测试数据
  await prisma.task.deleteMany();
});
```

### 4.4 环境变量隔离

```bash
# .env.test
DATABASE_URL="postgresql://localhost:5432/test_db"
JWT_SECRET="test-secret-key"
```

---

## 5. Mock 和 Stub

### 5.1 概念区别

- **Stub:** 替换依赖, 返回预设值 (用于控制测试环境)
- **Mock:** 验证函数是否被调用, 调用参数是什么

### 5.2 Vitest Mock

```typescript
import { vi, describe, it, expect } from 'vitest';

// Mock 整个模块
vi.mock('../store.js', () => ({
  taskStore: {
    findAll: vi.fn().mockReturnValue([]),
    findById: vi.fn().mockImplementation((id) => {
      if (id === '1') return { id: '1', title: '测试' };
      return undefined;
    }),
    create: vi.fn().mockReturnValue({ id: '1', title: '测试' }),
  },
}));

// Mock 单个方法
const mockFindAll = vi.spyOn(taskStore, 'findAll');
mockFindAll.mockReturnValue([testTask]);

// 验证调用
expect(mockFindAll).toHaveBeenCalled();
expect(mockFindAll).toHaveBeenCalledWith({ status: 'todo' });
```

### 5.3 Mock 外部 API

```typescript
// Mock fetch (测试外部 API 调用)
global.fetch = vi.fn().mockResolvedValue({
  ok: true,
  json: () => Promise.resolve({ data: 'mock' }),
} as Response);
```

### 5.4 Mock 时间

```typescript
// 固定时间
vi.useFakeTimers();
vi.setSystemTime(new Date('2026-01-01'));

expect(new Date().toISOString()).toBe('2026-01-01T00:00:00.000Z');

vi.useRealTimers();
```

---

## 6. 测试覆盖率

### 6.1 运行覆盖率

```bash
npx vitest run --coverage
```

### 6.2 覆盖率指标

| 指标 | 说明 | 目标 |
|------|------|------|
| **Statements** | 语句覆盖率 | ≥ 80% |
| **Branches** | 分支覆盖率 | ≥ 75% |
| **Functions** | 函数覆盖率 | ≥ 80% |
| **Lines** | 行覆盖率 | ≥ 80% |

### 6.3 覆盖率配置

```typescript
coverage: {
  provider: 'v8',
  reporter: ['text', 'json', 'html'],
  thresholds: {
    statements: 80,
    branches: 75,
    functions: 80,
    lines: 80,
  },
}
```

### 6.4 排除不需要测试的文件

```typescript
coverage: {
  exclude: [
    'src/**/*.test.ts',
    'src/index.ts',        // 入口文件
    'src/**/*.d.ts',       // 类型声明
  ],
}
```

---

## 7. 最佳实践

### 7.1 测试命名

```typescript
// ✅ 好的命名 - 描述行为
it('创建任务时标题为空应返回 400 错误')

// ❌ 差的命名 - 描述实现
it('should call validate', () => {})
```

### 7.2 AAA 模式

```typescript
it('更新任务状态', async () => {
  // Arrange - 准备
  const task = await createTestTask({ status: 'todo' });

  // Act - 执行
  const res = await request(app)
    .put(`/api/tasks/${task.id}`)
    .send({ status: 'done' });

  // Assert - 断言
  expect(res.status).toBe(200);
  expect(res.body.data.status).toBe('done');
});
```

### 7.3 测试独立性

- 每个测试应该独立运行
- 不依赖其他测试的执行顺序
- 测试前后清理状态

### 7.4 避免测试实现细节

```typescript
// ✅ 测试行为
it('返回过滤后的任务', async () => {
  const res = await request(app).get('/api/tasks?status=todo');
  res.body.data.forEach(t => expect(t.status).toBe('todo'));
});

// ❌ 测试实现
it('调用了 findAll 方法', async () => {
  expect(mockFindAll).toHaveBeenCalled();
});
```

---

## 8. 常用测试工具

| 工具 | 用途 |
|------|------|
| **Vitest** | 测试运行器和断言库 |
| **Supertest** | HTTP 请求测试 |
| **MSW (Mock Service Worker)** | 网络请求 mock |
| **nock** | Node.js HTTP mock |
| **fishery** | 测试数据工厂 |
| **faker** | 假数据生成 |

---

## 9. 今日练习

1. ✅ 创建 vitest.config.ts
2. ✅ 编写 auth.test.ts (注册/登录/认证)
3. ✅ 编写 tasks.test.ts (CRUD/过滤/认证)
4. 🔄 安装 vitest 和 supertest 并运行测试
5. 🔄 查看测试覆盖率报告

---

## 10. 项目结构

```
express-api/
├── src/
│   ├── __tests__/
│   │   ├── auth.test.ts      ← 认证测试
│   │   └── tasks.test.ts     ← 任务 CRUD 测试
│   ├── middleware/
│   │   ├── error-handler.ts
│   │   ├── logger.ts
│   │   └── validate.ts
│   ├── routes/
│   │   └── tasks.ts
│   ├── app.ts                ← Express 应用 (导出, 不启动)
│   ├── index.ts              ← 服务器入口 (启动)
│   ├── store.ts
│   └── types.ts
├── vitest.config.ts          ← Vitest 配置
└── package.json
```

---

## 明日计划

- Day 19: API 集成模式 - 前后端联调、API Client 设计
