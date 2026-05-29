---
title: Day 54 - Core Web Vitals 优化
date: 2026-05-29
tags:
  - 性能优化
  - core-web-vitals
  - lighthouse
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 54 - Core Web Vitals 优化

## 📚 学习目标
- 理解 Core Web Vitals 指标
- 掌握性能优化技巧
- 学会使用 Lighthouse 进行性能审计

## 🎯 核心概念

### 1. Core Web Vitals 指标

#### LCP（Largest Contentful Paint）
- **定义**：最大内容元素渲染完成时间
- **目标**：< 2.5 秒
- **优化**：
  - 预加载关键资源
  - 优化图片大小
  - 使用 CDN

#### FID（First Input Delay）
- **定义**：首次输入延迟
- **目标**：< 100 毫秒
- **优化**：
  - 减少主线程阻塞
  - 代码分割
  - 延迟加载非关键 JavaScript

#### CLS（Cumulative Layout Shift）
- **定义**：累积布局偏移
- **目标**：< 0.1
- **优化**：
  - 设置图片尺寸
  - 避免动态插入内容
  - 使用 CSS contain

### 2. 性能优化技巧

#### 图片优化
```typescript
// 使用 Next.js Image 组件
import Image from 'next/image';

function OptimizedImage() {
  return (
    <Image
      src="/hero.jpg"
      alt="Hero"
      width={800}
      height={600}
      priority // 首屏图片
      placeholder="blur"
      blurDataURL="data:image/jpeg;base64,..."
    />
  );
}
```

#### 字体优化
```typescript
// 使用 next/font
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap', // 避免 FOIT
});

export default function RootLayout({ children }) {
  return (
    <html lang="zh-CN" className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

#### 代码分割
```typescript
// 动态导入
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false, // 仅客户端渲染
});

function App() {
  return (
    <div>
      <HeavyComponent />
    </div>
  );
}
```

### 3. 资源加载优化

#### 预加载关键资源
```typescript
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        {/* 预连接 */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        
        {/* 预加载关键资源 */}
        <link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossOrigin="anonymous" />
        
        {/* 预获取下一页 */}
        <link rel="prefetch" href="/about" />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

#### 关键 CSS 内联
```typescript
// 使用 critters
// next.config.ts
const nextConfig = {
  experimental: {
    optimizeCss: true,
  },
};
```

### 4. 运行时优化

#### 避免主线程阻塞
```typescript
// 使用 Web Workers
const worker = new Worker('/worker.js');

worker.postMessage({ data: largeData });

worker.onmessage = (event) => {
  const result = event.data;
  // 处理结果
};
```

#### 使用 requestIdleCallback
```typescript
function scheduleNonUrgentWork(callback) {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(callback);
  } else {
    setTimeout(callback, 0);
  }
}

scheduleNonUrgentWork(() => {
  // 非紧急工作
});
```

### 5. 监控和分析

#### 使用 Web Vitals 库
```typescript
import { onCLS, onFID, onLCP } from 'web-vitals';

function reportWebVitals({ name, value, id }) {
  // 发送到分析服务
  gtag('event', name, {
    event_category: 'Web Vitals',
    event_label: id,
    value: Math.round(name === 'CLS' ? value * 1000 : value),
  });
}

onCLS(reportWebVitals);
onFID(reportWebVitals);
onLCP(reportWebVitals);
```

#### Lighthouse 审计
```bash
# 安装 Lighthouse
npm install -g lighthouse

# 运行审计
lighthouse https://example.com --output html --output-path ./report.html
```

## 🔧 实战练习

### 练习 1：优化 LCP
```typescript
// 优化前
function Hero() {
  return (
    <div>
      <img src="/hero.jpg" alt="Hero" />
      <h1>欢迎</h1>
    </div>
  );
}

// 优化后
function Hero() {
  return (
    <div>
      {/* 预加载首屏图片 */}
      <link rel="preload" href="/hero.jpg" as="image" />
      
      {/* 使用 priority 属性 */}
      <Image
        src="/hero.jpg"
        alt="Hero"
        width={1200}
        height={600}
        priority
        placeholder="blur"
        blurDataURL="data:image/jpeg;base64,..."
      />
      
      <h1>欢迎</h1>
    </div>
  );
}
```

### 练习 2：优化 CLS
```typescript
// 优化前
function ImageGallery() {
  return (
    <div>
      {/* 没有尺寸的图片会导致布局偏移 */}
      <img src="/image1.jpg" alt="Image 1" />
      <img src="/image2.jpg" alt="Image 2" />
    </div>
  );
}

// 优化后
function ImageGallery() {
  return (
    <div>
      {/* 设置明确的尺寸 */}
      <Image
        src="/image1.jpg"
        alt="Image 1"
        width={400}
        height={300}
      />
      <Image
        src="/image2.jpg"
        alt="Image 2"
        width={400}
        height={300}
      />
    </div>
  );
}
```

### 练习 3：优化 FID
```typescript
// 优化前
function App() {
  // 主线程阻塞
  const result = heavyComputation();
  
  return <div>{result}</div>;
}

// 优化后
function App() {
  const [result, setResult] = useState(null);
  
  useEffect(() => {
    // 使用 Web Worker
    const worker = new Worker('/worker.js');
    worker.postMessage({ data: largeData });
    worker.onmessage = (event) => {
      setResult(event.data);
    };
    
    return () => worker.terminate();
  }, []);
  
  if (!result) return <Loading />;
  
  return <div>{result}</div>;
}
```

## 📝 最佳实践

### 1. 图片优化
```typescript
// 好：使用 Next.js Image
<Image
  src="/image.jpg"
  alt="Description"
  width={800}
  height={600}
  priority
/>

// 不好：使用原生 img
<img src="/image.jpg" alt="Description" />
```

### 2. 字体优化
```typescript
// 好：使用 next/font
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'], display: 'swap' });

// 不好：使用 @font-face
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter.woff2');
}
```

### 3. 代码分割
```typescript
// 好：动态导入
const HeavyComponent = dynamic(() => import('./HeavyComponent'));

// 不好：静态导入
import HeavyComponent from './HeavyComponent';
```

## 🎓 今日总结

**关键知识点：**
1. Core Web Vitals：LCP、FID、CLS
2. 图片优化使用 Next.js Image
3. 字体优化使用 next/font
4. 代码分割使用动态导入
5. 监控使用 Web Vitals 库

**明日计划：**
- Day 55-60: 综合项目实战
