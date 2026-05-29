---
title: Day 46 - Vitest 入门
date: 2026-05-29
tags:
  - vitest
  - 测试
  - 单元测试
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 46 - Vitest 入门

## 📚 学习目标
- 理解测试的重要性
- 掌握 Vitest 的配置和使用
- 学会编写单元测试

## 🎯 核心概念

### 1. 为什么需要测试

#### 测试的好处
- 提高代码质量
- 减少 Bug
- 方便重构
- 提供文档
- 加速开发

#### 测试金字塔
```
       E2E 测试
      /        \
   集成测试
  /          \
单元测试
```

### 2. Vitest 配置

#### 安装
```bash
npm install -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
```

#### 配置文件
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    css: true,
  },
});
```

#### 测试设置
```typescript
// src/test/setup.ts
import '@testing-library/jest-dom';
```

### 3. 编写单元测试

#### 基本测试
```typescript
// src/lib/utils.test.ts
import { describe, it, expect } from 'vitest';
import { cn } from './utils';

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
```

#### 测试异步函数
```typescript
// src/lib/api.test.ts
import { describe, it, expect, vi } from 'vitest';
import { fetchUser } from './api';

describe('fetchUser', () => {
  it('应该获取用户数据', async () => {
    const mockUser = { id: '1', name: 'Test User' };
    
    vi.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockUser),
    } as Response);

    const user = await fetchUser('1');
    
    expect(user).toEqual(mockUser);
    expect(fetch).toHaveBeenCalledWith('/api/users/1');
  });

  it('应该处理请求失败', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValue({
      ok: false,
      status: 404,
    } as Response);

    await expect(fetchUser('1')).rejects.toThrow('Failed to fetch user');
  });
});
```

#### 测试类
```typescript
// src/lib/calculator.test.ts
import { describe, it, expect } from 'vitest';
import { Calculator } from './calculator';

describe('Calculator', () => {
  it('应该正确加法', () => {
    const calc = new Calculator();
    expect(calc.add(2, 3)).toBe(5);
  });

  it('应该正确减法', () => {
    const calc = new Calculator();
    expect(calc.subtract(5, 3)).toBe(2);
  });

  it('应该正确乘法', () => {
    const calc = new Calculator();
    expect(calc.multiply(2, 3)).toBe(6);
  });

  it('应该正确除法', () => {
    const calc = new Calculator();
    expect(calc.divide(6, 3)).toBe(2);
  });

  it('应该处理除零错误', () => {
    const calc = new Calculator();
    expect(() => calc.divide(1, 0)).toThrow('Cannot divide by zero');
  });
});
```

### 4. 测试覆盖率

#### 配置覆盖率
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
      ],
    },
  },
});
```

#### 运行覆盖率测试
```bash
npx vitest run --coverage
```

### 5. Mock 和 Spy

#### Mock 函数
```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Mock 函数', () => {
  it('应该调用 mock 函数', () => {
    const mockFn = vi.fn();
    mockFn('arg1', 'arg2');
    
    expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
    expect(mockFn).toHaveBeenCalledTimes(1);
  });

  it('应该返回 mock 值', () => {
    const mockFn = vi.fn().mockReturnValue('mocked');
    expect(mockFn()).toBe('mocked');
  });

  it('应该返回 mock 实现', () => {
    const mockFn = vi.fn((x: number) => x * 2);
    expect(mockFn(5)).toBe(10);
  });
});
```

#### Mock 模块
```typescript
import { describe, it, expect, vi } from 'vitest';

vi.mock('./api', () => ({
  fetchUser: vi.fn(),
}));

import { fetchUser } from './api';

describe('使用 mock 模块', () => {
  it('应该使用 mock 的 fetchUser', async () => {
    const mockUser = { id: '1', name: 'Test' };
    vi.mocked(fetchUser).mockResolvedValue(mockUser);
    
    const user = await fetchUser('1');
    expect(user).toEqual(mockUser);
  });
});
```

## 🔧 实战练习

