---
title: Day 47 - React Testing Library
date: 2026-05-29
tags:
  - react-testing-library
  - 测试
  - 组件测试
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 47 - React Testing Library

## 📚 学习目标
- 掌握 React Testing Library 的使用
- 学会测试 React 组件
- 理解用户行为驱动的测试

## 🎯 核心概念

### 1. 核心原则

#### 测试行为而非实现
```typescript
// 好：测试用户看到的内容
render(<Button>点击</Button>);
expect(screen.getByText('点击')).toBeInTheDocument();

// 不好：测试内部状态
expect(component.state.count).toBe(0);
```

#### 查询优先级
```typescript
// 优先使用这些查询
getByRole       // 推荐
getByLabelText  // 表单元素
getByPlaceholderText
getByText

// 避免使用
getByTestId     // 最后的手段
```

### 2. 基本测试

#### 渲染组件
```typescript
import { render, screen } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('应该渲染按钮文本', () => {
    render(<Button>点击</Button>);
    expect(screen.getByText('点击')).toBeInTheDocument();
  });

  it('应该调用 onClick', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();
    
    render(<Button onClick={handleClick}>点击</Button>);
    await user.click(screen.getByText('点击'));
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### 3. 查询元素

#### getBy 系列
```typescript
// getByText - 通过文本查找
screen.getByText('Hello');
screen.getByText(/hello/i); // 正则

// getByRole - 通过角色查找
screen.getByRole('button', { name: '提交' });
screen.getByRole('textbox', { name: '邮箱' });
screen.getByRole('heading', { level: 1 });

// getByLabelText - 通过标签查找
screen.getByLabelText('用户名');

// getByPlaceholderText - 通过占位符查找
screen.getByPlaceholderText('请输入邮箱');

// getByTestId - 通过测试 ID 查找（最后手段）
screen.getByTestId('custom-element');
```

#### queryBy 系列
```typescript
// queryByText - 不存在时返回 null
const element = screen.queryByText('不存在');
expect(element).not.toBeInTheDocument();

// queryAllBy - 返回数组
const items = screen.queryAllByRole('listitem');
expect(items).toHaveLength(3);
```

#### findBy 系列
```typescript
// findByText - 异步等待元素出现
const element = await screen.findByText('加载完成');
expect(element).toBeInTheDocument();

// findByRole
const button = await screen.findByRole('button', { name: '提交' });
expect(button).toBeInTheDocument();
```

### 4. 用户交互

#### 使用 userEvent
```typescript
import userEvent from '@testing-library/user-event';

