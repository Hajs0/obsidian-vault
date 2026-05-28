# 📚 我的知识库

欢迎来到我的个人知识管理系统！

## 📁 目录结构

```
obsidian-vault/
├── 00-Inbox/              # 收件箱（临时笔记）
├── 01-Projects/           # 项目笔记
├── 02-Areas/              # 领域知识
│   ├── Technology/        # 技术
│   ├── Career/            # 职业
│   ├── Health/            # 健康
│   └── Finance/           # 财务
├── 03-Resources/          # 资源收集
│   ├── Articles/          # 文章
│   ├── Books/             # 书籍
│   ├── Courses/           # 课程
│   └── Tutorials/         # 教程
├── 04-Archive/            # 归档
├── Templates/             # 模板
├── Daily/                 # 日记
├── Attachments/           # 附件
└── Scripts/               # 脚本
```

## 🚀 快速开始

### 1. 安装 Obsidian

- macOS: `brew install obsidian`
- Windows: `winget install Obsidian.Obsidian`
- Linux: 下载 AppImage

### 2. 打开 Vault

1. 打开 Obsidian
2. 点击 "Open folder as vault"
3. 选择 `~/obsidian-vault` 目录

### 3. 安装插件

1. Settings → Community plugins
2. 关闭 "Safe mode"
3. 点击 "Browse" 搜索并安装：
   - **Dataview** - 数据查询
   - **Calendar** - 日历视图
   - **Kanban** - 看板视图
   - **Templater** - 高级模板

### 4. 开始使用

1. 点击 "New note" 创建笔记
2. 使用模板：Ctrl/Cmd + P → "Template"
3. 使用双向链接：`[[笔记名]]`
4. 使用标签：`#tag`

## 📝 模板使用

### 日记模板

1. 点击左侧日历图标
2. 或使用快捷键：Ctrl/Cmd + P → "Daily notes"

### 笔记模板

1. 创建新笔记
2. Ctrl/Cmd + P → "Templates: Insert template"
3. 选择 "note-template"

### 项目模板

1. 创建新笔记
2. Ctrl/Cmd + P → "Templates: Insert template"
3. 选择 "project-template"

## 🔗 双向链接

```markdown
# 笔记 A
这是一篇关于 [[机器学习]] 的笔记。

# 笔记 B（机器学习）
机器学习是 [[人工智能]] 的子领域。
```

## 🏷️ 标签使用

```markdown
---
tags: [ai, machine-learning, tutorial]
---

#ai #machine-learning #tutorial
```

## 📊 Dataview 查询

### 列出所有项目

````markdown
```dataview
TABLE file.ctime AS "创建时间", status AS "状态"
FROM #project
SORT file.mtime DESC
```
````

### 列出待办任务

````markdown
```dataview
TASK
FROM #project
WHERE !completed
SORT file.ctime DESC
```
````

## ☁️ 同步设置

### Git 同步

```bash
cd ~/obsidian-vault
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/my-knowledge-base.git
git push -u origin main
```

### 自动同步脚本

```bash
# 添加到 crontab
0 * * * * cd ~/obsidian-vault && git add . && git commit -m "Auto sync" && git push
```

## 🎯 工作流

### PARA 方法

- **Projects** - 有明确目标和截止日期
- **Areas** - 需要持续维护的领域
- **Resources** - 感兴趣的主题
- **Archive** - 已完成内容

### Zettelkasten 方法

1. 一个笔记一个主题
2. 用自己的话重述
3. 建立双向链接
4. 添加元数据和标签

## 📚 更多资源

- [Obsidian 官网](https://obsidian.md)
- [Obsidian 帮助文档](https://help.obsidian.md)
- [Obsidian 论坛](https://forum.obsidian.md)

---

*创建时间：2026-05-28*
