# 工业管理 APP 原型 UI 样式提取

> 来源：`demo.niubi748.top` HTML 原型站点
> 提取日期：2026-05-21

---

## 1. 设计基准

| 项目 | 规格 |
|------|------|
| 画布尺寸 | 393 × 852 px（iPhone 14 Pro 逻辑分辨率） |
| 视口 | `width=393, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover` |
| 安全区顶部 | `env(safe-area-inset-top, 12px)` |
| 安全区底部 | `env(safe-area-inset-bottom, 8px)` |
| 字体 | Inter + system-ui + -apple-system + sans-serif |
| 图标库 | Font Awesome 6.5.1 Solid/Regular |
| CSS 框架 | Tailwind CSS（CDN）+ 少量自定义 CSS |

---

## 2. 色彩系统

### 2.1 品牌色

| 名称 | 色值 | Tailwind | 用途 |
|------|------|----------|------|
| 品牌主色 | `#0f766e` | `teal-700` | 主按钮、强调文字、选中态 |
| 品牌亮部 | `#14b8a6` | `teal-500` | hover、高亮 |
| 品牌浅底 | `teal-50` | `bg-teal-50` | 图标容器背景、选中项底色 |
| 品牌边框 | `teal-200/300` | `border-teal-200` | 选中边框、聚焦 ring |

### 2.2 中性色

| 名称 | Tailwind | 用途 |
|------|----------|------|
| 页面背景 | `bg-slate-100` | 全局页面底色 `#f1f5f9` |
| 卡片背景 | `bg-white` | 内容卡片、列表项 |
| 次级背景 | `bg-slate-50` | 信息块、只读输入框 `#f8fafc` |
| 主文字 | `text-slate-900` | 标题、核心内容 |
| 次级文字 | `text-slate-600/700` | 正文、标签 |
| 辅助文字 | `text-slate-500` | 描述、时间、提示 |
| 禁用/极弱 | `text-slate-400` | 占位符、次要说明 |
| 边框 | `border-slate-200` | 卡片边框、分割线 |
| 分割线 | `divide-slate-100` | 列表内部分隔 |

### 2.3 语义状态色

| 状态 | 主色 | 浅底 | 边框 | 图标色 |
|------|------|------|------|--------|
| 待派工 / 警告 | `amber-600/700` | `amber-50` | `amber-200/300` | `amber-700` |
| 已派工 / 信息 | `teal-600/700` | `teal-50` | `teal-200` | `teal-700` |
| 生产中 / 成功 | `emerald-600/700` | `emerald-50` | `emerald-200/300` | `emerald-700` |
| 待报工 / 天蓝 | `sky-700` | `sky-50` | — | `sky-700` |
| 异常 / 危险 | `rose-600` | `rose-50` | `rose-200` | `rose-500/600` |
| 已报工 / 工时 | `slate-800` | `slate-50` | — | `slate-700` |
| 工单列表 | `indigo-700` | `indigo-50` | — | `indigo-700` |
| 质检看板 | `rose-700` | `rose-50` | — | `rose-700` |

### 2.4 看板专用深色主题（质检看板 `qa-dashboard.html`）

| 元素 | 色值 |
|------|------|
| 页面背景 | `bg-slate-950` + 毛玻璃 |
| 卡片背景 | `bg-slate-900/60` + `backdrop-blur` + `border-cyan-300/25` |
| 强调色 | `cyan-300` 文字 + `cyan-400/10` 光晕 |
| Tab 激活 | `bg-cyan-300 text-slate-950` |
| Tab 未激活 | `border-cyan-300/25 bg-slate-900/60 text-cyan-100` |
| 正增长 | `text-emerald-300` |
| 负向/废品 | `text-rose-300` |

---

## 3. 字体排版

### 3.1 字号层级

