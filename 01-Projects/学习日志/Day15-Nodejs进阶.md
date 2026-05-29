---
tags:
  - nodejs
  - express
  - backend
  - middleware
  - day15
created: 2026-05-30
day: 15
---

# Day 15 - Node.js + Express 进阶

## Express 进阶模式

### 自定义中间件

Express 中间件本质是一个 `(req, res, next)` 函数。按功能分类：

#### 1. 日志中间件

```typescript
import { Request, Response, NextFunction } from 'express';

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(
      `${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`
    );
  });

  next();
}
```

#### 2. 认证中间件

```typescript
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: '未提供认证令牌' });
  }

  try {
    const payload = verifyToken(token); // 你的验证逻辑
    req.user = payload;
    next();
  } catch {
    res.status(401).json({ error: '令牌无效或已过期' });
  }
}
```

#### 3. 限流中间件 (Rate Limiting)

```typescript
const requestCounts = new Map<string, { count: number; resetTime: number }>();

export function rateLimit(maxRequests: number, windowMs: number) {
  return (req: Request, res: Response, next: NextFunction) => {
    const ip = req.ip || 'unknown';
    const now = Date.now();
    const record = requestCounts.get(ip);

    if (!record || now > record.resetTime) {
      requestCounts.set(ip, { count: 1, resetTime: now + windowMs });
      return next();
    }

    if (record.count >= maxRequests) {
      return res.status(429).json({ error: '请求过于频繁，请稍后再试' });
    }

    record.count++;
    next();
  };
}

// 使用：app.use(rateLimit(100, 60 * 1000)); // 每分钟最多100次
```

### 错误处理中间件

#### Express 错误处理核心概念

Express 识别错误中间件的标志是 **4 个参数** `(err, req, res, next)`：

```typescript
// 全局错误处理（放在所有路由之后）
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    error: '服务器内部错误',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});
```

#### Async Error Wrapper（关键模式！）

Express 不会自动捕获 async 函数的错误，需要包装：

```typescript
type AsyncHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => Promise<any>;

export function asyncHandler(fn: AsyncHandler) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// 使用方式
router.get(
  '/tasks/:id',
  asyncHandler(async (req, res) => {
    const task = await taskStore.findById(req.params.id);
    if (!task) {
      throw new AppError('任务不存在', 404); // 自定义错误类
    }
    res.json(task);
  })
);
```

#### 自定义应用错误类

```typescript
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = 'AppError';
  }
}
```

### 路由组织 (Modular Routes)

```typescript
// src/routes/tasks.ts
import { Router } from 'express';

const router = Router();

router.get('/', listTasks);
router.get('/:id', getTask);
router.post('/', createTask);
router.put('/:id', updateTask);
router.delete('/:id', deleteTask);

export default router;

// src/index.ts
import taskRoutes from './routes/tasks.js';
app.use('/api/tasks', taskRoutes);
```

**好处**：每个资源一个路由文件，index.ts 只负责挂载。

### 请求验证 (Zod + Express)

```typescript
import { z } from 'zod';

// 定义 schema
const createTaskSchema = z.object({
  title: z.string().min(1, '标题不能为空').max(200),
  description: z.string().optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
});

// 通用验证中间件
import { ZodSchema } from 'zod';

export function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: '请求数据无效',
        details: result.error.flatten().fieldErrors,
      });
    }
    req.body = result.data; // 使用解析后的数据
    next();
  };
}

// 使用
router.post('/', validate(createTaskSchema), createTask);
```

### 文件上传 (Multer)

```typescript
import multer from 'multer';

const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${file.originalname}`;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('只允许上传图片文件'));
    }
  },
});

// 使用
router.post('/upload', upload.single('avatar'), (req, res) => {
  res.json({ filename: req.file?.filename });
});
```

### 安全中间件

```typescript
import helmet from 'helmet';
import cors from 'cors';

// Helmet - 设置安全 HTTP 头
app.use(helmet());

