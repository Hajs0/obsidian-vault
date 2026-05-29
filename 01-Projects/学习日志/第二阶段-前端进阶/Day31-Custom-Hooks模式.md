---
title: Day 31 - Custom Hooks 模式
date: 2026-05-29
tags:
  - react
  - hooks
  - frontend
  - 第二阶段
category: 前端进阶
status: completed
---

# Day 31 - Custom Hooks 模式

## 📚 学习目标
- 理解 Custom Hooks 的设计原则
- 掌握常用 Custom Hooks 的实现
- 学会抽取和复用逻辑

## 🎯 核心概念

### 1. 什么是 Custom Hooks？
Custom Hooks 是以 `use` 开头的函数，可以封装和复用状态逻辑。

**设计原则：**
- 命名以 `use` 开头
- 只能调用其他 Hooks
- 返回需要的值或函数
- 保持单一职责

### 2. 常用 Custom Hooks 模式

#### 数据获取 Hook
```typescript
// useFetch.ts
import { useState, useEffect } from 'react';

interface UseFetchResult<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

export function useFetch<T>(url: string): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('请求失败');
      const result = await response.json();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : '未知错误');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [url]);

  return { data, loading, error, refetch: fetchData };
}
```

#### localStorage Hook
```typescript
// useLocalStorage.ts
import { useState, useEffect } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue;
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}
```

#### 防抖 Hook
```typescript
// useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}
```

#### 窗口尺寸 Hook
```typescript
// useWindowSize.ts
import { useState, useEffect } from 'react';

interface WindowSize {
  width: number;
  height: number;
}

export function useWindowSize(): WindowSize {
  const [size, setSize] = useState<WindowSize>({
    width: window.innerWidth,
    height: window.innerHeight,
  });

  useEffect(() => {
    const handleResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return size;
}
```

#### 倒计时 Hook
```typescript
// useCountdown.ts
import { useState, useEffect, useCallback } from 'react';

export function useCountdown(initialSeconds: number) {
  const [seconds, setSeconds] = useState(initialSeconds);
  const [isRunning, setIsRunning] = useState(false);

  const start = useCallback(() => setIsRunning(true), []);
  const pause = useCallback(() => setIsRunning(false), []);
  const reset = useCallback(() => {
    setSeconds(initialSeconds);
    setIsRunning(false);
  }, [initialSeconds]);

  useEffect(() => {
    if (!isRunning || seconds <= 0) return;

    const timer = setInterval(() => {
      setSeconds(prev => {
        if (prev <= 1) {
          setIsRunning(false);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isRunning, seconds]);

  return { seconds, isRunning, start, pause, reset };
}
```

#### 表单验证 Hook
```typescript
// useForm.ts
import { useState, useCallback } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
  onSubmit: (values: T) => void | Promise<void>;
}

export function useForm<T extends Record<string, unknown>>({
  initialValues,
  validate,
  onSubmit,
}: UseFormOptions<T>) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback((name: keyof T, value: unknown) => {
    setValues(prev => ({ ...prev, [name]: value }));
    setErrors(prev => ({ ...prev, [name]: undefined }));
  }, []);

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (validate) {
      const validationErrors = validate(values);
      if (Object.keys(validationErrors).length > 0) {
        setErrors(validationErrors);
        return;
      }
    }

    setIsSubmitting(true);
    try {
      await onSubmit(values);
    } finally {
      setIsSubmitting(false);
    }
  }, [values, validate, onSubmit]);

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
  }, [initialValues]);

  return {
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
    reset,
  };
}
```

## 🔧 实战练习

### 练习 1：创建 useToggle Hook
```typescript
// useToggle.ts
import { useState, useCallback } from 'react';

export function useToggle(initialValue = false) {
  const [value, setValue] = useState(initialValue);

  const toggle = useCallback(() => setValue(prev => !prev), []);
  const setTrue = useCallback(() => setValue(true), []);
  const setFalse = useCallback(() => setValue(false), []);

  return { value, toggle, setTrue, setFalse };
}
```

### 练习 2：创建 usePrevious Hook
```typescript
// usePrevious.ts
import { useRef, useEffect } from 'react';

export function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();

  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref.current;
}
```

### 练习 3：创建 useMediaQuery Hook
```typescript
// useMediaQuery.ts
import { useState, useEffect } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    setMatches(media.matches);

    const listener = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener('change', listener);
    return () => media.removeEventListener('change', listener);
  }, [query]);

  return matches;
}
```

## 📝 最佳实践

### 1. 单一职责
每个 Hook 只负责一个逻辑，避免创建"万能 Hook"。

### 2. 返回值设计
```typescript
// 好：返回对象，易于扩展
return { data, loading, error };

// 不太好：返回数组，位置固定
return [data, loading, error];
```

### 3. 参数设计
```typescript
// 好：使用 options 对象
function useFetch(url: string, options?: RequestInit) { ... }

// 不太好：参数过多
function useFetch(url: string, method: string, headers: object, ...) { ... }
```

### 4. 错误处理
```typescript
// 好：返回错误状态
return { data, loading, error };

// 不好：直接抛出异常（除非明确要求）
throw new Error('...');
```

## 🎓 今日总结

**关键知识点：**
1. Custom Hooks 是复用状态逻辑的最佳方式
2. 命名必须以 `use` 开头
3. 只能在函数组件或其他 Hooks 中调用
4. 保持单一职责，易于测试和维护

**常用 Hooks 收藏：**
- `useFetch` - 数据获取
- `useLocalStorage` - 本地存储
- `useDebounce` - 防抖
- `useWindowSize` - 窗口尺寸
- `useForm` - 表单管理
- `useToggle` - 开关状态

**明日计划：**
- Day 32: Context + useReducer 高级状态管理
