---
title: Day 40 - 第五周总结 + 动画实战
date: 2026-05-29
tags:
  - framer-motion
  - 总结
  - 实战
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 40 - 第五周总结 + 动画实战

## 📚 本周学习回顾

### Day 36: Framer Motion 入门
**核心知识点：**
- `motion` 组件创建动画元素
- `initial`, `animate`, `exit` 控制动画状态
- `transition` 配置动画参数
- `variants` 定义可复用的动画状态
- `AnimatePresence` 处理组件进出动画
- `layoutId` 实现共享布局动画

### Day 37: 页面过渡动画
**核心知识点：**
- 使用 AnimatePresence 处理路由切换
- 常见过渡效果：淡入淡出、滑动、缩放
- 方向感知过渡提升用户体验
- 共享元素过渡使用 layoutId
- 加载状态过渡

### Day 38: 手势与拖拽交互
**核心知识点：**
- 使用 `whileHover` 和 `whileTap` 实现手势动画
- 使用 `drag` 启用拖拽功能
- 使用 `dragConstraints` 设置拖拽边界
- 使用 `onDragEnd` 处理拖拽结束事件
- 使用 `useMotionValue` 和 `useTransform` 实现复杂交互

### Day 39: 滚动动画
**核心知识点：**
- `whileInView` 实现滚动触发动画
- `useScroll` 获取滚动进度
- `useTransform` 将进度映射到动画值
- `useSpring` 平滑滚动动画
- 视差滚动通过不同速度的层实现

## 🎯 实战项目：动画作品集网站

### 项目结构
```
portfolio-website/
├── src/
│   ├── components/
│   │   ├── Hero.tsx
│   │   ├── ProjectCard.tsx
│   │   ├── SkillsSection.tsx
│   │   ├── ContactForm.tsx
│   │   └── Navigation.tsx
│   ├── app/
│   │   ├── layout.tsx
│   │   └── page.tsx
│   └── styles/
│       └── globals.css
├── package.json
└── tsconfig.json
```

### 1. 英雄区域（视差效果）
```typescript
// components/Hero.tsx
'use client';

import { motion, useScroll, useTransform } from 'framer-motion';
import { useRef } from 'react';

export function Hero() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start start', 'end start'],
  });

  const backgroundY = useTransform(scrollYProgress, [0, 1], ['0%', '100%']);
  const textY = useTransform(scrollYProgress, [0, 1], ['0%', '50%']);
  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

  return (
    <section ref={ref} className="hero">
      <motion.div
        className="hero-background"
        style={{ y: backgroundY }}
      >
        <div className="gradient-bg" />
      </motion.div>
      <motion.div
        className="hero-content"
        style={{ y: textY, opacity }}
      >
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          你好，我是开发者
        </motion.h1>
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
        >
          专注于创建优秀的用户体验
        </motion.p>
        <motion.div
          className="scroll-indicator"
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          ↓ 向下滚动
        </motion.div>
      </motion.div>
    </section>
  );
}
```

### 2. 项目卡片（滚动动画）
```typescript
// components/ProjectCard.tsx
'use client';

import { motion, useInView } from 'framer-motion';
import { useRef } from 'react';

interface Props {
  project: {
    title: string;
    description: string;
    image: string;
  };
  index: number;
}

export function ProjectCard({ project, index }: Props) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-100px' });

  return (
    <motion.div
      ref={ref}
      className="project-card"
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 50 }}
      transition={{
        duration: 0.5,
        delay: index * 0.1,
        ease: [0.25, 0.46, 0.45, 0.94],
      }}
      whileHover={{ 
        scale: 1.05,
        boxShadow: '0 20px 40px rgba(0,0,0,0.1)',
      }}
    >
      <motion.div 
        className="project-image"
        whileHover={{ scale: 1.1 }}
        transition={{ duration: 0.3 }}
      >
        <img src={project.image} alt={project.title} />
      </motion.div>
      <div className="project-info">
        <h3>{project.title}</h3>
        <p>{project.description}</p>
      </div>
    </motion.div>
  );
}
```

### 3. 技能展示（滚动进度）
```typescript
// components/SkillsSection.tsx
'use client';

import { motion, useScroll, useTransform } from 'framer-motion';
import { useRef } from 'react';

const skills = [
  { name: 'React', level: 90 },
  { name: 'TypeScript', level: 85 },
  { name: 'Node.js', level: 80 },
  { name: 'Framer Motion', level: 75 },
];

export function SkillsSection() {
  const sectionRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ['start end', 'end start'],
  });

  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0, 1, 1, 0]);
  const y = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [100, 0, 0, -100]);

  return (
    <motion.section
      ref={sectionRef}
      className="skills-section"
      style={{ opacity, y }}
    >
      <h2>技能展示</h2>
      <div className="skills-grid">
        {skills.map((skill, index) => (
          <SkillBar key={skill.name} skill={skill} index={index} />
        ))}
      </div>
    </motion.section>
  );
}

function SkillBar({ skill, index }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-50px' });

  return (
    <div ref={ref} className="skill-bar">
      <span>{skill.name}</span>
      <div className="bar-container">
        <motion.div
          className="bar-fill"
          initial={{ width: 0 }}
          animate={isInView ? { width: `${skill.level}%` } : { width: 0 }}
          transition={{
            duration: 1,
            delay: index * 0.1,
            ease: 'easeOut',
          }}
        />
      </div>
      <span>{skill.level}%</span>
    </div>
  );
}
```

