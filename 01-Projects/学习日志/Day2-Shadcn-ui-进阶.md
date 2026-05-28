---
tags: [shadcn, ui, components, day2, learning, dialog, dropdown, toast]
created: 2026-05-27
day: 2
---

# 📚 Day 2：Shadcn/ui 进阶学习

## 🎯 今日目标
- 学习更多组件（Dialog, Dropdown Menu, Toast, Avatar, Separator）
- 学习组件组合使用
- 实践：构建导航栏和综合示例页面

---

## 🧩 新学习的组件

### 1. Dialog 对话框

**核心概念**:
- 模态对话框组件
- 基于 Radix UI Dialog
- 支持键盘导航（ESC 关闭）
- 支持无障碍访问

**子组件**:
- `Dialog` - 对话框容器
- `DialogTrigger` - 触发按钮
- `DialogContent` - 对话框内容
- `DialogHeader` - 对话框头部
- `DialogTitle` - 对话框标题
- `DialogDescription` - 对话框描述
- `DialogFooter` - 对话框底部

**代码示例**:
```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

export function DialogDemo() {
  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="outline">打开对话框</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>标题</DialogTitle>
          <DialogDescription>描述</DialogDescription>
        </DialogHeader>
        <div className="py-4">
          {/* 内容 */}
        </div>
        <DialogFooter>
          <Button type="submit">保存</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

**学习心得**:
- 使用 `asChild` 避免额外 DOM 元素
- 支持受控和非受控模式
- 自动处理焦点锁定

---

### 2. Dropdown Menu 下拉菜单

**核心概念**:
- 下拉菜单组件
- 基于 Radix UI DropdownMenu
- 支持键盘导航
- 支持嵌套菜单

**子组件**:
- `DropdownMenu` - 菜单容器
- `DropdownMenuTrigger` - 触发元素
- `DropdownMenuContent` - 菜单内容
- `DropdownMenuItem` - 菜单项
- `DropdownMenuLabel` - 菜单标签
- `DropdownMenuSeparator` - 分隔符

**代码示例**:
```tsx
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"

export function DropdownMenuDemo() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline">打开菜单</Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56">
        <DropdownMenuLabel>我的账户</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem>个人资料</DropdownMenuItem>
        <DropdownMenuItem>设置</DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem>退出登录</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

**学习心得**:
- 使用 `align` 和 `sideOffset` 控制位置
- 支持 `forceMount` 强制渲染
- 支持 `onSelect` 事件处理

---

### 3. Toast 通知（Sonner）

**核心概念**:
- Toast 通知组件
- 使用 Sonner 库（替代旧版 Toast）
- 支持多种类型（success, error, info, warning）
- 支持自定义位置

**使用方式**:
```tsx
// 1. 添加 Toaster 到布局
import { Toaster } from "@/components/ui/sonner"

export default function Layout({ children }) {
  return (
    <>
      {children}
      <Toaster position="top-right" />
    </>
  )
}

// 2. 使用 toast 函数
import { toast } from "sonner"

// 成功通知
toast.success("操作成功！")

// 错误通知
toast.error("操作失败！")

// 信息通知
toast.info("这是一条信息")

// 自定义通知
toast("自定义通知", {
  description: "这是描述",
  action: {
    label: "撤销",
    onClick: () => console.log("撤销"),
  },
})
```

**学习心得**:
- Sonner 是新版 Toast 的替代品
- 支持 Promise 通知
- 支持自定义样式

---

### 4. Avatar 头像

**核心概念**:
- 用户头像组件
- 支持图片和回退文字
- 支持圆形和圆角

**子组件**:
- `Avatar` - 头像容器
- `AvatarImage` - 头像图片
- `AvatarFallback` - 回退内容

**代码示例**:
```tsx
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

export function AvatarDemo() {
  return (
    <Avatar>
      <AvatarImage src="https://github.com/shadcn.png" alt="@shadcn" />
      <AvatarFallback>CN</AvatarFallback>
    </Avatar>
  )
}
```

**学习心得**:
- 支持 `onLoadingStatusChange` 监听加载状态
- 回退内容支持文字或图标
- 可自定义尺寸和样式

---

### 5. Separator 分隔符

**核心概念**:
- 分隔符组件
- 支持水平和垂直方向
- 用于分组内容

