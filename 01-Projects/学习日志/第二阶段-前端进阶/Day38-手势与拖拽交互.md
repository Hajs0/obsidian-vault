---
title: Day 38 - 手势与拖拽交互
date: 2026-05-29
tags:
  - framer-motion
  - 手势
  - 拖拽
  - react
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 38 - 手势与拖拽交互

## 📚 学习目标
- 掌握手势动画的实现
- 学会实现拖拽交互
- 理解拖拽排序的实现

## 🎯 核心概念

### 1. 手势动画

#### 悬停和点击
```typescript
import { motion } from 'framer-motion';

function InteractiveBox() {
  return (
    <motion.div
      whileHover={{ 
        scale: 1.05,
        boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
      }}
      whileTap={{ scale: 0.95 }}
      transition={{ type: 'spring', stiffness: 400, damping: 17 }}
    >
      悬停和点击我
    </motion.div>
  );
}
```

#### 拖拽提示
```typescript
function DragHint() {
  return (
    <motion.div
      animate={{ x: [0, 10, 0] }}
      transition={{ 
        duration: 1.5, 
        repeat: Infinity,
        ease: 'easeInOut',
      }}
    >
      ← 拖拽 →
    </motion.div>
  );
}
```

### 2. 拖拽功能

#### 基本拖拽
```typescript
import { motion } from 'framer-motion';

function DraggableBox() {
  return (
    <motion.div
      drag
      dragConstraints={{ left: -100, right: 100, top: -100, bottom: 100 }}
      dragElastic={0.1}
      whileDrag={{ scale: 1.1, cursor: 'grabbing' }}
    >
      拖拽我
    </motion.div>
  );
}
```

#### 拖拽事件
```typescript
function DraggableWithEvents() {
  return (
    <motion.div
      drag
      onDragStart={(event, info) => {
        console.log('拖拽开始', info.point);
      }}
      onDrag={(event, info) => {
        console.log('拖拽中', info.offset);
      }}
      onDragEnd={(event, info) => {
        console.log('拖拽结束', info.velocity);
      }}
    >
      拖拽我
    </motion.div>
  );
}
```

### 3. 拖拽约束

#### 边界约束
```typescript
function ConstrainedDrag() {
  const constraintsRef = useRef(null);

  return (
    <div ref={constraintsRef} className="container">
      <motion.div
        drag
        dragConstraints={constraintsRef}
        dragElastic={0.1}
      >
        我只能在容器内拖拽
      </motion.div>
    </div>
  );
}
```

#### 弹性约束
```typescript
function ElasticDrag() {
  return (
    <motion.div
      drag
      dragConstraints={{ left: -100, right: 100 }}
      dragElastic={0.5} // 弹性系数，0-1
      dragTransition={{ bounceStiffness: 300, bounceDamping: 10 }}
    >
      弹性拖拽
    </motion.div>
  );
}
```

### 4. 拖拽排序

#### 基本实现
```typescript
import { useState } from 'react';
import { motion, AnimatePresence, useMotionValue } from 'framer-motion';

function DragSortList() {
  const [items, setItems] = useState([1, 2, 3, 4, 5]);

  const handleReorder = (newOrder) => {
    setItems(newOrder);
  };

  return (
    <ul>
      <AnimatePresence>
        {items.map((item) => (
          <DragSortItem
            key={item}
            id={item}
            items={items}
            onReorder={handleReorder}
          />
        ))}
      </AnimatePresence>
    </ul>
  );
}

function DragSortItem({ id, items, onReorder }) {
  const y = useMotionValue(0);

  return (
    <motion.li
      layout
      drag="y"
      dragConstraints={{ top: 0, bottom: 0 }}
      dragElastic={1}
      style={{ y }}
      onDragEnd={(event, info) => {
        const offset = info.offset.y;
        const velocity = info.velocity.y;
        
        // 计算新位置
        const currentIndex = items.indexOf(id);
        const itemHeight = 60; // 每项高度
        const moveBy = Math.round((offset + velocity * 0.2) / itemHeight);
        const newIndex = Math.max(0, Math.min(items.length - 1, currentIndex + moveBy));
        
        if (newIndex !== currentIndex) {
          const newItems = [...items];
          newItems.splice(currentIndex, 1);
          newItems.splice(newIndex, 0, id);
          onReorder(newItems);
        }
      }}
      whileDrag={{ scale: 1.05, boxShadow: '0 5px 15px rgba(0,0,0,0.1)' }}
    >
      Item {id}
    </motion.li>
  );
}
```

### 5. 滑动手势

#### 滑动删除
```typescript
function SwipeToDelete({ onDelete, children }) {
  const x = useMotionValue(0);
  const opacity = useTransform(x, [-200, -100, 0], [0, 1, 1]);

  return (
    <motion.div style={{ x, opacity }}>
      <motion.div
        drag="x"
        dragConstraints={{ left: -200, right: 0 }}
        dragElastic={0.1}
        onDragEnd={(event, info) => {
          if (info.offset.x < -100) {
            onDelete();
          }
        }}
        style={{ x }}
      >
        {children}
      </motion.div>
      <div className="delete-indicator">
        删除
      </div>
    </motion.div>
  );
}
```

