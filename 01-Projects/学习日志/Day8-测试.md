# Day 8 - 前端测试方法论

## 学习日期: 2026-05-29

---

## 一、测试金字塔

```
        /  E2E  \        少量、慢、高成本
       /----------\
      / Integration\     适量
     /--------------\
    /   Unit Tests   \   大量、快、低成本
   /==================\
```

**核心原则**: 底层单元测试数量最多，顶层E2E测试数量最少

---

## 二、Jest 单元测试

### 2.1 基础配置

```bash
npm install --save-dev jest @types/jest ts-jest
```

**jest.config.js**
```js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts?(x)', '**/?(*.)+(spec|test).ts?(x)'],
  moduleNameMapper: {
    '\\.(css|less|scss)$': 'identity-obj-proxy',
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/index.tsx'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

### 2.2 核心API

```typescript
// ===== 基础断言 =====
expect(value).toBe(expected)          // 严格相等 (===)
expect(value).toEqual(expected)       // 深度相等 (对象/数组)
expect(value).toBeTruthy()            // 真值
expect(value).toBeFalsy()             // 假值
expect(value).toBeNull()             // null
expect(value).toBeUndefined()        // undefined
expect(value).toBeDefined()          // 已定义
expect(value).toBeGreaterThan(n)     // 大于
expect(value).toBeGreaterThanOrEqual(n)
expect(value).toBeCloseTo(0.1)       // 浮点数近似
expect(array).toContain(item)         // 包含
expect(string).toMatch(/regex/)       // 正则匹配
expect(fn).toThrow(Error)             // 抛出异常
expect(mockFn).toBeCalled()           // 函数被调用
expect(mockFn).toBeCalledWith(args)   // 参数匹配
expect(mockFn).toHaveBeenCalledTimes(n)

// ===== 数组/对象 =====
expect(array).toHaveLength(3)
expect(array).toEqual(expect.arrayContaining([1, 2]))
expect(obj).toEqual(expect.objectContaining({ name: 'test' }))
expect(string).toEqual(expect.stringContaining('hello'))
```

### 2.3 测试结构

```typescript
describe('Calculator', () => {
  let calculator: Calculator;

  // 每个测试前执行
  beforeEach(() => {
    calculator = new Calculator();
  });

  // 每个测试后执行
  afterEach(() => {
    // 清理
  });

  // 所有测试前执行一次
  beforeAll(() => {
    // 全局设置
  });

  it('should add two numbers correctly', () => {
    expect(calculator.add(1, 2)).toBe(3);
  });

  it('should throw error when dividing by zero', () => {
    expect(() => calculator.divide(1, 0)).toThrow('Cannot divide by zero');
  });

  // 参数化测试
  test.each([
    [1, 1, 2],
    [2, 3, 5],
    [-1, 1, 0],
  ])('add(%i, %i) should return %i', (a, b, expected) => {
    expect(calculator.add(a, b)).toBe(expected);
  });
});
```

### 2.4 Mock 模拟

```typescript
// ===== Mock 函数 =====
const mockFn = jest.fn();
mockFn('hello');
expect(mockFn).toBeCalledWith('hello');

// 带返回值
const mockFn = jest.fn().mockReturnValue('result');
const mockFn = jest.fn().mockResolvedValue('async result');

// 实现特定逻辑
const mockFn = jest.fn((x) => x * 2);

// ===== Mock 模块 =====
jest.mock('@/utils/api', () => ({
  fetchUser: jest.fn().mockResolvedValue({ id: 1, name: 'Test User' }),
  fetchPosts: jest.fn().mockResolvedValue([]),
}));

// 部分Mock（保留原实现）
jest.mock('@/utils/api', () => ({
  ...jest.requireActual('@/utils/api'),
  fetchUser: jest.fn().mockResolvedValue({ id: 1, name: 'Test' }),
}));

// ===== Mock 类 =====
jest.mock('@/services/UserService');
const MockedUserService = jest.mocked(UserService);
MockedUserService.prototype.getUser.mockResolvedValue({ id: 1 });

// ===== Mock 定时器 =====
jest.useFakeTimers();
jest.advanceTimersByTime(1000);
jest.runAllTimers();
jest.useRealTimers();

