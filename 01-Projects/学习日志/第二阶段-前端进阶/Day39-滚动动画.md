---
title: Day 39 - 滚动动画
date: 2026-05-29
tags:
  - framer-motion
  - 滚动动画
  - react
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 39 - 滚动动画

## 📚 学习目标
- 掌握滚动触发动画的实现
- 学会使用 useScroll 和 useTransform
- 实现视差滚动效果

## 🎯 核心概念

### 1. 滚动触发动画

#### 使用 whileInView
```typescript
import { motion } from 'framer-motion';

function ScrollReveal() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 50 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-100px' }}
      transition={{ duration: 0.5 }}
    >
      滚动到此处时显示
    </motion.div>
  );
}
```

#### 使用 useInView Hook
```typescript
import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';

function AnimatedSection({ children }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-100px' });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 50 }}
      transition={{ duration: 0.5 }}
    >
      {children}
    </motion.div>
  );
}
```

### 2. 滚动进度

#### 使用 useScroll
```typescript
import { motion, useScroll } from 'framer-motion';

function ScrollProgress() {
  const { scrollYProgress } = useScroll();

  return (
    <motion.div
      className="progress-bar"
      style={{ scaleX: scrollYProgress }}
    />
  );
}
```

#### 容器滚动进度
```typescript
function ContainerScrollProgress() {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ['start end', 'end end'],
  });

  return (
    <div ref={containerRef}>
      <motion.div
        className="progress-bar"
        style={{ scaleX: scrollYProgress }}
      />
    </div>
  );
}
```

### 3. 视差滚动

#### 基本视差效果
```typescript
import { motion, useScroll, useTransform } from 'framer-motion';

function ParallaxSection() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start end', 'end start'],
  });

  const y = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5, 1], [1, 1, 0]);

  return (
    <div ref={ref} className="parallax-container">
      <motion.div style={{ y, opacity }} className="parallax-content">
        视差内容
      </motion.div>
    </div>
  );
}
```

#### 多层视差
```typescript
function MultiLayerParallax() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start end', 'end start'],
  });

  const y1 = useTransform(scrollYProgress, [0, 1], ['0%', '30%']);
  const y2 = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const y3 = useTransform(scrollYProgress, [0, 1], ['0%', '70%']);

  return (
    <div ref={ref} className="parallax-container">
      <motion.div style={{ y: y1 }} className="layer-1">
        背景层
      </motion.div>
      <motion.div style={{ y: y2 }} className="layer-2">
        中间层
      </motion.div>
      <motion.div style={{ y: y3 }} className="layer-3">
        前景层
      </motion.div>
    </div>
  );
}
```

### 4. 滚动驱动动画

#### 使用 useMotionValueEvent
```typescript
import { motion, useScroll, useMotionValueEvent } from 'framer-motion';

function ScrollDrivenAnimation() {
  const { scrollY } = useScroll();
  const [direction, setDirection] = useState('down');

  useMotionValueEvent(scrollY, 'change', (latest) => {
    const previous = scrollY.getPrevious();
    setDirection(latest > previous ? 'down' : 'up');
  });

  return (
    <motion.div
      animate={{
        y: direction === 'down' ? -50 : 0,
      }}
    >
      导航栏
    </motion.div>
  );
}
```

#### 透明度变化
```typescript
function ScrollOpacity() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start start', 'end start'],
  });

  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);
  const scale = useTransform(scrollYProgress, [0, 0.5], [1, 0.8]);

  return (
    <motion.div ref={ref} style={{ opacity, scale }}>
      滚动时透明度变化
    </motion.div>
  );
}
```

### 5. 滚动动画列表

#### 交错出现
```typescript
function AnimatedList({ items }) {
  return (
    <ul>
      {items.map((item, index) => (
        <motion.li
          key={item.id}
          initial={{ opacity: 0, x: -50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true, margin: '-50px' }}
          transition={{
            duration: 0.5,
            delay: index * 0.1,
          }}
        >
          {item.content}
        </motion.li>
      ))}
    </ul>
  );
}
```

#### 使用 variants
```typescript
const listVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

function StaggeredList({ items }) {
  return (
    <motion.ul
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true }}
      variants={listVariants}
    >
      {items.map((item) => (
        <motion.li key={item.id} variants={itemVariants}>
          {item.content}
        </motion.li>
      ))}
    </motion.ul>
  );
}
```

## 🔧 实战练习

### 练习 1：滚动进度条
```typescript
function ScrollProgressBar() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001,
  });

  return (
    <motion.div
      className="scroll-progress"
      style={{
        scaleX,
        transformOrigin: 'left',
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        height: '4px',
        background: '#0070f3',
      }}
    />
  );
}
```

### 练习 2：视差英雄区域
```typescript
function ParallaxHero() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start start', 'end start'],
  });

  const backgroundY = useTransform(scrollYProgress, [0, 1], ['0%', '100%']);
  const textY = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

  return (
    <div ref={ref} className="hero-container">
      <motion.div
        className="hero-background"
        style={{ y: backgroundY }}
      />
      <motion.div
        className="hero-text"
        style={{ y: textY, opacity }}
      >
        <h1>欢迎来到我的网站</h1>
        <p>向下滚动探索更多</p>
      </motion.div>
    </div>
  );
}
```

### 练习 3：滚动计数器
```typescript
function ScrollCounter({ target }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const count = useMotionValue(0);
  const rounded = useTransform(count, (value) => Math.round(value));

  useEffect(() => {
    if (isInView) {
      const controls = animate(count, target, {
        duration: 2,
        ease: 'easeOut',
      });
      return controls.stop;
    }
  }, [isInView, count, target]);

  return (
    <div ref={ref}>
      <motion.span>{rounded}</motion.span>
    </div>
  );
}
```

### 练习 4：粘性元素
```typescript
function StickyElement() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start start', 'end end'],
  });

  const opacity = useTransform(scrollYProgress, [0, 0.5, 1], [0, 1, 0]);
  const scale = useTransform(scrollYProgress, [0, 0.5, 1], [0.8, 1, 0.8]);

  return (
    <div ref={ref} className="sticky-container">
      <motion.div
        className="sticky-content"
        style={{
          position: 'sticky',
          top: '50%',
          opacity,
          scale,
        }}
      >
        粘性内容
      </motion.div>
    </div>
  );
}
```

## 📝 最佳实践

### 1. 使用 viewport 控制触发时机
```typescript
<motion.div
  whileInView={{ opacity: 1 }}
  viewport={{ 
    once: true, // 只触发一次
    margin: '-100px', // 提前触发
    amount: 0.5, // 可见比例
  }}
/>
```

### 2. 使用 useSpring 平滑滚动
```typescript
const { scrollYProgress } = useScroll();
const smoothProgress = useSpring(scrollYProgress, {
  stiffness: 100,
  damping: 30,
  restDelta: 0.001,
});
```

### 3. 优化性能
```typescript
// 好：使用 transform
const y = useTransform(scrollYProgress, [0, 1], [0, 100]);
<motion.div style={{ y }} />

// 不好：使用 layout 属性
<motion.div style={{ top: scrollYProgress }} />
```

## 🎓 今日总结

**关键知识点：**
1. `whileInView` 实现滚动触发动画
2. `useScroll` 获取滚动进度
3. `useTransform` 将进度映射到动画值
4. `useSpring` 平滑滚动动画
5. 视差滚动通过不同速度的层实现

**明日计划：**
- Day 40: 第五周总结 + 动画实战
