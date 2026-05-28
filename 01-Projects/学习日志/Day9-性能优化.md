# Day 9 - 性能优化

> 日期：2026-05-29
> 主题：Web 性能优化全面学习

---

## 1. Web Vitals 指标

### 核心指标（Core Web Vitals）

| 指标 | 全称 | 衡量内容 | 良好标准 |
|------|------|----------|----------|
| **LCP** | Largest Contentful Paint | 最大内容绘制时间 | ≤ 2.5s |
| **INP** | Interaction to Next Paint | 交互响应延迟 | ≤ 200ms |
| **CLS** | Cumulative Layout Shift | 累积布局偏移 | ≤ 0.1 |

> INP 于 2024 年 3 月正式替代 FID（First Input Delay）

### 其他重要指标

- **FCP**（First Contentful Paint）：首次内容绘制，理想 ≤ 1.8s
- **TTFB**（Time to First Byte）：首字节到达时间，理想 ≤ 800ms
- **TBT**（Total Blocking Time）：总阻塞时间，实验室指标
- **TTI**（Time to Interactive）：可交互时间

### 测量工具

```javascript
// 使用 web-vitals 库
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);   // 最大内容绘制
onINP(console.log);   // 交互延迟
onCLS(console.log);   // 布局偏移
```

- **Lighthouse**：Chrome DevTools 内置
- **PageSpeed Insights**：线上 + 实验室数据
- **Chrome UX Report (CrUX)**：真实用户数据
- **WebPageTest**：详细瀑布图分析

---

## 2. 代码分割和懒加载

### 路由级代码分割

```jsx
import { lazy, Suspense } from 'react';

// 路由懒加载
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### 组件级懒加载

```jsx
// 条件加载 —— 只在需要时加载
const HeavyChart = lazy(() => import('./HeavyChart'));

function Reports() {
  const [showChart, setShowChart] = useState(false);
  return (
    <>
      <button onClick={() => setShowChart(true)}>显示图表</button>
      {showChart && (
        <Suspense fallback={<Spinner />}>
          <HeavyChart />
        </Suspense>
      )}
    </>
  );
}
```

### Webpack 魔法注释

```javascript
// 指定 chunk 名称和预加载
const Admin = lazy(() => import(
  /* webpackChunkName: "admin" */
  /* webpackPrefetch: true */
  './pages/Admin'
));
```

### 动态导入工具库

```javascript
// 按需加载第三方库
async function exportPDF(data) {
  const { jsPDF } = await import('jspdf');
  const doc = new jsPDF();
  // ...
  doc.save('report.pdf');
}
```

### 预加载策略

```html
<!-- preload：当前页面立即需要 -->
<link rel="preload" href="/font.woff2" as="font" crossorigin>

<!-- prefetch：下一页可能需要 -->
<link rel="prefetch" href="/next-page.js">

<!-- preconnect：提前建立连接 -->
<link rel="preconnect" href="https://api.example.com">
```

---

## 3. 图片优化

### 格式选择

| 格式 | 适用场景 | 特点 |
|------|----------|------|
| **WebP** | 通用照片/图形 | 比 JPEG 小 25-35% |
| **AVIF** | 高质量照片 | 比 WebP 再小 20% |
| **SVG** | 图标/插图 | 矢量，无限缩放 |
| **JPEG** | 照片（兼容性） | 广泛支持 |
| **PNG** | 需要透明度 | 无损，文件较大 |

### 响应式图片

```html
<picture>
  <!-- 优先 AVIF -->
  <source srcset="hero.avif" type="image/avif">
  <!-- 其次 WebP -->
  <source srcset="hero.webp" type="image/webp">
  <!-- 兜底 JPEG -->
  <img src="hero.jpg" alt="Hero" loading="lazy" decoding="async">
</picture>
```

```html
<!-- 不同分辨率适配 -->
<img
  srcset="hero-400w.jpg 400w, hero-800w.jpg 800w, hero-1200w.jpg 1200w"
  sizes="(max-width: 600px) 400px, (max-width: 1000px) 800px, 1200px"
  src="hero-800w.jpg"
  alt="Hero"
>
```

### 懒加载

```html
<!-- 原生懒加载 -->
<img src="photo.webp" loading="lazy" decoding="async" alt="Photo">
```

### Next.js Image 组件

```jsx
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={800}
  height={600}
  placeholder="blur"
  blurDataURL={blurHash}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
// 自动：懒加载、WebP/AVIF 转换、响应式尺寸、CLS 预防
```

### CDN 图片处理

```
// 典型 CDN 图片 URL
https://cdn.example.com/image.jpg?w=800&h=600&f=webp&q=80
```

---

## 4. 缓存策略

### HTTP 缓存头

```
# 强缓存（不发请求）
Cache-Control: max-age=31536000, immutable    # 不可变资源（带 hash）
Cache-Control: max-age=3600, must-revalidate  # 可变资源

