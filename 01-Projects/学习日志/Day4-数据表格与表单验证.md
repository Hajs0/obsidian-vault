---
tags: [shadcn, ui, table, form, validation, day4, learning]
created: 2026-05-27
day: 4
---

# 📚 Day 4：数据表格 + 表单验证

## 🎯 今日目标
- 学习 Table 组件
- 学习 Form + 表单验证
- 实践：管理后台

---

## 🧩 新学习的组件

### 1. Table 数据表格

**子组件**:
- `Table` - 表格容器
- `TableHeader` - 表头
- `TableBody` - 表体
- `TableRow` - 表行
- `TableHead` - 表头单元格
- `TableCell` - 表格单元格
- `TableCaption` - 表格标题

**代码示例**:
```tsx
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

export function TableDemo() {
  return (
    <Table>
      <TableCaption>用户列表</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead>姓名</TableHead>
          <TableHead>邮箱</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        <TableRow>
          <TableCell>张三</TableCell>
          <TableCell>zhangsan@example.com</TableCell>
        </TableRow>
      </TableBody>
    </Table>
  )
}
```

---

### 2. Form 表单 + Zod 验证

**技术栈**:
- `react-hook-form` - 表单状态管理
- `@hookform/resolvers` - 验证解析器
- `zod` - Schema 验证

**核心步骤**:
```tsx
// 1. 定义 Schema
const formSchema = z.object({
  username: z.string().min(2, "用户名至少 2 个字符"),
  email: z.string().email("请输入有效的邮箱"),
  password: z.string().min(8, "密码至少 8 个字符"),
})

// 2. 创建表单
const form = useForm<z.infer<typeof formSchema>>({
  resolver: zodResolver(formSchema),
  defaultValues: {
    username: "",
    email: "",
    password: "",
  },
})

// 3. 提交处理
function onSubmit(values: z.infer<typeof formSchema>) {
  console.log(values)
}
```

**Form 子组件**:
- `Form` - 表单容器
- `FormField` - 表单字段
- `FormItem` - 字单项
- `FormLabel` - 字段标签
- `FormControl` - 字段控制
- `FormDescription` - 字段描述
- `FormMessage` - 错误消息

---

### 3. Select 选择器

```tsx
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

<Select onValueChange={field.onChange} defaultValue={field.value}>
  <SelectTrigger>
    <SelectValue placeholder="选择角色" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="admin">管理员</SelectItem>
    <SelectItem value="editor">编辑</SelectItem>
    <SelectItem value="user">用户</SelectItem>
  </SelectContent>
</Select>
```

---

### 4. Checkbox 复选框

```tsx
import { Checkbox } from "@/components/ui/checkbox"

<Checkbox
  checked={field.value}
  onCheckedChange={field.onChange}
/>
```

---

### 5. Switch 开关

```tsx
import { Switch } from "@/components/ui/switch"

<Switch
  checked={field.value}
  onCheckedChange={field.onChange}
/>
```

---

### 6. Tabs 标签页

```tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

<Tabs defaultValue="account">
  <TabsList>
    <TabsTrigger value="account">账户</TabsTrigger>
    <TabsTrigger value="password">密码</TabsTrigger>
  </TabsList>
  <TabsContent value="account">账户内容</TabsContent>
  <TabsContent value="password">密码内容</TabsContent>
</Tabs>
```

---

### 7. Badge 徽章

```tsx
import { Badge } from "@/components/ui/badge"

<Badge variant="default">默认</Badge>
<Badge variant="secondary">次要</Badge>
<Badge variant="destructive">危险</Badge>
<Badge variant="outline">轮廓</Badge>
```

---

## 🎨 实践项目：管理后台

### 页面结构
```
src/app/admin/page.tsx    # 管理后台页面
src/components/
├── table-demo.tsx        # 数据表格示例
├── form-demo.tsx         # 表单验证示例
└── navbar.tsx            # 导航栏
```

### 核心功能
1. ✅ **用户列表** - Table 展示用户数据
2. ✅ **添加用户** - Form + Zod 验证
3. ✅ **系统设置** - Switch 开关配置
4. ✅ **标签页导航** - Tabs 组件

---

## 📊 学习成果

### 已掌握组件（共 16 个）
1. ✅ Button
2. ✅ Card
3. ✅ Input
4. ✅ Label
5. ✅ Dialog
6. ✅ Dropdown Menu
7. ✅ Toast (Sonner)
8. ✅ Avatar
9. ✅ Separator
10. ✅ Table
11. ✅ Form
12. ✅ Select
13. ✅ Checkbox
14. ✅ Switch
15. ✅ Tabs
16. ✅ Badge

### 技能掌握
- ✅ 组件基础使用
- ✅ 组件定制方法
- ✅ 主题配置
- ✅ 表单验证（Zod）
- ✅ 状态管理（react-hook-form）

### 代码统计
- 组件数量：16 个
- 自定义组件：2 个
- 代码行数：~1500 行
- 学习时间：4 天

---

## 💡 学习心得

### 1. 表单验证最佳实践
```tsx
// 使用 Zod 定义 Schema
const schema = z.object({
  email: z.string().email(),
  age: z.number().min(18).max(100),
})

// 结合 react-hook-form
const form = useForm({
  resolver: zodResolver(schema),
})
```

### 2. 数据表格设计
- 使用语义化 HTML（table, thead, tbody）
- 支持排序和筛选
- 支持分页（大数据量）
- 操作列使用 Button 组件

### 3. 组件组合模式
```tsx
// Tabs + Card + Form 组合
<Tabs>
  <TabsList>...</TabsList>
  <TabsContent>
    <Card>
      <CardContent>
        <Form>...</Form>
      </CardContent>
    </Card>
  </TabsContent>
</Tabs>
```

---

## 🎯 明日计划

### Day 5 任务
- [ ] 学习 Next.js App Router
- [ ] 学习 Server Components
- [ ] 实践：构建博客系统
- [ ] 记录学习笔记

---

## 🎉 总结

今天是学习 Shadcn/ui 的第四天，我：

1. ✅ **学习了 7 个新组件**
   - Table、Form、Select、Checkbox、Switch、Tabs、Badge

2. ✅ **掌握了表单验证**
   - Zod Schema 定义
   - react-hook-form 集成
   - 错误消息显示

3. ✅ **完成了管理后台**
   - 用户列表展示
   - 添加用户表单
   - 系统设置页面

**累计学习**: 16 个组件，4 天

**继续学习，持续成长！** 🚀