// ===== Spy =====
const spy = jest.spyOn(object, 'methodName');
spy.mockReturnValue('mocked');
spy.mockImplementation((arg) => arg + ' modified');
spy.mockRestore(); // 恢复原实现
```

### 2.5 异步测试

```typescript
// Promise
it('fetches data', () => {
  return fetchData().then(data => {
    expect(data).toBe('result');
  });
});

// Async/Await (推荐)
it('fetches data async', async () => {
  const data = await fetchData();
  expect(data).toBe('result');
});

// 异步错误
it('handles error', async () => {
  await expect(fetchData()).rejects.toThrow('Network error');
});

// 回调
it('callback style', (done) => {
  fetchData((err, data) => {
    expect(data).toBe('result');
    done();
  });
});
```

---

## 三、React Testing Library (RTL)

### 3.1 核心理念

> "你的测试越像用户使用软件的方式，它们就越能给你信心。"
> — Kent C. Dodds

**原则**:
- 测试行为，不测试实现细节
- 像用户一样查询元素（优先级：Role > Text > Form > Display > TestId）
- 避免直接测试组件内部状态

### 3.2 安装配置

```bash
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

**setupTests.ts**
```typescript
import '@testing-library/jest-dom';
```

### 3.3 查询优先级

```
优先使用 ↓                               避免使用 ↓
─────────────────────────────────────────────────────
getByRole          ✅ 首选               container.querySelector  ❌
getByLabelText     ✅ 表单元素           enzyme .find()           ❌
getByPlaceholderText ✅                  直接访问 state/props     ❌
getByText          ✅ 非交互元素
getByDisplayValue  ✅
getByAltText       ✅ 图片
getByTitle         ✅
getByTestId        ⚠️ 最后手段
```

### 3.4 组件测试实例

```tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserProfile } from './UserProfile';

// ===== 基础渲染测试 =====
describe('UserProfile', () => {
  it('renders user name', () => {
    render(<UserProfile name="John" email="john@test.com" />);
    expect(screen.getByText('John')).toBeInTheDocument();
    expect(screen.getByText('john@test.com')).toBeInTheDocument();
  });

  // ===== 交互测试 =====
  it('toggles edit mode on button click', async () => {
    const user = userEvent.setup();
    render(<UserProfile name="John" />);

    const editButton = screen.getByRole('button', { name: /edit/i });
    await user.click(editButton);

    expect(screen.getByRole('textbox', { name: /name/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument();
  });

  // ===== 表单测试 =====
  it('submits updated name', async () => {
    const onSave = jest.fn();
    const user = userEvent.setup();
    render(<UserProfile name="John" onSave={onSave} />);

    await user.click(screen.getByRole('button', { name: /edit/i }));
    const input = screen.getByRole('textbox', { name: /name/i });
    await user.clear(input);
    await user.type(input, 'Jane');
    await user.click(screen.getByRole('button', { name: /save/i }));

    expect(onSave).toHaveBeenCalledWith({ name: 'Jane' });
  });

  // ===== 异步测试 =====
  it('loads and displays data', async () => {
    render(<UserProfile userId={1} />);

    // 等待loading消失
    expect(screen.getByText(/loading/i)).toBeInTheDocument();

    // 等待数据加载
    await waitFor(() => {
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
    });
    expect(screen.getByText('John')).toBeInTheDocument();
  });

  // ===== 异步查询（推荐方式） =====
  it('loads user asynchronously', async () => {
    render(<UserProfile userId={1} />);

    // findByText 自带等待
    const name = await screen.findByText('John');
    expect(name).toBeInTheDocument();
  });

  // ===== 条件渲染 =====
  it('shows error state', () => {
    render(<UserProfile error="Failed to load" />);
    expect(screen.getByRole('alert')).toHaveTextContent('Failed to load');
    expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
  });
});
```

### 3.5 Hook 测试

```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

it('increments count', () => {
  const { result } = renderHook(() => useCounter(0));

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});

// 带 Provider
it('uses context', () => {
  const wrapper = ({ children }) => (
    <AuthProvider value={mockUser}>{children}</AuthProvider>
  );
  const { result } = renderHook(() => useAuth(), { wrapper });
  expect(result.current.user).toEqual(mockUser);
});
```

### 3.6 自定义渲染（封装Provider）

```tsx
// test-utils.tsx
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

function AllProviders({ children }) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  });
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <AuthProvider>{children}</AuthProvider>
      </Router>
    </QueryClientProvider>
  );
}

function customRender(ui, options?) {
  return render(ui, { wrapper: AllProviders, ...options });
}

export { customRender as render };
```

