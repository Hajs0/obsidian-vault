#!/bin/bash
# 同步之前的知识库到 Obsidian Vault

set -e

SOURCE_DIR="$HOME/knowledge-base-project/vault/concepts"
TARGET_DIR="$HOME/obsidian-vault/03-Resources/Articles"

echo "🔄 开始同步知识库到 Obsidian..."
echo "源目录: $SOURCE_DIR"
echo "目标目录: $TARGET_DIR"

# 创建目标目录（如果不存在）
mkdir -p "$TARGET_DIR"

# 同步所有 .md 文件
for file in "$SOURCE_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "📄 同步: $filename"
        cp "$file" "$TARGET_DIR/$filename"
    fi
done

# 同步记忆相关笔记（可选）
MEMORY_DIR="$HOME/knowledge-base-project/vault/memory"
if [ -d "$MEMORY_DIR" ]; then
    echo ""
    echo "📚 同步记忆笔记..."
    mkdir -p "$HOME/obsidian-vault/02-Areas/Memory"
    
    for dir in factual procedural long_term; do
        if [ -d "$MEMORY_DIR/$dir" ]; then
            for file in "$MEMORY_DIR/$dir"/*.md; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file")
                    echo "  📝 同步记忆: $filename"
                    cp "$file" "$HOME/obsidian-vault/02-Areas/Memory/$filename"
                fi
            done
        fi
    done
fi

# 同步进度文档
if [ -f "$HOME/knowledge-base-project/PROGRESS.md" ]; then
    echo ""
    echo "📊 同步进度文档..."
    cp "$HOME/knowledge-base-project/PROGRESS.md" "$HOME/obsidian-vault/01-Projects/知识库项目进度.md"
fi

echo ""
echo "✅ 同步完成！"
echo ""
find "$TARGET_DIR" -name "*.md" | wc -l | xargs echo "已同步文章："
