---
title: "Day 30 - 作品集与展望"
tags:
  - portfolio
  - future
  - career
  - day30
created: 2026-05-30
day: 30
type: learning-log
---

# 🚀 个人作品集与未来展望

> 30天学习旅程的终点，也是职业生涯新阶段的起点。本文档记录了完整的作品集、技术栈总结和未来规划。

---

## 🎨 项目展示

### 1. TaskFlow 任务管理应用

一个功能完整的任务管理工具，专注于用户体验和效率。

**技术栈：**
- Next.js 16 (App Router + RSC)
- Shadcn/ui + Tailwind CSS
- Zustand (状态管理)
- TypeScript

**核心功能：**
- ✅ 任务CRUD（创建、编辑、删除、完成）
- ✅ 状态管理（待办、进行中、已完成）
- ✅ 批量操作（全选、批量删除、批量状态变更）
- ✅ 拖拽排序（基于 @dnd-kit/core）
- ✅ 键盘快捷键（Ctrl+N新建、Ctrl+K搜索）
- ✅ 主题切换（亮色/暗色/系统）
- ✅ 响应式设计（移动端适配）

**代码位置：** `~/shadcn-learning/src/app/task-manager/`

**项目亮点：**
```
task-manager/
├── components/
│   ├── TaskCard.tsx          # 任务卡片组件
│   ├── TaskList.tsx          # 任务列表
│   ├── TaskForm.tsx          # 创建/编辑表单
│   ├── BatchActions.tsx      # 批量操作栏
│   └── KeyboardShortcuts.tsx # 快捷键处理
├── store/
│   └── taskStore.ts          # Zustand状态管理
├── hooks/
│   ├── useTasks.ts           # 任务操作Hook
│   └── useDragAndDrop.ts     # 拖拽Hook
└── types/
    └── task.ts               # 类型定义
```

**学习收获：**
- 掌握了复杂状态管理的设计模式
- 理解了拖拽交互的实现原理
- 实践了键盘快捷键的最佳实践

---

### 2. Knowledge Hub 知识管理系统

一个全栈知识管理平台，支持文章管理和团队协作。

**技术栈：**
- Frontend: Next.js 16 + Shadcn/ui
- Backend: Express.js + TypeScript
- Database: PostgreSQL + Prisma ORM
- Auth: JWT + bcrypt

**核心功能：**
- ✅ 用户认证（注册、登录、JWT Token）
- ✅ 文章CRUD（Markdown编辑器、富文本预览）
- ✅ 分类与标签（多对多关系、筛选、排序）
- ✅ 全文搜索（PostgreSQL FTS）
- ✅ 仪表板（数据统计、图表可视化）
- ✅ 角色权限（管理员、编辑、访客）

**代码位置：**
- 前端：`~/shadcn-learning/knowledge-hub/`
- 后端：`~/shadcn-learning/knowledge-hub-api/`

**数据库设计：**
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  name      String
  role      Role     @default(USER)
  articles  Article[]
  createdAt DateTime @default(now())
}

model Article {
  id        String   @id @default(cuid())
  title     String
  content   String
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  categories Category[]
  tags      Tag[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Category {
  id       String    @id @default(cuid())
  name     String    @unique
  articles Article[]
}

model Tag {
  id       String    @id @default(cuid())
  name     String    @unique
  articles Article[]
}
```

**API设计：**
```
POST   /api/auth/register    # 用户注册
POST   /api/auth/login       # 用户登录
GET    /api/auth/me          # 获取当前用户

GET    /api/articles         # 获取文章列表
POST   /api/articles         # 创建文章
GET    /api/articles/:id     # 获取文章详情
PUT    /api/articles/:id     # 更新文章
DELETE /api/articles/:id     # 删除文章

GET    /api/categories       # 获取分类列表
GET    /api/tags             # 获取标签列表
GET    /api/search?q=        # 全文搜索
GET    /api/dashboard        # 仪表板数据
```

**学习收获：**
- 理解了全栈应用的完整架构
- 掌握了JWT认证的安全实践
- 学会了数据库关系设计和优化

---

### 3. Express API 框架

一个可复用的RESTful API框架，包含认证、验证和错误处理。

**技术栈：**
- Express.js + TypeScript
- Prisma ORM
- JWT认证
- Zod验证
- Winston日志

**核心功能：**
- ✅ RESTful路由设计
- ✅ JWT认证中间件
- ✅ 请求验证（Zod Schema）
- ✅ 统一错误处理
- ✅ 请求日志记录
- ✅ CORS配置
- ✅ 环境变量管理

**代码位置：** `~/shadcn-learning/express-api/`

**项目结构：**
```
express-api/
├── src/
│   ├── controllers/        # 路由控制器
│   ├── middlewares/        # 中间件
│   │   ├── auth.ts         # JWT认证
│   │   ├── validate.ts     # Zod验证
│   │   └── errorHandler.ts # 错误处理
│   ├── routes/             # 路由定义
│   ├── services/           # 业务逻辑
│   ├── utils/              # 工具函数
│   └── app.ts              # 应用入口
├── prisma/
│   └── schema.prisma       # 数据库模型
├── tests/                  # 测试文件
└── docker-compose.yml      # Docker配置
```

**中间件示例：**
```typescript
// JWT认证中间件
export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      throw new AppError('未提供认证令牌', 401);
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    req.user = decoded;
    next();
  } catch (error) {
    next(new AppError('认证失败', 401));
  }
};

