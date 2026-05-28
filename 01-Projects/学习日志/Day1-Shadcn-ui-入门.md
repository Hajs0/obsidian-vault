---
tags: [shadcn, ui, components, day1, learning]
created: 2026-05-27
day: 1
---

# 📚 Day 1：Shadcn/ui 入门学习

## 🎯 今日目标
- 掌握 Shadcn/ui 核心概念
- 学习基础组件使用
- 实践：构建登录页面

---

## 🔥 Shadcn/ui 核心概念

### 1. 什么是 Shadcn/ui？
- **不是 npm 包**，而是可复制粘贴的组件
- 基于 **Radix UI**（无样式原语）+ **Tailwind CSS**（样式）
- 完全可定制，代码在你的项目中
- 优秀的无障碍访问支持

### 2. 为什么选择 Shadcn/ui？
- ✅ 完全控制代码
- ✅ 无依赖冲突
- ✅ 高度可定制
- ✅ TypeScript 支持
- ✅ 社区活跃

### 3. 核心架构
```
Radix UI（交互逻辑）
    ↓
Shadcn/ui（组件模板）
    ↓
Tailwind CSS（样式定制）
```

---

## 🧩 已学习的组件

### 1. Button 按钮

**变体（Variants）**:
- `default` - 默认按钮
- `destructive` - 危险操作
- `outline` - 轮廓按钮
- `secondary` - 次要按钮
- `ghost` - 幽灵按钮
- `link` - 链接按钮

**尺寸（Sizes）**:
- `default` - 默认尺寸
- `sm` - 小尺寸
- `lg` - 大尺寸

**代码示例**:
```tsx
import { Button } from "@/components/ui/button"

// 基础用法
<Button>点击我</Button>

// 带变体
<Button variant="outline">轮廓按钮</Button>

// 带尺寸
<Button size="lg">大按钮</Button>

// 组合使用
<Button variant="destructive" size="sm">删除</Button>
```

**学习心得**:
- 使用 `cva`（class-variance-authority）管理变体
- 通过 `cn` 工具函数合并类名
- 支持 `asChild` 属性自定义渲染元素

---

### 2. Card 卡片

**子组件**:
- `Card` - 卡片容器
- `CardHeader` - 卡片头部
- `CardTitle` - 卡片标题
- `CardDescription` - 卡片描述
- `CardContent` - 卡片内容
- `CardFooter` - 卡片底部

**代码示例**:
```tsx
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Button } from "@/components/ui/button"

export function CardDemo() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>卡片标题</CardTitle>
        <CardDescription>卡片描述</CardDescription>
      </CardHeader>
      <CardContent>
        <p>卡片内容</p>
      </CardContent>
      <CardFooter>
        <Button>操作</Button>
      </CardFooter>
    </Card>
  )
}
```

**学习心得**:
- 组件化设计，灵活组合
- 使用 `forwardRef` 支持 ref 转发
- 通过 `cn` 合并自定义样式

---

### 3. Input 输入框

**属性**:
- `type` - 输入类型（text, email, password 等）
- `placeholder` - 占位符
- `disabled` - 禁用状态
- `required` - 必填

**代码示例**:
```tsx
import { Input } from "@/components/ui/input"

// 基础用法
<Input placeholder="请输入..." />

// 带类型
<Input type="email" placeholder="邮箱" />
<Input type="password" placeholder="密码" />

// 带标签
<div className="space-y-2">
  <Label htmlFor="email">邮箱</Label>
  <Input id="email" type="email" placeholder="name@example.com" />
</div>
```

**学习心得**:
- 统一的样式规范
- 支持所有原生 input 属性
- 通过 `className` 自定义样式

---

### 4. Label 标签

**用途**:
- 为表单元素提供标签
- 提高可访问性
- 支持点击聚焦

**代码示例**:
```tsx
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"

// 基础用法
<Label htmlFor="name">姓名</Label>
<Input id="name" placeholder="请输入姓名" />

// 带必填标记
<Label htmlFor="email">
  邮箱 <span className="text-red-500">*</span>
</Label>
<Input id="email" type="email" required />
```

