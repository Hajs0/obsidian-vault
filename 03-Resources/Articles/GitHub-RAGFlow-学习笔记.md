---
title: RAGFlow
created: 2026-05-28
tags: [github, rag, llm, knowledge-base, agent]
source: https://github.com/infiniflow/ragflow
stars: 81000+
---

# RAGFlow

## 简介
领先的开源 RAG（检索增强生成）引擎，将前沿 RAG 与 Agent 能力融合，为 LLM 提供卓越的上下文层。

## 核心功能
- **深度文档理解**：基于 DeepDoc 的知识提取，支持复杂格式的非结构化数据
- **模板化分块**：智能可解释的分块策略，多种模板可选
- **引用溯源**：减少幻觉，可视化分块过程，支持人工干预
- **异构数据源兼容**：支持 Word、PPT、Excel、TXT、图片、扫描件、网页等
- **自动化 RAG 工作流**：可配置的 LLM 和嵌入模型，多路召回 + 融合重排
- **Agent 能力**：支持 agentic workflow、MCP 协议、代码执行器
- **Memory 记忆**：AI Agent 记忆功能（2025-12 新增）
- **数据同步**：支持 Confluence、S3、Notion、Discord、Google Drive

## 技术栈
- 语言：Python
- 部署：Docker Compose
- 最低要求：CPU >= 4核, RAM >= 16GB, Disk >= 50GB
- 支持 GPU 加速 DeepDoc 任务

## 使用方法
```bash
# 1. 设置系统参数
sudo sysctl -w vm.max_map_count=262144

# 2. 克隆项目
git clone https://github.com/infiniflow/ragflow.git

# 3. 启动服务
cd ragflow/docker
docker compose -f docker-compose.yml up -d

# 4. 检查状态
docker logs -f docker-ragflow-cpu-1

# 5. 浏览器访问 http://IP_OF_YOUR_MACHINE
```

## 最佳实践
- **"Quality in, quality out"**：高质量文档输入是高质量检索的前提
- 使用模板化分块策略，根据文档类型选择合适的模板
- 利用可视化分块功能进行人工审查和调优
- 多路召回 + 融合重排提升检索精度
- 使用 Agent 模板快速构建复杂工作流

## 适用场景
- 企业知识库建设
- 文档问答系统
- 需要高精度检索的 RAG 应用
- 多模态文档处理（PDF、图片、扫描件）
- 需要 Agent 能力的智能工作流
