---
tags:
  - project
  - task-manager
  - features
  - day13
created: 2026-05-30
day: 13
---

# Day 13 — TaskFlow 任务管理应用完善

## 今日完成

### 1. 批量操作功能
- 创建了 `batch-actions.tsx` 组件
- 支持全选 / 取消选择
- 批量删除（带确认对话框）
- 批量状态变更（标记待办/进行中/已完成）
- 显示已选任务数量的 Badge

### 2. 任务详情弹窗
- 创建了 `task-detail-modal.tsx` 组件
- 使用 Shadcn Dialog 组件展示完整任务详情
- 内联状态切换（直接点击切换 todo/in_progress/done）
- 编辑按钮跳转到编辑表单
- 删除操作带 AlertDialog 确认
- 显示创建时间、更新时间、截止日期等元信息

### 3. 键盘快捷键
- 创建了 `keyboard-shortcuts.tsx` 组件
- 快捷键列表：
  - `n` — 新建任务（自动聚焦标题输入框）
  - `Escape` — 关闭弹窗 / 清除选择
  - `1/2/3/4` — 按状态筛选（全部/待办/进行中/已完成）
  - `d` — 删除选中任务
  - `a` — 全选任务
  - `s` — 切换排序方式
- 通过 Tooltip 显示快捷键帮助信息

### 4. 增强的空状态
- 无任务时显示带插图的欢迎界面
- 筛选无结果时显示筛选提示和清除按钮
- 展示应用功能亮点（截止日期、优先级管理、进度追踪）

### 5. Store 增强
- 新增 `selectedIds` 状态及操作（toggleSelect, selectAll, clearSelection）
- 新增 `batchDelete` 和 `batchStatusChange` 批量操作
- 新增 `sortOptions` 排序功能（按创建时间、更新时间、优先级、状态、截止日期）
- 新增 `detailModalTaskId` 控制详情弹窗
- 新增 `setStatus` 直接设置任务状态

### 6. 任务项交互增强
- 添加选择 Checkbox（左侧第一个）
- 点击任务卡片打开详情弹窗
- 选中状态视觉反馈（蓝色边框 + 背景）
- 使用 `stopPropagation` 防止按钮点击触发卡片点击

## 技术决策

### Base UI vs Radix UI
- 项目使用 `@base-ui/react` 而非传统的 Radix UI
- Base UI 不支持 `asChild` prop，改用 `render` prop 模式
- 例如：`<AlertDialogTrigger render={<Button />} />` 替代 `<AlertDialogTrigger asChild><Button /></AlertDialogTrigger>`

### 排序实现
- 在 `getFilteredTasks` selector 中实现排序逻辑
- 优先级使用权重映射（high=3, medium=2, low=1）
- 状态使用权重映射（todo=1, in_progress=2, done=3）
- 支持升序/降序切换

### 选择状态管理
- `selectedIds` 存储在 Zustand store 中
- 全选操作基于当前过滤后的任务列表
- 批量删除后自动清空选择
- 删除单个任务时同步清除其选择状态

### 持久化策略
- 只持久化 `tasks` 和 `sortOptions`
- `selectedIds`、`filter`、`editingTask` 等临时状态不持久化

## 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `store.ts` | 修改 | 新增选择、排序、批量操作状态和方法 |
| `page.tsx` | 修改 | 集成新组件，更新标题为 Day 13 |
| `task-item.tsx` | 修改 | 添加选择 Checkbox 和点击查看详情 |
| `task-list.tsx` | 修改 | 增强空状态，添加排序 UI |
| `batch-actions.tsx` | 新增 | 批量操作组件 |
| `task-detail-modal.tsx` | 新增 | 任务详情弹窗 |
| `keyboard-shortcuts.tsx` | 新增 | 键盘快捷键组件 |