| 层级 | 类名 | 像素 | 用途 |
|------|------|------|------|
| 大标题 | `text-2xl font-bold` | 24px | 首页问候语、看板核心数字 |
| 页面标题 | `text-lg font-bold` | 18px | 导航栏标题、区块标题 |
| 卡片标题 | `text-base font-bold` | 16px | 卡片内主标题 |
| 正文/标签 | `text-sm font-semibold` | 14px | 功能名称、列表标题 |
| 辅助说明 | `text-xs` | 12px | 描述文字、状态提示 |
| 极小字 | `text-[10px]` / `text-[11px]` | 10-11px | 时间、角标、提示、表格头 |
| 等宽编号 | `text-[10px] font-mono` | 10px | 工单号（如 `MO000003`） |
| 看板数字 | `text-4xl font-black` | 36px | KPI 大字（如 `96.8%`） |

### 3.2 字重

| 类名 | 用途 |
|------|------|
| `font-black` | 看板超大 KPI 数字 |
| `font-bold` | 标题、核心数据 |
| `font-semibold` | 按钮文字、列表主标题、标签 |
| `font-medium` | 角色徽章、次级标签 |
| `font-normal` | 正文（默认） |

---

## 4. 间距系统

### 4.1 页面边距

| 场景 | 类名 | 数值 |
|------|------|------|
| 页面水平边距 | `px-5` | 20px |
| 卡片内边距 | `p-4` | 16px |
| 紧凑内边距 | `p-3` | 12px |
| 底部安全区 | `pb-24` / `pb-10` | 96px / 40px |
| 顶部状态栏占位 | `.status-bar-spacer` | `safe-top + 8px` |

### 4.2 元素间距

| 场景 | 类名 | 数值 |
|------|------|------|
| 卡片间隙 | `gap-3` / `space-y-3` | 12px |
| 紧密间隙 | `gap-2` | 8px |
| 区块间隙 | `space-y-4` / `space-y-5` | 16-20px |
| 图标文字间距 | `gap-2` / `gap-3` | 8-12px |

---

## 5. 圆角系统

| 类名 | 数值 | 用途 |
|------|------|------|
| `rounded-3xl` | 24px | 大卡片、看板区块、头像外框 |
| `rounded-2xl` | 16px | 标准卡片、按钮、信息块、图标容器 |
| `rounded-xl` | 12px | 小信息块、输入框、列表项、图标底色 |
| `rounded-lg` | 8px | 状态徽章、小标签 |
| `rounded-full` | 999px | 角色徽章、返回按钮、通知按钮 |
| `rounded-full (SVG)` | 50% | 状态弹窗成功图标（72px） |

---

## 6. 阴影与效果

| 类名 | 用途 |
|------|------|
| `shadow-sm` | 卡片轻微浮起 |
| `backdrop-blur` | 看板毛玻璃头部、底部导航 |
| `ring-1 ring-{color}-200` | 待办卡片边框强调（如 `ring-teal-200`） |
| `ring-2 ring-teal-100` | 头像聚焦环 |
| `focus:ring-2 focus:ring-teal-200` | 输入框聚焦态 |

---

## 7. 布局模式

### 7.1 页面结构

```
body (bg-slate-100 text-slate-900)
  └─ .phone-scroll (no-scrollbar overflow-y-auto max-h-[852px])
      ├─ .status-bar-spacer
      ├─ header (sticky top-0)
      └─ main (px-5 pb-24 space-y-4)
```

### 7.2 常用布局类

| 布局 | 类名 |
|------|------|
| 单列卡片堆叠 | `space-y-3/4` |
| 双列信息网格 | `grid grid-cols-2 gap-3` |
| 三列信息网格 | `grid grid-cols-3 gap-3` |
| 三列快捷入口 | `grid grid-cols-3 gap-3` |
| 四列快捷入口 | `grid grid-cols-4 gap-3` |
| 横向弹性布局 | `flex items-center gap-3` |
| 两端对齐 | `flex items-center justify-between` |
| 左侧图标+右侧文字 | `flex items-start gap-3`（左侧 shrink-0，右侧 min-w-0 flex-1） |

---

## 8. 组件样式详解

### 8.1 顶部导航栏

