---
title: AnythingLLM
created: 2026-05-28
tags: [github, llm, knowledge-base, rag, agent]
source: https://github.com/Mintplex-Labs/anything-llm
stars: 61000+
---

# AnythingLLM

## 简介
一站式 AI 应用，可构建私有的全功能 ChatGPT，支持文档对话、AI Agent、多用户，零配置即可本地运行。

## 核心功能
- **动态模型路由**：根据对话规则自动选择最佳模型和提供商
- **记忆系统**：自动和用户管理的记忆，LLM 可记住重要信息
- **定时任务**：基于 cron 调度的周期性任务，支持完整 Agent 能力
- **智能技能选择**：支持无限工具，减少 80% token 消耗
- **无代码 Agent 构建器**：可视化构建 AI Agent 工作流
- **MCP 兼容**：支持 Model Context Protocol
- **多模态支持**：同时支持闭源和开源 LLM
- **多用户支持**：权限控制，保护隐私和知识产权
- **文档对话**：支持 PDF、TXT、DOCX 等多种格式
- **可嵌入聊天组件**：可嵌入到网站中

## 技术栈
- 语言：JavaScript/TypeScript
- 支持桌面端（Mac、Windows、Linux）和 Docker 部署
- 支持所有主流 LLM 提供商（OpenAI、Anthropic、本地模型等）
- 支持多种向量数据库

## 使用方法
```bash
# Docker 部署
docker pull mintplexlabs/anythingllm
docker run -d -p 3001:3001 mintplexlabs/anythingllm

# 或下载桌面应用
# https://anythingllm.com/download
```

## 最佳实践
- 使用动态模型路由降低 API 成本
- 利用记忆系统实现个性化对话
- 定时任务可用于自动化报告、监控等场景
- 智能技能选择可大幅减少 token 消耗
- 多用户模式适合团队协作场景

## 适用场景
- 企业内部知识问答
- 个人 AI 助手
- 团队协作的 AI 工作空间
- 文档分析和摘要
- 需要多模型切换的场景