---

## 四、E2E 测试

### 4.1 Cypress

**安装配置**
```bash
npm install --save-dev cypress
npx cypress open  # 首次运行会生成配置文件
```

**cypress.config.ts**
```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: false,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
    supportFile: 'cypress/support/e2e.ts',
    specPattern: 'cypress/e2e/**/*.cy.{js,ts}',
  },
});
```

**测试示例**
```typescript
// cypress/e2e/login.cy.ts
describe('Login Page', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('logs in successfully', () => {
    cy.get('[data-testid="email-input"]')
      .type('user@example.com');
    cy.get('[data-testid="password-input"]')
      .type('password123');
    cy.get('button[type="submit"]')
      .click();

    // 断言跳转
    cy.url().should('include', '/dashboard');
    cy.contains('Welcome').should('be.visible');
  });

  it('shows error for invalid credentials', () => {
    cy.get('[data-testid="email-input"]').type('wrong@email.com');
    cy.get('[data-testid="password-input"]').type('wrong');
    cy.get('button[type="submit"]').click();

    cy.get('[role="alert"]')
      .should('contain', 'Invalid credentials');
  });

  // 自定义命令
  it('uses custom login command', () => {
    cy.login('user@example.com', 'password123');
    cy.url().should('include', '/dashboard');
  });

  // API 拦截
  it('mocks API response', () => {
    cy.intercept('GET', '/api/users', { fixture: 'users.json' }).as('getUsers');
    cy.visit('/users');
    cy.wait('@getUsers');
    cy.get('[data-testid="user-list"]').should('have.length', 5);
  });
});

// cypress/support/commands.ts
Cypress.Commands.add('login', (email, password) => {
  cy.session([email, password], () => {
    cy.request({
      method: 'POST',
      url: '/api/auth/login',
      body: { email, password }
    });
  });
});
```

### 4.2 Playwright（推荐替代方案）

```bash
npm init playwright@latest
```

```typescript
import { test, expect } from '@playwright/test';

test.describe('Login', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('successful login', async ({ page }) => {
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Welcome')).toBeVisible();
  });

  // 截图对比
  test('visual regression', async ({ page }) => {
    await expect(page).toHaveScreenshot('login-page.png');
  });
});
```

### 4.3 Cypress vs Playwright 对比

| 特性 | Cypress | Playwright |
|------|---------|------------|
| 多标签页 | ❌ 不支持 | ✅ 原生支持 |
| 多浏览器 | Chrome/Firefox/Edge | Chrome/Firefox/Safari/WebKit |
| 并行执行 | 需付费Dashboard | ✅ 免费内置 |
| API测试 | ✅ | ✅ |
| 速度 | 较慢 | 较快 |
| 社区生态 | 成熟 | 快速增长 |
| 调试体验 | Time Travel | Trace Viewer |
| iframe支持 | 有限 | ✅ 完整 |

---

## 五、测试最佳实践

### 5.1 测试原则 (FIRST)

```
F - Fast       快速执行（毫秒级）
I - Independent 独立运行，不依赖其他测试
R - Repeatable  可重复，结果一致
S - Self-validating 自动验证，无需人工判断
T - Timely      及时编写，随功能一起
```

### 5.2 AAA 模式

```typescript
it('calculates total with tax', () => {
  // Arrange（准备）
  const items = [{ price: 10 }, { price: 20 }];
  const taxRate = 0.1;

  // Act（执行）
  const total = calculateTotal(items, taxRate);

  // Assert（断言）
  expect(total).toBe(33); // (10+20) * 1.1
});
```

### 5.3 测试命名规范

```typescript
// ✅ 推荐：描述行为
describe('ShoppingCart', () => {
  describe('when empty', () => {
    it('should show empty message', () => {});
    it('should disable checkout button', () => {});
  });
  describe('when items added', () => {
    it('should display item count', () => {});
    it('should calculate correct total', () => {});
  });
});

// ❌ 避免：描述实现
it('should set state to true', () => {});
it('should call the API', () => {});
```

### 5.4 常见反模式

