---
tags: [shadcn, ui, customization, theme, day3, learning]
created: 2026-05-27
day: 3
---

# 📚 Day 3：组件定制与主题配置

## 🎯 今日目标
- 学习组件定制方法
- 理解主题系统
- 实践：自定义主题和组件变体

---

## 🎨 组件定制方法

### 1. 使用 className 定制

**基础用法**:
```tsx
import { Button } from "@/components/ui/button"

// 直接添加类名
<Button className="bg-blue-500 hover:bg-blue-600">
  蓝色按钮
</Button>

// 使用 Tailwind 工具类
<Button className="w-full text-lg py-6">
  大按钮
</Button>
```

**组合类名**:
```tsx
import { cn } from "@/lib/utils"

<Button className={cn(
  "w-full",
  "bg-gradient-to-r from-blue-500 to-purple-500",
  "hover:from-blue-600 hover:to-purple-600",
  className  // 允许外部传入类名
)}>
  渐变按钮
</Button>
```

---

### 2. 使用 cva 定义变体

**cva 是什么**:
- `class-variance-authority` 的缩写
- 用于管理组件变体
- 类型安全的类名管理

**基础用法**:
```tsx
import { cva, type VariantProps } from "class-variance-authority"

const buttonVariants = cva(
  // 基础样式
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "underline-offset-4 hover:underline text-primary",
      },
      size: {
        default: "h-10 py-2 px-4",
        sm: "h-9 px-3 rounded-md",
        lg: "h-11 px-8 rounded-md",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

// 使用
interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
```

**学习心得**:
- `cva` 管理变体，`cn` 合并类名
- 支持默认变体
- 类型安全，自动补全

---

### 3. 创建自定义组件

**示例：渐变按钮**:
```tsx
"use client"

import { forwardRef } from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const gradientButtonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none",
  {
    variants: {
      variant: {
        blue: "bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:from-blue-600 hover:to-blue-700 shadow-lg shadow-blue-500/25",
        purple: "bg-gradient-to-r from-purple-500 to-purple-600 text-white hover:from-purple-600 hover:to-purple-700 shadow-lg shadow-purple-500/25",
        pink: "bg-gradient-to-r from-pink-500 to-pink-600 text-white hover:from-pink-600 hover:to-pink-700 shadow-lg shadow-pink-500/25",
        rainbow: "bg-gradient-to-r from-red-500 via-yellow-500 via-green-500 via-blue-500 to-purple-500 text-white hover:opacity-90 shadow-lg",
      },
      size: {
        default: "h-10 py-2 px-4",
        sm: "h-9 px-3 rounded-md",
        lg: "h-11 px-8 rounded-md",
        xl: "h-12 px-10 rounded-lg text-base",
      },
    },
    defaultVariants: {
      variant: "blue",
      size: "default",
    },
  }
)

interface GradientButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof gradientButtonVariants> {}

const GradientButton = forwardRef<HTMLButtonElement, GradientButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(gradientButtonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
GradientButton.displayName = "GradientButton"

export { GradientButton, gradientButtonVariants }
```

---

## 🌙 主题系统

### 1. CSS 变量配置

**globals.css 主题变量**:
```css
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;

    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;

    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;

    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;

    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;

    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;

    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;

    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;

    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;

    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;

    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;

    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;

    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;

    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;

    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;

    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;

    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;

    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
```

---

### 2. 自定义主题

**创建自定义主题**:
```css
/* 蓝色主题 */
[data-theme="blue"] {
  --primary: 221.2 83.2% 53.3%;
  --primary-foreground: 210 40% 98%;
  
  --accent: 221.2 83.2% 53.3%;
  --accent-foreground: 210 40% 98%;
}

/* 绿色主题 */
[data-theme="green"] {
  --primary: 142.1 76.2% 36.3%;
  --primary-foreground: 355.7 100% 97.3%;
  
  --accent: 142.1 76.2% 36.3%;
  --accent-foreground: 355.7 100% 97.3%;
}

/* 紫色主题 */
[data-theme="purple"] {
  --primary: 262.1 83.3% 57.8%;
  --primary-foreground: 210 20% 98%;
  
  --accent: 262.1 83.3% 57.8%;
  --accent-foreground: 210 20% 98%;
}
```

**使用主题**:
```tsx
// 设置主题
document.documentElement.setAttribute("data-theme", "blue")

// 切换主题
const toggleTheme = (theme: string) => {
  document.documentElement.setAttribute("data-theme", theme)
  localStorage.setItem("theme", theme)
}
```

---

### 3. 暗色模式切换