```html
<header class="px-5 pt-2 pb-3 flex items-center gap-3
               border-b border-slate-200/80
               bg-slate-100 sticky top-0 z-10">
  <!-- 返回按钮 -->
  <button class="h-9 w-9 rounded-full bg-white border border-slate-200
                 flex items-center justify-center text-slate-600">
    <i class="fa-solid fa-chevron-left"></i>
  </button>

  <!-- 标题区 -->
  <div class="flex-1 min-w-0">
    <p class="text-[10px] font-mono text-teal-700 font-semibold">MO000003</p>
    <h1 class="text-base font-bold truncate">工单详情 · 待派工</h1>
  </div>

  <!-- 右侧操作 -->
  <button class="text-xs font-semibold text-teal-700">修改</button>
</header>
```

### 8.2 按钮规范

| 类型 | 样式 |
|------|------|
| **主按钮（全局操作）** | `w-full rounded-2xl bg-teal-600 py-3 text-sm font-semibold text-white` |
| **派工按钮** | `bg-amber-600` |
| **去生产按钮** | `bg-emerald-600` |
| **报工按钮** | `bg-sky-600` 或 `bg-teal-600` |
| **危险按钮（报废）** | `bg-rose-600` |
| **操作员选择（未选中）** | `rounded-xl bg-slate-100 text-slate-600 py-3 text-xs font-semibold border border-slate-200` |
| **操作员选择（选中）** | `rounded-xl bg-teal-50 text-teal-700 py-3 text-xs font-semibold border-2 border-teal-300` |
| **文字按钮** | `text-xs font-semibold text-teal-700` |
| **图标按钮** | `h-9/10 w-9/10 rounded-full bg-white border border-slate-200 text-slate-600` |

### 8.3 卡片规范

**标准内容卡片**
```html
<section class="rounded-2xl bg-white border border-slate-200 p-4 shadow-sm">
```

**强调状态卡片（待办）**
```html
<div class="rounded-2xl bg-white border border-slate-200 p-4
            shadow-sm ring-1 ring-teal-200">
```

**信息提示卡片**
```html
<!-- 待派工提示 -->
<section class="rounded-2xl bg-amber-50 border border-amber-200 px-4 py-3
               flex items-center gap-3">

<!-- 去生产提示 -->
<section class="rounded-2xl bg-emerald-50 border-2 border-emerald-300 p-4">

<!-- 异常提示 -->
<div class="rounded-xl bg-rose-50 border border-rose-200 p-3
            flex items-center gap-2">
```

**信息块（网格内）**
```html
<div class="rounded-xl bg-slate-50 p-3">
  <p class="text-[10px] text-slate-500">标签</p>
  <p class="font-semibold mt-1">值</p>
</div>
```

### 8.4 图标容器

| 尺寸 | 圆角 | 用途 |
|------|------|------|
| `h-11 w-11 rounded-2xl` | 16px | 快捷入口大图标 |
| `h-10 w-10 rounded-xl` | 12px | 列表项图标、状态提示图标 |
| `h-9 w-9 rounded-xl` | 12px | 设置列表图标 |

图标容器统一使用 `{color}-50` 背景 + `{color}-700` 图标色。

### 8.5 状态徽章

```html
<!-- 待派工 -->
<span class="px-2 py-1 rounded-lg bg-amber-50 text-amber-700 text-[10px] font-semibold">

<!-- 已派工 -->
<span class="px-2 py-1 rounded-lg bg-teal-50 text-teal-700 text-[10px] font-semibold">

<!-- 生产中 -->
<span class="px-2 py-1 rounded-lg bg-emerald-50 text-emerald-700 text-[10px] font-semibold">

<!-- 角色徽章 -->
<span class="inline-flex items-center rounded-full bg-slate-800 px-2.5 py-1
            text-white text-xs font-medium">
```

### 8.6 输入框

```html
<select class="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5
               text-sm bg-slate-50 outline-none
               focus:ring-2 focus:ring-teal-200">
```

### 8.7 待办卡片（TodoCard）

