---
title: Day 48 - E2E 测试（Playwright）
date: 2026-05-29
tags:
  - playwright
  - e2e测试
  - 端到端测试
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 48 - E2E 测试（Playwright）

## 📚 学习目标
- 理解 E2E 测试的重要性
- 掌握 Playwright 的配置和使用
- 学会编写端到端测试

## 🎯 核心概念

### 1. E2E 测试 vs 单元测试

#### 区别
| 特性 | 单元测试 | E2E 测试 |
|------|----------|----------|
| 范围 | 单个函数/组件 | 整个应用 |
| 速度 | 快 | 慢 |
| 依赖 | 模拟 | 真实环境 |
| 维护 | 低 | 高 |
| 可靠性 | 高 | 中 |

### 2. Playwright 配置

#### 安装
```bash
npm init playwright@latest
```

#### 配置文件
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### 3. 编写 E2E 测试

#### 基本测试
```typescript
// e2e/homepage.spec.ts
import { test, expect } from '@playwright/test';

test('首页应该正确显示', async ({ page }) => {
  await page.goto('/');
  
  await expect(page).toHaveTitle(/Knowledge Hub/);
  await expect(page.getByRole('heading', { name: '管理知识更高效' })).toBeVisible();
});
```

#### 导航测试
```typescript
test('应该能够导航到文章页面', async ({ page }) => {
  await page.goto('/');
  
  await page.getByRole('link', { name: '浏览文章' }).click();
  
  await expect(page).toHaveURL('/articles');
  await expect(page.getByRole('heading', { name: '文章' })).toBeVisible();
});
```

#### 表单测试
```typescript
test('应该能够登录', async ({ page }) => {
  await page.goto('/login');
  
  await page.getByLabel('邮箱').fill('alice@example.com');
  await page.getByLabel('密码').fill('password123');
  await page.getByRole('button', { name: '登录' }).click();
  
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText('Alice Johnson')).toBeVisible();
});
```

### 4. 页面对象模式

#### 创建页面对象
```typescript
// e2e/pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel('邮箱');
    this.passwordInput = page.getByLabel('密码');
    this.submitButton = page.getByRole('button', { name: '登录' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }
}
```

#### 使用页面对象
```typescript
// e2e/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';

test('应该能够登录', async ({ page }) => {
  const loginPage = new LoginPage(page);
  
  await loginPage.goto();
  await loginPage.login('alice@example.com', 'password123');
  
  await expect(page).toHaveURL('/dashboard');
});

test('应该显示错误信息', async ({ page }) => {
  const loginPage = new LoginPage(page);
  
  await loginPage.goto();
  await loginPage.login('wrong@example.com', 'wrongpassword');
  
  const error = await loginPage.getErrorMessage();
  expect(error).toContain('登录失败');
});
```

### 5. 高级功能

#### 截图和视频
```typescript
test('应该捕获截图', async ({ page }) => {
  await page.goto('/');
  await page.screenshot({ path: 'screenshot.png', fullPage: true });
});
```

#### 网络拦截
```typescript
test('应该模拟 API 响应', async ({ page }) => {
  await page.route('/api/users', (route) => {
    route.fulfill({
      status: 200,
      body: JSON.stringify([{ id: '1', name: 'Test User' }]),
    });
  });
  
  await page.goto('/users');
  await expect(page.getByText('Test User')).toBeVisible();
});
```

#### 多标签页测试
```typescript
test('应该处理多标签页', async ({ page, context }) => {
  const newPage = await context.newPage();
  
  await page.goto('/');
  await newPage.goto('/about');
  
  await expect(page).toHaveURL('/');
  await expect(newPage).toHaveURL('/about');
});
```

## 🔧 实战练习

### 练习 1：测试购物车流程
```typescript
// e2e/cart.spec.ts
import { test, expect } from '@playwright/test';

test.describe('购物车流程', () => {
  test('应该能够添加商品到购物车', async ({ page }) => {
    await page.goto('/products');
    
    // 点击第一个商品的"添加到购物车"按钮
    await page.getByRole('button', { name: '添加到购物车' }).first().click();
    
    // 验证购物车图标显示数量
    await expect(page.getByTestId('cart-count')).toHaveText('1');
  });

  test('应该能够查看购物车', async ({ page }) => {
    await page.goto('/cart');
    
    // 验证购物车页面显示
    await expect(page.getByRole('heading', { name: '购物车' })).toBeVisible();
  });

  test('应该能够结算', async ({ page }) => {
    await page.goto('/cart');
    
    // 点击结算按钮
    await page.getByRole('button', { name: '去结算' }).click();
    
    // 验证跳转到结算页面
    await expect(page).toHaveURL('/checkout');
  });
});
```

### 练习 2：测试搜索功能
```typescript
// e2e/search.spec.ts
import { test, expect } from '@playwright/test';

test.describe('搜索功能', () => {
  test('应该能够搜索文章', async ({ page }) => {
    await page.goto('/articles');
    
    // 输入搜索关键词
    await page.getByPlaceholder('搜索文章...').fill('React');
    await page.getByRole('button', { name: '搜索' }).click();
    
    // 验证搜索结果
    await expect(page.getByText('React')).toBeVisible();
  });

  test('应该显示无结果提示', async ({ page }) => {
    await page.goto('/articles');
    
    await page.getByPlaceholder('搜索文章...').fill('不存在的内容');
    await page.getByRole('button', { name: '搜索' }).click();
    
    await expect(page.getByText('没有找到相关文章')).toBeVisible();
  });
});
```

### 练习 3：测试响应式布局
```typescript
// e2e/responsive.spec.ts
import { test, expect } from '@playwright/test';

test.describe('响应式布局', () => {
  test('应该在移动端显示汉堡菜单', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    
    // 验证汉堡菜单可见
    await expect(page.getByRole('button', { name: '菜单' })).toBeVisible();
  });

  test('应该在桌面端显示导航栏', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto('/');
    
    // 验证导航栏可见
    await expect(page.getByRole('navigation')).toBeVisible();
  });
});
```

## 📝 最佳实践

### 1. 使用页面对象模式
```typescript
// 好
const loginPage = new LoginPage(page);
await loginPage.login(email, password);

// 不好
await page.fill('#email', email);
await page.fill('#password', password);
await page.click('#submit');
```

### 2. 等待元素可见
```typescript
// 好
await expect(element).toBeVisible();

// 不好
await page.waitForTimeout(1000);
```

### 3. 使用语义化查询
```typescript
// 好
page.getByRole('button', { name: '提交' });
page.getByLabel('邮箱');

// 不好
page.locator('#submit-button');
page.locator('.email-input');
```

## 🎓 今日总结

**关键知识点：**
1. Playwright 是现代化的 E2E 测试框架
2. 页面对象模式提高测试可维护性
3. 使用语义化查询提高测试可读性
4. 支持多浏览器和移动端测试
5. 支持截图、视频和网络拦截

**明日计划：**
- Day 49: 无障碍访问（a11y）
