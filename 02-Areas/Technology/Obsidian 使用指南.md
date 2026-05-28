---
title: Obsidian 个人知识管理系统使用指南
created: 2026-05-28
updated: 2026-05-28
tags: [obsidian, guide, pkm]
---

# 📚 Obsidian 个人知识管理系统使用指南

> 从零开始使用你的个人知识管理系统

---

## 一、系统概述

### 1.1 目录结构

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

### 1.2 工作流

1. **收件箱** - 新笔记先进入 00-Inbox
2. **处理** - 定期整理，移动到相应目录
3. **链接** - 建立双向链接，形成知识网络
4. **归档** - 完成的内容移动到 04-Archive

---

## 二、快速开始

### 2.1 安装 Obsidian

**macOS**:
```bash
brew install obsidian
```

**Windows**:
```powershell
winget install Obsidian.Obsidian
```

**Linux**:
```bash
# 下载 AppImage
wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.0/Obsidian-1.5.0.AppImage
chmod +x Obsidian-1.5.0.AppImage
./Obsidian-1.5.0.AppImage
```

### 2.2 打开 Vault

1. 打开 Obsidian
2. 点击 "Open folder as vault"
3. 选择 `~/obsidian-vault` 目录

### 2.3 安装插件

1. Settings → Community plugins
2. 关闭 "Safe mode"
3. 点击 "Browse" 搜索并安装：
   - **Dataview** - 数据查询
   - **Calendar** - 日历视图
   - **Kanban** - 看板视图
   - **Templater** - 高级模板

---

## 三、日常使用

### 3.1 创建笔记

**方法 1**：点击左侧 "New note" 图标

**方法 2**：快捷键 `Ctrl/Cmd + N`

**方法 3**：在文件管理器中右键 → "New note"

### 3.2 使用模板

1. 创建新笔记
2. `Ctrl/Cmd + P` 打开命令面板
3. 输入 "Templates: Insert template"
4. 选择模板：
   - `note-template` - 普通笔记
   - `project-template` - 项目笔记
   - `resource-template` - 资源笔记
   - `meeting-template` - 会议记录

### 3.3 写日记

**方法 1**：点击左侧日历图标

**方法 2**：`Ctrl/Cmd + P` → "Daily notes: Open today's daily note"

### 3.4 建立链接

**双向链接**：
```markdown
这是一篇关于 [[机器学习]] 的笔记。
```

**嵌入笔记**：
```markdown
![[笔记名]]
![[笔记名#标题]]
```

**别名链接**：
```markdown
---
aliases: [ML, 机器学习基础]
---
```

这样可以用 `[[ML]]` 或 `[[机器学习基础]]` 链接到这篇笔记。

### 3.5 使用标签

**在 frontmatter 中**：
```markdown
---
tags: [ai, machine-learning, tutorial]
---
```

**在正文中**：
```markdown
#ai #machine-learning #tutorial
```

---

## 四、高级功能

### 4.1 Dataview 查询

**列出所有项目**：
````markdown
```dataview
TABLE file.ctime AS "创建时间", status AS "状态"
FROM #project
SORT file.mtime DESC
```
````

**列出待办任务**：
````markdown
```dataview
TASK
FROM #project
WHERE !completed
SORT file.ctime DESC
```
````

**按标签统计**：
````markdown
```dataview
TABLE length(rows) AS "数量"
FROM #tag
GROUP BY file.tags
```
````

### 4.2 搜索

**快速打开**：`Ctrl/Cmd + O`

**全局搜索**：`Ctrl/Cmd + Shift + F`

**搜索语法**：
- `tag:#ai` - 搜索标签
- `path:01-Projects` - 搜索路径
- `content:机器学习` - 搜索内容

### 4.3 知识图谱

1. 点击左侧 "Graph view" 图标
2. 查看笔记之间的关联
3. 点击节点跳转到笔记
4. 使用筛选器过滤节点

---

## 五、工作流示例

### 5.1 PARA 方法

- **Projects** - 有明确目标和截止日期
  - 示例：开发一个网站、写一本书
