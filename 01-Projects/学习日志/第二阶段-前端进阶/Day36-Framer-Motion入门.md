---
title: Day 36 - Framer Motion 入门
date: 2026-05-29
tags:
  - framer-motion
  - 动画
  - react
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 36 - Framer Motion 入门

## 📚 学习目标
- 理解 Framer Motion 的核心概念
- 掌握基本动画的实现
- 学会使用 AnimatePresence

## 🎯 核心概念

### 1. 安装与基本用法
```bash
npm install framer-motion
```

### 2. motion 组件
```typescript
import { motion } from 'framer-motion';

function Box() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      Hello Framer Motion
    </motion.div>
  );
}
```

### 3. 动画属性

#### 基本属性
```typescript
<motion.div
  // 初始状态
  initial={{ opacity: 0, scale: 0.5 }}
  // 目标状态
  animate={{ opacity: 1, scale: 1 }}
  // 过渡配置
  transition={{
    duration: 0.8,
    delay: 0.5,
    ease: [0, 0.71, 0.2, 1.01],
  }}
/>
```

#### 悬停和点击
```typescript
<motion.button
  whileHover={{ scale: 1.1 }}
  whileTap={{ scale: 0.9 }}
  transition={{ type: 'spring', stiffness: 400, damping: 17 }}
>
  点击我
</motion.button>
```

### 4. 变体（Variants）
```typescript
const variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: {
      duration: 0.5,
      ease: 'easeOut',
    },
  },
  exit: { 
    opacity: 0, 
    y: -20,
    transition: {
      duration: 0.3,
    },
  },
};

function AnimatedBox() {
  return (
    <motion.div
      initial="hidden"
      animate="visible"
      exit="exit"
      variants={variants}
    >
      Animated Content
    </motion.div>
  );
}
```

#### 子元素动画
```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1, // 子元素依次动画
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

function List() {
  return (
    <motion.ul
      initial="hidden"
      animate="visible"
      variants={containerVariants}
    >
      {items.map((item, index) => (
        <motion.li key={index} variants={itemVariants}>
          {item}
        </motion.li>
      ))}
    </motion.ul>
  );
}
```

### 5. AnimatePresence
```typescript
import { AnimatePresence, motion } from 'framer-motion';

function Modal({ isOpen, onClose, children }) {
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
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.8, opacity: 0 }}
            transition={{ type: 'spring', damping: 25 }}
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

### 6. 布局动画
```typescript
import { motion, LayoutGroup } from 'framer-motion';

function Tabs({ tabs, selected, onSelect }) {
  return (
    <LayoutGroup>
      <div className="tabs">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onSelect(tab.id)}
            className="tab"
          >
            {tab.label}
            {selected === tab.id && (
              <motion.div
                layoutId="underline"
                className="underline"
              />
            )}
          </button>
        ))}
      </div>
    </LayoutGroup>
  );
}
```

## 🔧 实战练习

### 练习 1：淡入淡出动画
```typescript
function FadeIn({ children, delay = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
    >
      {children}
    </motion.div>
  );
}

// 使用
<FadeIn delay={0.2}>
  <h1>标题</h1>
</FadeIn>
<FadeIn delay={0.4}>
  <p>内容</p>
</FadeIn>
```

### 练习 2：列表动画
```typescript
function AnimatedList({ items }) {
  return (
    <motion.ul
      initial="hidden"
      animate="visible"
      variants={{
        visible: {
          transition: {
            staggerChildren: 0.1,
          },
        },
      }}
    >
      {items.map((item) => (
        <motion.li
          key={item.id}
          variants={{
            hidden: { opacity: 0, x: -20 },
            visible: { opacity: 1, x: 0 },
          }}
        >
          {item.text}
        </motion.li>
      ))}
    </motion.ul>
  );
}
```

### 练习 3：弹性按钮
```typescript
function SpringButton({ children, onClick }) {
  return (
    <motion.button
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      transition={{
        type: 'spring',
        stiffness: 400,
        damping: 17,
      }}
      onClick={onClick}
    >
      {children}
    </motion.button>
  );
}
```

## 📝 最佳实践

### 1. 使用 transform 优化性能
```typescript
// 好：使用 transform
<motion.div animate={{ x: 100, scale: 1.2 }} />

// 不好：使用 layout 属性
<motion.div animate={{ width: 200 }} />
```

### 2. 使用 layoutId 实现共享动画
```typescript
// 列表页
<motion.div layoutId={`card-${id}`}>...</motion.div>

// 详情页
<motion.div layoutId={`card-${id}`}>...</motion.div>
```

### 3. 使用 useAnimation 控制复杂动画
```typescript
import { useAnimation } from 'framer-motion';

function ComplexAnimation() {
  const controls = useAnimation();

  const sequence = async () => {
    await controls.start({ x: 100 });
    await controls.start({ y: 100 });
    await controls.start({ rotate: 180 });
  };

  return (
    <motion.div animate={controls} onClick={sequence}>
      Click me
    </motion.div>
  );
}
```

## 🎓 今日总结

**关键知识点：**
1. `motion` 组件创建动画元素
2. `initial`, `animate`, `exit` 控制动画状态
3. `transition` 配置动画参数
4. `variants` 定义可复用的动画状态
5. `AnimatePresence` 处理组件进出动画
6. `layoutId` 实现共享布局动画

**明日计划：**
- Day 37: 页面过渡动画
