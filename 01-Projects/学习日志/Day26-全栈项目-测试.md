---
tags:
  - project
  - testing
  - vitest
  - day26
created: 2026-05-30
day: 26
---

# Day 26 - 全栈项目测试

## 测试策略概览

全栈项目的测试分为三个层次：

| 层级 | 工具 | 覆盖范围 |
|------|------|----------|
| 单元测试 | Vitest | 函数、工具方法、hooks |
| 集成测试 | Vitest + Supertest | API 路由、数据库交互 |
| E2E 测试 | Playwright | 完整用户流程 |

**测试金字塔原则**：单元测试数量最多（快、便宜），E2E 测试数量最少（慢、贵）。

---

## 1. Vitest 配置和使用

### 安装依赖

```bash
# 后端
cd backend
npm install -D vitest @vitest/coverage-v8 supertest

# 前端
cd frontend
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

### Vitest 配置（后端）

```ts
// backend/vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/index.ts'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    setupFiles: ['./tests/setup.ts'],
  },
})
```

### Vitest 配置（前端）

```ts
// frontend/vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: true,
  },
})
```

### 前端测试 setup

```ts
// frontend/src/test/setup.ts
import '@testing-library/jest-dom'
```

---

## 2. Supertest 测试 Express API

### 测试工具函数

```ts
// backend/tests/helpers.ts
import { prisma } from '../src/lib/prisma'

export async function cleanDatabase() {
  const tablenames = await prisma.$queryRaw<
    Array<{ tablename: string }>
  >`SELECT tablename FROM pg_tables WHERE schemaname='public'`

  for (const { tablename } of tablenames) {
    if (tablename !== '_prisma_migrations') {
      await prisma.$executeRawUnsafe(
        `TRUNCATE TABLE "public"."${tablename}" CASCADE;`
      )
    }
  }
}
```

### 测试 setup

```ts
// backend/tests/setup.ts
import { afterAll, beforeEach } from 'vitest'
import { cleanDatabase } from './helpers'
import { prisma } from '../src/lib/prisma'

beforeEach(async () => {
  await cleanDatabase()
})

afterAll(async () => {
  await prisma.$disconnect()
})
```

### API 集成测试示例

```ts
// backend/tests/api/users.test.ts
import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { app } from '../../src/app'

describe('用户 API', () => {
  describe('POST /api/users', () => {
    it('应该创建新用户', async () => {
      const res = await request(app)
        .post('/api/users')
        .send({
          name: '张三',
          email: 'zhangsan@example.com',
          password: 'Secure123!',
        })

      expect(res.status).toBe(201)
      expect(res.body).toHaveProperty('id')
      expect(res.body.name).toBe('张三')
      expect(res.body).not.toHaveProperty('password')
    })

    it('缺少必填字段应返回 400', async () => {
      const res = await request(app)
        .post('/api/users')
        .send({ name: '张三' })

      expect(res.status).toBe(400)
      expect(res.body.error).toBeDefined()
    })

    it('重复邮箱应返回 409', async () => {
      const payload = {
        name: '张三',
        email: 'dup@example.com',
        password: 'Secure123!',
      }

      await request(app).post('/api/users').send(payload)
      const res = await request(app).post('/api/users').send(payload)

      expect(res.status).toBe(409)
    })
  })

  describe('GET /api/users/:id', () => {
    it('应返回指定用户', async () => {
      const createRes = await request(app)
        .post('/api/users')
        .send({
          name: '李四',
          email: 'lisi@example.com',
          password: 'Secure123!',
        })

      const res = await request(app).get(`/api/users/${createRes.body.id}`)

      expect(res.status).toBe(200)
      expect(res.body.name).toBe('李四')
    })

    it('不存在的 ID 应返回 404', async () => {
      const res = await request(app).get('/api/users/nonexistent-id')
      expect(res.status).toBe(404)
    })
  })

  describe('POST /api/auth/login', () => {
    it('正确凭证应返回 token', async () => {
      await request(app)
        .post('/api/users')
        .send({
          name: '王五',
          email: 'wangwu@example.com',
          password: 'Secure123!',
        })

      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'wangwu@example.com',
          password: 'Secure123!',
        })

      expect(res.status).toBe(200)
      expect(res.body).toHaveProperty('token')
    })

    it('错误密码应返回 401', async () => {
      await request(app)
        .post('/api/users')
        .send({
          name: '赵六',
          email: 'zhaoliu@example.com',
          password: 'Secure123!',
        })

      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'zhaoliu@example.com',
          password: 'WrongPass!',
        })

      expect(res.status).toBe(401)
    })
  })
})
```

### 带认证的接口测试

```ts
// 带 Token 请求受保护接口
async function authRequest(userId: string) {
  const { generateToken } = await import('../../src/lib/jwt')
  const token = generateToken({ userId })

  return (method: string, url: string) =>
    request(app)[method](url).set('Authorization', `Bearer ${token}`)
}

