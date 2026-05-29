---
tags:
  - project
  - task-manager
  - planning
  - day12
created: 2026-05-30
day: 12
---

# Day 12 — TaskFlow（任务流）项目规划

## 项目名称

**TaskFlow（任务流）** — 一个全功能任务管理应用

## 功能需求

- **任务 CRUD**（创建/读取/更新/删除）
- **任务状态**：待办 / 进行中 / 已完成
- **优先级**：高 / 中 / 低
- **分类标签**：支持多标签
- **截止日期**：带过期提醒
- **搜索和过滤**：按状态、优先级、关键词筛选
- **拖拽排序**（可选，后续迭代）

## 技术栈

| 技术 | 用途 |
|------|------|
| Next.js 16 | 框架（App Router, Server Components） |
| Shadcn/ui | UI 组件库（Card, Badge, Button, Input, Select 等） |
| Zustand | 客户端状态管理（immer, devtools, persist 中间件） |
| TypeScript | 类型安全 |
| Tailwind CSS v4 | 样式 |
| Zod | 表单验证 |

## 页面结构

```
/task-manager          — 主页面（任务列表 + 侧边栏过滤 + 统计）
/task-manager/[id]     — 任务详情（可选，后续迭代）
```

## 组件拆分

```
src/app/task-manager/
├── page.tsx          — 主页面（Server Component 包装）
├── store.ts          — Zustand 状态管理
├── task-form.tsx     — 任务表单（创建/编辑）
├── task-item.tsx     — 单个任务卡片
├── task-filter.tsx   — 侧边栏过滤面板
├── task-stats.tsx    — 统计仪表盘
└── task-list.tsx     — 任务列表容器
```

## 状态管理设计（Zustand Store）

### 数据模型

```typescript
interface Task {
  id: string;
  title: string;
  description: string;
  status: 'todo' | 'in_progress' | 'done';
  priority: 'high' | 'medium' | 'low';
  tags: string[];
  dueDate: string | null;
  createdAt: string;
  updatedAt: string;
}

interface TaskFilter {
  status: 'all' | 'todo' | 'in_progress' | 'done';
  priority: 'all' | 'high' | 'medium' | 'low';
  search: string;
  tags: string[];
}
```

### Store Actions

| Action | 说明 |
|--------|------|
| `addTask(task)` | 添加新任务 |
| `updateTask(id, updates)` | 更新任务 |
| `deleteTask(id)` | 删除任务 |
| `toggleStatus(id)` | 切换任务状态 |
| `setFilter(filter)` | 设置过滤条件 |
| `clearFilters()` | 清除所有过滤 |

### 中间件栈

```
devtools → persist (localStorage) → subscribeWithSelector → immer
```

### 计算属性（Derived State）

- `filteredTasks` — 根据当前过滤条件返回任务列表
- `taskStats` — 各状态/优先级的任务计数、完成率、逾期数

## 学习目标

- [x] 综合运用 Shadcn/ui 组件
- [x] Zustand 完整 store 设计（slices + middleware）
- [x] Server Component / Client Component 分离
- [x] 表单处理（useActionState + Zod 验证）
- [x] 响应式布局
- [ ] Server Actions（后续迭代）
- [ ] 数据持久化（后续迭代）

## Day 12 进度

✅ 项目规划
✅ Zustand Store 创建
✅ TaskForm 组件
✅ TaskItem 组件
✅ TaskFilter 组件
✅ TaskStats 组件
✅ 主页面集成