**学习心得**:
- 使用 `htmlFor` 关联输入框
- 提高表单可访问性
- 支持自定义样式

---

## 🎨 实践项目：登录页面

### 项目结构
```
shadcn-learning/
├── src/
│   ├── app/
│   │   ├── login/
│   │   │   └── page.tsx      # 登录页面
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   └── ui/
│   │       ├── button.tsx
│   │       ├── card.tsx
│   │       ├── input.tsx
│   │       └── label.tsx
│   └── lib/
│       └── utils.ts
└── components.json
```

### 核心代码

**登录页面特点**:
1. ✅ 使用 Card 组件构建表单容器
2. ✅ 使用 Input + Label 构建表单字段
3. ✅ 使用 Button 构建操作按钮
4. ✅ 支持 GitHub OAuth 登录
5. ✅ 响应式设计
6. ✅ 暗色模式支持

**关键代码片段**:
```tsx
// 表单字段
<div className="space-y-2">
  <Label htmlFor="email">邮箱</Label>
  <Input
    id="email"
    type="email"
    placeholder="name@example.com"
    required
  />
</div>

// 主按钮
<Button className="w-full" size="lg">
  登录
</Button>

// OAuth 按钮
<Button variant="outline" className="w-full" size="lg">
  <svg>...</svg>
  使用 GitHub 登录
</Button>
```

---

## 💡 学习心得

### 1. 组件设计理念
- **组合优于继承** - 通过组合子组件构建复杂 UI
- **关注点分离** - 逻辑、样式、结构分离
- **可复用性** - 组件可在不同场景复用

### 2. Tailwind CSS 技巧
- 使用 `space-y-*` 控制垂直间距
- 使用 `flex` + `items-center` + `justify-center` 居中
- 使用 `dark:` 前缀支持暗色模式
- 使用 `bg-gradient-to-*` 创建渐变背景

### 3. TypeScript 优势
- 类型安全，减少运行时错误
- 自动补全，提高开发效率
- 代码可读性更强

### 4. 无障碍访问
- 使用 `htmlFor` 关联标签和输入框
- 使用 `aria-*` 属性增强可访问性
- 使用语义化 HTML 标签

---

## 📊 今日成果

### 已完成
- ✅ 搭建 Shadcn/ui 项目
- ✅ 学习 4 个基础组件
- ✅ 实践：构建登录页面
- ✅ 记录学习笔记

### 代码统计
- 组件数量：4 个
- 代码行数：~150 行
- 学习时间：4 小时

---

## 🎯 明日计划

### Day 2 任务
- [ ] 学习更多组件（Dialog, Dropdown Menu, Toast）
- [ ] 学习组件定制方法
- [ ] 实践：构建导航栏
- [ ] 记录学习笔记

### 学习目标
- 掌握 5+ 个组件
- 理解组件定制
- 完成导航栏项目

---

## 📚 参考资源

### 官方文档
- [Shadcn/ui](https://ui.shadcn.com/)
- [Radix UI](https://www.radix-ui.com/)
- [Tailwind CSS](https://tailwindcss.com/)

### 学习资源
- [Shadcn/ui Examples](https://ui.shadcn.com/examples)
- [Tailwind CSS Tutorial](https://tailwindcss.com/docs)

---

## 🎉 总结

今天是学习 Shadcn/ui 的第一天，我：

1. ✅ **理解了核心概念**
   - 不是 npm 包，而是可复制粘贴的组件
   - 基于 Radix UI + Tailwind CSS
   - 完全可定制

2. ✅ **掌握了 4 个基础组件**
   - Button - 按钮
   - Card - 卡片
   - Input - 输入框
   - Label - 标签

3. ✅ **完成了实践项目**
   - 登录页面
   - 响应式设计
   - 暗色模式支持

4. ✅ **记录了学习笔记**
   - 组件使用方法
   - 学习心得
   - 最佳实践

**继续学习，持续成长！** 🚀

---

*"The more I learn, the more I realize how much I don't know." - Albert Einstein*
