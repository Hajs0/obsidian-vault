---
title: Day 41 - 自定义设计系统
date: 2026-05-29
tags:
  - tailwindcss
  - 设计系统
  - 设计令牌
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 41 - 自定义设计系统

## 📚 学习目标
- 理解设计系统的核心概念
- 掌握 Tailwind CSS 设计令牌配置
- 学会创建可复用的设计系统

## 🎯 核心概念

### 1. 设计令牌（Design Tokens）

#### 颜色系统
```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
          950: '#082f49',
        },
        neutral: {
          50: '#fafafa',
          100: '#f5f5f5',
          200: '#e5e5e5',
          300: '#d4d4d4',
          400: '#a3a3a3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          900: '#171717',
          950: '#0a0a0a',
        },
        success: {
          50: '#f0fdf4',
          500: '#22c55e',
          900: '#14532d',
        },
        warning: {
          50: '#fffbeb',
          500: '#f59e0b',
          900: '#78350f',
        },
        error: {
          50: '#fef2f2',
          500: '#ef4444',
          900: '#7f1d1d',
        },
      },
    },
  },
};

export default config;
```

#### 字体系统
```typescript
// tailwind.config.ts
const config: Config = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        serif: ['Merriweather', 'Georgia', 'serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
        '6xl': ['3.75rem', { lineHeight: '1' }],
      },
    },
  },
};
```

#### 间距系统
```typescript
// tailwind.config.ts
const config: Config = {
  theme: {
    extend: {
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
        '144': '36rem',
      },
      borderRadius: {
        '4xl': '2rem',
        '5xl': '2.5rem',
      },
    },
  },
};
```

### 2. 组件设计原则

#### 原子设计方法论
```typescript
// 原子（Atoms）
const Button = ({ children, variant = 'primary', size = 'md' }) => {
  const baseStyles = 'inline-flex items-center justify-center font-medium rounded-lg transition-colors';
  
  const variants = {
    primary: 'bg-primary-500 text-white hover:bg-primary-600',
    secondary: 'bg-neutral-200 text-neutral-800 hover:bg-neutral-300',
    outline: 'border-2 border-primary-500 text-primary-500 hover:bg-primary-50',
    ghost: 'text-primary-500 hover:bg-primary-50',
  };
  
  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };
  
  return (
    <button className={`${baseStyles} ${variants[variant]} ${sizes[size]}`}>
      {children}
    </button>
  );
};

// 分子（Molecules）
const SearchBar = ({ onSearch }) => {
  const [query, setQuery] = useState('');
  
  return (
    <div className="flex items-center gap-2">
      <Input
        type="search"
        placeholder="搜索..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      <Button onClick={() => onSearch(query)}>搜索</Button>
    </div>
  );
};

// 有机体（Organisms）
const Header = () => {
  return (
    <header className="bg-white shadow-sm">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Logo />
        <Navigation />
        <SearchBar onSearch={handleSearch} />
      </div>
    </header>
  );
};
```

### 3. 主题配置

#### CSS 变量方式
```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  /* 颜色 */
  --color-primary: #0ea5e9;
  --color-primary-light: #38bdf8;
  --color-primary-dark: #0284c7;
  
  /* 字体 */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', Fira Code, monospace;
  
  /* 间距 */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  
  /* 圆角 */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 1rem;
  --radius-full: 9999px;
  
  /* 阴影 */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
}

@layer base {
  body {
    font-family: var(--font-sans);
    color: var(--color-neutral-900);
    background-color: var(--color-neutral-50);
  }
}

@layer components {
  .btn-primary {
    @apply bg-[var(--color-primary)] text-white px-4 py-2 rounded-[var(--radius-md)] 
           hover:bg-[var(--color-primary-dark)] transition-colors;
  }
  
  .card {
    @apply bg-white rounded-[var(--radius-lg)] shadow-[var(--shadow-md)] p-6;
  }
}
```

### 4. 响应式设计系统

#### 断点配置
```typescript
// tailwind.config.ts
const config: Config = {
  theme: {
    screens: {
      'xs': '475px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
    },
  },
};
```

#### 容器配置
```typescript
// tailwind.config.ts
const config: Config = {
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: '1rem',
        sm: '2rem',
        lg: '4rem',
        xl: '5rem',
        '2xl': '6rem',
      },
    },
  },
};
```

## 🔧 实战练习

### 练习 1：创建按钮组件库
```typescript
// components/ui/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-primary-500 text-white hover:bg-primary-600 focus-visible:ring-primary-500',
        secondary: 'bg-neutral-200 text-neutral-800 hover:bg-neutral-300 focus-visible:ring-neutral-500',
        outline: 'border-2 border-primary-500 text-primary-500 hover:bg-primary-50 focus-visible:ring-primary-500',
        ghost: 'text-primary-500 hover:bg-primary-50 focus-visible:ring-primary-500',
        destructive: 'bg-error-500 text-white hover:bg-error-600 focus-visible:ring-error-500',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-base',
        lg: 'h-12 px-6 text-lg',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  isLoading?: boolean;
}

export function Button({ 
  className, 
  variant, 
  size, 
  isLoading, 
  children, 
  ...props 
}: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      disabled={isLoading}
      {...props}
    >
      {isLoading && (
        <svg
          className="mr-2 h-4 w-4 animate-spin"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
          />
        </svg>
      )}
      {children}
    </button>
  );
}
```

### 练习 2：创建卡片组件
```typescript
// components/ui/Card.tsx
import { cn } from '@/lib/utils';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'bordered' | 'elevated';
}

export function Card({ className, variant = 'default', ...props }: CardProps) {
  const variants = {
    default: 'bg-white rounded-xl shadow-md',
    bordered: 'bg-white rounded-xl border-2 border-neutral-200',
    elevated: 'bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow',
  };

  return (
    <div
      className={cn(variants[variant], 'p-6', className)}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('mb-4', className)}
      {...props}
    />
  );
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn('text-xl font-semibold text-neutral-900', className)}
      {...props}
    />
  );
}

export function CardDescription({ className, ...props }: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p
      className={cn('text-sm text-neutral-500', className)}
      {...props}
    />
  );
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('text-neutral-700', className)}
      {...props}
    />
  );
}

export function CardFooter({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('mt-4 flex items-center gap-2', className)}
      {...props}
    />
  );
}
```

## 📝 最佳实践

### 1. 使用语义化类名
```typescript
// 好：语义化
<div className="bg-primary-500 text-white">...</div>

// 不好：硬编码
<div className="bg-blue-500 text-white">...</div>
```

### 2. 使用设计令牌
```typescript
// 好：使用配置
theme.extend.colors.primary

// 不好：直接写颜色值
bg-[#0ea5e9]
```

### 3. 组件变体使用 CVA
```typescript
import { cva } from 'class-variance-authority';

const buttonVariants = cva('base-styles', {
  variants: {
    variant: { ... },
    size: { ... },
  },
});
```

## 🎓 今日总结

**关键知识点：**
1. 设计令牌是设计系统的基础
2. Tailwind CSS 配置设计令牌
3. 原子设计方法论组织组件
4. CSS 变量实现主题切换
5. CVA 管理组件变体

**明日计划：**
- Day 42: 响应式设计进阶
