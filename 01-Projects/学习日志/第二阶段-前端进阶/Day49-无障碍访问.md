---
title: Day 49 - 无障碍访问（a11y）
date: 2026-05-29
tags:
  - 无障碍访问
  - a11y
  - wai-aria
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 49 - 无障碍访问（a11y）

## 📚 学习目标
- 理解无障碍访问的重要性
- 掌握 WCAG 指南
- 学会实现无障碍组件

## 🎯 核心概念

### 1. 为什么需要无障碍访问

#### 无障碍的好处
- 扩大用户群体
- 提升 SEO
- 符合法律要求
- 提升用户体验

#### 无障碍人群
- 视觉障碍（色盲、低视力、失明）
- 听觉障碍（听力损失）
- 运动障碍（无法使用鼠标）
- 认知障碍（阅读困难）

### 2. WCAG 指南

#### 四大原则（POUR）
1. **可感知（Perceivable）**
   - 文本替代
   - 字幕和替代媒体
   - 可适应的内容
   - 可区分的内容

2. **可操作（Operable）**
   - 键盘可访问
   - 足够的时间
   - 不引发癫痫
   - 可导航

3. **可理解（Understandable）**
   - 可读性
   - 可预测性
   - 输入辅助

4. **健壮性（Robust）**
   - 兼容性
   - 辅助技术

### 3. ARIA 属性

#### 基本 ARIA 属性
```html
<!-- 角色 -->
<button role="button">提交</button>
<nav role="navigation">导航</nav>
<main role="main">主要内容</main>

<!-- 状态 -->
<button aria-disabled="true">禁用</button>
<button aria-pressed="true">已按下</button>
<input aria-invalid="true" aria-describedby="error" />

<!-- 属性 -->
<input aria-label="邮箱地址" />
<input aria-labelledby="label-id" />
<div aria-live="polite">动态内容</div>
```

#### 常见 ARIA 模式
```html
<!-- 模态框 -->
<div role="dialog" aria-modal="true" aria-labelledby="title">
  <h2 id="title">标题</h2>
  <button aria-label="关闭">×</button>
</div>

<!-- 选项卡 -->
<div role="tablist">
  <button role="tab" aria-selected="true" aria-controls="panel1">标签1</button>
  <button role="tab" aria-selected="false" aria-controls="panel2">标签2</button>
</div>
<div role="tabpanel" id="panel1">内容1</div>
<div role="tabpanel" id="panel2">内容2</div>

<!-- 菜单 -->
<div role="menu">
  <div role="menuitem">菜单项1</div>
  <div role="menuitem">菜单项2</div>
</div>

<!-- 进度条 -->
<div role="progressbar" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100">
  50%
</div>
```

### 4. 键盘导航

#### 焦点管理
```typescript
// 焦点陷阱
function Modal({ isOpen, onClose, children }) {
  const modalRef = useRef(null);

  useEffect(() => {
    if (isOpen && modalRef.current) {
      modalRef.current.focus();
    }
  }, [isOpen]);

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      onClose();
    }
    
    // 焦点陷阱
    if (e.key === 'Tab') {
      const focusableElements = modalRef.current.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  };

  return (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={handleKeyDown}
    >
      {children}
    </div>
  );
}
```

#### 跳过导航
```html
<a href="#main-content" class="skip-link">
  跳过导航
</a>
<nav>...</nav>
<main id="main-content">...</main>
```

```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
```

### 5. 表单无障碍

#### 标签关联
```html
<!-- 使用 label -->
<label for="email">邮箱</label>
<input type="email" id="email" />

<!-- 使用 aria-label -->
<input type="email" aria-label="邮箱" />

<!-- 使用 aria-labelledby -->
<span id="email-label">邮箱</span>
<input type="email" aria-labelledby="email-label" />
```

#### 错误提示
```html
<div>
  <label for="email">邮箱</label>
  <input
    type="email"
    id="email"
    aria-invalid="true"
    aria-describedby="email-error"
  />
  <span id="email-error" role="alert">
    请输入有效的邮箱地址
  </span>
</div>
```

