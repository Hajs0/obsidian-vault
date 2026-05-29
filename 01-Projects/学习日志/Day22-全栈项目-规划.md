---
tags:
  - project
  - fullstack
  - knowledge-management
  - day22
created: 2026-05-30
day: 22
---

# Day 22-25: 全栈项目 — 知识管理系统 (Knowledge Hub)

## 项目概述

知识管理系统是一个全栈 Web 应用，允许用户创建、组织、搜索和分享知识文章。作为 30 天学习计划的综合项目，它将综合运用所学的所有技术栈。

---

## 功能需求

### 1. 用户认证
- 用户注册（邮箱 + 密码）
- 用户登录 / 登出
- JWT Token 认证
- 个人资料管理（头像、简介）

### 2. 知识文章 CRUD
- 创建文章（标题 + Markdown 内容 + 分类 + 标签）
- 编辑文章
- 删除文章（软删除）
- 文章详情查看

### 3. 分类和标签
- 文章分类管理（树形结构）
- 标签系统（多对多关系）
- 按分类 / 标签筛选

### 4. 全文搜索
- 按标题和内容搜索
- 搜索结果高亮
- 搜索建议

### 5. Markdown 编辑器
- 实时预览
- 语法高亮
- 工具栏（加粗、斜体、标题、链接、图片、代码块）

### 6. 文章收藏和点赞
- 点赞 / 取消点赞
- 收藏 / 取消收藏
- 收藏列表

### 7. 仪表板统计
- 文章总数
- 总浏览量
- 总点赞数
- 分类分布图
- 最近文章列表

### 8. 响应式设计
- 桌面端 / 平板 / 手机适配
- 移动端侧边栏折叠

---

## 技术架构图

```
┌─────────────────────────────────────────────────────────┐
│                      客户端 (Browser)                     │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           Next.js 16 App Router (前端)              │ │
│  │                                                     │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │ │
│  │  │ Shadcn/ui│ │ Zustand  │ │ React Hook Form  │   │ │
│  │  │  组件库   │ │ 状态管理  │ │   表单验证        │   │ │
│  │  └──────────┘ └──────────┘ └──────────────────┘   │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │ │
│  │  │  Tailwind│ │  Zod     │ │  Lucide Icons    │   │ │
│  │  │  CSS     │ │  验证     │ │   图标库          │   │ │
│  │  └──────────┘ └──────────┘ └──────────────────┘   │ │
│  └─────────────────────┬───────────────────────────────┘ │
└────────────────────────┼─────────────────────────────────┘
                         │ HTTP/JSON
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  Express.js 后端服务器                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────────┐│
│  │ JWT 认证  │ │ 路由处理  │ │   中间件 (CORS/日志)      ││
│  └──────────┘ └──────────┘ └──────────────────────────┘│
│  ┌──────────────────────────────────────────────────────┐│
│  │                   业务逻辑层                          ││
│  │  用户服务 | 文章服务 | 分类服务 | 搜索服务 | 统计服务   ││
│  └──────────────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────────────┐│
│  │                  Prisma ORM                          ││
│  └──────────────────────┬───────────────────────────────┘│
└─────────────────────────┼────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    PostgreSQL 数据库                      │
│                                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌───────┐│
│  │ Users  │ │Articles│ │Category│ │  Tags  │ │Likes  ││
│  └────────┘ └────────┘ └────────┘ └────────┘ └───────┘│
└─────────────────────────────────────────────────────────┘
```

---

## 数据库设计

### 用户表 (User)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| email | String | 邮箱（唯一） |
| password | String | 密码哈希 |
| name | String | 用户名 |
| avatar | String? | 头像 URL |
| bio | String? | 个人简介 |
| createdAt | DateTime | 创建时间 |
| updatedAt | DateTime | 更新时间 |

### 文章表 (Article)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| title | String | 标题 |
| content | Text | Markdown 内容 |
| excerpt | String | 摘要（自动截取） |
| published | Boolean | 是否发布 |
| viewCount | Integer | 浏览次数 |
| authorId | UUID | 外键 - 作者 |
| categoryId | UUID | 外键 - 分类 |
| createdAt | DateTime | 创建时间 |
| updatedAt | DateTime | 更新时间 |