### 练习 1：测试工具函数
```typescript
// src/lib/string.test.ts
import { describe, it, expect } from 'vitest';
import { capitalize, truncate, slugify } from './string';

describe('字符串工具函数', () => {
  describe('capitalize', () => {
    it('应该首字母大写', () => {
      expect(capitalize('hello')).toBe('Hello');
    });

    it('应该处理空字符串', () => {
      expect(capitalize('')).toBe('');
    });

    it('应该处理已经是大写的字符串', () => {
      expect(capitalize('Hello')).toBe('Hello');
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

  describe('slugify', () => {
    it('应该生成 slug', () => {
      expect(slugify('Hello World')).toBe('hello-world');
    });

    it('应该处理特殊字符', () => {
      expect(slugify('Hello! @World#')).toBe('hello-world');
    });
  });
});
```

### 练习 2：测试异步操作
```typescript
// src/lib/async.test.ts
import { describe, it, expect, vi } from 'vitest';
import { delay, retry } from './async';

describe('异步工具函数', () => {
  describe('delay', () => {
    it('应该延迟执行', async () => {
      vi.useFakeTimers();
      const promise = delay(1000);
      
      vi.advanceTimersByTime(1000);
      await promise;
      
      vi.useRealTimers();
    });
  });

  describe('retry', () => {
    it('应该重试失败的操作', async () => {
      let attempts = 0;
      const fn = vi.fn().mockImplementation(() => {
        attempts++;
        if (attempts < 3) {
          throw new Error('Failed');
        }
        return 'success';
      });

      const result = await retry(fn, 3);
      
      expect(result).toBe('success');
      expect(fn).toHaveBeenCalledTimes(3);
    });

    it('应该在超过重试次数后抛出错误', async () => {
      const fn = vi.fn().mockRejectedValue(new Error('Failed'));
      
      await expect(retry(fn, 3)).rejects.toThrow('Failed');
      expect(fn).toHaveBeenCalledTimes(3);
    });
  });
});
```

### 练习 3：测试状态管理
```typescript
// src/stores/counter.test.ts
import { describe, it, expect } from 'vitest';
import { useCounterStore } from './counter';

describe('Counter Store', () => {
  beforeEach(() => {
    useCounterStore.setState({ count: 0 });
  });

  it('应该初始化为 0', () => {
    expect(useCounterStore.getState().count).toBe(0);
  });

  it('应该增加计数', () => {
    useCounterStore.getState().increment();
    expect(useCounterStore.getState().count).toBe(1);
  });

  it('应该减少计数', () => {
    useCounterStore.getState().increment();
    useCounterStore.getState().decrement();
    expect(useCounterStore.getState().count).toBe(0);
  });

  it('应该重置计数', () => {
    useCounterStore.getState().increment();
    useCounterStore.getState().increment();
    useCounterStore.getState().reset();
    expect(useCounterStore.getState().count).toBe(0);
  });
});
```

## 📝 最佳实践

### 1. 测试命名清晰
```typescript
// 好
describe('UserService', () => {
  describe('getUser', () => {
    it('应该返回用户数据', async () => { ... });
    it('应该处理用户不存在', async () => { ... });
  });
});

// 不好
describe('UserService', () => {
  it('test1', () => { ... });
  it('test2', () => { ... });
});
```

### 2. 测试隔离
```typescript
beforeEach(() => {
  // 每个测试前重置状态
  useStore.setState({ ... });
});
```

### 3. 避免测试实现细节
```typescript
// 好：测试行为
it('应该显示用户名称', () => {
  render(<UserProfile user={{ name: 'John' }} />);
  expect(screen.getByText('John')).toBeInTheDocument();
});

// 不好：测试实现
it('应该调用 useState', () => {
  const spy = vi.spyOn(React, 'useState');
  render(<Component />);
  expect(spy).toHaveBeenCalled();
});
```

## 🎓 今日总结

**关键知识点：**
1. Vitest 是 Vite 原生测试框架
2. 使用 `describe`, `it`, `expect` 编写测试
3. 使用 `vi.fn()` 和 `vi.mock()` 进行 Mock
4. 测试覆盖率帮助发现未测试的代码
5. 遵循测试最佳实践

**明日计划：**
- Day 47: React Testing Library
