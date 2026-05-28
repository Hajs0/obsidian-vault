---
title: Firecrawl
created: 2026-05-28
tags: [github, scraping, ai-agent, web, data-extraction]
source: https://github.com/firecrawl/firecrawl
stars: 125000+
---

# Firecrawl

## 简介
为 AI Agent 提供搜索、抓取和清洗网页的能力，将网页内容转化为干净的 Markdown 或结构化数据。

## 核心功能
- **Search**：搜索网页并获取完整页面内容
- **Scrape**：将任意 URL 转换为 Markdown、HTML、截图或结构化 JSON
- **Interact**：抓取页面后，使用 AI 提示或代码进行交互
- **Agent**：自动化数据采集，只需描述需求
- **Crawl**：单个请求抓取网站所有 URL
- **Map**：即时发现网站所有 URL
- **Batch Scrape**：异步批量抓取数千个 URL
- **媒体解析**：解析 PDF、DOCX 等网页托管的文档
- **Actions**：抓取前可执行点击、滚动、输入、等待等操作

## 技术栈
- 语言：TypeScript
- SDK：Python、Node.js、cURL、CLI
- 覆盖 96% 的网页，包括 JS 重度页面
- P95 延迟 3.4 秒

## 使用方法
```python
from firecrawl import Firecrawl

app = Firecrawl(api_key="fc-YOUR_API_KEY")

# 搜索
search_result = app.search("firecrawl", limit=5)

# 抓取单页
result = app.scrape('firecrawl.dev')

# 爬取整个站点
crawl_result = app.crawl('firecrawl.dev', limit=100)
```

```bash
# CLI 使用
firecrawl search "firecrawl" --limit 5
firecrawl scrape https://firecrawl.dev
```

## 最佳实践
- 使用 `only-main-content` 参数过滤导航栏等噪音
- 对于 JS 重度页面，Firecrawl 自动处理，无需额外配置
- 批量抓取时使用异步接口，避免阻塞
- Agent 模式适合需要多步骤数据采集的场景
- 输出 Markdown 格式最适合 LLM 消费

## 适用场景
- RAG 系统的数据采集
- AI Agent 的网页信息获取
- 竞品监控和市场调研
- 内容聚合和知识库建设
- 需要结构化网页数据的场景
