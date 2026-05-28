---
title: RAG 检索增强生成
created: 2026-05-27
updated: 2026-05-28
tags: [ai, rag, knowledge-base]
related: ["向量数据库简介", "GitHub-LangChain 学习笔记", "GitHub-LlamaIndex 学习笔记"]
---

# RAG 检索增强生成

## 什么是 RAG？

RAG（Retrieval-Augmented Generation，检索增强生成）是一种结合了信息检索和文本生成的技术框架。

## 核心原理

```
用户提问 → 检索相关文档 → 将文档作为上下文 → LLM 生成回答
```

## 主要优势

1. **减少幻觉**：基于真实文档生成回答
2. **知识更新**：无需重新训练模型，更新文档即可
3. **可追溯**：可以查看回答来源

## 技术栈

| 组件 | 工具 | 说明 |
|------|------|------|
| 向量数据库 | [[向量数据库简介\|Chroma / FAISS / Pinecone]] | 存储和检索向量 |
| Embedding | OpenAI / HuggingFace | 文本向量化 |
| LLM | MiMo / GPT / Claude | 生成回答 |
| 框架 | [[GitHub-LangChain 学习笔记\|LangChain]] / [[GitHub-LlamaIndex 学习笔记\|LlamaIndex]] | 编排流程 |

## 实施步骤

1. **文档加载**：读取 PDF/TXT/Markdown 等格式
2. **文本分割**：将长文档切分为小块
3. **向量化**：使用 Embedding 模型生成向量
4. **存储索引**：存入[[向量数据库简介|向量数据库]]
5. **检索匹配**：根据查询检索相关文档
6. **生成回答**：LLM 基于检索结果生成回答

## 相关知识

- [[向量数据库简介]] - 存储向量的基础设施
- [[GitHub-LangChain 学习笔记]] - RAG 编排框架
- [[GitHub-LlamaIndex 学习笔记]] - 数据索引框架
- [[GitHub-AnythingLLM 学习笔记]] - 私有化 RAG 方案
- [[MiMo V2.5 使用指南]] - 可选的 LLM

## 最佳实践

1. **分块策略**：根据文档类型选择合适的分块大小
2. **检索优化**：使用混合检索（向量 + BM25）
3. **提示工程**：设计好的提示模板
4. **评估指标**：关注准确率、召回率、相关性

---

*参考来源：[RAG 与知识检索 | 菜鸟教程](https://www.runoob.com/ai-agent/retrieval-augmented-generation.html)*
