# Day6 - 认证授权系统

> 📅 日期：2026-05-29
> 🏷️ 标签：#认证 #授权 #JWT #NextAuth #OAuth #安全

---

## 一、JWT 认证原理

### 1.1 什么是 JWT

JWT（JSON Web Token）是一种开放标准（RFC 7519），用于在各方之间安全地传输信息。

### 1.2 JWT 结构

```
xxxxx.yyyyy.zzzzz
  Header    .    Payload    .    Signature
```

```json
// Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// Payload
{
  "sub": "1234567890",
  "name": "张三",
  "iat": 1516239022,
  "exp": 1516242622,
  "role": "admin"
}

// Signature
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

### 1.3 认证流程

```
用户登录 ──→ 服务器验证 ──→ 生成JWT ──→ 返回给客户端
                                           │
客户端存储JWT ←────────────────────────────┘
     │
     ▼
后续请求携带JWT ──→ 服务器验证签名 ──→ 返回数据
```

### 1.4 Node.js 实现

```javascript
const jwt = require('jsonwebtoken');

// 生成 Token
const token = jwt.sign(
  { userId: 123, role: 'admin' },
  process.env.JWT_SECRET,
  { expiresIn: '7d' }
);

// 验证 Token
try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  console.log(decoded.userId); // 123
} catch (err) {
  // Token 无效或已过期
}
```

### 1.5 JWT vs Session 对比

| 特性 | JWT | Session |
|------|-----|---------|
| 存储位置 | 客户端 | 服务端 |
| 扩展性 | ✅ 无状态 | ❌ 需要共享存储 |
| 安全性 | ⚠️ 需注意XSS | ✅ HttpOnly Cookie |
| 撤销难度 | ❌ 较难 | ✅ 容易 |
| 适用场景 | API、微服务 | 传统Web应用 |

---

## 二、NextAuth.js 使用

### 2.1 安装配置

```bash
npm install next-auth
```

### 2.2 API 路由配置

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import GithubProvider from 'next-auth/providers/github';
import CredentialsProvider from 'next-auth/providers/credentials';

const handler = NextAuth({
  providers: [
    GithubProvider({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        const user = await verifyUser(credentials);
        if (user) return user;
        return null;
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role;
      }
      return token;
    },
    async session({ session, token }) {
      session.user.role = token.role;
      return session;
    }
  },
  pages: {
    signIn: '/login',
    error: '/auth/error',
  },
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30天
  }
});

export { handler as GET, handler as POST };
```

### 2.3 前端使用

```tsx
// 使用 useSession hook
'use client';
import { useSession, signIn, signOut } from 'next-auth/react';

export function AuthButton() {
  const { data: session, status } = useSession();

  if (status === 'loading') return <p>加载中...</p>;

  if (session) {
    return (
      <div>
        <p>欢迎, {session.user.name}</p>
        <button onClick={() => signOut()}>退出</button>
      </div>
    );
  }

  return <button onClick={() => signIn()}>登录</button>;
}
```

### 2.4 服务端获取会话

```typescript
// 在 Server Component 中
import { getServerSession } from 'next-auth';
import { authOptions } from './api/auth/[...nextauth]/route';

export default async function Dashboard() {
  const session = await getServerSession(authOptions);

  if (!session) {
    redirect('/login');
  }

  return <div>欢迎回来, {session.user.name}</div>;
}
```

---

## 三、Session 管理

### 3.1 Cookie-based Session

```typescript
// Express + express-session 示例
import session from 'express-session';

app.use(session({
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,    // 防止XSS
    secure: true,      // 仅HTTPS
    sameSite: 'lax',   // 防止CSRF
    maxAge: 24 * 60 * 60 * 1000 // 24小时
  }
}));

// 存储到Redis
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient();
app.use(session({
  store: new RedisStore({ client: redisClient }),
  // ...其他配置
}));
```

### 3.2 安全最佳实践

```
✅ HttpOnly: 防止JavaScript访问Cookie
✅ Secure: 仅通过HTTPS传输
✅ SameSite: 防止CSRF攻击
✅ 合理设置过期时间
✅ 敏感操作需要重新验证
✅ 登出时销毁Session
```

---

## 四、权限控制（RBAC）

### 4.1 角色权限模型

```typescript
// 权限定义
const PERMISSIONS = {
  ADMIN: ['read', 'write', 'delete', 'manage_users'],
  EDITOR: ['read', 'write'],
  VIEWER: ['read'],
} as const;

// 角色检查中间件
function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user || !roles.includes(user.role)) {
      return res.status(403).json({ error: '权限不足' });
    }
    next();
  };
}

// 使用
app.delete('/api/users/:id', requireRole('ADMIN'), deleteUser);
```

### 4.2 Next.js Middleware 权限控制

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware';

