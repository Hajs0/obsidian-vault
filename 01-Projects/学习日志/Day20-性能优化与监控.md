---
tags:
  - performance
  - monitoring
  - nodejs
  - redis
  - day20
created: 2026-05-30
day: 20
---

# Day 20: 性能优化与监控 🚀

## 今日目标

- 掌握 Node.js 性能优化技巧
- 学会 API 性能优化策略
- 了解监控工具的使用
- 实践缓存和连接池优化

---

## 一、Node.js 性能优化

### 1.1 Cluster 模式

Node.js 是单线程的，利用 Cluster 可以充分利用多核 CPU：

```typescript
// src/cluster.ts
import cluster from 'cluster';
import os from 'os';
import { createApp } from './app';

const numCPUs = os.cpus().length;

if (cluster.isPrimary) {
  console.log(`主进程 ${process.pid} 正在运行`);
  console.log(`启动 ${numCPUs} 个工作进程...`);

  // Fork 工作进程
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  // 监听工作进程退出
  cluster.on('exit', (worker, code, signal) => {
    console.log(`工作进程 ${worker.process.pid} 已退出 (code: ${code}, signal: ${signal})`);
    console.log('启动新的工作进程...');
    cluster.fork();
  });

  // 监听工作进程消息
  cluster.on('message', (worker, message) => {
    console.log(`来自工作进程 ${worker.process.pid} 的消息:`, message);
  });
} else {
  const app = createApp();
  const PORT = process.env.PORT || 3000;

  app.listen(PORT, () => {
    console.log(`工作进程 ${process.pid} 已启动，监听端口 ${PORT}`);
  });
}
```

```json
// package.json
{
  "scripts": {
    "start": "node dist/cluster.js",
    "dev": "tsx watch src/index.ts",
    "cluster": "tsx src/cluster.ts"
  }
}
```

### 1.2 内存管理

```typescript
// src/utils/memory.ts
import v8 from 'v8';

export function getMemoryUsage() {
  const memory = process.memoryUsage();
  return {
    rss: formatBytes(memory.rss),           // 常驻内存
    heapTotal: formatBytes(memory.heapTotal), // 堆总内存
    heapUsed: formatBytes(memory.heapUsed),   // 堆已用内存
    external: formatBytes(memory.external),   // 外部内存
    arrayBuffers: formatBytes(memory.arrayBuffers)
  };
}

export function getHeapStatistics() {
  const stats = v8.getHeapStatistics();
  return {
    totalHeapSize: formatBytes(stats.total_heap_size),
    usedHeapSize: formatBytes(stats.used_heap_size),
    heapSizeLimit: formatBytes(stats.heap_size_limit),
    mallocedMemory: formatBytes(stats.malloced_memory),
    peakMallocedMemory: formatBytes(stats.peak_malloced_memory)
  };
}

function formatBytes(bytes: number): string {
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;
  
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  
  return `${size.toFixed(2)} ${units[unitIndex]}`;
}

// 定期检查内存使用
export function startMemoryMonitor(interval = 30000) {
  setInterval(() => {
    const usage = getMemoryUsage();
    console.log('内存使用情况:', usage);
    
    // 如果堆内存使用超过 80%，发出警告
    const heapUsed = process.memoryUsage().heapUsed;
    const heapTotal = process.memoryUsage().heapTotal;
    const usagePercent = (heapUsed / heapTotal) * 100;
    
    if (usagePercent > 80) {
      console.warn(`⚠️ 堆内存使用率过高: ${usagePercent.toFixed(2)}%`);
      // 可以触发垃圾回收
      if (global.gc) {
        global.gc();
      }
    }
  }, interval);
}
```

```bash
# 启动时启用垃圾回收日志
node --expose-gc --trace-gc src/index.js

# 监控内存泄漏
node --inspect src/index.js
# 然后打开 chrome://inspect 进行内存分析
```

### 1.3 事件循环监控