### 4. 联系表单（交互动画）
```typescript
// components/ContactForm.tsx
'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';

export function ContactForm() {
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isFocused, setIsFocused] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    // 模拟提交
    await new Promise(resolve => setTimeout(resolve, 1000));
    setIsSubmitted(true);
  };

  return (
    <section className="contact-section">
      <h2>联系我</h2>
      <AnimatePresence mode="wait">
        {isSubmitted ? (
          <motion.div
            key="success"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            className="success-message"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', damping: 15 }}
            >
              ✓
            </motion.div>
            <p>消息已发送！</p>
          </motion.div>
        ) : (
          <motion.form
            key="form"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            onSubmit={handleSubmit}
          >
            <div className="form-group">
              <motion.label
                animate={{
                  color: isFocused === 'name' ? '#0070f3' : '#666',
                }}
              >
                姓名
              </motion.label>
              <motion.input
                onFocus={() => setIsFocused('name')}
                onBlur={() => setIsFocused(null)}
                whileFocus={{ scale: 1.02 }}
                transition={{ duration: 0.2 }}
              />
            </div>
            <div className="form-group">
              <motion.label
                animate={{
                  color: isFocused === 'email' ? '#0070f3' : '#666',
                }}
              >
                邮箱
              </motion.label>
              <motion.input
                type="email"
                onFocus={() => setIsFocused('email')}
                onBlur={() => setIsFocused(null)}
                whileFocus={{ scale: 1.02 }}
                transition={{ duration: 0.2 }}
              />
            </div>
            <div className="form-group">
              <motion.label
                animate={{
                  color: isFocused === 'message' ? '#0070f3' : '#666',
                }}
              >
                消息
              </motion.label>
              <motion.textarea
                onFocus={() => setIsFocused('message')}
                onBlur={() => setIsFocused(null)}
                whileFocus={{ scale: 1.02 }}
                transition={{ duration: 0.2 }}
              />
            </div>
            <motion.button
              type="submit"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              transition={{ type: 'spring', stiffness: 400, damping: 17 }}
            >
              发送消息
            </motion.button>
          </motion.form>
        )}
      </AnimatePresence>
    </section>
  );
}
```

### 5. 导航栏（滚动交互）
```typescript
// components/Navigation.tsx
'use client';

import { motion, useScroll, useMotionValueEvent } from 'framer-motion';
import { useState } from 'react';

export function Navigation() {
  const { scrollY } = useScroll();
  const [isScrolled, setIsScrolled] = useState(false);

  useMotionValueEvent(scrollY, 'change', (latest) => {
    setIsScrolled(latest > 50);
  });

  return (
    <motion.nav
      className="navigation"
      animate={{
        backgroundColor: isScrolled 
          ? 'rgba(255, 255, 255, 0.9)' 
          : 'rgba(255, 255, 255, 0)',
        backdropFilter: isScrolled ? 'blur(10px)' : 'blur(0px)',
        boxShadow: isScrolled 
          ? '0 2px 20px rgba(0,0,0,0.1)' 
          : '0 0px 0px rgba(0,0,0,0)',
      }}
      transition={{ duration: 0.3 }}
    >
      <div className="nav-content">
        <motion.a
          href="#"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          Logo
        </motion.a>
        <div className="nav-links">
          {['关于', '项目', '技能', '联系'].map((item, index) => (
            <motion.a
              key={item}
              href={`#${item}`}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ y: -2 }}
            >
              {item}
            </motion.a>
          ))}
        </div>
      </div>
    </motion.nav>
  );
}
```

## 📝 本周学习总结

### 掌握的核心技能
1. **Framer Motion 基础** - 动画、变体、过渡
2. **页面过渡** - 路由切换动画、共享元素
3. **手势交互** - 悬停、点击、拖拽
4. **滚动动画** - 视差、进度、触发动画

### 实战项目收获
通过构建动画作品集网站，实践了本周学习的所有知识点：
- 视差滚动英雄区域
- 滚动触发动画
- 拖拽交互
- 表单动画
- 导航栏滚动效果

### 下周预告
**第六周：Tailwind CSS 进阶**
- Day 41: 自定义设计系统
- Day 42: 响应式设计进阶
- Day 43: 暗色模式实现
- Day 44: 组件库开发
- Day 45: 第六周总结