it('获取当前用户信息', async () => {
  const agent = await authRequest(createdUserId)
  const res = await agent('get', '/api/auth/me')

  expect(res.status).toBe(200)
  expect(res.body.email).toBe('wangwu@example.com')
})
```

---

## 3. React Testing Library 测试组件

### 组件测试示例

```tsx
// frontend/src/components/__tests__/LoginForm.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { LoginForm } from '../LoginForm'

// Mock API 调用
const mockLogin = vi.fn()
vi.mock('../../hooks/useAuth', () => ({
  useAuth: () => ({ login: mockLogin }),
}))

describe('LoginForm', () => {
  it('应渲染登录表单', () => {
    render(<LoginForm />)

    expect(screen.getByLabelText(/邮箱/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/密码/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /登录/i })).toBeInTheDocument()
  })

  it('应验证必填字段', async () => {
    const user = userEvent.setup()
    render(<LoginForm />)

    await user.click(screen.getByRole('button', { name: /登录/i }))

    await waitFor(() => {
      expect(screen.getByText(/请输入邮箱/i)).toBeInTheDocument()
      expect(screen.getByText(/请输入密码/i)).toBeInTheDocument()
    })
  })

  it('应调用 login 函数', async () => {
    mockLogin.mockResolvedValueOnce(undefined)
    const user = userEvent.setup()
    render(<LoginForm />)

    await user.type(screen.getByLabelText(/邮箱/i), 'test@example.com')
    await user.type(screen.getByLabelText(/密码/i), 'Secure123!')
    await user.click(screen.getByRole('button', { name: /登录/i }))

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'Secure123!',
      })
    })
  })

  it('登录失败应显示错误信息', async () => {
    mockLogin.mockRejectedValueOnce(new Error('账号或密码错误'))
    const user = userEvent.setup()
    render(<LoginForm />)

    await user.type(screen.getByLabelText(/邮箱/i), 'bad@example.com')
    await user.type(screen.getByLabelText(/密码/i), 'wrong')
    await user.click(screen.getByRole('button', { name: /登录/i }))

    await waitFor(() => {
      expect(screen.getByText(/账号或密码错误/i)).toBeInTheDocument()
    })
  })
})
```

### Mock Service Worker (MSW)

```ts
// frontend/src/test/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.post('/api/auth/login', async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string }

    if (body.email === 'test@example.com' && body.password === 'Secure123!') {
      return HttpResponse.json({ token: 'fake-jwt-token' })
    }

    return HttpResponse.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    )
  }),

  http.get('/api/users/me', () => {
    return HttpResponse.json({
      id: '1',
      name: '测试用户',
      email: 'test@example.com',
    })
  }),
]
```

```ts
// frontend/src/test/server.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

```ts
// frontend/src/test/setup.ts
import '@testing-library/jest-dom'
import { server } from './server'
import { beforeAll, afterEach, afterAll } from 'vitest'

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

---

## 4. Playwright E2E 测试

### 安装和配置

```bash
npm init playwright@latest
```

```ts
// e2e/playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['json', { outputFile: 'results.json' }]],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: [
    {
      command: 'cd backend && npm run dev',
      port: 4000,
      reuseExistingServer: !process.env.CI,
    },
    {
      command: 'cd frontend && npm run dev',
      port: 3000,
      reuseExistingServer: !process.env.CI,
    },
  ],
})
```

### E2E 测试示例

```ts
// e2e/tests/auth.spec.ts
import { test, expect } from '@playwright/test'

