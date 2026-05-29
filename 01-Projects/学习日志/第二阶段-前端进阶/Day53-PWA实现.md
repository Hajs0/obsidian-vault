---
title: Day 53 - PWA 实现
date: 2026-05-29
tags:
  - pwa
  - service-worker
  - 离线应用
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 53 - PWA 实现

## 📚 学习目标
- 理解 PWA 的核心概念
- 掌握 Service Worker 的使用
- 学会实现离线应用

## 🎯 核心概念

### 1. 什么是 PWA？

#### PWA 特性
- **可靠**：离线也能工作
- **快速**：响应迅速
- **沉浸式**：类似原生应用体验

#### 核心技术
- Service Worker
- Web App Manifest
- Cache API
- Push API

### 2. Service Worker

#### 注册 Service Worker
```typescript
// public/sw.js
self.addEventListener('install', (event) => {
  console.log('Service Worker 安装');
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker 激活');
});

self.addEventListener('fetch', (event) => {
  console.log('拦截请求:', event.request.url);
  event.respondWith(fetch(event.request));
});
```

#### 在应用中注册
```typescript
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              if ('serviceWorker' in navigator) {
                window.addEventListener('load', () => {
                  navigator.serviceWorker.register('/sw.js');
                });
              }
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

### 3. 缓存策略

#### 缓存优先
```typescript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
```

#### 网络优先
```typescript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
```

#### 缓存并更新
```typescript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      const fetchPromise = fetch(event.request).then((networkResponse) => {
        caches.open('v1').then((cache) => {
          cache.put(event.request, networkResponse);
        });
        return networkResponse.clone();
      });
      
      return cachedResponse || fetchPromise;
    })
  );
});
```

### 4. Web App Manifest

#### manifest.json
```json
{
  "name": "Knowledge Hub",
  "short_name": "KH",
  "description": "知识管理系统",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0ea5e9",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

#### 在应用中引用
```typescript
// app/layout.tsx
export const metadata = {
  manifest: '/manifest.json',
  themeColor: '#0ea5e9',
  viewport: {
    width: 'device-width',
    initialScale: 1,
    maximumScale: 1,
  },
};
```

### 5. 推送通知

#### 请求权限
```typescript
async function requestNotificationPermission() {
  const permission = await Notification.requestPermission();
  
  if (permission === 'granted') {
    console.log('通知权限已授予');
  }
}
```

#### 发送通知
```typescript
self.addEventListener('push', (event) => {
  const data = event.data.json();
  
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192x192.png',
      badge: '/icons/badge-72x72.png',
    })
  );
});
```

## 🔧 实战练习

### 练习 1：完整的 PWA 配置
```typescript
// next.config.ts
import type { NextConfig } from 'next';
import withPWAInit from 'next-pwa';

const withPWA = withPWAInit({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
});

const nextConfig: NextConfig = {
  // 其他配置
};

export default withPWA(nextConfig);
```

### 练习 2：离线页面
```typescript
// public/offline.html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>离线</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f5f5;
    }
    .container {
      text-align: center;
      padding: 2rem;
    }
    h1 {
      color: #333;
    }
    p {
      color: #666;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔌 离线状态</h1>
    <p>您当前处于离线状态，请检查网络连接后重试。</p>
    <button onclick="window.location.reload()">重试</button>
  </div>
</body>
</html>
```

### 练习 3：缓存策略
```typescript
// public/sw.js
const CACHE_NAME = 'v1';
const STATIC_ASSETS = [
  '/',
  '/offline.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
];

// 安装时缓存静态资源
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
});

// 激活时清理旧缓存
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
});

// 拦截请求
self.addEventListener('fetch', (event) => {
  // API 请求使用网络优先策略
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(event.request);
      })
    );
    return;
  }
  
  // 静态资源使用缓存优先策略
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      
      return fetch(event.request)
        .then((response) => {
          // 缓存新资源
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
          return response;
        })
        .catch(() => {
          // 离线时返回离线页面
          if (event.request.mode === 'navigate') {
            return caches.match('/offline.html');
          }
        });
    })
  );
});
```

## 📝 最佳实践

### 1. 合理设置缓存策略
```typescript
// 好：根据资源类型选择策略
// 静态资源：缓存优先
// API 请求：网络优先
// 图片：缓存并更新

// 不好：所有资源相同策略
```

### 2. 提供离线体验
```typescript
// 好：离线页面
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match('/offline.html');
    })
  );
});

// 不好：直接失败
```

### 3. 更新通知
```typescript
// 好：提示用户更新
self.addEventListener('activate', (event) => {
  event.waitUntil(
    self.clients.matchAll().then((clients) => {
      clients.forEach((client) => {
        client.postMessage({ type: 'UPDATE_AVAILABLE' });
      });
    })
  );
});
```

## 🎓 今日总结

**关键知识点：**
1. PWA 提供原生应用体验
2. Service Worker 实现离线缓存
3. Web App Manifest 配置应用信息
4. 缓存策略决定资源获取方式
5. 推送通知增强用户参与

**明日计划：**
- Day 54: Core Web Vitals 优化