// CORS - 控制跨域访问
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true,
}));
```

**常见安全 HTTP 头**（Helmet 自动设置）:
| 头部 | 作用 |
|---|---|
| `X-Content-Type-Options` | 防止 MIME 嗅探 |
| `X-Frame-Options` | 防止点击劫持 |
| `Strict-Transport-Security` | 强制 HTTPS |
| `Content-Security-Policy` | 防止 XSS |

### 日志 (Winston / Pino)

```typescript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

export default logger;
```

**Winston vs Pino 对比**：
| 特性 | Winston | Pino |
|---|---|---|
| 性能 | 中等 | 极快（JSON 序列化优化） |
| 插件生态 | 丰富 | 较少 |
| 格式化 | 内置丰富 | 需要 pino-pretty |
| 适用场景 | 通用 | 高吞吐生产环境 |

### 环境变量管理 (dotenv)

```typescript
import dotenv from 'dotenv';

// 根据环境加载不同文件
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
dotenv.config({ path: envFile });

// 使用
const PORT = parseInt(process.env.PORT || '3001', 10);
const NODE_ENV = process.env.NODE_ENV || 'development';
```

`.env` 文件示例：
```env
PORT=3001
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
LOG_LEVEL=debug
```

> **最佳实践**：永远不要把 `.env` 提交到 Git。用 `.env.example` 作为模板。

---

## Express vs Fastify vs Hono 对比

| 特性 | Express | Fastify | Hono |
|---|---|---|---|
| **性能** | 一般 | 快（~2x Express） | 极快 |
| **TypeScript** | 类型需额外安装 | 内置良好 | 原生支持 |
| **中间件** | 生态最丰富 | 插件系统 | 中间件模式 |
| **学习曲线** | 低 | 中等 | 低 |
| **WS 支持** | 需要额外库 | 原生支持 | 有限 |
| **适用场景** | 通用/学习 | 高性能 API | Edge/Serverless |
| **维护状态** | 稳定但慢 | 活跃 | 非常活跃 |

**选择建议**：
- 学习/快速原型 → Express（资料最多）
- 生产 API 服务 → Fastify（性能+类型安全）
- Edge Runtime / 多平台 → Hono（支持 Deno/Bun/CF Workers）

---

## Node.js 22 新特性

### 1. `require()` 加载 ES Modules (实验性)

```javascript
// 现在可以在 CommonJS 中 require ESM 模块了
// 需要 --experimental-require-module 标志
const esmModule = require('./my-esm-module.mjs');
```

### 2. `WebSocket` 客户端（内置）

```javascript
// 不再需要安装 ws 库来做客户端 WebSocket
const ws = new WebSocket('ws://localhost:8080');
ws.onopen = () => ws.send('Hello');
ws.onmessage = (event) => console.log(event.data);
```

### 3. `--watch` 模式稳定

```bash
# 内置文件监听，无需 nodemon
node --watch src/index.js
```

### 4. `glob` 和 `globSync` 内置

```javascript
const { glob, globSync } = require('node:fs');
const files = globSync('**/*.ts', { cwd: 'src' });
```

### 5. `test_runner` 改进

```javascript
import { describe, it, mock } from 'node:test';

describe('数学测试', () => {
  it('应该正确相加', () => {
    assert.strictEqual(1 + 1, 2);
  });
});
```

### 6. Maglev 编译器

V8 引擎新增 Maglev 中间层编译器，介于 Sparkplug 和 TurboFan 之间，提升中等热度代码的执行性能。

---

## 今日项目

完整示例见 `~/shadcn-learning/express-api/`，包含：
- TypeScript + ES Modules 配置
- Task CRUD API（增删改查）
- Zod 请求验证
- 全局错误处理
- 请求日志中间件
- Helmet + CORS 安全配置

```bash
cd ~/shadcn-learning/express-api
npm install
npx tsx src/index.ts
# 访问 http://localhost:3001/api/tasks
```

---

## 关键要点

1. **async 错误必须用 wrapper 捕获** — Express 的致命缺陷，必须记住
2. **Zod 做运行时验证** — TypeScript 只在编译时检查，HTTP 请求需要运行时验证
3. **中间件顺序很重要** — `helmet()` → `cors()` → `json()` → routes → error handler
4. **生产环境至少需要** helmet + cors + rate limiting + structured logging
