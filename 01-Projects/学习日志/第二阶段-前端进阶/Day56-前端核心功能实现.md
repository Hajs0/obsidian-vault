---
title: Day 56 - 前端核心功能实现
date: 2026-05-29
tags:
  - 项目实战
  - 前端开发
  - 组件开发
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 56 - 前端核心功能实现

## 📚 学习目标
- 实现核心 UI 组件
- 构建任务管理界面
- 实现状态管理

## 🎯 核心功能实现

### 1. 项目初始化

#### 创建 Next.js 项目
```bash
npx create-next-app@latest taskflow --typescript --tailwind --eslint --app --src-dir
cd taskflow
```

#### 安装依赖
```bash
# UI 组件
npx shadcn@latest init
npx shadcn@latest add button card input label select tabs dialog dropdown-menu avatar badge

# 状态管理
npm install zustand @tanstack/react-query

# 动画
npm install framer-motion

# 表单
npm install react-hook-form zod @hookform/resolvers

# 数据库
npm install prisma @prisma/client

# 认证
npm install next-auth @auth/prisma-adapter
```

### 2. 核心组件实现

#### 任务卡片组件
```typescript
// src/components/tasks/TaskCard.tsx
'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MoreHorizontal, Calendar, User } from 'lucide-react';
import { Task, TaskStatus, Priority } from '@/types/task';

interface TaskCardProps {
  task: Task;
  onStatusChange: (taskId: string, status: TaskStatus) => void;
  onEdit: (task: Task) => void;
  onDelete: (taskId: string) => void;
}

const priorityColors: Record<Priority, string> = {
  LOW: 'bg-gray-100 text-gray-800',
  MEDIUM: 'bg-blue-100 text-blue-800',
  HIGH: 'bg-orange-100 text-orange-800',
  URGENT: 'bg-red-100 text-red-800',
};

const statusLabels: Record<TaskStatus, string> = {
  TODO: '待办',
  IN_PROGRESS: '进行中',
  IN_REVIEW: '审核中',
  DONE: '已完成',
};

export function TaskCard({ task, onStatusChange, onEdit, onDelete }: TaskCardProps) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      whileHover={{ scale: 1.02 }}
      transition={{ duration: 0.2 }}
    >
      <Card className="cursor-pointer hover:shadow-md transition-shadow">
        <CardHeader className="pb-2">
          <div className="flex items-start justify-between">
            <CardTitle className="text-sm font-medium">{task.title}</CardTitle>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {task.description && (
            <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
              {task.description}
            </p>
          )}
          <div className="flex items-center gap-2 flex-wrap">
            <Badge variant="secondary" className={priorityColors[task.priority]}>
              {task.priority}
            </Badge>
            {task.dueDate && (
              <div className="flex items-center text-xs text-muted-foreground">
                <Calendar className="h-3 w-3 mr-1" />
                {new Date(task.dueDate).toLocaleDateString()}
              </div>
            )}
            {task.assignee && (
              <div className="flex items-center text-xs text-muted-foreground">
                <User className="h-3 w-3 mr-1" />
                {task.assignee.name}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
```

#### 看板视图组件
```typescript
// src/components/tasks/KanbanBoard.tsx
'use client';

import { useState } from 'react';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { TaskCard } from './TaskCard';
import { Task, TaskStatus } from '@/types/task';

interface KanbanBoardProps {
  tasks: Task[];
  onTaskMove: (taskId: string, newStatus: TaskStatus) => void;
  onTaskEdit: (task: Task) => void;
  onTaskDelete: (taskId: string) => void;
}

const columns: { id: TaskStatus; title: string }[] = [
  { id: 'TODO', title: '待办' },
  { id: 'IN_PROGRESS', title: '进行中' },
  { id: 'IN_REVIEW', title: '审核中' },
  { id: 'DONE', title: '已完成' },
];

export function KanbanBoard({ tasks, onTaskMove, onTaskEdit, onTaskDelete }: KanbanBoardProps) {
  const handleDragEnd = (result: any) => {
    if (!result.destination) return;
    
    const taskId = result.draggableId;
    const newStatus = result.destination.droppableId as TaskStatus;
    
    onTaskMove(taskId, newStatus);
  };

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {columns.map((column) => (
          <div key={column.id} className="bg-gray-50 rounded-lg p-4">
            <h3 className="font-semibold mb-4 flex items-center justify-between">
              {column.title}
              <span className="text-sm text-muted-foreground">
                {tasks.filter((t) => t.status === column.id).length}
              </span>
            </h3>
            <Droppable droppableId={column.id}>
              {(provided) => (
                <div
                  ref={provided.innerRef}
                  {...provided.droppableProps}
                  className="space-y-3 min-h-[200px]"
                >
                  {tasks
                    .filter((task) => task.status === column.id)
                    .map((task, index) => (
                      <Draggable key={task.id} draggableId={task.id} index={index}>
                        {(provided) => (
                          <div
                            ref={provided.innerRef}
                            {...provided.draggableProps}
                            {...provided.dragHandleProps}
                          >
                            <TaskCard
                              task={task}
                              onStatusChange={onTaskMove}
                              onEdit={onTaskEdit}
                              onDelete={onTaskDelete}
                            />
                          </div>
                        )}
                      </Draggable>
                    ))}
                  {provided.placeholder}
                </div>
              )}
            </Droppable>
          </div>
        ))}
      </div>
    </DragDropContext>
  );
}
```

