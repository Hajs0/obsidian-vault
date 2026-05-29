---
title: Day 44 - 组件库开发
date: 2026-05-29
tags:
  - tailwindcss
  - 组件库
  - shadcn/ui
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 44 - 组件库开发

## 📚 学习目标
- 掌握组件库的架构设计
- 学会使用 shadcn/ui
- 理解组件库的最佳实践

## 🎯 核心概念

### 1. 组件库架构

#### 目录结构
```
components/
├── ui/                 # 基础 UI 组件
│   ├── button.tsx
│   ├── input.tsx
│   ├── card.tsx
│   └── ...
├── layout/            # 布局组件
│   ├── header.tsx
│   ├── sidebar.tsx
│   └── footer.tsx
├── forms/             # 表单组件
│   ├── login-form.tsx
│   └── register-form.tsx
├── features/          # 功能组件
│   ├── dashboard/
│   └── settings/
└── shared/            # 共享组件
    ├── loading.tsx
    └── error-boundary.tsx
```

### 2. shadcn/ui 组件

#### 安装配置
```bash
npx shadcn@latest init
```

#### 添加组件
```bash
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add input
```

#### 组件示例
```typescript
// components/ui/button.tsx
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
```

### 3. 组件设计原则

#### 可组合性
```typescript
// 好：支持组合
<Card>
  <CardHeader>
    <CardTitle>标题</CardTitle>
    <CardDescription>描述</CardDescription>
  </CardHeader>
  <CardContent>内容</CardContent>
  <CardFooter>底部</CardFooter>
</Card>

// 不好：单一组件
<Card 
  title="标题" 
  description="描述" 
  content="内容" 
  footer="底部" 
/>
```

#### 可访问性
```typescript
// 使用 ARIA 属性
<button
  aria-label="关闭"
  aria-disabled={isDisabled}
  role="button"
>
  <CloseIcon />
</button>

// 使用 Radix UI 原语
import * as Dialog from '@radix-ui/react-dialog';

function Modal({ children }) {
  return (
    <Dialog.Root>
      <Dialog.Trigger>打开</Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay />
        <Dialog.Content>
          {children}
          <Dialog.Close>关闭</Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
```

### 4. 组件文档

#### Storybook 配置
```bash
npx storybook@latest init
```

#### 组件故事
```typescript
// stories/Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from '@/components/ui/button';

const meta: Meta<typeof Button> = {
  title: 'UI/Button',
  component: Button,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: ['default', 'destructive', 'outline', 'secondary', 'ghost', 'link'],
    },
    size: {
      control: { type: 'select' },
      options: ['default', 'sm', 'lg', 'icon'],
    },
  },
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    children: 'Button',
  },
};

export const Destructive: Story = {
  args: {
    variant: 'destructive',
    children: 'Destructive',
  },
};

export const Outline: Story = {
  args: {
    variant: 'outline',
    children: 'Outline',
  },
};

export const Small: Story = {
  args: {
    size: 'sm',
    children: 'Small',
  },
};

export const Large: Story = {
  args: {
    size: 'lg',
    children: 'Large',
  },
};
```

## 🔧 实战练习

### 练习 1：创建自定义组件库
```typescript
// components/ui/index.ts
export { Button, buttonVariants } from './button';
export { Input } from './input';
export { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from './card';
export { Badge, badgeVariants } from './badge';
export { Avatar, AvatarFallback, AvatarImage } from './avatar';
export { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './dialog';
export { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from './dropdown-menu';
export { Select, SelectTrigger, SelectContent, SelectItem, SelectValue } from './select';
export { Tabs, TabsList, TabsTrigger, TabsContent } from './tabs';
export { Toast, ToastProvider, ToastViewport } from './toast';
```

### 练习 2：创建表单组件
```typescript
// components/ui/form.tsx
import * as React from 'react';
import { cn } from '@/lib/utils';
import { Label } from './label';

interface FormFieldProps extends React.HTMLAttributes<HTMLDivElement> {
  label?: string;
  error?: string;
  description?: string;
}

export function FormField({ 
  label, 
  error, 
  description, 
  className, 
  children, 
  ...props 
}: FormFieldProps) {
  return (
    <div className={cn('space-y-2', className)} {...props}>
      {label && <Label>{label}</Label>}
      {children}
      {description && (
        <p className="text-sm text-muted-foreground">{description}</p>
      )}
      {error && (
        <p className="text-sm text-destructive">{error}</p>
      )}
    </div>
  );
}

export function FormMessage({ 
  error, 
  className, 
  ...props 
}: { error?: string } & React.HTMLAttributes<HTMLParagraphElement>) {
  if (!error) return null;
  
  return (
    <p
      className={cn('text-sm font-medium text-destructive', className)}
      {...props}
    >
      {error}
    </p>
  );
}
```

### 练习 3：创建布局组件
```typescript
// components/layout/page-header.tsx
import { cn } from '@/lib/utils';

interface PageHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ 
  title, 
  description, 
  actions, 
  className, 
  ...props 
}: PageHeaderProps) {
  return (
    <div className={cn('flex items-center justify-between', className)} {...props}>
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {description && (
          <p className="text-muted-foreground">{description}</p>
        )}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}

// components/layout/page-container.tsx
import { cn } from '@/lib/utils';

interface PageContainerProps extends React.HTMLAttributes<HTMLDivElement> {}

export function PageContainer({ className, ...props }: PageContainerProps) {
  return (
    <div
      className={cn('container mx-auto px-4 py-6 md:px-6 lg:px-8', className)}
      {...props}
    />
  );
}
```

## 📝 最佳实践

### 1. 使用 forwardRef
```typescript
const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, ...props }, ref) => {
    return <button ref={ref} className={className} {...props} />;
  }
);
```

### 2. 使用 TypeScript
```typescript
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'destructive' | 'outline';
  size?: 'default' | 'sm' | 'lg';
}
```

### 3. 使用 class-variance-authority
```typescript
import { cva } from 'class-variance-authority';

const buttonVariants = cva('base-styles', {
  variants: {
    variant: { ... },
    size: { ... },
  },
});
```

### 4. 提供文档
```typescript
/**
 * 按钮组件
 * 
 * @example
 * <Button variant="default" size="md">点击</Button>
 * <Button variant="destructive">删除</Button>
 */
```

## 🎓 今日总结

**关键知识点：**
1. 组件库架构设计
2. shadcn/ui 组件使用
3. 可组合性设计原则
4. 可访问性（ARIA）支持
5. 组件文档（Storybook）

**明日计划：**
- Day 45: 第六周总结
