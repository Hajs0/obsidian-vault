#!/bin/bash
# Obsidian Vault 增量同步（用于定时任务）
# 每 30 分钟检查一次，有变更才同步

set -e

VAULT_DIR="$HOME/obsidian-vault"
LOG_FILE="$VAULT_DIR/Scripts/sync.log"

cd "$VAULT_DIR"

# 记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "开始检查同步..."

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    log "没有变更，跳过同步"
    exit 0
fi

# 统计变更数量
CHANGED_FILES=$(git diff --name-only | wc -l)
log "检测到 $CHANGED_FILES 个文件变更"

# 添加变更
git add .

# 提交
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
COMMIT_MSG="🔄 自动同步 - $TIMESTAMP ($CHANGED_FILES 个文件)"
git commit -m "$COMMIT_MSG"

# 推送
git push origin main

log "✅ 同步成功：$CHANGED_FILES 个文件"

# 清理旧日志（保留最近 100 行）
if [ -f "$LOG_FILE" ]; then
    tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
