---
title: Day 37 - 页面过渡动画
date: 2026-05-29
tags:
  - framer-motion
  - 页面过渡
  - react
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 37 - 页面过渡动画

## 📚 学习目标
- 掌握页面过渡动画的实现
- 学会使用 AnimatePresence 处理路由切换
- 实现平滑的页面切换效果

## 🎯 核心概念

### 1. Next.js 页面过渡

#### 使用 AnimatePresence
```typescript
// app/layout.tsx
'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { usePathname } from 'next/navigation';

export default function RootLayout({ children }) {
  const pathname = usePathname();

  return (
    <html>
      <body>
        <AnimatePresence mode="wait">
          <motion.div
            key={pathname}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
          >
            {children}
          </motion.div>
        </AnimatePresence>
      </body>
    </html>
  );
}
```

### 2. 常见过渡效果

#### 淡入淡出
```typescript
const fadeVariants = {
  initial: { opacity: 0 },
  animate: { opacity: 1 },
  exit: { opacity: 0 },
};

function FadeTransition({ children }) {
  const pathname = usePathname();
  
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial="initial"
        animate="animate"
        exit="exit"
        variants={fadeVariants}
        transition={{ duration: 0.3 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

#### 滑动效果
```typescript
const slideVariants = {
  initial: { x: '100%', opacity: 0 },
  animate: { x: 0, opacity: 1 },
  exit: { x: '-100%', opacity: 0 },
};

function SlideTransition({ children }) {
  const pathname = usePathname();
  
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial="initial"
        animate="animate"
        exit="exit"
        variants={slideVariants}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

#### 缩放效果
```typescript
const scaleVariants = {
  initial: { scale: 0.8, opacity: 0 },
  animate: { scale: 1, opacity: 1 },
  exit: { scale: 1.1, opacity: 0 },
};

function ScaleTransition({ children }) {
  const pathname = usePathname();
  
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial="initial"
        animate="animate"
        exit="exit"
        variants={scaleVariants}
        transition={{ duration: 0.3 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

### 3. 方向感知过渡

#### 根据路由方向切换动画
```typescript
import { usePathname, useRouter } from 'next/navigation';

const routes = ['/', '/about', '/contact'];

function useRouteDirection() {
  const pathname = usePathname();
  const [prevPathname, setPrevPathname] = useState(pathname);
  const [direction, setDirection] = useState(0);

  useEffect(() => {
    if (pathname !== prevPathname) {
      const currentIndex = routes.indexOf(pathname);
      const prevIndex = routes.indexOf(prevPathname);
      setDirection(currentIndex > prevIndex ? 1 : -1);
      setPrevPathname(pathname);
    }
  }, [pathname, prevPathname]);

  return direction;
}

function DirectionalTransition({ children }) {
  const pathname = usePathname();
  const direction = useRouteDirection();

  const variants = {
    initial: { x: direction > 0 ? '100%' : '-100%', opacity: 0 },
    animate: { x: 0, opacity: 1 },
    exit: { x: direction > 0 ? '-100%' : '100%', opacity: 0 },
  };

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial="initial"
        animate="animate"
        exit="exit"
        variants={variants}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

### 4. 共享元素过渡

#### 使用 layoutId
```typescript
// 列表页
function ProductCard({ product }) {
  return (
    <motion.div layoutId={`product-${product.id}`}>
      <h2>{product.name}</h2>
      <p>{product.description}</p>
    </motion.div>
  );
}

// 详情页
function ProductDetail({ product }) {
  return (
    <motion.div layoutId={`product-${product.id}`}>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <p>{product.details}</p>
    </motion.div>
  );
}
```

### 5. 加载状态过渡

#### 骨架屏过渡
```typescript
function ContentWithSkeleton({ isLoading, children }) {
  return (
    <AnimatePresence mode="wait">
      {isLoading ? (
        <motion.div
          key="skeleton"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <Skeleton />
        </motion.div>
      ) : (
        <motion.div
          key="content"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

## 🔧 实战练习

### 练习 1：简单的页面过渡
```typescript
'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { usePathname } from 'next/navigation';

export function PageTransition({ children }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <motion.main
        key={pathname}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
        transition={{
          duration: 0.3,
          ease: [0.25, 0.46, 0.45, 0.94],
        }}
      >
        {children}
      </motion.main>
    </AnimatePresence>
  );
}
```

### 练习 2：带进度条的页面过渡
```typescript
'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';

export function PageTransitionWithProgress({ children }) {
  const pathname = usePathname();
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setIsLoading(true);
    const timer = setTimeout(() => setIsLoading(false), 300);
    return () => clearTimeout(timer);
  }, [pathname]);

  return (
    <>
      <AnimatePresence>
        {isLoading && (
          <motion.div
            initial={{ scaleX: 0 }}
            animate={{ scaleX: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="progress-bar"
          />
        )}
      </AnimatePresence>
      <AnimatePresence mode="wait">
        <motion.main
          key={pathname}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
        >
          {children}
        </motion.main>
      </AnimatePresence>
    </>
  );
}
```

### 练习 3：模态框过渡
```typescript
'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { useEffect } from 'react';

export function Modal({ isOpen, onClose, children }) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="modal-overlay"
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.8, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.8, opacity: 0, y: 20 }}
            transition={{
              type: 'spring',
              damping: 25,
              stiffness: 300,
            }}
            className="modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            {children}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

## 📝 最佳实践

### 1. 使用 mode="wait"
```typescript
// 好：等待退出动画完成后再进入
<AnimatePresence mode="wait">
  <motion.div key={pathname}>...</motion.div>
</AnimatePresence>

// 不好：新旧元素同时存在
<AnimatePresence>
  <motion.div key={pathname}>...</motion.div>
</AnimatePresence>
```

### 2. 使用 key 属性
```typescript
// 好：使用唯一标识
<motion.div key={pathname}>...</motion.div>

// 不好：没有 key
<motion.div>...</motion.div>
```

### 3. 优化性能
```typescript
// 好：使用 transform
<motion.div animate={{ x: 100, opacity: 1 }} />

// 不好：使用 layout 属性
<motion.div animate={{ width: 200 }} />
```

## 🎓 今日总结

**关键知识点：**
1. 使用 AnimatePresence 处理组件进出动画
2. 使用 mode="wait" 确保动画顺序
3. 使用 key 属性触发动画
4. 常见过渡效果：淡入淡出、滑动、缩放
5. 方向感知过渡提升用户体验
6. 共享元素过渡使用 layoutId

**明日计划：**
- Day 38: 手势与拖拽交互
