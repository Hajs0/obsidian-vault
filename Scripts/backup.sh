#!/bin/bash
# Obsidian Vault 备份脚本
# 使用方法: ./backup.sh

set -e

VAULT_DIR="$HOME/obsidian-vault"
BACKUP_DIR="$HOME/Backups/obsidian"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/obsidian-backup-$DATE.tar.gz"

echo "开始备份 Obsidian Vault..."

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 创建备份
tar -czf "$BACKUP_FILE" -C "$HOME" obsidian-vault

echo "备份完成: $BACKUP_FILE"

# 保留最近 30 天的备份
find "$BACKUP_DIR" -name "obsidian-backup-*.tar.gz" -mtime +30 -delete

echo "清理旧备份完成"