// Zod验证中间件
export const validate = (schema: ZodSchema) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      next(new AppError('请求参数验证失败', 400));
    }
  };
};
```

**学习收获：**
- 掌握了Express中间件的高级用法
- 理解了API安全的最佳实践
- 学会了构建可复用的后端框架

---

## 📚 学习笔记清单

### 第1周：UI设计 + 组件库
- [[Day01-环境搭建与Shadcn-ui入门]]
- [[Day02-Shadcn-ui组件深入]]
- [[Day03-Radix-UI基础]]
- [[Day04-布局系统]]
- [[Day05-Next.js-App-Router]]
- [[Day06-React-Server-Components]]
- [[Day07-数据库入门与Prisma]]
- [[Day08-测试基础]]
- [[Day09-性能优化]]

### 第2周：前端框架深入
- [[Day10-Server-Actions]]
- [[Day11-状态管理与Zustand]]
- [[Day12-TaskFlow项目启动]]
- [[Day13-TaskFlow核心功能]]
- [[Day14-TaskFlow完善]]

### 第3周：后端开发
- [[Day15-Express入门]]
- [[Day16-Express中间件]]
- [[Day17-Prisma进阶]]
- [[Day18-JWT认证]]
- [[Day19-API测试]]
- [[Day20-Docker基础]]
- [[Day21-API文档]]

### 第4周：全栈项目
- [[Day22-Knowledge-Hub架构]]
- [[Day23-用户认证系统]]
- [[Day24-文章CRUD与Markdown]]
- [[Day25-分类与标签系统]]
- [[Day26-全文搜索实现]]
- [[Day27-仪表板与数据可视化]]
- [[Day28-Knowledge-Hub部署与优化]]

### 总结
- [[Day29-30天学习总结]]

---

## 🗺️ 技术栈总结图

```
┌─────────────────────────────────────────────────────────────┐
│                      前端技术栈                              │
├─────────────────────────────────────────────────────────────┤
│  Next.js 16 (App Router + RSC)                              │
│  ├── React 19 (Hooks + 组件组合)                             │
│  ├── TypeScript (类型安全)                                   │
│  ├── Shadcn/ui (UI组件库)                                   │
│  ├── Tailwind CSS (样式系统)                                 │
│  ├── Zustand (状态管理)                                     │
│  └── React Query (数据获取)                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      后端技术栈                              │
├─────────────────────────────────────────────────────────────┤
│  Express.js + TypeScript                                    │
│  ├── Prisma ORM (数据库)                                    │
│  ├── JWT (认证)                                             │
│  ├── Zod (验证)                                             │
│  ├── Winston (日志)                                         │
│  └── Swagger (文档)                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      DevOps工具                              │
├─────────────────────────────────────────────────────────────┤
│  Docker + docker-compose                                    │
│  ├── Git (版本控制)                                         │
│  ├── Jest (测试)                                            │
│  ├── ESLint + Prettier (代码规范)                            │
│  └── GitHub Actions (CI/CD)                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📈 技能雷达图

```
         UI设计
           ★★★★
            │
            │
   部署 ★★★├────┤★★★★ TypeScript
            │    │
   测试 ★★★├────┤★★★★ React
            │    │
  Docker ★★★├────┤★★★★ Next.js
            │    │
  Prisma ★★★├────┤★★★★ Express
            │    │
 Zustand ★★★├────┤★★★ PostgreSQL
            │
         Git/CI
          ★★★
```

---

## 🗓️ 未来规划

### 3个月规划（2026年6月-8月）

#### 目标1：深入React Native（移动端开发）

**为什么选择React Native：**
- 已有React基础，学习曲线平缓
- 跨平台开发，一套代码覆盖iOS和Android
- 就业市场需求大

**学习计划：**
- Week 1-2: React Native基础 + Expo
- Week 3-4: 导航、状态管理、原生模块
- Week 5-6: 构建一个完整的移动端项目
- Week 7-8: 发布到App Store / Google Play

**实践项目：**
将TaskFlow移植到移动端，实现：
- 任务管理（CRUD）
- 离线支持
- 推送通知
- 手势操作

---

#### 目标2：学习Kubernetes

**为什么学习K8s：**
- 现代云原生应用的标准部署方式
- 容器编排能力是高级工程师必备技能
- 微服务架构的基础

**学习计划：**
- Week 1-2: Docker深入 + K8s基础概念
- Week 3-4: Pod、Service、Deployment
- Week 5-6: ConfigMap、Secret、持久化存储
- Week 7-8: Helm Charts、CI/CD集成