```html
<div class="cursor-pointer rounded-2xl bg-white border border-slate-200 p-4
            shadow-sm ring-1 ring-{semantic-color}-200">
  <div class="flex items-start gap-3">
    <!-- 左侧图标 -->
    <div class="h-10 w-10 rounded-xl bg-{color}-50 text-{color}-700
                flex items-center justify-center shrink-0">
      <i class="fa-solid fa-{icon}"></i>
    </div>
    <!-- 右侧内容 -->
    <div class="min-w-0 flex-1">
      <p class="text-sm font-semibold text-slate-900">标题 · 状态</p>
      <p class="text-xs text-slate-500 mt-1">描述信息</p>
      <p class="text-[11px] text-{color}-700 font-medium mt-2">操作提示</p>
    </div>
  </div>
</div>
```

### 8.8 底部导航栏

```html
<nav class="fixed bottom-0 left-0 right-0 max-w-[393px] mx-auto
            bg-white/95 backdrop-blur border-t border-slate-200
            px-6 py-2 flex justify-between text-[10px] text-slate-500"
     style="padding-bottom: max(10px, env(safe-area-inset-bottom, 10px));">
  <!-- 当前激活项 -->
  <div class="flex flex-col items-center gap-1 text-teal-700 font-semibold">
    <i class="fa-solid fa-house text-lg"></i> 工作台
  </div>
  <!-- 未激活项 -->
  <div class="cursor-pointer flex flex-col items-center gap-1">
    <i class="fa-solid fa-database text-lg"></i> 数据
  </div>
</nav>
```

### 8.9 状态变更弹窗（自定义动画）

```css
.status-overlay {
  position: fixed; inset: 0; z-index: 200;
  display: flex; align-items: center; justify-content: center;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(6px);
  opacity: 0; transition: opacity .3s ease;
}
.status-card {
  background: #fff; border-radius: 28px;
  padding: 36px 28px 28px; text-align: center;
  max-width: 310px; width: 85%;
  transform: scale(.88) translateY(24px);
  transition: transform .35s cubic-bezier(.34,1.56,.64,1);
}
.status-check {
  width: 72px; height: 72px; border-radius: 50%;
  animation: st-pop .45s cubic-bezier(.34,1.56,.64,1) .15s both;
}
```

关键帧动画：
- `st-pop`：从 `scale(0)` 弹入
- `st-draw`：SVG 对勾描边动画
- `st-arrow`：箭头滑入

---

## 9. 页面级差异

### 9.1 普通页面（工单、产线、个人中心）

- 背景：`bg-slate-100`
- 文字：`text-slate-900`
- 导航栏：`bg-slate-100 border-b border-slate-200/80`
- 卡片：`bg-white border border-slate-200`

### 9.2 质检看板（深色主题）

- 背景：`bg-slate-950 text-white`
- 头部：`backdrop-blur bg-slate-950/70 border-b border-cyan-400/15`
- 卡片：`bg-slate-900/60 backdrop-blur border-cyan-300/25`
- 强调：`cyan-300` 为主视觉色
- Tab 切换：胶囊式圆角全满 `rounded-full`

---

## 10. ArkUI 映射建议

将以上 Tailwind 类名映射到 HarmonyOS ArkUI 时，可参考以下对应关系：

| Tailwind | ArkUI 属性 |
|----------|-----------|
| `bg-slate-100` | `.backgroundColor('#f1f5f9')` |
| `bg-white` | `.backgroundColor('#ffffff')` |
| `bg-teal-600` | `.backgroundColor('#0d9488')` |
| `text-slate-900` | `.fontColor('#0f172a')` |
| `text-teal-700` | `.fontColor('#0f766e')` |
| `rounded-2xl` | `.borderRadius(16)` |
| `rounded-xl` | `.borderRadius(12)` |
| `rounded-full` | `.borderRadius(999)` |
| `shadow-sm` | `.shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })` |
| `border border-slate-200` | `.border({ width: 1, color: '#e2e8f0' })` |
| `px-5 py-4` | `.padding({ left: 20, right: 20, top: 16, bottom: 16 })` |
| `flex items-center gap-3` | `.layoutWeight(1)` + `.alignItems(VerticalAlign.Center)` |
| `sticky top-0` | 使用 `Scroll` + `Sticky` 或自定义实现 |
| `backdrop-blur` | `.backdropBlur(10)`（API 12+）或自定义模糊层 |
| `no-scrollbar` | `.scrollBar(BarState.Off)` |