describe('表单交互', () => {
  it('应该输入文本', async () => {
    const user = userEvent.setup();
    render(<input placeholder="请输入" />);
    
    const input = screen.getByPlaceholderText('请输入');
    await user.type(input, 'Hello');
    
    expect(input).toHaveValue('Hello');
  });

  it('应该点击按钮', async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();
    render(<button onClick={handleClick}>点击</button>);
    
    await user.click(screen.getByText('点击'));
    
    expect(handleClick).toHaveBeenCalled();
  });

  it('应该选择选项', async () => {
    const user = userEvent.setup();
    render(
      <select>
        <option value="1">选项1</option>
        <option value="2">选项2</option>
      </select>
    );
    
    await user.selectOptions(screen.getByRole('combobox'), '2');
    
    expect(screen.getByRole('option', { name: '选项2' }).selected).toBe(true);
  });
});
```

### 5. 测试异步组件

#### 测试加载状态
```typescript
describe('异步组件', () => {
  it('应该显示加载状态', () => {
    render(<UserProfile userId="1" />);
    
    expect(screen.getByText('加载中...')).toBeInTheDocument();
  });

  it('应该显示用户数据', async () => {
    render(<UserProfile userId="1" />);
    
    const userName = await screen.findByText('John Doe');
    expect(userName).toBeInTheDocument();
  });

  it('应该显示错误信息', async () => {
    vi.mocked(fetchUser).mockRejectedValue(new Error('Failed'));
    
    render(<UserProfile userId="1" />);
    
    const error = await screen.findByText('加载失败');
    expect(error).toBeInTheDocument();
  });
});
```

### 6. 测试表单

```typescript
describe('登录表单', () => {
  it('应该提交表单数据', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    
    render(<LoginForm onSubmit={onSubmit} />);
    
    await user.type(screen.getByLabelText('邮箱'), 'test@example.com');
    await user.type(screen.getByLabelText('密码'), 'password123');
    await user.click(screen.getByRole('button', { name: '登录' }));
    
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });

  it('应该显示验证错误', async () => {
    const user = userEvent.setup();
    
    render(<LoginForm />);
    
    await user.click(screen.getByRole('button', { name: '登录' }));
    
    expect(screen.getByText('邮箱不能为空')).toBeInTheDocument();
    expect(screen.getByText('密码不能为空')).toBeInTheDocument();
  });
});
```

## 🔧 实战练习

### 练习 1：测试按钮组件
```typescript
// Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('应该渲染按钮', () => {
    render(<Button>点击</Button>);
    expect(screen.getByRole('button', { name: '点击' })).toBeInTheDocument();
  });

  it('应该调用 onClick', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    
    render(<Button onClick={onClick}>点击</Button>);
    await user.click(screen.getByRole('button'));
    
    expect(onClick).toHaveBeenCalled();
  });

  it('应该禁用状态', () => {
    render(<Button disabled>点击</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('应该显示加载状态', () => {
    render(<Button isLoading>提交</Button>);
    expect(screen.getByText('加载中...')).toBeInTheDocument();
  });
});
```

### 练习 2：测试列表组件
```typescript
// TodoList.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TodoList } from './TodoList';

describe('TodoList', () => {
  const todos = [
    { id: '1', text: '学习 React', completed: false },
    { id: '2', text: '学习测试', completed: true },
  ];

  it('应该渲染列表', () => {
    render(<TodoList todos={todos} />);
    
    expect(screen.getByText('学习 React')).toBeInTheDocument();
    expect(screen.getByText('学习测试')).toBeInTheDocument();
  });

  it('应该显示完成状态', () => {
    render(<TodoList todos={todos} />);
    
    const checkbox = screen.getByRole('checkbox', { name: '学习测试' });
    expect(checkbox).toBeChecked();
  });

  it('应该切换完成状态', async () => {
    const user = userEvent.setup();
    const onToggle = vi.fn();
    
    render(<TodoList todos={todos} onToggle={onToggle} />);
    await user.click(screen.getByRole('checkbox', { name: '学习 React' }));
    
    expect(onToggle).toHaveBeenCalledWith('1');
  });

  it('应该删除待办', async () => {
    const user = userEvent.setup();
    const onDelete = vi.fn();
    
    render(<TodoList todos={todos} onDelete={onDelete} />);
    await user.click(screen.getByRole('button', { name: '删除学习 React' }));
    
    expect(onDelete).toHaveBeenCalledWith('1');
  });
});
```

### 练习 3：测试模态框
```typescript
// Modal.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Modal } from './Modal';

describe('Modal', () => {
  it('应该打开模态框', () => {
    render(
      <Modal isOpen={true} onClose={() => {}}>
        <h2>模态框标题</h2>
        <p>模态框内容</p>
      </Modal>
    );
    
    expect(screen.getByText('模态框标题')).toBeInTheDocument();
    expect(screen.getByText('模态框内容')).toBeInTheDocument();
  });

  it('应该关闭模态框', async () => {
    const user = userEvent.setup();
    const onClose = vi.fn();
    
    render(
      <Modal isOpen={true} onClose={onClose}>
        <h2>模态框标题</h2>
      </Modal>
    );
    
    await user.click(screen.getByRole('button', { name: '关闭' }));
    
    expect(onClose).toHaveBeenCalled();
  });

  it('应该点击遮罩层关闭', async () => {
    const user = userEvent.setup();
    const onClose = vi.fn();
    
    render(
      <Modal isOpen={true} onClose={onClose}>
        <h2>模态框标题</h2>
      </Modal>
    );
    
    await user.click(screen.getByTestId('modal-overlay'));
    
    expect(onClose).toHaveBeenCalled();
  });
});
```

## 📝 最佳实践

### 1. 使用 userEvent
```typescript
// 好
const user = userEvent.setup();
await user.click(button);

// 不好
fireEvent.click(button);
```

### 2. 使用 findBy 处理异步
```typescript
// 好
const element = await screen.findByText('加载完成');

// 不好
await waitFor(() => {
  expect(screen.getByText('加载完成')).toBeInTheDocument();
});
```

### 3. 测试可访问性
```typescript
// 好：使用 role 查询
screen.getByRole('button', { name: '提交' });

// 不好：使用 testId
screen.getByTestId('submit-button');
```

## 🎓 今日总结

**关键知识点：**
1. React Testing Library 测试用户行为
2. 查询优先级：getByRole > getByText > getByTestId
3. 使用 userEvent 模拟用户交互
4. 使用 findBy 处理异步操作
5. 测试表单和异步组件

**明日计划：**
- Day 48: E2E 测试（Playwright）
