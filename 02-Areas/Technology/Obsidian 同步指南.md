---
tags: [obsidian, github, sync, guide]
created: 2026-05-27
---

# 🔄 Obsidian Vault 同步指南

## 📋 概述

你的 Obsidian Vault 已配置自动同步到 GitHub，确保知识库安全备份并可跨设备访问。

**仓库地址**：https://github.com/Hajs0/obsidian-vault

---

## ⚙️ 自动同步配置

### 同步频率

| 任务 | 频率 | 说明 |
|------|------|------|
| 自动同步 | 每 30 分钟 | 检测变更并推送 |
| 手动同步 | 随时 | 使用脚本手动触发 |

### Cron Job

- **Job ID**: `6b475a729bc3`
- **Schedule**: `*/30 * * * *`（每 30 分钟）
- **状态**: ✅ 已启用

---

## 🛠️ 手动同步

### 方法 1：使用脚本（推荐）

```bash
# 同步到 GitHub
cd ~/obsidian-vault
./Scripts/sync-to-github.sh

# 或带自定义提交信息
./Scripts/sync-to-github.sh "添加了新的笔记"
```

### 方法 2：手动命令

```bash
cd ~/obsidian-vault

# 查看变更
git status

# 添加变更
git add .

# 提交
git commit -m "你的提交信息"

# 推送
git push origin main
```

---

## 📥 从 GitHub 拉取更新

### 在其他设备上克隆

```bash
# 克隆仓库
git clone https://github.com/Hajs0/obsidian-vault.git ~/obsidian-vault

# 进入目录
cd ~/obsidian-vault
```

### 拉取最新更新

```bash
cd ~/obsidian-vault
git pull origin main
```

---

## 🔍 查看同步日志

```bash
# 查看同步日志
cat ~/obsidian-vault/Scripts/sync.log

# 查看最近 20 条日志
tail -20 ~/obsidian-vault/Scripts/sync.log
```

---

## 📊 查看 Git 历史

```bash
cd ~/obsidian-vault

# 查看提交历史
git log --oneline -10

# 查看详细变更
git log --stat -5

# 查看某个文件的历史
git log --follow --oneline 03-Resources/Articles/xxx.md
```

---

## 🔄 同步工作流

### 日常使用

1. **在 Obsidian 中编辑笔记**
2. **每 30 分钟自动同步**（Cron Job）
3. **或手动同步**：`./Scripts/sync-to-github.sh`

### 多设备同步

1. **设备 A 编辑** → 自动同步到 GitHub
2. **设备 B** → `git pull origin main`
3. **设备 B 编辑** → 自动同步到 GitHub
4. **设备 A** → `git pull origin main`

---

## ⚠️ 注意事项

### 冲突处理

如果多个设备同时编辑同一文件，可能会产生冲突：

```bash
# 拉取更新
git pull origin main

# 如果有冲突，手动解决
# 编辑冲突文件，删除 <<< === >>> 标记

# 添加解决后的文件
git add .

# 提交
git commit -m "解决冲突"

# 推送
git push origin main
```

### 大文件

- **不要同步大文件**（>100MB）
- 使用 `.gitignore` 排除
- 考虑使用 Git LFS（如需要）

### 敏感信息

- **不要同步密码、Token**
- 使用环境变量
- 添加到 `.gitignore`

---

## 🎯 最佳实践

### 1. 频繁提交

```bash
# 好的做法：小改动频繁提交
git commit -m "添加了关于 X 的笔记"
git commit -m "更新了 Y 的内容"

# 避免：大量改动一个提交
git commit -m "一大堆改动"
```

### 2. 有意义的提交信息

```bash
# 好的做法
git commit -m "添加了 Python 学习笔记"
git commit -m "更新了项目进度文档"

# 避免
git commit -m "更新"
git commit -m "修改"
```

### 3. 定期整理

```bash
# 每周检查
git log --oneline -20
git status
```

---

## 🆘 常见问题

### Q: 同步失败怎么办？

```bash
# 检查网络
ping github.com

# 检查 Git 配置
git config --list

# 查看错误日志
cat ~/obsidian-vault/Scripts/sync.log
```

### Q: 如何恢复到之前的版本？

```bash
# 查看提交历史
git log --oneline

# 恢复到某个提交
git reset --hard <commit-hash>

# 强制推送（谨慎使用）
git push origin main --force
```

### Q: 如何停止自动同步？

```bash
# 查看 cron jobs
crontab -l

# 编辑 crontab
crontab -e

# 注释掉 Obsidian 同试行
# */30 * * * * ...
```

---

## 📚 相关资源

- [Git 官方文档](https://git-scm.com/doc)
- [GitHub 帮助](https://docs.github.com)
- [Obsidian 官方文档](https://help.obsidian.md)

---

## 🎉 总结

你的 Obsidian Vault 现在已经：
- ✅ 自动同步到 GitHub（每 30 分钟）
- ✅ 可手动同步
- ✅ 支持多设备访问
- ✅ 安全备份

**开始使用吧！** 🚀

如有问题，请查看日志或询问我。