#### 滑动切换
```typescript
function SwipeCarousel({ items }) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const x = useMotionValue(0);

  const handleDragEnd = (event, info) => {
    const threshold = 50;
    if (info.offset.x < -threshold && currentIndex < items.length - 1) {
      setCurrentIndex(currentIndex + 1);
    } else if (info.offset.x > threshold && currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }
  };

  return (
    <div className="carousel">
      <motion.div
        drag="x"
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.2}
        onDragEnd={handleDragEnd}
        style={{ x }}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={currentIndex}
            initial={{ opacity: 0, x: 100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -100 }}
            transition={{ duration: 0.3 }}
          >
            {items[currentIndex]}
          </motion.div>
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
```

## 🔧 实战练习

### 练习 1：可拖拽的卡片
```typescript
function DraggableCard({ children }) {
  const [isDragging, setIsDragging] = useState(false);

  return (
    <motion.div
      drag
      dragConstraints={{ left: -200, right: 200, top: -100, bottom: 100 }}
      dragElastic={0.1}
      onDragStart={() => setIsDragging(true)}
      onDragEnd={() => setIsDragging(false)}
      whileDrag={{ 
        scale: 1.05, 
        boxShadow: '0 20px 40px rgba(0,0,0,0.15)',
        cursor: 'grabbing',
      }}
      animate={{
        scale: isDragging ? 1.05 : 1,
      }}
      style={{ cursor: isDragging ? 'grabbing' : 'grab' }}
    >
      {children}
    </motion.div>
  );
}
```

### 练习 2：滑动操作菜单
```typescript
function SwipeableMenuItem({ onDelete, onEdit, children }) {
  const x = useMotionValue(0);
  const background = useTransform(
    x,
    [-200, -100, 0],
    ['#ff4444', '#ff8844', '#ffffff']
  );

  return (
    <div className="swipeable-item">
      <motion.div
        className="actions"
        style={{ opacity: useTransform(x, [-200, -100, 0], [1, 0.5, 0]) }}
      >
        <button onClick={onEdit}>编辑</button>
        <button onClick={onDelete}>删除</button>
      </motion.div>
      <motion.div
        drag="x"
        dragConstraints={{ left: -200, right: 0 }}
        dragElastic={0.1}
        style={{ x, background }}
        onDragEnd={(event, info) => {
          if (info.offset.x < -150) {
            onDelete();
          } else if (info.offset.x < -75) {
            onEdit();
          }
        }}
      >
        {children}
      </motion.div>
    </div>
  );
}
```

### 练习 3：拖拽排序列表
```typescript
function SortableList({ items, onReorder }) {
  return (
    <ul className="sortable-list">
      <AnimatePresence>
        {items.map((item) => (
          <SortableItem
            key={item.id}
            item={item}
            items={items}
            onReorder={onReorder}
          />
        ))}
      </AnimatePresence>
    </ul>
  );
}

function SortableItem({ item, items, onReorder }) {
  const y = useMotionValue(0);
  const scale = useTransform(y, [-100, 0, 100], [1.1, 1, 1.1]);

  return (
    <motion.li
      layout
      drag="y"
      dragConstraints={{ top: 0, bottom: 0 }}
      dragElastic={1}
      style={{ y, scale }}
      onDragEnd={(event, info) => {
        const offset = info.offset.y;
        const velocity = info.velocity.y;
        const itemHeight = 60;
        const moveBy = Math.round((offset + velocity * 0.2) / itemHeight);
        const currentIndex = items.indexOf(item);
        const newIndex = Math.max(0, Math.min(items.length - 1, currentIndex + moveBy));
        
        if (newIndex !== currentIndex) {
          const newItems = [...items];
          newItems.splice(currentIndex, 1);
          newItems.splice(newIndex, 0, item);
          onReorder(newItems);
        }
      }}
      whileDrag={{ 
        scale: 1.05, 
        boxShadow: '0 10px 20px rgba(0,0,0,0.1)',
        zIndex: 10,
      }}
    >
      {item.name}
    </motion.li>
  );
}
```

## 📝 最佳实践

### 1. 设置拖拽约束
```typescript
// 好：明确的拖拽边界
<motion.div
  drag
  dragConstraints={{ left: -100, right: 100, top: -100, bottom: 100 }}
/>

// 不好：无限制拖拽
<motion.div drag />
```

### 2. 提供视觉反馈
```typescript
<motion.div
  drag
  whileDrag={{ 
    scale: 1.05, 
    boxShadow: '0 10px 20px rgba(0,0,0,0.1)',
    cursor: 'grabbing',
  }}
/>
```

### 3. 处理拖拽结束
```typescript
<motion.div
  drag
  onDragEnd={(event, info) => {
    // 根据偏移量和速度处理逻辑
    const { offset, velocity } = info;
    // ...
  }}
/>
```

## 🎓 今日总结

**关键知识点：**
1. 使用 `whileHover` 和 `whileTap` 实现手势动画
2. 使用 `drag` 启用拖拽功能
3. 使用 `dragConstraints` 设置拖拽边界
4. 使用 `onDragEnd` 处理拖拽结束事件
5. 使用 `useMotionValue` 和 `useTransform` 实现复杂交互

**明日计划：**
- Day 39: 滚动动画