### 3. 状态管理

#### 任务状态管理
```typescript
// src/stores/taskStore.ts
import { create } from 'zustand';
import { Task, TaskStatus, CreateTaskInput } from '@/types/task';

interface TaskState {
  tasks: Task[];
  isLoading: boolean;
  error: string | null;
  
  // 操作
  fetchTasks: () => Promise<void>;
  createTask: (input: CreateTaskInput) => Promise<void>;
  updateTask: (id: string, input: Partial<Task>) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  moveTask: (id: string, status: TaskStatus) => Promise<void>;
}

export const useTaskStore = create<TaskState>((set, get) => ({
  tasks: [],
  isLoading: false,
  error: null,
  
  fetchTasks: async () => {
    set({ isLoading: true, error: null });
    try {
      const response = await fetch('/api/tasks');
      const data = await response.json();
      set({ tasks: data, isLoading: false });
    } catch (error) {
      set({ error: '获取任务失败', isLoading: false });
    }
  },
  
  createTask: async (input) => {
    set({ isLoading: true, error: null });
    try {
      const response = await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(input),
      });
      const newTask = await response.json();
      set((state) => ({
        tasks: [...state.tasks, newTask],
        isLoading: false,
      }));
    } catch (error) {
      set({ error: '创建任务失败', isLoading: false });
    }
  },
  
  updateTask: async (id, input) => {
    set({ isLoading: true, error: null });
    try {
      const response = await fetch(`/api/tasks/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(input),
      });
      const updatedTask = await response.json();
      set((state) => ({
        tasks: state.tasks.map((t) => (t.id === id ? updatedTask : t)),
        isLoading: false,
      }));
    } catch (error) {
      set({ error: '更新任务失败', isLoading: false });
    }
  },
  
  deleteTask: async (id) => {
    set({ isLoading: true, error: null });
    try {
      await fetch(`/api/tasks/${id}`, { method: 'DELETE' });
      set((state) => ({
        tasks: state.tasks.filter((t) => t.id !== id),
        isLoading: false,
      }));
    } catch (error) {
      set({ error: '删除任务失败', isLoading: false });
    }
  },
  
  moveTask: async (id, status) => {
    set({ isLoading: true, error: null });
    try {
      const response = await fetch(`/api/tasks/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      const updatedTask = await response.json();
      set((state) => ({
        tasks: state.tasks.map((t) => (t.id === id ? updatedTask : t)),
        isLoading: false,
      }));
    } catch (error) {
      set({ error: '移动任务失败', isLoading: false });
    }
  },
}));
```

### 4. 页面实现

#### 任务页面
```typescript
// src/app/(dashboard)/tasks/page.tsx
'use client';

import { useEffect } from 'react';
import { useTaskStore } from '@/stores/taskStore';
import { KanbanBoard } from '@/components/tasks/KanbanBoard';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { useState } from 'react';
import { CreateTaskDialog } from '@/components/tasks/CreateTaskDialog';

export default function TasksPage() {
  const { tasks, isLoading, fetchTasks, moveTask, deleteTask } = useTaskStore();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);

  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  const handleTaskMove = async (taskId: string, newStatus: string) => {
    await moveTask(taskId, newStatus as any);
  };

  const handleTaskEdit = (task: any) => {
    // 编辑任务
  };

  const handleTaskDelete = async (taskId: string) => {
    if (confirm('确定要删除这个任务吗？')) {
      await deleteTask(taskId);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">任务管理</h1>
          <p className="text-muted-foreground">管理和跟踪你的任务</p>
        </div>
        <Button onClick={() => setIsCreateDialogOpen(true)}>
          <Plus className="h-4 w-4 mr-2" />
          创建任务
        </Button>
      </div>

      {isLoading ? (
        <div className="text-center py-10">加载中...</div>
      ) : (
        <KanbanBoard
          tasks={tasks}
          onTaskMove={handleTaskMove}
          onTaskEdit={handleTaskEdit}
          onTaskDelete={handleTaskDelete}
        />
      )}

      <CreateTaskDialog
        open={isCreateDialogOpen}
        onOpenChange={setIsCreateDialogOpen}
      />
    </div>
  );
}
```

## 📝 最佳实践

### 1. 组件设计
```typescript
// 好：单一职责
<TaskCard task={task} />
<KanbanBoard tasks={tasks} />

// 不好：过度耦合
<TaskManager tasks={tasks} onMove={...} onEdit={...} onDelete={...} />
```

### 2. 状态管理
```typescript
// 好：使用 Zustand
const { tasks, fetchTasks } = useTaskStore();

// 不好：prop drilling
<TaskList tasks={tasks} onMove={onMove} onEdit={onEdit} onDelete={onDelete} />
```

### 3. 类型安全
```typescript
// 好：使用 TypeScript
interface Task {
  id: string;
  title: string;
  status: TaskStatus;
}

// 不好：使用 any
const task: any = { ... };
```

## 🎓 今日总结

**关键知识点：**
1. 项目初始化和依赖安装
2. 核心组件实现（任务卡片、看板）
3. 状态管理（Zustand）
4. 页面实现（任务页面）

**明日计划：**
- Day 57: 后端 API 开发
