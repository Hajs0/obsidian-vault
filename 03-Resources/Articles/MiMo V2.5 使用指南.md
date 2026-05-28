---
title: MiMo V2.5 使用指南
created: 2026-05-27
updated: 2026-05-28
tags: [mimo, ai, api, xiaomi, cache]
related: ["RAG 检索增强生成", "缓存命中率优化"]
---

# 🤖 MiMo V2.5 使用指南

## 今日重要更新（2026-05-27）

### API 价格永久降价

MiMo V2.5 系列 API 永久降价，最高降幅达 99%！

| 模型 | 命中缓存 | 未命中缓存 | 输出 |
|------|----------|------------|------|
| MiMo-V2.5-Pro | ¥0.025/M | ¥3.00/M | ¥6.00/M |
| MiMo-V2.5 | ¥0.020/M | ¥1.00/M | ¥2.00/M |

### Token Plan 订阅

| 套餐 | 价格 | Credits |
|------|------|---------|
| Lite | ¥39/月 | 41 亿 |
| Standard | ¥99/月 | 110 亿 |
| Pro | ¥329/月 | 380 亿 |
| Max | ¥659/月 | 820 亿 |

## 缓存命中率优化

### 核心原则

**固定内容在前，变化内容在后**

```python
# ✅ 正确示例
messages = [
    {"role": "system", "content": "固定 System Prompt"},
    {"role": "user", "content": "用户输入"}
]
```

### 提高命中率的方法

1. **保持 System Prompt 固定**
2. **多轮对话保持消息顺序**
3. **避免在 prompt 前部插入动态内容**
4. **使用固定的采样参数**

### 成本对比

| 缓存命中率 | 1M tokens 成本 | 节省 |
|-----------|---------------|------|
| 0% | ¥3.00 | - |
| 95% | ¥0.15 | 95% |
| 100% | ¥0.025 | 99% |

## API 调用示例

```python
from openai import OpenAI

client = OpenAI(
    api_key="your-api-key",
    base_url="https://api.mimo.mi.com/v1"
)

response = client.chat.completions.create(
    model="mimo-v2.5-pro",
    messages=[
        {"role": "system", "content": "你是专业助手。"},
        {"role": "user", "content": "你好！"}
    ]
)
```

## 在 RAG 中的应用

MiMo 可以作为 [[RAG 检索增强生成|RAG 系统]] 的 LLM：

```python
# RAG 示例
def rag_query(question, context):
    messages = [
        {"role": "system", "content": "根据以下文档回答问题。"},
        {"role": "user", "content": f"文档：{context}\n\n问题：{question}"}
    ]
    return client.chat.completions.create(
        model="mimo-v2.5-pro",
        messages=messages
    )
```

## 相关知识

- [[RAG 检索增强生成]] - 使用 MiMo 的场景
- [[向量数据库简介]] - 配合 MiMo 使用
- [[GitHub-LangChain 学习笔记]] - 集成 MiMo

## 相关资源

- 官网: https://mimo.mi.com
- API 文档: https://mimo.mi.com/docs

---

*更新时间：2026-05-28*