```typescript
// src/utils/eventLoop.ts
import { monitorEventLoopDelay } from 'perf_hooks';

export class EventLoopMonitor {
  private histogram: any;
  private interval: NodeJS.Timer | null = null;

  constructor() {
    // 创建事件循环延迟监控器
    this.histogram = monitorEventLoopDelay({ resolution: 20 });
    this.histogram.enable();
  }

  start(interval = 5000) {
    this.interval = setInterval(() => {
      const stats = {
        min: (this.histogram.min / 1e6).toFixed(2) + 'ms',
        max: (this.histogram.max / 1e6).toFixed(2) + 'ms',
        mean: (this.histogram.mean / 1e6).toFixed(2) + 'ms',
        p50: (this.histogram.percentile(50) / 1e6).toFixed(2) + 'ms',
        p99: (this.histogram.percentile(99) / 1e6).toFixed(2) + 'ms'
      };

      console.log('事件循环延迟:', stats);

      // 如果 p99 延迟超过 100ms，发出警告
      if (this.histogram.percentile(99) > 100 * 1e6) {
        console.warn('⚠️ 事件循环延迟过高！');
      }

      this.histogram.reset();
    }, interval);
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval);
    }
    this.histogram.disable();
  }
}

// 使用示例
export function checkEventLoopLag() {
  let lastTime = process.hrtime.bigint();
  
  const check = () => {
    const now = process.hrtime.bigint();
    const lag = Number(now - lastTime) / 1e6; // 转换为毫秒
    
    if (lag > 100) { // 超过 100ms
      console.warn(`事件循环延迟: ${lag.toFixed(2)}ms`);
    }
    
    lastTime = now;
    setTimeout(check, 0);
  };
  
  check();
}
```

---

## 二、API 性能优化

### 2.1 数据库连接池

```typescript
// src/config/database.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  },
  // 连接池配置
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'event' },
    { level: 'warn', emit: 'event' }
  ]
});

// 监控查询性能
prisma.$on('query', (e) => {
  if (e.duration > 1000) { // 查询超过 1 秒
    console.warn(`慢查询 (${e.duration}ms):`, e.query);
  }
});

// 连接池状态监控
export async function getConnectionPoolStatus() {
  try {
    const result = await prisma.$queryRaw`
      SELECT 
        count(*) as total_connections,
        count(CASE WHEN state = 'active' THEN 1 END) as active,
        count(CASE WHEN state = 'idle' THEN 1 END) as idle
      FROM pg_stat_activity 
      WHERE datname = current_database()
    `;
    return result;
  } catch (error) {
    // SQLite 不支持此查询
    return { total: 'N/A', active: 'N/A', idle: 'N/A' };
  }
}

export default prisma;
```

### 2.2 查询优化

```typescript
// src/services/userService.ts
import prisma from '../config/database';

export class UserService {
  // ❌ 不好的做法：N+1 查询
  async getUsersWithPostsBad() {
    const users = await prisma.user.findMany(); // 1 次查询
    
    for (const user of users) {
      user.posts = await prisma.post.findMany({ // N 次查询
        where: { authorId: user.id }
      });
    }
    
    return users;
  }

  // ✅ 好的做法：使用 include 一次查询
  async getUsersWithPostsGood() {
    return prisma.user.findMany({
      include: {
        posts: true,
        _count: {
          select: { posts: true }
        }
      }
    });
  }

  // ✅ 分页查询优化
  async getUsersPaginated(page: number, limit: number) {
    const skip = (page - 1) * limit;
    
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        skip,
        take: limit,
        select: {
          id: true,
          name: true,
          email: true,
          createdAt: true
        }
      }),
      prisma.user.count()
    ]);
    
    return {
      data: users,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  // ✅ 使用索引优化查询
  async searchUsers(query: string) {
    return prisma.user.findMany({
      where: {
        OR: [
          { name: { contains: query } },
          { email: { contains: query } }
        ]
      },
      take: 20
    });
  }
}
```

```prisma
// prisma/schema.prisma - 添加索引
model User {
  id        String   @id @default(cuid())
  name      String
  email     String   @unique
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  posts     Post[]

  @@index([name])      // 为 name 添加索引
  @@index([createdAt]) // 为 createdAt 添加索引
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([authorId])  // 为外键添加索引
  @@index([published]) // 为 published 添加索引
}
```

### 2.3 缓存 (Redis)

```typescript
// src/config/redis.ts
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD,
  maxRetriesPerRequest: 3,
  retryStrategy(times) {
    const delay = Math.min(times * 50, 2000);
    return delay;
  }
});

redis.on('connect', () => {
  console.log('✅ Redis 连接成功');
});

redis.on('error', (err) => {
  console.error('❌ Redis 连接错误:', err);
});

export default redis;
```