**代码示例**:
```tsx
import { Separator } from "@/components/ui/separator"

export function SeparatorDemo() {
  return (
    <div>
      <div>内容 1</div>
      <Separator className="my-4" />
      <div>内容 2</div>
    </div>
  )
}

// 垂直分隔符
<div className="flex items-center">
  <span>项目 1</span>
  <Separator orientation="vertical" className="h-8 mx-2" />
  <span>项目 2</span>
</div>
```

**学习心得**:
- 使用 `orientation` 控制方向
- 支持自定义样式
- 语义化 `role="separator"`

---

## 🎨 实践项目：导航栏

### 项目结构
```
src/components/
├── navbar.tsx          # 导航栏
├── dialog-demo.tsx     # 对话框示例
└── ui/                 # UI 组件
```

### 核心功能
1. ✅ **Logo 和品牌**
2. ✅ **导航链接**
3. ✅ **通知按钮**
4. ✅ **用户菜单**（Dropdown Menu + Avatar）
5. ✅ **Toast 通知**

### 关键代码

**导航栏结构**:
```tsx
<nav className="border-b bg-white dark:bg-slate-950">
  <div className="max-w-7xl mx-auto px-4">
    <div className="flex items-center justify-between h-16">
      {/* Logo */}
      <Link href="/" className="text-xl font-bold">MyApp</Link>
      
      {/* Navigation Links */}
      <div className="hidden md:block">
        <div className="flex items-baseline space-x-4">
          <Link href="/">首页</Link>
          <Link href="/about">关于</Link>
        </div>
      </div>
      
      {/* Right Section */}
      <div className="flex items-center space-x-4">
        <Button onClick={() => toast.success("通知")}>🔔</Button>
        <Separator orientation="vertical" className="h-8" />
        <DropdownMenu>
          {/* 用户菜单 */}
        </DropdownMenu>
      </div>
    </div>
  </div>
</nav>
```

---

## 📊 学习成果

### 已掌握组件（共 9 个）
1. ✅ Button - 按钮
2. ✅ Card - 卡片
3. ✅ Input - 输入框
4. ✅ Label - 标签
5. ✅ Dialog - 对话框
6. ✅ Dropdown Menu - 下拉菜单
7. ✅ Toast (Sonner) - 通知
8. ✅ Avatar - 头像
9. ✅ Separator - 分隔符

### 代码统计
- 组件数量：9 个
- 代码行数：~500 行
- 学习时间：4 小时

---

## 💡 学习心得

### 1. 组件组合模式
```tsx
// 好的实践：组合使用
<Dialog>
  <DialogTrigger asChild>
    <Button>打开</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>标题</DialogTitle>
    </DialogHeader>
  </DialogContent>
</Dialog>
```

### 2. 状态管理
```tsx
// 受控模式
const [open, setOpen] = useState(false)
<Dialog open={open} onOpenChange={setOpen}>
```

### 3. 事件处理
```tsx
// 点击事件
<Button onClick={() => toast.success("点击")}>按钮</Button>

// 表单提交
<form onSubmit={(e) => {
  e.preventDefault()
  toast.success("提交成功")
}}>
```

### 4. 样式定制
```tsx
// 使用 cn 合并类名
<Button className={cn("w-full", className)}>按钮</Button>

// 使用 Tailwind 工具类
<div className="flex items-center justify-between">
```

---

## 🎯 明日计划

### Day 3 任务
- [ ] 学习组件定制方法
- [ ] 学习主题配置
- [ ] 实践：构建数据表格
- [ ] 记录学习笔记

### 学习目标
- 掌握组件定制
- 理解主题系统
- 完成数据表格项目

---

## 🎉 总结

今天是学习 Shadcn/ui 的第二天，我：

1. ✅ **学习了 5 个新组件**
   - Dialog - 对话框
   - Dropdown Menu - 下拉菜单
   - Toast (Sonner) - 通知
   - Avatar - 头像
   - Separator - 分隔符

2. ✅ **掌握了组件组合**
   - 对话框 + 表单
   - 下拉菜单 + 头像
   - 通知 + 按钮

3. ✅ **完成了实践项目**
   - 导航栏组件
   - 综合示例页面

4. ✅ **记录了学习笔记**
   - 组件使用方法
   - 学习心得
   - 最佳实践

**累计学习**: 9 个组件，2 天

**继续学习，持续成长！** 🚀

---

*"Learning is not attained by chance, it must be sought for with ardor and attended to with diligence." - Abigail Adams*
