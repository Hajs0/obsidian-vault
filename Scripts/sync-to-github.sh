#!/bin/bash
# Obsidian Vault 自动同步到 GitHub
# 用法: ./sync-to-github.sh [commit_message]

set -e

VAULT_DIR="$HOME/obsidian-vault"
cd "$VAULT_DIR"

# 获取当前时间
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# 默认提交信息
if [ -z "$1" ]; then
    COMMIT_MSG="🔄 自动同步 - $TIMESTAMP"
else
    COMMIT_MSG="$1"
fi

echo "🔄 开始同步到 GitHub..."
echo "📁 Vault 目录: $VAULT_DIR"
echo "💬 提交信息: $COMMIT_MSG"
echo ""

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    echo "✅ 没有变更，无需同步"
    exit 0
fi

# 添加所有变更
echo "📦 添加变更..."
git add .

# 显示变更统计
echo ""
echo "📊 变更统计:"
git diff --cached --stat
echo ""

# 提交变更
echo "💾 提交变更..."
git commit -m "$COMMIT_MSG"

# 推送到 GitHub
echo "🚀 推送到 GitHub..."
git push origin main

echo ""
echo "✅ 同步完成！"
echo "🔗 仓库地址: https://github.com/Hajs0/obsidian-vault"
echo ""

# 显示最新提交
echo "📝 最新提交:"
git log --oneline -1