# 协商缓存（发请求验证 304）
ETag: "abc123"
Last-Modified: Wed, 21 May 2026 08:00:00 GMT
```

### 缓存策略分层

```
请求 → Service Worker Cache → HTTP 强缓存 → HTTP 协商缓存 → 源服务器
```

### Next.js 缓存体系

```
┌──────────────────────────────────────┐
│          Next.js 缓存层次            │
├──────────────────────────────────────┤
│ 1. Request Memoization (请求去重)    │ ← 同一请求自动合并
│ 2. Data Cache (数据缓存)             │ ← fetch 结果持久化
│ 3. Full Route Cache (路由缓存)       │ ← 静态 HTML/ RSC payload
│ 4. Router Cache (路由缓存)           │ ← 客户端内存缓存
└──────────────────────────────────────┘
```

```javascript
// 控制缓存
// 强制动态（不缓存）
fetch('https://api.example.com/data', { cache: 'no-store' });

// 重新验证
fetch('https://api.example.com/data', { next: { revalidate: 3600 } });
```

### Service Worker 缓存

```javascript
// 缓存策略
// Cache First — 静态资源
// Network First — API 数据
// Stale While Revalidate — 频繁更新的内容

// Workbox 示例
import { registerRoute } from 'workbox-routing';
import { CacheFirst, StaleWhileRevalidate } from 'workbox-strategies';

registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({ cacheName: 'images' })
);
```

---

## 5. SSR / SSG / ISR 优化

### 三种渲染策略对比

| 策略 | 全称 | 时机 | 适用场景 |
|------|------|------|----------|
| **SSG** | Static Site Generation | 构建时 | 博客、文档、营销页 |
| **SSR** | Server-Side Rendering | 请求时 | 个性化页面、搜索结果 |
| **ISR** | Incremental Static Regen | 构建 + 定期更新 | 电商产品页、新闻 |

### SSG 示例

```jsx
// Next.js App Router — 默认就是静态生成
export default async function AboutPage() {
  const data = await fetch('https://api.example.com/about', {
    cache: 'force-cache'  // 构建时获取并缓存
  });
  return <div>{/* ... */}</div>;
}
```

### SSR 示例

```jsx
// 强制动态渲染
export const dynamic = 'force-dynamic';

export default async function SearchPage({ searchParams }) {
  const results = await fetch(`/api/search?q=${searchParams.q}`, {
    cache: 'no-store'  // 每次请求重新获取
  });
  return <div>{/* ... */}</div>;
}
```

### ISR 示例

```jsx
// 定时重新生成（每 60 秒）
export const revalidate = 60;

export default async function ProductPage({ params }) {
  const product = await fetch(`/api/products/${params.id}`, {
    next: { revalidate: 60 }
  });
  return <div>{/* ... */}</div>;
}

// 按需重新生成
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(request) {
  revalidatePath('/products/[id]');
  revalidateTag('products');
  return Response.json({ revalidated: true });
}
```

### Streaming 与 Suspense

```jsx
// 流式渲染 —— 边生成边发送
export default function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      {/* 首屏快速返回 */}
      <Suspense fallback={<ChartSkeleton />}>
        <SlowChart />      {/* 数据准备好后再流式发送 */}
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <SlowTable />
      </Suspense>
    </div>
  );
}
```

### 部分预渲染（PPR）

```jsx
// Next.js 15+ —— 静态壳 + 动态洞
export const experimental_ppr = true;

export default function Page() {
  return (
    <>
      <StaticHeader />         {/* 构建时渲染 */}
      <Suspense fallback={<Skeleton />}>
        <DynamicWidget />      {/* 请求时渲染 */}
      </Suspense>
      <StaticFooter />         {/* 构建时渲染 */}
    </>
  );
}
```

---

## 6. 性能优化 Checklist

### 打包优化
- [ ] Tree shaking 去除无用代码
- [ ] 代码分割（路由级 + 组件级）
- [ ] 压缩 JS/CSS（Terser/CSSNano）
- [ ] 分析打包体积（Bundle Analyzer）
- [ ] 第三方库按需导入

### 加载优化
- [ ] 关键资源 preload
- [ ] 非关键资源 defer/async
- [ ] 字体优化（font-display: swap）
- [ ] 图片懒加载 + 现代格式
- [ ] CDN 分发静态资源

### 渲染优化
- [ ] 避免布局抖动（CLS）
- [ ] 减少主线程阻塞（长任务拆分）
- [ ] 虚拟列表处理长列表
- [ ] 合理使用 SSR/SSG/ISR
- [ ] Streaming + Suspense

### 网络优化
- [ ] Gzip/Brotli 压缩
- [ ] HTTP/2 或 HTTP/3
- [ ] 减少第三方脚本
- [ ] 资源预连接（preconnect）
- [ ] 合理的缓存策略

---

## 学习总结

今天系统学习了 Web 性能优化的六大核心领域：

1. **Web Vitals** 是衡量用户体验的黄金标准，LCP/INP/CLS 三者缺一不可
2. **代码分割** 通过 `lazy()` + `import()` 实现按需加载，配合 prefetch 预测用户行为
3. **图片优化** 格式选择（AVIF > WebP > JPEG）+ 响应式 + 懒加载三管齐下
4. **缓存策略** 分层设计：强缓存 → 协商缓存 → Service Worker，不同资源不同策略
5. **SSR/SSG/ISR** 根据数据更新频率选择，ISR 是 SSG 和 SSR 的最佳折中
6. **PPR（部分预渲染）** 是 Next.js 15+ 的前沿方案，静态壳 + 动态洞

> **核心理念**：性能优化的本质是「在正确的时间加载正确的内容」