```typescript
// ❌ 1. 测试实现细节
it('sets loading to true', () => {
  expect(component.state('loading')).toBe(true); // 不要测内部状态
});

// ✅ 改为测试用户可见的行为
it('shows loading indicator', () => {
  expect(screen.getByText(/loading/i)).toBeInTheDocument();
});

// ❌ 2. 过度Mock
jest.mock('./Button'); // Mock整个组件？不需要

// ❌ 3. 快照测试滥用
it('matches snapshot', () => {
  expect(component.toJSON()).toMatchSnapshot(); // 容易变成无意义测试
});

// ❌ 4. 测试间共享可变状态
let sharedData; // 每个测试应该独立

// ❌ 5. 无意义的测试
it('is a function', () => {
  expect(typeof myFunc).toBe('function');
});
```

### 5.5 测试策略决策树

```
要测什么？
├── 纯函数/工具方法 → Jest 单元测试
├── React 组件
│   ├── 用户交互 → RTL + userEvent
│   ├── 数据展示 → RTL 渲染+断言
│   └── 自定义Hook → renderHook
├── API调用 → Mock + 单元测试
├── 状态管理(Redux/Zustand) → 集成测试
└── 完整用户流程 → E2E (Playwright/Cypress)
```

---

## 六、测试覆盖率

### 6.1 覆盖率指标

| 指标 | 含义 | 目标 |
|------|------|------|
| **Statements** | 语句执行比例 | ≥ 80% |
| **Branches** | 分支(if/else)执行比例 | ≥ 80% |
| **Functions** | 函数调用比例 | ≥ 80% |
| **Lines** | 代码行执行比例 | ≥ 80% |

### 6.2 运行覆盖率

```bash
# 生成覆盖率报告
npx jest --coverage

# 查看HTML报告
open coverage/lcov-report/index.html
```

### 6.3 覆盖率配置

```js
// jest.config.js
module.exports = {
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{ts,tsx}',
    '!src/index.tsx',
    '!src/reportWebVitals.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    // 特定模块更高要求
    './src/utils/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  }
};
```

### 6.4 覆盖率陷阱

> **高覆盖率 ≠ 高质量测试**
>
> - 100% 覆盖率但只测 happy path = 虚假安全感
> - 重要的是测试**边界条件**和**错误路径**
> - 覆盖率是下限指标，不是目标

```typescript
// ❌ 为覆盖率而写的测试
it('calls function', () => {
  myFunction(); // 只调用，不验证结果
});

// ✅ 有意义的测试
it('returns sorted array', () => {
  expect(myFunction([3, 1, 2])).toEqual([1, 2, 3]);
});
it('handles empty array', () => {
  expect(myFunction([])).toEqual([]);
});
```

---

## 七、常用工具速查

| 工具 | 用途 |
|------|------|
| **Jest** | 测试运行器 + 断言 + Mock |
| **Vitest** | Vite生态的Jest替代，更快 |
| **React Testing Library** | React组件测试 |
| **MSW** | API Mock（Service Worker级别） |
| **Playwright** | E2E测试（推荐） |
| **Cypress** | E2E测试 |
| **Storybook** | 组件可视化开发+测试 |
| **Testing Library Queries** | 查询工具集 |

---

## 八、MSW Mock API

```typescript
// __tests__/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'John' },
      { id: 2, name: 'Jane' },
    ]);
  }),
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'John' });
  }),
  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 3, ...body }, { status: 201 });
  }),
];

// __tests__/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);

// setupTests.ts
import { server } from './mocks/server';
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## 九、今日总结

### 关键收获

1. **测试金字塔**: 单元测试为基础，E2E为保障
2. **Jest**: 强大的测试运行器，掌握Mock是关键
3. **RTL**: 测试用户行为而非实现细节
4. **E2E**: Playwright比Cypress更现代，推荐学习
5. **覆盖率**: 工具不是目标，测试质量比数量重要

### 下一步计划

- [ ] 在现有项目中添加单元测试
- [ ] 练习RTL组件测试
- [ ] 搭建Playwright E2E测试
- [ ] 学习MSW进行API Mock
- [ ] 配置CI/CD自动运行测试

---

## 参考资源

- [Jest 官方文档](https://jestjs.io/docs/getting-started)
- [Testing Library 文档](https://testing-library.com/docs/)
- [Playwright 文档](https://playwright.dev/)
- [Kent C. Dodds - Testing JavaScript](https://testingjavascript.com/)
- [MSW 文档](https://mswjs.io/)