**实践项目：**
将Knowledge Hub部署到K8s集群：
- 前端、后端、数据库分别部署
- 配置Ingress和SSL
- 实现自动扩缩容

---

#### 目标3：贡献开源项目

**选择标准：**
- 技术栈匹配（Next.js/React生态）
- 社区活跃（Star > 1000，有定期Release）
- 文档完善（有贡献指南）

**目标项目：**
1. Shadcn/ui - 组件库
2. Next.js - 框架
3. Prisma - ORM

**贡献计划：**
- 先从文档改进开始
- 修复Good First Issue
- 逐步实现新功能

---

#### 目标4：构建个人品牌

**内容输出：**
- 技术博客（每周1篇）
- 开源项目（维护2-3个）
- 技术分享（线上/线下）

**平台选择：**
- GitHub（代码展示）
- 掘金/思否（中文社区）
- Dev.to/Medium（英文社区）
- Twitter/X（技术动态）

---

### 6个月规划（2026年9月-2027年2月）

#### 目标1：系统设计学习

**学习内容：**
- 分布式系统原理
- 数据库设计（SQL vs NoSQL）
- 缓存策略（Redis）
- 消息队列（RabbitMQ/Kafka）
- 负载均衡与高可用

**推荐资源：**
- 《系统设计面试》
- Alex Xu的系统设计课程
- High Scalability博客

**实践项目：**
设计一个短链接服务（类似bit.ly），包含：
- URL缩短算法
- 高并发处理
- 统计分析
- 分布式缓存

---

#### 目标2：分布式系统

**核心概念：**
- CAP定理
- 一致性协议（Raft、Paxos）
- 分布式事务
- 数据分片

**学习路径：**
1. 理论基础（MIT 6.824课程）
2. 实践项目（实现简单的分布式KV存储）
3. 阅读论文（Google File System、MapReduce）

---

#### 目标3：云原生技术

**技术栈：**
- Kubernetes（深入）
- Istio（服务网格）
- Prometheus + Grafana（监控）
- Jaeger（分布式追踪）

**认证目标：**
- CKA（Kubernetes管理员）
- AWS Solutions Architect

---

## 💼 职业发展路径

```
当前阶段（2026年5月）
    │
    ▼
┌─────────────────────────────────────┐
│  初级全栈开发工程师                    │
│  - 独立完成前端/后端任务               │
│  - 参与代码Review                    │
│  - 编写单元测试                      │
└─────────────────────────────────────┘
    │
    │ 6-12个月
    ▼
┌─────────────────────────────────────┐
│  中级全栈开发工程师                    │
│  - 负责完整功能模块                   │
│  - 技术方案设计                      │
│  - 指导初级工程师                    │
└─────────────────────────────────────┘
    │
    │ 1-2年
    ▼
┌─────────────────────────────────────┐
│  高级全栈开发工程师                    │
│  - 系统架构设计                      │
│  - 技术选型决策                      │
│  - 性能优化专家                      │
└─────────────────────────────────────┘
    │
    │ 2-3年
    ▼
┌─────────────────────────────────────┐
│  技术负责人 / 架构师                   │
│  - 技术战略规划                      │
│  - 团队管理                         │
│  - 跨团队协作                       │
└─────────────────────────────────────┘
```

---

## 🎯 2026年度目标回顾

| 目标 | 状态 | 说明 |
|------|------|------|
| 掌握Next.js 16 | ✅ 完成 | App Router + RSC + Server Actions |
| 学会状态管理 | ✅ 完成 | Zustand + React Context |
| 掌握后端开发 | ✅ 完成 | Express + Prisma + JWT |
| 完成全栈项目 | ✅ 完成 | Knowledge Hub |
| 学会Docker | ✅ 完成 | 基础容器化 |
| 学习测试 | 🟡 进行中 | 需要更多实践 |
| 学习CI/CD | ⏳ 待开始 | GitHub Actions |
| 部署到生产 | 🟡 进行中 | 基础部署完成 |

---

## 📝 写给未来自己的信

亲爱的未来的我：

当你看到这封信时，希望你已经实现了这些目标。

30天前，你还是一个对全栈开发充满迷茫的新手。现在，你已经能够独立完成前端、后端和部署的完整流程。

记住这30天教会你的：
1. **持续学习**比天赋更重要
2. **动手实践**比看教程更有效
3. **解决问题**的能力比记住答案更重要
4. **代码质量**比代码速度更重要
5. **团队协作**比个人英雄更关键

保持好奇心，保持学习的激情。

技术在变化，但学习的方法和解决问题的思维是永恒的。

**加油，未来的自己！**

---

## 🙏 致谢

感谢所有在这30天里帮助过我的人：

- 官方文档的编写者们
- Stack Overflow上的热心回答者们
- GitHub上开源项目的贡献者们
- 技术社区里分享经验的前辈们

**学习永无止境，让我们继续前行。**

---

## 📌 相关笔记

- [[Day29-30天学习总结]]
- [[Day28-Knowledge-Hub部署与优化]]
- [[Day14-TaskFlow完善]]

---

*最后更新：2026-05-30*