- **Areas** - 需要持续维护的领域
  - 示例：技术、职业、健康、财务
- **Resources** - 感兴趣的主题
  - 示例：文章、书籍、课程
- **Archive** - 已完成内容
  - 示例：已完成的项目、过时的资源

### 5.2 Zettelkasten 方法

1. **原子化** - 一个笔记一个主题
2. **重述** - 用自己的话写
3. **链接** - 建立双向链接
4. **元数据** - 添加标签和属性

### 5.3 渐进式总结

1. **第一层**：原文摘录
2. **第二层**：加粗重点
3. **第三层**：高亮关键句
4. **第四层**：用自己的话总结
5. **第五层**：整合到其他笔记

---

## 六、同步与备份

### 6.1 Git 同步

**初始化**：
```bash
cd ~/obsidian-vault
git remote add origin https://github.com/YOUR_USERNAME/my-knowledge-base.git
git push -u origin master
```

**手动同步**：
```bash
cd ~/obsidian-vault
./Scripts/sync.sh
```

**自动同步**（每小时）：
```bash
crontab -e
# 添加：0 * * * * ~/obsidian-vault/Scripts/sync.sh
```

### 6.2 备份

**手动备份**：
```bash
cd ~/obsidian-vault
./Scripts/backup.sh
```

**自动备份**（每天）：
```bash
crontab -e
# 添加：0 2 * * * ~/obsidian-vault/Scripts/backup.sh
```

---

## 七、最佳实践

### ✅ DO（推荐做法）

1. **每天写日记** - 记录想法和进展
2. **使用模板** - 保持一致性
3. **建立链接** - 形成知识网络
4. **定期整理** - 清理收件箱
5. **备份** - 定期备份

### ❌ DON'T（避免做法）

1. **不要过度组织** - 避免过深的文件夹层级
2. **不要完美主义** - 先写后改
3. **不要孤岛笔记** - 建立链接
4. **不要忽略元数据** - 使用 frontmatter
5. **不要手动同步** - 使用自动化工具

---

## 八、常见问题

### Q1: 如何开始？

1. 安装 Obsidian
2. 打开 Vault
3. 写第一篇日记
4. 使用模板创建笔记
5. 建立链接

### Q2: 如何组织笔记？

使用 PARA 方法：
- 01-Projects - 当前项目
- 02-Areas - 持续领域
- 03-Resources - 感兴趣的主题
- 04-Archive - 已完成内容

### Q3: 如何建立链接？

1. 使用 `[[]]` 语法
2. 使用标签 `#tag`
3. 使用别名 `aliases: [别名]`
4. 使用嵌入 `![[]]`

### Q4: 如何搜索？

1. `Ctrl/Cmd + O` - 快速打开
2. `Ctrl/Cmd + Shift + F` - 全局搜索
3. 使用 Dataview 查询
4. 使用标签面板

### Q5: 如何同步？

推荐方案：
- **苹果用户** - iCloud
- **技术用户** - Git
- **简单需求** - Obsidian Sync

---

## 九、快捷键速查

| 快捷键 | 功能 |
|--------|------|
| `Ctrl/Cmd + N` | 新建笔记 |
| `Ctrl/Cmd + O` | 快速打开 |
| `Ctrl/Cmd + P` | 命令面板 |
| `Ctrl/Cmd + Shift + F` | 全局搜索 |
| `Ctrl/Cmd + E` | 切换编辑/预览模式 |
| `Ctrl/Cmd + L` | 切换行号 |
| `Ctrl/Cmd + /` | 切换源码模式 |
| `Ctrl/Cmd + B` | 粗体 |
| `Ctrl/Cmd + I` | 斜体 |
| `Ctrl/Cmd + K` | 插入链接 |

---

## 十、更多资源

- [Obsidian 官网](https://obsidian.md)
- [Obsidian 帮助文档](https://help.obsidian.md)
- [Obsidian 论坛](https://forum.obsidian.md)
- [Obsidian 插件市场](https://obsidian.md/plugins)

---

*创建时间：2026-05-28*
*最后更新：2026-05-28*
