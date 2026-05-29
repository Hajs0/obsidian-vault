---
title: Day 43 - 暗色模式实现
date: 2026-05-29
tags:
  - tailwindcss
  - 暗色模式
  - 主题切换
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 43 - 暗色模式实现

## 📚 学习目标
- 掌握暗色模式的实现原理
- 学会使用 Tailwind 暗色模式
- 实现主题切换功能

## 🎯 核心概念

### 1. 暗色模式原理

#### CSS 变量方式
```css
:root {
  --color-bg: #ffffff;
  --color-text: #171717;
  --color-primary: #0ea5e9;
}

.dark {
  --color-bg: #0a0a0a;
  --color-text: #fafafa;
  --color-primary: #38bdf8;
}
```

#### Tailwind 暗色模式
```typescript
// tailwind.config.ts
const config: Config = {
  darkMode: 'class', // 使用 class 策略
  // ...
};
```

### 2. Tailwind 暗色模式

#### 基本用法
```html
<!-- 默认浅色，dark: 前缀为深色 -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  内容
</div>

<!-- 暗色模式下的卡片 -->
<div class="bg-white dark:bg-gray-800 shadow-md dark:shadow-gray-700/50 rounded-lg p-6">
  <h2 class="text-gray-900 dark:text-white">标题</h2>
  <p class="text-gray-600 dark:text-gray-300">内容</p>
</div>
```

#### 颜色系统配置
```typescript
// tailwind.config.ts
const config: Config = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: {
          DEFAULT: 'var(--background)',
          secondary: 'var(--background-secondary)',
        },
        foreground: {
          DEFAULT: 'var(--foreground)',
          secondary: 'var(--foreground-secondary)',
        },
        primary: {
          DEFAULT: 'var(--primary)',
          foreground: 'var(--primary-foreground)',
        },
      },
    },
  },
};
```

### 3. 主题切换实现

#### 使用 next-themes
```bash
npm install next-themes
```

#### 配置 ThemeProvider
```typescript
// app/providers.tsx
'use client';

import { ThemeProvider } from 'next-themes';

export function Providers({ children }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
    >
      {children}
    </ThemeProvider>
  );
}
```

#### 在布局中使用
```typescript
// app/layout.tsx
import { Providers } from './providers';

export default function RootLayout({ children }) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

#### 主题切换按钮
```typescript
// components/ThemeToggle.tsx
'use client';

import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return (
    <button
      onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
      className="p-2 rounded-lg bg-gray-200 dark:bg-gray-800"
    >
      {theme === 'dark' ? '🌞' : '🌙'}
    </button>
  );
}
```

### 4. CSS 变量实现

#### 定义 CSS 变量
```css
/* globals.css */
:root {
  --background: 0 0% 100%;
  --foreground: 0 0% 3.9%;
  
  --primary: 192 100% 50%;
  --primary-foreground: 0 0% 98%;
  
  --secondary: 0 0% 96.1%;
  --secondary-foreground: 0 0% 9%;
  
  --muted: 0 0% 96.1%;
  --muted-foreground: 0 0% 45.1%;
  
  --accent: 0 0% 96.1%;
  --accent-foreground: 0 0% 9%;
  
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 0 0% 98%;
  
  --border: 0 0% 89.8%;
  --input: 0 0% 89.8%;
  --ring: 192 100% 50%;
  
  --radius: 0.5rem;
}

.dark {
  --background: 0 0% 3.9%;
  --foreground: 0 0% 98%;
  
  --primary: 192 100% 50%;
  --primary-foreground: 0 0% 9%;
  
  --secondary: 0 0% 14.9%;
  --secondary-foreground: 0 0% 98%;
  
  --muted: 0 0% 14.9%;
  --muted-foreground: 0 0% 63.9%;
  
  --accent: 0 0% 14.9%;
  --accent-foreground: 0 0% 98%;
  
  --destructive: 0 62.8% 30.6%;
  --destructive-foreground: 0 0% 98%;
  
  --border: 0 0% 14.9%;
  --input: 0 0% 14.9%;
  --ring: 192 100% 50%;
}
```

#### 在 Tailwind 中使用
```typescript
// tailwind.config.ts
const config: Config = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
    },
  },
};
```

## 🔧 实战练习

### 练习 1：暗色模式卡片
```typescript
function DarkModeCard({ title, description }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md dark:shadow-gray-700/50 p-6 transition-colors">
      <h3 className="text-gray-900 dark:text-white text-xl font-semibold mb-2">
        {title}
      </h3>
      <p className="text-gray-600 dark:text-gray-300">
        {description}
      </p>
    </div>
  );
}
```

### 练习 2：暗色模式表单
```typescript
function DarkModeForm() {
  return (
    <form className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
          邮箱
        </label>
        <input
          type="email"
          className="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 
                     bg-white dark:bg-gray-800 
                     text-gray-900 dark:text-white
                     shadow-sm focus:border-primary-500 focus:ring-primary-500
                     dark:focus:border-primary-400 dark:focus:ring-primary-400"
        />
      </div>
      <button
        type="submit"
        className="w-full bg-primary-500 dark:bg-primary-400 
                   text-white dark:text-gray-900
                   rounded-md py-2 px-4 
                   hover:bg-primary-600 dark:hover:bg-primary-500
                   transition-colors"
      >
        提交
      </button>
    </form>
  );
}
```

### 练习 3：完整的主题切换
```typescript
// components/ThemeSwitcher.tsx
'use client';

import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const themes = [
  { name: 'light', icon: '🌞', label: '浅色' },
  { name: 'dark', icon: '🌙', label: '深色' },
  { name: 'system', icon: '💻', label: '系统' },
];

export function ThemeSwitcher() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  const currentTheme = themes.find((t) => t.name === theme) || themes[2];

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 p-2 rounded-lg bg-gray-200 dark:bg-gray-800"
      >
        <span>{currentTheme.icon}</span>
        <span className="hidden sm:inline">{currentTheme.label}</span>
      </button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden"
          >
            {themes.map((t) => (
              <button
                key={t.name}
                onClick={() => {
                  setTheme(t.name);
                  setIsOpen(false);
                }}
                className={`w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-gray-700 ${
                  theme === t.name ? 'bg-primary-50 dark:bg-primary-900/20' : ''
                }`}
              >
                <span>{t.icon}</span>
                <span className="text-gray-900 dark:text-white">{t.label}</span>
                {theme === t.name && (
                  <span className="ml-auto text-primary-500">✓</span>
                )}
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
```

## 📝 最佳实践

### 1. 使用 class 策略
```typescript
// tailwind.config.ts
darkMode: 'class'
```

### 2. 避免闪烁
```typescript
// 使用 suppressHydrationWarning
<html suppressHydrationWarning>
```

### 3. 平滑过渡
```css
/* 添加过渡效果 */
* {
  transition: background-color 0.2s, color 0.2s;
}
```

### 4. 图片适配
```html
<!-- 使用深色模式图片 -->
<img class="block dark:hidden" src="light-logo.svg" />
<img class="hidden dark:block" src="dark-logo.svg" />
```

## 🎓 今日总结

**关键知识点：**
1. Tailwind 暗色模式使用 `dark:` 前缀
2. 使用 `next-themes` 管理主题
3. CSS 变量实现主题颜色
4. 避免闪烁使用 `suppressHydrationWarning`
5. 平滑过渡使用 CSS transition

**明日计划：**
- Day 44: 组件库开发