#### 必填字段
```html
<label for="name">
  姓名 <span aria-hidden="true">*</span>
</label>
<input type="text" id="name" aria-required="true" />
```

### 6. 图片无障碍

#### 装饰性图片
```html
<img src="decorative.png" alt="" aria-hidden="true" />
```

#### 信息性图片
```html
<img src="chart.png" alt="2023年销售趋势：第一季度100万，第二季度150万" />
```

#### 复杂图片
```figure
<figure>
  <img src="complex-chart.png" alt="2023年销售趋势图" aria-describedby="chart-desc" />
  <figcaption id="chart-desc">
    详细描述图表内容...
  </figcaption>
</figure>
```

## 🔧 实战练习

### 练习 1：无障碍按钮
```typescript
function AccessibleButton({ children, onClick, disabled, ...props }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      aria-disabled={disabled}
      role="button"
      tabIndex={disabled ? -1 : 0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onClick?.();
        }
      }}
      {...props}
    >
      {children}
    </button>
  );
}
```

### 练习 2：无障碍模态框
```typescript
function AccessibleModal({ isOpen, onClose, title, children }) {
  const modalRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      modalRef.current?.focus();
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      tabIndex={-1}
      onKeyDown={(e) => {
        if (e.key === 'Escape') onClose();
      }}
    >
      <div className="modal-overlay" onClick={onClose} aria-hidden="true" />
      <div className="modal-content">
        <h2 id="modal-title">{title}</h2>
        <button
          onClick={onClose}
          aria-label="关闭"
          className="modal-close"
        >
          ×
        </button>
        {children}
      </div>
    </div>
  );
}
```

### 练习 3：无障碍表单
```typescript
function AccessibleForm({ onSubmit }) {
  const [errors, setErrors] = useState({});

  const handleSubmit = (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);
    
    // 验证
    const newErrors = {};
    if (!data.email) newErrors.email = '邮箱不能为空';
    if (!data.password) newErrors.password = '密码不能为空';
    
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }
    
    onSubmit(data);
  };

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">
          邮箱 <span aria-hidden="true">*</span>
        </label>
        <input
          type="email"
          id="email"
          name="email"
          aria-required="true"
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {errors.email && (
          <span id="email-error" role="alert" className="error">
            {errors.email}
          </span>
        )}
      </div>
      
      <div>
        <label htmlFor="password">
          密码 <span aria-hidden="true">*</span>
        </label>
        <input
          type="password"
          id="password"
          name="password"
          aria-required="true"
          aria-invalid={!!errors.password}
          aria-describedby={errors.password ? 'password-error' : undefined}
        />
        {errors.password && (
          <span id="password-error" role="alert" className="error">
            {errors.password}
          </span>
        )}
      </div>
      
      <button type="submit">登录</button>
    </form>
  );
}
```

## 📝 最佳实践

### 1. 使用语义化 HTML
```html
<!-- 好 -->
<button>提交</button>
<nav>导航</nav>
<main>主要内容</main>

<!-- 不好 -->
<div onclick="submit()">提交</div>
<div class="nav">导航</div>
<div class="main">主要内容</div>
```

### 2. 提供替代文本
```html
<!-- 好 -->
<img src="logo.png" alt="公司 Logo" />

<!-- 不好 -->
<img src="logo.png" />
```

### 3. 确保键盘可访问
```html
<!-- 好 -->
<button tabindex="0">可聚焦</button>

<!-- 不好 -->
<div onclick="handleClick()">不可聚焦</div>
```

### 4. 使用 ARIA 属性
```html
<!-- 好 -->
<button aria-label="关闭" aria-disabled="true">×</button>

<!-- 不好 -->
<button>×</button>
```

## 🎓 今日总结

**关键知识点：**
1. 无障碍访问扩大用户群体
2. WCAG 四大原则：可感知、可操作、可理解、健壮性
3. ARIA 属性提供语义信息
4. 键盘导航确保可操作性
5. 表单无障碍提升用户体验

**明日计划：**
- Day 50: 第七周总结