export default withAuth({
  callbacks: {
    authorized: ({ token, req }) => {
      const path = req.nextUrl.pathname;

      // 管理页面需要admin权限
      if (path.startsWith('/admin')) {
        return token?.role === 'admin';
      }

      // 其他受保护页面只需登录
      return !!token;
    },
  },
});

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
};
```

### 4.3 ABAC（基于属性的访问控制）

```typescript
// 更细粒度的权限控制
interface Policy {
  effect: 'allow' | 'deny';
  action: string;
  resource: string;
  condition?: (user: User, resource: any) => boolean;
}

function checkPermission(user: User, action: string, resource: any): boolean {
  const policies = getUserPolicies(user);

  // 检查是否有拒绝策略
  const denyPolicy = policies.find(
    p => p.effect === 'deny' && p.action === action && matchResource(p.resource, resource)
  );
  if (denyPolicy) return false;

  // 检查是否有允许策略
  const allowPolicy = policies.find(
    p => p.effect === 'allow' && p.action === action && matchResource(p.resource, resource)
  );
  if (allowPolicy) {
    if (allowPolicy.condition) {
      return allowPolicy.condition(user, resource);
    }
    return true;
  }

  return false; // 默认拒绝
}
```

---

## 五、OAuth 2.0 集成

### 5.1 OAuth 2.0 授权流程

```
┌──────────┐                              ┌───────────────┐
│  用户    │                              │  OAuth Provider│
└────┬─────┘                              └───────┬───────┘
     │                                            │
     │  1. 点击登录                               │
     ├───────────────────────────────────────────→│
     │                                            │
     │  2. 授权页面                               │
     │←───────────────────────────────────────────┤
     │                                            │
     │  3. 用户授权                               │
     ├───────────────────────────────────────────→│
     │                                            │
     │  4. 返回授权码                             │
     │←───────────────────────────────────────────┤
     │                                            │
     │  5. 用授权码换取Token    (后端通信)         │
     │←──────────────────────────────────────────→│
```

### 5.2 GitHub OAuth 集成示例

```typescript
// 1. 注册 GitHub OAuth App
// https://github.com/settings/developers

// 2. 实现授权流程
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID;
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET;

// 重定向到GitHub授权页面
app.get('/auth/github', (req, res) => {
  const url = `https://github.com/login/oauth/authorize?client_id=${GITHUB_CLIENT_ID}&scope=user`;
  res.redirect(url);
});

// 回调处理
app.get('/auth/github/callback', async (req, res) => {
  const { code } = req.query;

  // 用code换取access_token
  const tokenRes = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      client_id: GITHUB_CLIENT_ID,
      client_secret: GITHUB_CLIENT_SECRET,
      code
    })
  });

  const { access_token } = await tokenRes.json();

  // 获取用户信息
  const userRes = await fetch('https://api.github.com/user', {
    headers: { Authorization: `Bearer ${access_token}` }
  });
  const user = await userRes.json();

  // 创建/更新用户，设置session
  // ...
});
```

### 5.3 NextAuth.js 多Provider配置

```typescript
import GithubProvider from 'next-auth/providers/github';
import GoogleProvider from 'next-auth/providers/google';
import WeChatProvider from 'next-auth/providers/wechat'; // 需要第三方包

providers: [
  GithubProvider({
    clientId: process.env.GITHUB_ID!,
    clientSecret: process.env.GITHUB_SECRET!,
  }),
  GoogleProvider({
    clientId: process.env.GOOGLE_ID!,
    clientSecret: process.env.GOOGLE_SECRET!,
  }),
]
```

---

## 六、安全防护清单

### 6.1 常见攻击与防护

| 攻击类型 | 防护措施 |
|---------|---------|
| XSS | HttpOnly Cookie, CSP头 |
| CSRF | SameSite Cookie, CSRF Token |
| 暴力破解 | 限流, 账户锁定 |
| Token泄露 | 短期Token, HTTPS |
| 会话固定 | 登录后重新生成Session ID |

### 6.2 密码安全

```typescript
import bcrypt from 'bcrypt';

// 加密
const hashedPassword = await bcrypt.hash(password, 12);

// 验证
const isValid = await bcrypt.compare(inputPassword, hashedPassword);
```

---

## 七、学习总结

### 今日要点
1. **JWT** 是无状态认证方案，适合API和微服务
2. **NextAuth.js** 简化了Next.js中的认证实现
3. **Session** 需要注意安全配置（HttpOnly、Secure等）
4. **RBAC** 是常用的权限控制模型
5. **OAuth 2.0** 是第三方登录的标准方案

### 实践建议
- 生产环境优先使用成熟的认证库
- 敏感数据不要存储在JWT Payload中
- 定期轮换密钥和Token
- 实施最小权限原则

### 明日计划
- 学习数据库设计与ORM
- 实践Prisma或Drizzle

---

*学习笔记 Day6 完成 ✅*