test.describe('用户认证流程', () => {
  test('完整注册登录流程', async ({ page }) => {
    // 注册
    await page.goto('/register')
    await page.fill('[name="name"]', 'E2E用户')
    await page.fill('[name="email"]', `e2e-${Date.now()}@test.com`)
    await page.fill('[name="password"]', 'SecureE2E123!')
    await page.click('button[type="submit"]')

    // 验证跳转到登录页
    await expect(page).toHaveURL('/login')

    // 登录
    await page.fill('[name="email"]', `e2e-${Date.now()}@test.com`)
    await page.fill('[name="password"]', 'SecureE2E123!')
    await page.click('button[type="submit"]')

    // 验证登录成功
    await expect(page).toHaveURL('/dashboard')
    await expect(page.getByText('欢迎')).toBeVisible()
  })

  test('无效凭证应显示错误', async ({ page }) => {
    await page.goto('/login')
    await page.fill('[name="email"]', 'wrong@test.com')
    await page.fill('[name="password"]', 'wrong')
    await page.click('button[type="submit"]')

    await expect(page.getByText(/登录失败/i)).toBeVisible()
  })

  test('受保护页面未登录应跳转', async ({ page }) => {
    await page.goto('/dashboard')
    await expect(page).toHaveURL('/login')
  })
})
```

```ts
// e2e/tests/todo.spec.ts
import { test, expect } from '@playwright/test'

test.describe('待办事项 CRUD', () => {
  test.beforeEach(async ({ page }) => {
    // 使用 API 登录，跳过 UI
    const response = await page.request.post('/api/auth/login', {
      data: { email: 'e2e@test.com', password: 'SecureE2E123!' },
    })
    const { token } = await response.json()
    await page.context().addCookies([
      { name: 'token', value: token, domain: 'localhost', path: '/' },
    ])
    await page.goto('/todos')
  })

  test('应能添加待办事项', async ({ page }) => {
    await page.fill('[placeholder="添加新任务"]', '学习 E2E 测试')
    await page.click('button:text("添加")')

    await expect(page.getByText('学习 E2E 测试')).toBeVisible()
  })

  test('应能完成待办事项', async ({ page }) => {
    await page.fill('[placeholder="添加新任务"]', '将被完成')
    await page.click('button:text("添加")')

    await page.click('input[type="checkbox"]')
    await expect(page.getByText('将被完成')).toHaveCSS(
      'text-decoration-line',
      'line-through'
    )
  })

  test('应能删除待办事项', async ({ page }) => {
    await page.fill('[placeholder="添加新任务"]', '将被删除')
    await page.click('button:text("添加")')

    page.on('dialog', (dialog) => dialog.accept())
    await page.click('button:text("删除")')

    await expect(page.getByText('将被删除')).not.toBeVisible()
  })
})
```

---

## 5. 测试覆盖率

### package.json 脚本

```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui"
  }
}
```

### 运行覆盖率报告

```bash
# 后端覆盖率
cd backend && npm run test:coverage

# 前端覆盖率
cd frontend && npm run test:coverage

# 生成 HTML 报告后在浏览器打开
open backend/coverage/index.html
```

### 覆盖率阈值配置

```ts
// vitest.config.ts
coverage: {
  provider: 'v8',
  thresholds: {
    // 全局最低要求
    lines: 80,
    functions: 80,
    branches: 80,
    statements: 80,
  },
}
```

---

## 6. 测试最佳实践

### 命名规范

```ts
// ✅ 好的命名：描述行为
describe('用户注册', () => {
  it('重复邮箱应返回 409 冲突错误', () => {})
  it('密码少于8位应返回 400 验证错误', () => {})
})

// ❌ 差的命名：描述实现
describe('POST /users', () => {
  it('should return 409', () => {})
})
```

### 测试原则

1. **AAA 模式**：Arrange（准备）→ Act（执行）→ Assert（断言）
2. **独立性**：每个测试互不依赖，可单独运行
3. **快速反馈**：单元测试 < 100ms，集成测试 < 1s
4. **确定性**：相同输入总是产生相同结果
5. **可读性**：测试即文档

---

## 今日总结

- 配置了 Vitest 作为单元/集成测试框架
- 使用 Supertest 测试 Express API 路由
- 使用 React Testing Library + MSW 测试前端组件
- 使用 Playwright 进行端到端测试
- 配置了测试覆盖率阈值
- 掌握了测试金字塔和 AAA 测试模式