**主题切换组件**:
```tsx
"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

export function ThemeToggle() {
  const [theme, setTheme] = useState<"light" | "dark" | "system">("system")

  useEffect(() => {
    const savedTheme = localStorage.getItem("theme") as "light" | "dark" | "system" || "system"
    setTheme(savedTheme)
    applyTheme(savedTheme)
  }, [])

  const applyTheme = (newTheme: "light" | "dark" | "system") => {
    if (newTheme === "system") {
      const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
      document.documentElement.classList.toggle("dark", systemTheme === "dark")
    } else {
      document.documentElement.classList.toggle("dark", newTheme === "dark")
    }
  }

  const handleThemeChange = (newTheme: "light" | "dark" | "system") => {
    setTheme(newTheme)
    localStorage.setItem("theme", newTheme)
    applyTheme(newTheme)
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          {theme === "light" ? "☀️" : theme === "dark" ? "🌙" : "💻"}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => handleThemeChange("light")}>
          ☀️ 浅色
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleThemeChange("dark")}>
          🌙 深色
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => handleThemeChange("system")}>
          💻 系统
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

---

## 🎨 实践：主题切换页面

### 创建主题展示页面

```tsx
"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { GradientButton } from "@/components/gradient-button"
import { ThemeToggle } from "@/components/theme-toggle"

const themes = [
  { name: "默认", value: "default", color: "bg-slate-900" },
  { name: "蓝色", value: "blue", color: "bg-blue-500" },
  { name: "绿色", value: "green", color: "bg-green-500" },
  { name: "紫色", value: "purple", color: "bg-purple-500" },
]

export default function ThemePage() {
  const [currentTheme, setCurrentTheme] = useState("default")

  const handleThemeChange = (theme: string) => {
    setCurrentTheme(theme)
    document.documentElement.setAttribute("data-theme", theme)
  }

  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold">主题定制</h1>
          <ThemeToggle />
        </div>

        <Card>
          <CardHeader>
            <CardTitle>选择主题</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex gap-4">
              {themes.map((theme) => (
                <Button
                  key={theme.value}
                  variant={currentTheme === theme.value ? "default" : "outline"}
                  onClick={() => handleThemeChange(theme.value)}
                >
                  <span className={`w-4 h-4 rounded-full ${theme.color} mr-2`} />
                  {theme.name}
                </Button>
              ))}
            </div>
          </CardContent>
        </Card>

        <div className="grid grid-cols-2 gap-4">
          <Card>
            <CardHeader>
              <CardTitle>按钮变体</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap gap-2">
                <Button>默认</Button>
                <Button variant="secondary">次要</Button>
                <Button variant="outline">轮廓</Button>
                <Button variant="ghost">幽灵</Button>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>渐变按钮</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap gap-2">
                <GradientButton variant="blue">蓝色</GradientButton>
                <GradientButton variant="purple">紫色</GradientButton>
                <GradientButton variant="pink">粉色</GradientButton>
                <GradientButton variant="rainbow">彩虹</GradientButton>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
```

---

## 📊 学习成果

### 已掌握技能
1. ✅ **组件定制方法**
   - className 定制
   - cva 变体管理
   - 自定义组件创建

2. ✅ **主题系统**
   - CSS 变量配置
   - 自定义主题
   - 暗色模式切换

3. ✅ **样式管理**
   - Tailwind CSS 技巧
   - cn 工具函数
   - 响应式设计

### 代码统计
- 自定义组件：2 个
- 主题配置：4 个主题
- 代码行数：~400 行
- 学习时间：4 小时

---

## 💡 学习心得

### 1. 组件定制最佳实践
```tsx
// 好的实践：使用 cva 管理变体
const variants = cva("base-class", {
  variants: {
    variant: { ... },
    size: { ... },
  },
  defaultVariants: { ... },
})

// 好的实践：使用 cn 合并类名
<Button className={cn(variants({ variant, size }), className)}>
```

### 2. 主题系统设计
```tsx
// 好的实践：使用 CSS 变量
:root {
  --primary: 222.2 47.4% 11.2%;
}

// 好的实践：使用 data 属性切换主题
[data-theme="blue"] {
  --primary: 221.2 83.2% 53.3%;
}
```

### 3. 暗色模式实现
```tsx
// 好的实践：使用 class 切换
document.documentElement.classList.toggle("dark", isDark)

// 好的实践：监听系统主题
window.matchMedia("(prefers-color-scheme: dark)")
```

---

## 🎯 明日计划

### Day 4 任务
- [ ] 学习数据表格组件
- [ ] 学习表单验证
- [ ] 实践：构建管理后台
- [ ] 记录学习笔记

### 学习目标
- 掌握数据表格
- 理解表单验证
- 完成管理后台项目

---

## 🎉 总结

今天是学习 Shadcn/ui 的第三天，我：

1. ✅ **掌握了组件定制方法**
   - className 定制
   - cva 变体管理
   - 自定义组件创建

2. ✅ **理解了主题系统**
   - CSS 变量配置
   - 自定义主题
   - 暗色模式切换

3. ✅ **完成了实践项目**
   - 渐变按钮组件
   - 主题切换组件
   - 主题展示页面

4. ✅ **记录了学习笔记**
   - 定制方法
   - 主题配置
   - 最佳实践

**累计学习**: 9 个组件 + 2 个自定义组件，3 天

**继续学习，持续成长！** 🚀

---

*"The only way to do great work is to love what you do." - Steve Jobs*
