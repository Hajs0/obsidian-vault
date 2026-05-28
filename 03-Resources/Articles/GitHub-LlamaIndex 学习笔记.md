---
title: GitHub-LlamaIndex 学习笔记
created: 2026-05-27
updated: 2026-05-27
tags: [llamaindex, rag, data-framework, github]
related: ["RAG 检索增强生成", "向量数据库简介", "GitHub-LangChain 学习笔记"]
---

# 📦 GitHub-LlamaIndex 学习笔记

> LlamaIndex 是一个数据框架，用于构建 LLM 应用程序

---

## 一、LlamaIndex 简介

### 1.1 什么是 LlamaIndex？

LlamaIndex（前身为 GPT Index）是一个**数据框架**，用于将自定义数据源与大语言模型（LLM）连接起来。

**核心功能**：
- 📄 **数据连接** - 连接各种数据源（PDF、数据库、API 等）
- 🔍 **索引构建** - 构建高效的索引结构
- 💬 **查询接口** - 提供自然语言查询接口
- 🔗 **与 LangChain 集成** - 可以与 LangChain 配合使用

### 1.2 LlamaIndex vs LangChain

| 特性 | LlamaIndex | LangChain |
|------|------------|-----------|
| **主要用途** | 数据索引和查询 | Agent 和链式调用 |
| **核心优势** | 数据连接和检索 | 工具编排和代理 |
| **学习曲线** | 较低 | 较高 |
| **适用场景** | RAG 应用 | 复杂 Agent 应用 |

**最佳实践**：两者可以配合使用
- LlamaIndex 负责数据索引和检索
- LangChain 负责 Agent 编排和工具调用

---

## 二、核心概念

### 2.1 索引（Index）

索引是 LlamaIndex 的核心，用于组织和检索数据。

**主要索引类型**：
- **VectorStoreIndex** - 向量索引（最常用）
- **ListIndex** - 列表索引
- **TreeIndex** - 树形索引
- **KeywordTableIndex** - 关键词索引

### 2.2 文档（Document）

文档是 LlamaIndex 的基本数据单位。

```python
from llama_index.core import Document

# 创建文档
doc = Document(
    text="这是一篇关于机器学习的文章...",
    metadata={"source": "article.txt", "author": "张三"}
)
```

### 2.3 节点（Node）

节点是文档的片段，用于构建索引。

```python
from llama_index.core import SimpleNodeParser

# 解析文档为节点
parser = SimpleNodeParser()
nodes = parser.get_nodes_from_documents([doc])
```

### 2.4 查询引擎（Query Engine）

查询引擎用于从索引中检索信息。

```python
# 创建查询引擎
query_engine = index.as_query_engine()

# 查询
response = query_engine.query("什么是机器学习？")
print(response)
```

---

## 三、快速开始

### 3.1 安装

```bash
pip install llama-index
```

### 3.2 基本使用

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

# 1. 加载文档
documents = SimpleDirectoryReader('./data').load_data()

# 2. 构建索引
index = VectorStoreIndex.from_documents(documents)

# 3. 创建查询引擎
query_engine = index.as_query_engine()

# 4. 查询
response = query_engine.query("这个文档的主要内容是什么？")
print(response)
```

### 3.3 使用 OpenAI

```python
import os
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms.openai import OpenAI

# 设置 API Key
os.environ["OPENAI_API_KEY"] = "your-api-key"

# 使用 GPT-4
llm = OpenAI(model="gpt-4")

# 加载文档
documents = SimpleDirectoryReader('./data').load_data()

# 构建索引
index = VectorStoreIndex.from_documents(documents)

# 创建查询引擎
query_engine = index.as_query_engine(llm=llm)

# 查询
response = query_engine.query("什么是机器学习？")
print(response)
```

---

## 四、高级功能

### 4.1 自定义 LLM

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms.openai import OpenAI
from llama_index.llms.anthropic import Anthropic

# 使用 OpenAI
llm_openai = OpenAI(model="gpt-4")

# 使用 Anthropic
llm_anthropic = Anthropic(model="claude-3-opus")

# 构建索引
index = VectorStoreIndex.from_documents(documents)

# 使用不同的 LLM
query_engine_openai = index.as_query_engine(llm=llm_openai)
query_engine_anthropic = index.as_query_engine(llm=llm_anthropic)
```

### 4.2 自定义 Embedding

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.embeddings.openai import OpenAIEmbedding

# 使用 OpenAI Embedding
embed_model = OpenAIEmbedding(model="text-embedding-3-small")