```typescript
// src/middleware/cache.ts
import { Request, Response, NextFunction } from 'express';
import redis from '../config/redis';

export function cacheMiddleware(ttl: number = 300) {
  return async (req: Request, res: Response, next: NextFunction) => {
    // 只缓存 GET 请求
    if (req.method !== 'GET') {
      return next();
    }

    const key = `cache:${req.originalUrl}`;

    try {
      const cached = await redis.get(key);
      
      if (cached) {
        console.log(`缓存命中: ${key}`);
        return res.json(JSON.parse(cached));
      }

      // 重写 res.json 方法来缓存响应
      const originalJson = res.json.bind(res);
      res.json = (body: any) => {
        // 异步缓存响应
        redis.setex(key, ttl, JSON.stringify(body)).catch(console.error);
        return originalJson(body);
      };

      next();
    } catch (error) {
      // Redis 错误时不阻止请求
      next();
    }
  };
}

// 清除缓存
export async function clearCache(pattern: string) {
  const keys = await redis.keys(pattern);
  if (keys.length > 0) {
    await redis.del(...keys);
    console.log(`清除缓存: ${keys.length} 个键`);
  }
}
```

```typescript
// src/routes/users.ts
import { Router } from 'express';
import { cacheMiddleware, clearCache } from '../middleware/cache';
import { UserService } from '../services/userService';

const router = Router();
const userService = new UserService();

// 缓存用户列表 5 分钟
router.get('/', cacheMiddleware(300), async (req, res) => {
  const users = await userService.getUsersPaginated(
    parseInt(req.query.page as string) || 1,
    parseInt(req.query.limit as string) || 10
  );
  res.json(users);
});

// 创建用户后清除缓存
router.post('/', async (req, res) => {
  const user = await userService.createUser(req.body);
  await clearCache('cache:/api/users*'); // 清除相关缓存
  res.status(201).json(user);
});

export default router;
```

```yaml
# docker-compose.yml 添加 Redis
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - app-network

volumes:
  redis-data:
```

---

## 三、监控工具

### 3.1 Prometheus 指标收集

```typescript
// src/utils/metrics.ts
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

// 创建注册表
export const register = new Registry();

// 收集默认指标（CPU、内存等）
collectDefaultMetrics({ register });

// 自定义指标
export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP 请求持续时间',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

export const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'HTTP 请求总数',
  labelNames: ['method', 'route', 'status_code']
});

export const activeConnections = new Gauge({
  name: 'active_connections',
  help: '活跃连接数'
});

export const dbQueryDuration = new Histogram({
  name: 'db_query_duration_seconds',
  help: '数据库查询持续时间',
  labelNames: ['operation', 'table'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
});

export const cacheHitRate = new Counter({
  name: 'cache_operations_total',
  help: '缓存操作总数',
  labelNames: ['operation', 'result'] // operation: get/set, result: hit/miss
});

// 注册自定义指标
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(activeConnections);
register.registerMetric(dbQueryDuration);
register.registerMetric(cacheHitRate);
```

```typescript
// src/middleware/metrics.ts
import { Request, Response, NextFunction } from 'express';
import { 
  httpRequestDuration, 
  httpRequestTotal, 
  activeConnections 
} from '../utils/metrics';

export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime.bigint();
  
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = Number(process.hrtime.bigint() - start) / 1e9;
    
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode.toString()
    };
    
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
    activeConnections.dec();
  });
  
  next();
}
```

```typescript
// src/routes/metrics.ts
import { Router } from 'express';
import { register } from '../utils/metrics';

const router = Router();

router.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

export default router;
```

### 3.2 Grafana 仪表板配置

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'express-api'
    static_configs:
      - targets: ['host.docker.internal:3000']
    metrics_path: '/metrics'
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

```json
// grafana/dashboards/express-api.json
{
  "dashboard": {
    "title": "Express API 监控",
    "panels": [
      {
        "title": "请求速率",
        "targets": [{
          "expr": "rate(http_requests_total[5m])"
        }]
      },
      {
        "title": "响应时间分布",
        "targets": [{
          "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
        }]
      },
      {
        "title": "错误率",
        "targets": [{
          "expr": "rate(http_requests_total{status_code=~\"5..\"}[5m])"
        }]
      },
      {
        "title": "活跃连接数",
        "targets": [{
          "expr": "active_connections"
        }]
      }
    ]
  }
}
```

