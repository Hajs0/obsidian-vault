---
title: Day 62 - GraphQL 高级特性
date: 2026-05-31
tags:
  - GraphQL
  - 高级特性
  - 实时通信
category: 高级进阶
status: in_progress
---

# Day 62 - GraphQL 高级特性

## 📚 学习目标

1. 掌握 GraphQL 订阅（Subscriptions）
2. 实现分页（Pagination）
3. 理解缓存策略
4. 学习错误处理
5. 优化性能（DataLoader）

---

## 1. 订阅（Subscriptions）

### 什么是订阅？
- 实时数据推送机制
- 客户端订阅特定事件
- 服务器在事件发生时推送数据

### 使用场景
- 聊天消息
- 实时通知
- 数据更新
- 协作编辑

### 实现示例

```javascript
// Schema 定义
const typeDefs = `
  type Subscription {
    messageCreated: Message!
    userStatusChanged: User!
  }
`;

// Resolver
const resolvers = {
  Subscription: {
    messageCreated: {
      subscribe: () => pubsub.asyncIterator(['MESSAGE_CREATED'])
    }
  }
};
```

---

## 2. 分页（Pagination）

### 两种分页方式

#### 1. 偏移分页（Offset Pagination）
```graphql
query {
  posts(limit: 10, offset: 0) {
    id
    title
  }
}
```

**优点**：简单易用
**缺点**：数据变化时可能跳过或重复

#### 2. 游标分页（Cursor Pagination）
```graphql
query {
  posts(first: 10, after: "cursor123") {
    edges {
      node {
        id
        title
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

**优点**：数据稳定，适合无限滚动
**缺点**：实现复杂

### Relay 规范

```graphql
type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  node: Post!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

---

## 3. 缓存策略

### Apollo Client 缓存

#### 默认缓存策略
```javascript
const client = new ApolloClient({
  cache: new InMemoryCache()
});
```

#### 缓存策略选项
1. **cache-first**（默认）- 先查缓存，再查网络
2. **network-only** - 只查网络
3. **cache-only** - 只查缓存
4. **no-cache** - 不使用缓存

```javascript
const { data } = useQuery(GET_POSTS, {
  fetchPolicy: 'cache-and-network'
});
```

#### 缓存更新
```javascript
const [createPost] = useMutation(CREATE_POST, {
  update(cache, { data: { createPost } }) {
    cache.modify({
      fields: {
        posts(existingPosts = []) {
          const newPostRef = cache.writeFragment({
            data: createPost,
            fragment: gql`
              fragment NewPost on Post {
                id
                title
              }
            `
          });
          return [...existingPosts, newPostRef];
        }
      }
    });
  }
});
```

---

## 4. 错误处理

### 统一错误格式

```graphql
type Query {
  user(id: ID!): UserResult!
}

union UserResult = User | NotFoundError | ValidationError

type NotFoundError {
  message: String!
  code: String!
}

type ValidationError {
  message: String!
  fields: [FieldError!]!
}

type FieldError {
  field: String!
  message: String!
}
```

### 错误处理最佳实践

1. **使用联合类型处理错误**
2. **定义明确的错误代码**
3. **提供有用的错误信息**
4. **记录错误日志**

---

## 5. 性能优化（DataLoader）

### N+1 问题

```graphql
# 这个查询会导致 N+1 问题
query {
  posts {
    title
    author {
      name
    }
  }
}
```

**问题**：查询 100 篇文章，会触发 101 次数据库查询

### DataLoader 解决方案

```javascript
const DataLoader = require('dataloader');

// 创建 DataLoader
const userLoader = new DataLoader(async (userIds) => {
  const users = await User.findByIds(userIds);
  return userIds.map(id => users.find(user => user.id === id));
});

// 在 Resolver 中使用
const resolvers = {
  Post: {
    author: (post) => userLoader.load(post.authorId)
  }
};
```

**效果**：将 101 次查询合并为 2 次查询

---

## 🎯 实战练习

### 练习 1：实现游标分页

1. 修改 Schema 添加分页类型
2. 实现分页 Resolver
3. 测试分页查询

### 练习 2：实现订阅

1. 安装 graphql-subscriptions
2. 定义订阅 Schema
3. 实现订阅 Resolver
4. 测试实时推送

### 练习 3：优化性能

1. 安装 dataloader
2. 实现用户批量加载
3. 测试 N+1 问题解决

---

## 📝 学习笔记

### 关键概念

1. **订阅**：实时数据推送，基于 WebSocket
2. **游标分页**：稳定的数据分页方式
3. **DataLoader**：批量加载数据，解决 N+1 问题
4. **缓存策略**：控制数据获取和更新方式

### 最佳实践

1. **订阅**：用于实时功能，如聊天、通知
2. **分页**：大数据集必须分页，推荐游标分页
3. **缓存**：合理使用缓存，减少网络请求
4. **错误处理**：使用联合类型，提供明确错误信息

### 常见问题

1. **订阅连接管理**：处理断线重连
2. **分页性能**：大数据集使用游标分页
3. **缓存一致性**：更新后及时刷新缓存

---

## 🎯 明日预告

**Day 63: tRPC 类型安全 API**
- tRPC 基础概念
- 类型安全的 API 开发
- 与 Next.js 集成
- 实战练习

继续加油！🚀
