---
title: Browser Use
created: 2026-05-28
tags: [github, browser-automation, ai-agent, playwright]
source: https://github.com/browser-use/browser-use
stars: 96000+
---

# Browser Use

## 简介
让网站对 AI Agent 可访问，轻松实现在线任务自动化。基于 Playwright 的 AI 浏览器自动化框架。

## 核心功能
- **AI 驱动的浏览器控制**：LLM 直接操作浏览器执行任务
- **多模型支持**：支持 BrowserUse 自有模型、Google Gemini、Anthropic Claude 等
- **云端和本地部署**：可选 Browser Use Cloud（隐身浏览器）或本地运行
- **任务描述即执行**：用自然语言描述任务，Agent 自动完成
- **Playwright 底层**：基于成熟的浏览器自动化框架

## 技术栈
- 语言：Python (>=3.11)
- 底层：Playwright + Chromium
- 支持 LLM：BrowserUse、Google Gemini、Anthropic Claude
- 包管理：uv

## 使用方法
```bash
# 安装
uv init && uv add browser-use && uv sync
uvx browser-use install  # 安装 Chromium
```

```python
from browser_use import Agent, Browser, ChatBrowserUse
import asyncio

async def main():
    browser = Browser()
    agent = Agent(
        task="Find the number of stars of the browser-use repo",
        llm=ChatBrowserUse(),
        browser=browser,
    )
    await agent.run()

if __name__ == "__main__":
    asyncio.run(main())
```

## 最佳实践
- 使用 `uv` 管理依赖，确保 Python >= 3.11
- 云部署可获得隐身浏览器能力，避免反爬检测
- 任务描述要具体明确，避免歧义
- 对于复杂任务，可分步骤描述
- 可与 Cursor、Claude Code 等编码 Agent 集成

## 适用场景
- 网页数据采集和监控
- 自动化表单填写
- 网站功能测试
- 重复性网页操作自动化
- AI Agent 的网页交互能力