---

## 四、性能优化清单

### 4.1 应用层优化

```typescript
// ✅ 启用 gzip 压缩
import compression from 'compression';
app.use(compression());

// ✅ 启用 ETag 缓存
app.set('etag', 'strong');

// ✅ 限制请求体大小
app.use(express.json({ limit: '10mb' }));

// ✅ 使用 Helmet 安全头
import helmet from 'helmet';
app.use(helmet());

// ✅ 限流保护
import rateLimit from 'express-rate-limit';
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分钟
  max: 100 // 每个 IP 最多 100 个请求
});
app.use('/api', limiter);
```

### 4.2 数据库优化

```typescript
// ✅ 使用 select 只查询需要的字段
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true
  }
});

// ✅ 使用 take 和 skip 分页
const posts = await prisma.post.findMany({
  take: 20,
  skip: 0,
  orderBy: { createdAt: 'desc' }
});

// ✅ 使用 cursor 分页（大数据集）
const posts = await prisma.post.findMany({
  take: 20,
  cursor: { id: lastPostId },
  orderBy: { id: 'asc' }
});

// ✅ 批量操作减少查询次数
await prisma.$transaction([
  prisma.user.update({ where: { id: 1 }, data: { name: 'Alice' } }),
  prisma.user.update({ where: { id: 2 }, data: { name: 'Bob' } }),
  prisma.user.update({ where: { id: 3 }, data: { name: 'Charlie' } })
]);
```

### 4.3 响应优化

```typescript
// ✅ 响应压缩中间件
app.use((req, res, next) => {
  // 设置缓存头
  if (req.method === 'GET') {
    res.set('Cache-Control', 'public, max-age=300'); // 5 分钟
  }
  next();
});

// ✅ 分页响应格式
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
  links: {
    self: string;
    next?: string;
    prev?: string;
  };
}
```

---

## 五、性能测试

### 5.1 使用 autocannon 进行负载测试

```bash
# 安装
npm install -g autocannon

# 测试 GET 请求
autocannon -c 100 -d 30 http://localhost:3000/api/users

# 测试 POST 请求
autocannon -c 100 -d 30 -m POST \
  -H "Content-Type=application/json" \
  -b '{"name":"test","email":"test@example.com"}' \
  http://localhost:3000/api/users
```

```typescript
// scripts/load-test.ts
import autocannon from 'autocannon';

const instance = autocannon({
  url: 'http://localhost:3000/api/users',
  connections: 100,
  duration: 30,
  headers: {
    'Authorization': 'Bearer test-token'
  }
}, (err, result) => {
  console.log('测试结果:');
  console.log(`  总请求数: ${result.requests.total}`);
  console.log(`  平均 RPS: ${result.requests.average}`);
  console.log(`  平均延迟: ${result.latency.average}ms`);
  console.log(`  P99 延迟: ${result.latency.p99}ms`);
  console.log(`  错误数: ${result.errors}`);
});

autocannon.track(instance);
```

---

## 六、性能优化检查清单

- [ ] 启用 gzip 压缩
- [ ] 配置数据库连接池
- [ ] 添加数据库索引
- [ ] 实现 Redis 缓存
- [ ] 使用 Cluster 模式
- [ ] 优化 N+1 查询
- [ ] 实现分页查询
- [ ] 配置限流保护
- [ ] 启用 HTTP/2
- [ ] 配置 CDN
- [ ] 监控事件循环延迟
- [ ] 设置内存告警
- [ ] 配置 Prometheus + Grafana
- [ ] 定期进行负载测试

---

## 今日练习

1. 为 Express API 添加 Cluster 模式支持
2. 实现 Redis 缓存中间件
3. 配置 Prometheus 指标收集
4. 使用 autocannon 进行负载测试并优化

---

## 今日总结

| 主题 | 掌握程度 |
|-----|---------|
| Cluster 模式 | ⭐⭐⭐ |
| 内存管理 | ⭐⭐⭐ |
| 数据库优化 | ⭐⭐⭐⭐ |
| Redis 缓存 | ⭐⭐⭐ |
| 监控工具 | ⭐⭐⭐ |
| 负载测试 | ⭐⭐⭐ |

> **关键收获：** 性能优化是一个持续的过程，需要通过监控发现问题，通过测试验证效果。合理的缓存策略和数据库优化可以显著提升 API 性能。
