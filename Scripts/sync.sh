#!/bin/bash
# Obsidian Vault 自动同步脚本
# 使用方法: ./sync.sh

set -e

VAULT_DIR="$HOME/obsidian-vault"
LOG_FILE="$VAULT_DIR/Scripts/sync.log"

echo "$(date): 开始同步..." >> "$LOG_FILE"

cd "$VAULT_DIR"

# 检查是否有更改
if git diff --quiet && git diff --cached --quiet; then
    echo "$(date): 没有更改，跳过同步" >> "$LOG_FILE"
    exit 0
fi

# 添加所有更改
git add .

# 提交更改
git commit -m "Auto sync: $(date '+%Y-%m-%d %H:%M:%S')"

# 推送到远程仓库（如果配置了）
if git remote | grep -q origin; then
    git push origin master 2>/dev/null || git push origin main 2>/dev/null || echo "推送失败，请检查远程仓库配置"
    echo "$(date): 同步完成" >> "$LOG_FILE"
else
    echo "$(date): 未配置远程仓库，仅本地提交" >> "$LOG_FILE"
fi