# 构建索引
index = VectorStoreIndex.from_documents(
    documents,
    embed_model=embed_model
)
```

### 4.3 使用向量数据库

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import StorageContext
import chromadb

# 创建 Chroma 客户端
chroma_client = chromadb.PersistentClient(path="./chroma_db")
chroma_collection = chroma_client.get_or_create_collection("my_collection")

# 创建向量存储
vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# 构建索引
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context
)
```

### 4.4 持久化索引

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, StorageContext, load_index_from_storage

# 构建索引
index = VectorStoreIndex.from_documents(documents)

# 保存索引
index.storage_context.persist(persist_dir="./storage")

# 加载索引
storage_context = StorageContext.from_defaults(persist_dir="./storage")
index = load_index_from_storage(storage_context)
```

---

## 五、数据连接器

### 5.1 支持的数据源

| 数据源 | 连接器 |
|--------|--------|
| 本地文件 | SimpleDirectoryReader |
| PDF | PDFReader |
| 网页 | SimpleWebPageReader |
| 数据库 | DatabaseReader |
| API | 各种 API Reader |
| Slack | SlackReader |
| Notion | NotionReader |
| Google Drive | GoogleDriveReader |

### 5.2 使用示例

```python
from llama_index.readers.file import PDFReader
from llama_index.readers.web import SimpleWebPageReader

# 读取 PDF
pdf_reader = PDFReader()
documents = pdf_reader.load_data(file="./document.pdf")

# 读取网页
web_reader = SimpleWebPageReader()
documents = web_reader.load_data(urls=["https://example.com"])
```

---

## 六、与 LangChain 集成

### 6.1 使用 LangChain 的 LLM

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.llms.langchain import LangChainLLM
from langchain_openai import ChatOpenAI

# 创建 LangChain LLM
langchain_llm = ChatOpenAI(model="gpt-4")

# 包装为 LlamaIndex LLM
llm = LangChainLLM(llm=langchain_llm)

# 构建索引
index = VectorStoreIndex.from_documents(documents)

# 使用 LangChain LLM
query_engine = index.as_query_engine(llm=llm)
```

### 6.2 作为 LangChain 工具

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.tools import QueryEngineTool
from langchain.agents import AgentType, initialize_agent

# 构建索引
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine()

# 创建工具
tool = QueryEngineTool.from_defaults(
    query_engine=query_engine,
    name="knowledge_base",
    description="用于查询知识库的工具"
)

# 使用 LangChain Agent
agent = initialize_agent(
    tools=[tool],
    llm=ChatOpenAI(model="gpt-4"),
    agent=AgentType.OPENAI_FUNCTIONS
)

response = agent.run("什么是机器学习？")
```

---

## 七、最佳实践

### ✅ DO（推荐做法）

1. **使用向量索引** - VectorStoreIndex 是最常用的索引类型
2. **持久化索引** - 避免重复构建索引
3. **使用向量数据库** - 对于大规模数据，使用 Chroma、FAISS 等
4. **自定义 Embedding** - 使用适合你场景的 Embedding 模型
5. **与 LangChain 集成** - 结合两者的优势

### ❌ DON'T（避免做法）

1. **不要加载过多数据** - 分批加载，避免内存溢出
2. **不要忽略元数据** - 使用 metadata 增强检索效果
3. **不要使用默认设置** - 根据场景调整参数
4. **忽略错误处理** - 添加异常处理

---

## 八、常见问题

### Q1: LlamaIndex 和 LangChain 有什么区别？

**LlamaIndex** 专注于数据索引和查询，**LangChain** 专注于 Agent 和链式调用。两者可以配合使用。

### Q2: 如何处理大规模数据？

使用向量数据库（如 Chroma、FAISS）存储索引，分批加载数据。

### Q3: 如何提高查询质量？

1. 使用更好的 Embedding 模型
2. 调整 chunk_size 和 chunk_overlap
3. 使用 metadata 过滤
4. 使用混合检索（向量 + 关键词）

---

## 九、参考资源

- [LlamaIndex 官方文档](https://docs.llamaindex.ai/)
- [LlamaIndex GitHub](https://github.com/run-llama/llama_index)
- [LlamaIndex 示例](https://github.com/run-llama/llama_index/tree/main/docs/examples)

---

## 十、总结

### 核心优势

1. **数据连接** - 支持多种数据源
2. **索引构建** - 高效的索引结构
3. **查询接口** - 自然语言查询
4. **与 LangChain 集成** - 结合两者优势

### 适用场景

- ✅ RAG 应用
- ✅ 知识库系统
- ✅ 文档问答
- ✅ 数据分析

### 推荐配置

```python
# 基本配置
index = VectorStoreIndex.from_documents(
    documents,
    embed_model=OpenAIEmbedding(model="text-embedding-3-small"),
    llm=OpenAI(model="gpt-4")
)

# 持久化
index.storage_context.persist(persist_dir="./storage")
```