### 分类表 (Category)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | String | 分类名称 |
| slug | String | URL 友好名 |
| description | String? | 描述 |
| parentId | UUID? | 父分类（自关联） |

### 标签表 (Tag)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | String | 标签名 |

### 文章标签关联表 (ArticleTag)
| 字段 | 类型 | 说明 |
|------|------|------|
| articleId | UUID | 文章 ID |
| tagId | UUID | 标签 ID |

### 点赞表 (Like)
| 字段 | 类型 | 说明 |
|------|------|------|
| userId | UUID | 用户 ID |
| articleId | UUID | 文章 ID |
| createdAt | DateTime | 点赞时间 |

### 收藏表 (Bookmark)
| 字段 | 类型 | 说明 |
|------|------|------|
| userId | UUID | 用户 ID |
| articleId | UUID | 文章 ID |
| createdAt | DateTime | 收藏时间 |

---

## API 设计

### 认证 API
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/register | 用户注册 |
| POST | /api/auth/login | 用户登录 |
| GET | /api/auth/me | 获取当前用户 |
| PUT | /api/auth/profile | 更新个人资料 |

### 文章 API
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/articles | 获取文章列表（分页、搜索、筛选） |
| GET | /api/articles/:id | 获取文章详情 |
| POST | /api/articles | 创建文章 |
| PUT | /api/articles/:id | 更新文章 |
| DELETE | /api/articles/:id | 删除文章 |
| POST | /api/articles/:id/like | 点赞/取消点赞 |
| POST | /api/articles/:id/bookmark | 收藏/取消收藏 |

### 分类 API
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/categories | 获取分类列表 |
| POST | /api/categories | 创建分类 |

### 标签 API
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/tags | 获取标签列表 |

### 统计 API
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/stats | 获取仪表板统计数据 |

---

## 组件设计

### 布局组件
- `RootLayout` — 根布局（字体、主题）
- `MainLayout` — 主布局（Navbar + Sidebar + Content）
- `AuthLayout` — 认证页面布局（居中卡片）

### 页面组件
- `LandingPage` — 首页（Hero + 功能介绍 + CTA）
- `LoginPage` — 登录表单
- `RegisterPage` — 注册表单
- `DashboardPage` — 仪表板（统计卡片 + 最近文章）
- `ArticleListPage` — 文章列表（搜索 + 筛选 + 排序）
- `ArticleCreatePage` — 创建文章（Markdown 编辑器）
- `ArticleDetailPage` — 文章详情（渲染 Markdown）
- `ProfilePage` — 个人资料

### 通用组件
- `Navbar` — 导航栏（Logo + 搜索 + 用户菜单）
- `Sidebar` — 侧边栏（分类 + 最近文章）
- `ArticleCard` — 文章卡片
- `ArticleEditor` — Markdown 编辑器（带预览）
- `SearchBar` — 搜索栏（防抖）
- `StatsCard` — 统计卡片
- `TagBadge` — 标签徽章
- `CategoryTree` — 分类树

### Shadcn/ui 组件
Button, Card, Input, Label, Badge, Dialog, Tabs, Textarea, Select, DropdownMenu, Avatar, Separator, Toast, Tooltip, Skeleton

---

## 开发计划

| 日期 | 内容 |
|------|------|
| Day 22 | 项目规划 + 前端搭建 + 基础页面 + Zustand Store |
| Day 23 | 后端搭建 + Prisma Schema + API 实现 |
| Day 24 | 前后端联调 + 高级功能（Markdown、搜索、统计） |
| Day 25 | 测试 + 优化 + 部署 |

---

## 学习要点

- [ ] Next.js 16 App Router 路由和布局
- [ ] Shadcn/ui 组件库集成和使用
- [ ] Zustand 状态管理模式
- [ ] Express + Prisma 后端开发
- [ ] JWT 认证流程
- [ ] TypeScript 全栈类型安全
- [ ] 测试驱动开发
