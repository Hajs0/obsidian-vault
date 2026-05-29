---
tags:
  - summary
  - week2
  - task-manager
  - deployment
  - day14
created: 2026-05-30
day: 14
---

# 📋 第二周学习总结 (Day 10 – Day 14)

## 一、本周概览

第二周聚焦于**高级特性**和**实际项目构建**，从状态管理到完整应用开发，再到测试与部署准备。

### Days 10-14 每日回顾

| Day | 主题 | 核心内容 |
|-----|------|----------|
| Day 10 | Server Actions + 数据获取 | Server Actions 与表单交互、`use()` Hook、Revalidate 缓存策略 |
| Day 11 | Zustand 状态管理 | Zustand 基础、中间件（devtools / persist / immer）、状态设计模式 |
| Day 12 | TaskFlow 规划 + 基础搭建 | 需求分析、数据模型设计、核心组件开发、Shadcn/ui 组件集成 |
| Day 13 | TaskFlow 功能完善 | 批量操作、键盘快捷键、任务详情弹窗、过滤排序、统计面板 |
| Day 14 | 部署准备 + 测试 | Docker 多阶段构建、Vitest 单元测试、部署文档编写 |

---

## 二、技术栈总结

| 技术 | 版本 | 用途 |
|------|------|------|
| **Next.js** | 16 | 全栈框架、SSR/SSG、App Router |
| **Shadcn/ui** | 4.8 | 无头UI组件库（Dialog、Input、Badge等） |
| **Zustand** | 5.0 | 轻量级状态管理（含 immer/persist/devtools 中间件） |
| **TypeScript** | 5.x | 类型安全、接口定义 |
| **Tailwind CSS** | 4.x | 原子化CSS、响应式设计 |
| **Vitest** | 最新 | 单元测试框架 |
| **Docker** | - | 容器化部署 |

---

## 三、TaskFlow 功能清单

### ✅ 核心功能
- [x] 任务 CRUD（创建、读取、更新、删除）
- [x] 任务状态流转：待办 → 进行中 → 已完成
- [x] 优先级设置：高 / 中 / 低
- [x] 标签系统（多标签支持）
- [x] 截止日期管理

### ✅ 高级功能
- [x] 全文搜索（标题 + 描述模糊匹配）
- [x] 多维度过滤（状态、优先级、标签）
- [x] 多字段排序（创建时间、优先级、状态、截止日期）
- [x] 批量选择 + 批量删除/状态变更
- [x] 键盘快捷键（`N` 新建、`/` 搜索、`Esc` 关闭）
- [x] 任务详情弹窗
- [x] 统计面板（总数、完成率、逾期数、优先级分布）

### ✅ 工程化
- [x] Zustand + immer 不可变状态管理
- [x] LocalStorage 持久化
- [x] DevTools 调试支持
- [x] 组件化架构（store / form / list / item / filter / stats / batch-actions）
- [x] TypeScript 类型全覆盖
- [x] Vitest 单元测试覆盖核心 store 逻辑
- [x] Docker 多阶段构建部署

---

## 四、遇到的问题和解决方案

### 问题 1: Zustand immer 中间件与 persist 冲突
**现象**: 中间件嵌套顺序错误导致 immer 的 draft 代理失效。
**解决**: 严格按 `devtools → persist → subscribeWithSelector → immer` 顺序嵌套，注意 immer 必须在最内层。

### 问题 2: Zustand store 在测试环境中无法使用
**现象**: 测试中 `"use client"` 指令和 `localStorage` 不可用导致报错。
**解决**: 通过 vitest setup 文件 polyfill `localStorage` 和 `crypto.randomUUID`，消除浏览器依赖。

### 问题 3: Server Actions 缓存策略不生效
**现象**: 调用 `revalidatePath` 后页面数据未更新。
**解决**: 确保 Server Action 是在 `"use server"` 指令的文件中定义，并正确导入 `revalidatePath`。

### 问题 4: Shadcn/ui 组件样式冲突
**现象**: 自定义 Tailwind 类与组件默认样式冲突。
**解决**: 使用 `cn()` 工具函数（clsx + tailwind-merge）合并类名，避免特异性冲突。

---

## 五、关键学习收获

1. **Zustand 中间件栈设计**: 理解了中间件的执行顺序和各自的职责——devtools 调试、persist 持久化、subscribeWithSelector 精准订阅、immer 不可变更新。

2. **Next.js Server Actions**: 掌握了表单与 Server Actions 的交互模式，理解了缓存失效机制。

3. **组件架构设计**: 学会将复杂功能拆分为职责单一的组件，通过 Zustand store 作为数据中枢实现解耦。

4. **TypeScript 类型驱动开发**: 先定义接口再实现逻辑，类型系统帮助在编译期捕获错误。

5. **部署工程化**: Docker 多阶段构建分离依赖安装、构建和运行，显著减小镜像体积。

---

## 六、下周计划 (Days 15-21)

> 主题：**后端 + 数据库 + API**

| Day | 计划内容 |
|-----|----------|
| Day 15 | 数据库基础：PostgreSQL 安装配置、SQL 基础操作 |
| Day 16 | Prisma ORM：Schema 设计、Migration、CRUD 操作 |
| Day 17 | API Routes：RESTful API 设计、路由处理器 |
| Day 18 | 数据验证：Zod Schema、API 中间件、错误处理 |
| Day 19 | 认证系统：NextAuth.js / JWT 基础 |
| Day 20 | TaskFlow 后端集成：数据库替换 localStorage、API 接入 |
| Day 21 | 第三周总结 + 后端最佳实践 |

**目标**: 将 TaskFlow 从纯前端应用升级为全栈应用，实现数据持久化到真实数据库。
