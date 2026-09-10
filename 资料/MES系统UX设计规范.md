# MES 系统 UX 设计规范

> 基于 ui-ux-pro-max Design Intelligence 生成，适配 HarmonyOS ArkUI V2 前端
> 生成日期：2026-06-12

---

## 目录

1. [设计总览](#1-设计总览)
2. [品牌规范](#2-品牌规范)
3. [色彩系统](#3-色彩系统)
4. [排版系统](#4-排版系统)
5. [间距与布局](#5-间距与布局)
6. [阴影与立面](#6-阴影与立面)
7. [组件规范](#7-组件规范)
8. [交互模式](#8-交互模式)
9. [导航规范](#9-导航规范)
10. [数据可视化](#10-数据可视化)
11. [无障碍规范](#11-无障碍规范)
12. [暗色模式策略](#12-暗色模式策略)
13. [文件清单](#13-文件清单)

---

## 1. 设计总览

### 产品定位

| 维度 | 描述 |
|------|------|
| 产品类型 | MES（制造执行系统）工业管理移动应用 |
| 目标用户 | 工厂车间操作员、班组长、质检员、管理员 |
| 使用场景 | 车间现场（手持设备）、办公室（平板）、低光/高噪环境 |
| 核心任务 | 工单状态追踪、生产进度监控、质检记录、异常处理 |

### 设计风格

**Data-Dense Dashboard** (数据密集型看板)

ui-ux-pro-max 推荐理由：MES 系统以实时数据监控为核心，需要高数据密度、清晰的信息层级、快速的状态识别。数据密集型风格强调空间效率、多图表组件、KPI 卡片和网格布局，与工业管理场景高度匹配。

| 特性 | 说明 |
|------|------|
| 光照模式 | Light ✓ Full / Dark ✓ Full |
| 关键词 | 多图表组件、数据表格、KPI 卡片、最小边距、网格布局、最大数据可见性 |
| 性能 | 优秀 |
| 无障碍 | WCAG AA |

### 设计原则

1. **数据优先** — 关键指标一目了然，减少导航层级
2. **状态可视** — 颜色 + 图标 + 文字三重编码状态信息
3. **操作快捷** — 高频操作 ≤ 2 步完成，关键操作有确认
4. **工业可靠** — 触摸目标 ≥ 44vp，错误有恢复路径
5. **环境适应** — 支持强光/低光，预留暗色模式

---

## 2. 品牌规范

### 品牌色彩

| 角色 | 色值 | 用途 |
|------|------|------|
| 主色 (Primary) | `#1565C0` | 导航栏、主按钮、标签页选中态、标题下划线 |
| 主色深 (Primary Dark) | `#0D47A1` | 渐变色终点、深色背景头部 |
| 主色浅 (Primary Light) | `#1890ff` | 次要蓝色元素、信息提示 |
| 辅助色 (Accent) | `#4CAF50` | 良品率、完成状态、成功反馈 |

### 功能色

| 语义 | 色值 | 用途 |
|------|------|------|
| 成功/良品 | `#4CAF50` / `#E8F5E9` | 生产中、完工、合格 |
| 警告/暂停 | `#FF9800` / `#FFF3E0` | 暂停中、让步接收、待处理 |
| 错误/报废 | `#F44336` / `#FFEBEE` | 报废、故障、不合格 |
| 信息/派工 | `#1890ff` / `#E3F2FD` | 已派工、提示信息 |

### 中性色

| 色值 | 用途 |
|------|------|
| `#1A1A2E` | 主文字色 |
| `#5A5A6E` | 次要文字色 |
| `#9A9AA8` | 辅助文字色、禁用态 |
| `#F5F7FA` | 页面背景 |
| `#FFFFFF` | 卡片/表面背景 |
| `#E8EBF0` | 分割线、边框 |

### 图标规范

- 统一使用 ArkUI SymbolGlyph 或 SVG 图标
- 禁止使用 emoji 作为结构性图标
- 同一视觉层使用一致的描边宽度（1.5px 或 2px）
- 同一层级使用统一的填充/线性风格

---

## 3. 色彩系统

### 架构：三层令牌模型

```
Primitive Tokens (基础色板)
    ↓
Semantic Tokens (语义令牌: primary, success, error, text...)
    ↓
Component Tokens (组件令牌: statusColors, roleColors, chartPalette...)
```

### 完整色板

#### Primitive Tokens

```typescript
// Blue 系列
blue-900: #0D47A1    blue-800: #1155B7    blue-700: #1565C0
blue-500: #1890ff    blue-50:  #E3F2FD

// Green 系列
green-600: #4CAF50   green-500: #52c41a   green-50:  #E8F5E9

// Red 系列
red-600: #F44336     red-500: #f5222d     red-50:    #FFEBEE

// Orange 系列
orange-600: #FF9800  orange-500: #faad14  orange-400: #fa8c14
orange-50:  #FFF3E0

// Purple 系列
purple-600: #722ed1  purple-50: #F3E5F5

// Teal 系列
teal-600: #00897B    teal-500: #13c2c2    teal-50:   #E0F2F1

// Gray 系列
gray-900: #1A1A2E    gray-700: #334155    gray-600: #5A5A6E
gray-500: #9A9AA8    gray-400: #999999    gray-200: #E8EBF0
gray-100: #F5F7FA    gray-50:  #F8FAFC    white:     #FFFFFF
```

#### Semantic Tokens (Colors 类)

| 令牌 | 色值 | 说明 |
|------|------|------|
| `Colors.primary` | `#1565C0` | 品牌主色 |
| `Colors.onPrimary` | `#FFFFFF` | 主色上的文字/图标 |
| `Colors.primaryDark` | `#0D47A1` | 深色变体 |
| `Colors.primaryLight` | `#1890ff` | 亮色变体 |
| `Colors.primaryBg` | `#E3F2FD` | 主色浅底 |
| `Colors.background` | `#F5F7FA` | 页面背景 |
| `Colors.surface` | `#FFFFFF` | 卡片/表面 |
| `Colors.foreground` | `#1A1A2E` | 前景色 |
| `Colors.textPrimary` | `#1A1A2E` | 主文字 |
| `Colors.textSecondary` | `#5A5A6E` | 次要文字 |
| `Colors.textMuted` | `#9A9AA8` | 辅助文字 |
| `Colors.border` | `#E8EBF0` | 边框/分割线 |
| `Colors.success` | `#4CAF50` | 成功/良品 |
| `Colors.warning` | `#FF9800` | 警告/暂停 |
| `Colors.error` | `#F44336` | 错误/报废 |
| `Colors.info` | `#1890ff` | 信息/提示 |
| `Colors.overlay` | `rgba(0,0,0,0.45)` | 模态遮罩 |

#### Component Tokens

**工单状态色** (9 种状态，每种含前景/背景)：

| 状态 | 前景色 | 背景色 |
|------|--------|--------|
| 待派工 | `#1565C0` | `#E3F2FD` |
| 已派工 | `#1890ff` | `#E6F7FF` |
| 生产中 | `#4CAF50` | `#E8F5E9` |
| 暂停中 | `#FF9800` | `#FFF3E0` |
| 生产完成 | `#722ED1` | `#F3E5F5` |
| 已报工 | `#00897B` | `#E0F2F1` |
| 完工 | `#4CAF50` | `#E8F5E9` |
| 报废 | `#F44336` | `#FFEBEE` |
| 异常 | `#F44336` | `#FFEBEE` |

**角色色**：

| 角色 | 头像色 | 徽章色 |
|------|--------|--------|
| 管理员 admin | `#EF5350` | `#F44336` / `#FFEBEE` |
| 班组长 leader | `#42A5F5` | `#1565C0` / `#E3F2FD` |
| 操作员 operator | `#66BB6A` | `#4CAF50` / `#E8F5E9` |
| 质检员 inspector | `#FFA726` | `#FF9800` / `#FFF3E0` |

**设备/产线状态色**：

| 状态 | 色值 |
|------|------|
| 运行中 | `#52c41a` / `#4CAF50` |
| 故障 | `#f5222d` / `#F44336` |
| 空闲 | `#999999` / `#9A9AA8` |

---

## 4. 排版系统

### 字体

| 角色 | 字体 | 备选 |
|------|------|------|
| 系统默认 | HarmonyOS Sans (系统) | — |
| 数据展示 | 系统等宽字体 | Fira Code (web) |

### 字号层级

```
Caption:  10vp — 小徽章、标签、统计标注
Label:    12vp — 标签、状态文字、标签页、辅助信息
Body:     14vp — 正文、列表项、输入框
Subtitle: 15vp — 卡片标题、列表项名称
Title:    18vp — 页面标题、对话框标题
Heading:  20vp — KPI 值、用户名称
Hero:     24vp — 大型关键指标
```

### 完整字号表

| 令牌 | 值 | 用途 |
|------|-----|------|
| `text10` | 10vp | 小徽章、统计标签 |
| `text11` | 11vp | 字段标签 |
| `text12` | 12vp | 辅助文字、标签页、状态文字 |
| `text13` | 13vp | 描述文字、次要值 |
| `text14` | 14vp | 正文、列表项 |
| `text15` | 15vp | 卡片标题 |
| `text16` | 16vp | 大正文、数据值 |
| `text18` | 18vp | 页面标题 |
| `text20` | 20vp | KPI 值 |
| `text22` | 22vp | 大 KPI |
| `text24` | 24vp | 超大指标 |
| `text28` | 28vp | 良品率大字 |
| `text36` | 36vp | 环形进度百分比 |

### 字重

| 令牌 | 值 | 用途 |
|------|-----|------|
| `weightRegular` | 400 | 正文 |
| `weightMedium` | 500 | 标签、标签页 |
| `weightSemibold` | 600 | 卡片标题、按钮、强调文字 |
| `weightBold` | 700 | 页面标题、KPI 值 |

### 行高

| 令牌 | 比率 | 用途 |
|------|------|------|
| `lineHeightTight` | 1.2 | 标题、KPI 值 |
| `lineHeightNormal` | 1.5 | 正文、列表 |
| `lineHeightRelaxed` | 1.75 | 长文本说明 |

### 预设样式

| 样式 | fontSize | fontWeight | fontColor |
|------|----------|------------|-----------|
| pageTitle | 18 | 700 | `#1A1A2E` |
| sectionTitle | 14 | 600 | `#1A1A2E` |
| cardTitle | 15 | 600 | `#1A1A2E` |
| bodyText | 14 | 400 | `#5A5A6E` |
| captionText | 12 | 400 | `#9A9AA8` |
| kpiValue | 24 | 700 | `#1565C0` |
| fieldLabel | 11 | 400 | `#9A9AA8` |
| fieldValue | 14 | 600 | `#1A1A2E` |

---

## 5. 间距与布局

### 基准网格：4dp 系统

所有间距以 4dp 为基准递增，确保视觉节奏一致。

```
基础间距: 2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 36, 48
```

### 语义间距

| 令牌 | 值 | 用途 |
|------|-----|------|
| `pageHorizontal` | 16vp | 页面左右边距 |
| `pageTop` | 16vp | 页面顶部边距 |
| `pageBottom` | 28vp | 页面底部边距（避开手势区） |
| `cardPaddingH` | 16vp | 卡片水平内边距 |
| `cardPaddingV` | 16vp | 卡片垂直内边距 |
| `cardGap` | 12vp | 卡片之间间距 |
| `listItemGap` | 8vp | 列表项间距 |
| `listSectionGap` | 12vp | 列表分区间距 |
| `formFieldGap` | 16vp | 表单字段间距 |
| `formLabelGap` | 4vp | 字段标签与值的间距 |
| `sectionTitleBottom` | 10vp | 分区标题下边距 |
| `sectionTitleMargin` | 14vp | 分区标题外边距 |
| `buttonPaddingH` | 16vp | 按钮水平内边距 |
| `buttonPaddingV` | 12vp | 按钮垂直内边距 |
| `buttonGap` | 12vp | 按钮之间间距 |

### 圆角

| 令牌 | 值 | 用途 |
|------|-----|------|
| `radiusSm` | 4vp | 标签、小徽章 |
| `radiusMd` | 8vp | 紧凑卡片、输入框 |
| `radiusLg` | 12vp | 标准卡片 |
| `radiusXl` | 16vp | 状态卡片、大卡片 |
| `radiusFull` | 20vp | 圆角标签 |
| `radiusRound` | 9999vp | 圆形（头像） |

### 响应式断点

| 断点 | 宽度 | 布局 |
|------|------|------|
| sm | < 600vp | 4 Tab 底部导航，全宽内容 |
| md | 600-840vp | 120vp 侧栏 + 内容区 |
| lg | ≥ 840vp | 160vp 侧栏 + 内容区 |

### 触摸目标

所有交互元素最小尺寸：**44 × 44vp** (iOS HIG) / **48 × 48dp** (Material Design)

项目采用 **44vp** 标准，图标小于 44vp 时扩展点击区域。

### 安全区域

- 顶部：避开状态栏（status bar）
- 底部：避开手势指示条（gesture bar），底部操作栏需额外 28vp padding
- 左右：避开曲面屏边缘

---

## 6. 阴影与立面

### 立面层级

| 层级 | 令牌 | 用途 | radius | color | offsetY |
|------|------|------|--------|-------|---------|
| 0 | `Shadows.none` | 扁平元素 | 0 | transparent | 0 |
| 1 | `Shadows.cardCompact` | 列表项 | 8 | `rgba(0,0,0,0.04)` | 1 |
| 2 | `Shadows.card` | 标准卡片 | 16 | `rgba(0,0,0,0.06)` | 2 |
| 3 | `Shadows.elevated` | 下拉/弹窗 | 20 | `rgba(0,0,0,0.12)` | 4 |
| 4 | `Shadows.modal` | 对话框 | 24 | `rgba(0,0,0,0.20)` | 8 |

### 特殊阴影

| 令牌 | 用途 |
|------|------|
| `Shadows.bottomBar` | 底部操作栏 — 顶部边框阴影 |
| `Shadows.buttonGlow` | 主操作按钮发光效果 |

---

## 7. 组件规范

### 7.1 卡片 (Card)

**标准卡片** — 应用的通用容器：

```
属性:
  padding: 16vp
  borderRadius: 12vp
  backgroundColor: #FFFFFF
  shadow: { radius: 16vp, color: rgba(0,0,0,0.06), offsetY: 2 }

何时使用:
  - 列表项内容容器
  - 详情页信息分区
  - 设置项分组

变体:
  - 紧凑卡片: borderRadius 8vp, shadow compact
  - 无阴影卡片: shadow none (用于嵌套结构)
```

**数据卡片 (KpiCard)** — 单一指标展示：

```
属性:
  title: 12vp, #9A9AA8
  value: 24-28vp, bold, 语义色
  padding: 16vp
  borderRadius: 8vp
  backgroundColor: #FFFFFF

何时使用:
  - 看板 KPI 网格
  - 首页统计数字
  - 详情页产量数据
```

### 7.2 状态标签 (StatusTag)

```
属性:
  fontSize: 12vp
  padding: { left: 8vp, right: 8vp, top: 2vp, bottom: 2vp }
  borderRadius: 4vp
  fontColor: 状态前景色
  backgroundColor: 状态前景色 + 20% 透明度

何时使用:
  - 工单列表中状态预览
  - 检验结论标签
  - 产线状态指示

状态色见 §3 色彩系统 → Component Tokens → 工单状态色
```

### 7.3 页面头部 (Page Header)

```
结构:
  Row {
    Image(back_icon).width(20).height(20) // 返回按钮
    Text(title).fontSize(18).fontWeight(700) // 居中标题
    Row().width(36).height(36) // 右侧占位（居中用）
  }
  padding: { left: 16vp, right: 16vp, top: 16vp, bottom: 12vp }
  backgroundColor: #FFFFFF
  border: { width: { bottom: 1vp }, color: #E8EBF0 }
```

### 7.4 分区标题 (Section Title)

```
属性:
  fontSize: 14vp
  fontWeight: 600
  fontColor: #1A1A2E
  padding: { bottom: 10vp }
  border: { width: { bottom: 1vp }, color: #E8EBF0 }
  width: 100%
  margin: { bottom: 14vp }
```

### 7.5 信息网格 (2-Column Info Grid)

```
结构:
  Flex({ wrap: FlexWrap.Wrap }) {
    Column() { // 每项占 50% 宽度
      Text('字段标签').fontSize(11).fontColor('#9A9AA8')
      Text('字段值').fontSize(14).fontWeight(600).fontColor('#1A1A2E')
    }
    .width('50%').margin({ bottom: 12vp })
  }
```

### 7.6 底部操作栏 (Bottom Action Bar)

```
属性:
  Row({ space: 12vp }) {
    Button('次要操作')...
    Button('主要操作')...
  }
  padding: { left: 16vp, right: 16vp, top: 12vp, bottom: 28vp }
  backgroundColor: #FFFFFF
  border: { width: { top: 1vp }, color: #E8EBF0 }
```

### 7.7 状态横幅 (Status Banner)

```
属性:
  Column {
    Row { statusTag }  // 状态标签
    Text(code).fontSize(13).fontColor('rgba(255,255,255,0.9)')
    Text(productName).fontSize(16).fontWeight(600).fontColor(white)
    Text(info).fontSize(13).fontColor('rgba(255,255,255,0.85)')
  }
  padding: 20vp
  backgroundColor: 状态色
  borderRadius: 16vp

状态背景色:
  待派工: #1565C0    生产中: #4CAF50    暂停中: #E65100
  生产完成: #FF9800   已报工/完工: #00897B / #4CAF50
  报废: #F44336
```

### 7.8 对话框/弹窗 (Dialog/Overlay)

```
结构:
  Stack {
    // 遮罩层
    Column().width('100%').height('100%')
      .backgroundColor('rgba(0,0,0,0.45)')
      .onClick(dismiss)

    // 弹窗内容
    Column { ... }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
  }
```

### 7.9 加载/空/错误状态

- **加载中**: `LoadingState` 组件 — 居中 spinner (`#1565C0`) + 可选文字
- **空数据**: `EmptyState` 组件 — 居中图标 + 标题 (`#5A5A6E`) + 可选操作按钮
- **错误**: `ErrorState` 组件 — 红色标题 (`#F44336`) + 消息 + 重试按钮

### 7.10 产线卡片 (LineCard)

```
属性:
  Row {
    Column { // 左侧图标
      Image(icon).width(40).height(40)
        .backgroundColor(状态色 20%)
        .borderRadius(8)
    }
    Column { // 中间信息
      Text(name).fontSize(15).fontWeight(600)
      StatusTag(status)
    }
    Column { // 右侧指标
      Text(progress).fontSize(13).fontWeight(600)
      Text(yield).fontSize(13).fontWeight(600)
      Text(output).fontSize(13).fontWeight(600)
    }
  }
  padding: 16vp
  backgroundColor: #FFFFFF
  borderRadius: 12vp
```

### 7.11 工位卡片 (StationCard)

```
属性:
  Column {
    Row {
      Text(opCode).fontSize(14).fontWeight(700)
      Text(name).fontSize(13)
    }
    Text(deviceStatus).fontSize(12) // 设备状态
    Row {
      Text(raw).fontSize(13).fontWeight(600)   // 来料
      Text(finished).fontSize(13).fontWeight(600) // 成品
      Text(ng).fontSize(13).fontWeight(600)    // 不良
    }
  }
  padding: 12vp
  backgroundColor: #FFFFFF
  borderRadius: 8vp
  borderLeft: 4vp solid 设备状态色  // 关键视觉特征
```

---

## 8. 交互模式

### 8.1 按钮交互

| 状态 | 行为 |
|------|------|
| 默认 | 正常色值，cursor pointer |
| 按压 (Pressed) | 缩放 0.97 + 透明度变化 (150ms ease-out) |
| 加载中 (Loading) | 禁用 + spinner 替代文字 |
| 禁用 (Disabled) | 透明度 0.38-0.5 + 无点击响应 |

### 8.2 列表交互

| 操作 | 行为 |
|------|------|
| 下拉刷新 | `Refresh` 组件包裹，下拉触发 `loadData()` |
| 滚动加载 | 触底加载更多（如需要） |
| 点击项 | 导航到详情页，150ms 按压反馈 |
| 长按 | 批量选择模式（如需要） |
| 空状态 | EmptyState 组件 |

### 8.3 表单交互

| 规则 | 说明 |
|------|------|
| 标签可见 | 每个输入框有可见标签（非 placeholder 替代） |
| 内联校验 | blur 时校验，非按键校验 |
| 错误展示 | 错误信息显示在对应字段下方 |
| 提交反馈 | 按钮显示 loading → success/error |
| 必填标识 | 必填字段加星号 |
| 键盘类型 | 数字字段触发数字键盘 |

### 8.4 确认流程

**关键操作前必须确认**（使用 Dialog）：
- 启动/停止产线
- 报废工单
- 删除记录
- 退出登录
- 重置设备

**Toast 反馈**（3-5 秒自动消失）：
- 操作成功
- 操作失败 + 原因
- 撤销提示

### 8.5 WebSocket 实时更新

- 连接指示器：LineDetailView 头部显示连接状态（绿点/红点 + 文字）
- 指数退避重连：2s × 2^attempt（上限 30s，最多 10 次）
- 心跳：30s 间隔
- 数据推送到达时：平滑更新数字（非跳变）

### 8.6 动效规范

| 属性 | 值 |
|------|-----|
| 微交互时长 | 150-300ms |
| 复杂过渡 | ≤ 400ms |
| 进入动画 | ease-out |
| 退出动画 | ease-in（~60-70% 进入时长） |
| 列表交错进入 | 30-50ms/项的延迟 |
| 模态进入 | 缩放+淡入，从触发源展开 |

**遵循规则**：
- 只使用 `transform` / `opacity` 做动画（不改变 width/height）
- 动画必须可中断（用户点击立即取消）
- 动画期间不阻塞用户输入
- 尊重 `prefers-reduced-motion`

---

## 9. 导航规范

### 9.1 顶层导航

```
sm (< 600vp):  4 个底部 Tab
  [工作台] [数据中心] [工单] [我的]

md (600-840):   120vp 左侧栏 + 内容区
lg (≥ 840):     160vp 左侧栏 + 内容区
```

### 9.2 导航栈

| Tab | NavPathStack | 目标页面 |
|-----|-------------|---------|
| 工作台 (Home) | 主页面栈 | AdminHome / OperatorHome / LeaderHome / InspectorHome |
| 数据中心 (Data) | dataStack | LineList → LineDetail → StationDetail, InspectionList → InspectionDetail, Dashboard, ExceptionList → ExceptionDetail |
| 工单 (WorkOrder) | workOrderStack | WorkOrderList → 各状态 Detail, WorkOrderAdd/Edit/Copy → WorkOrderForm |
| 我的 (Profile) | profileStack | Profile, EmployeeList |

### 9.3 导航规则

- 底部导航 ≤ 5 项（当前 4 项符合 Material Design 规范）
- 每个导航项必须有图标 + 文字（非纯图标）
- 当前页面对应的导航项高亮显示
- 返回按钮始终在左上角，保持导航栈完整性
- 返回时恢复滚动位置和筛选状态
- 模态框不使用导航栈（独立层级）
- 关键页面支持深度链接
- 跨 Tab 导航使用 DeepLink 模式

### 9.4 DeepLink 跨 Tab 导航

```typescript
// 从工单详情跳转到数据中心的异常列表
this.deepLink = {
  targetTab: 'DataTab',
  targetPage: 'ExceptionList',
  params: { workOrderId: 'WO001' }
};
this.activeTab = 'DataTab';
this.pageStack.replacePath({ name: 'DataTab' });
```

---

## 10. 数据可视化

### 10.1 图表类型选择

| 数据类型 | 推荐图表 | 当前实现 |
|----------|---------|---------|
| 时间趋势（日报工率） | 柱状图 (Canvas) | DashboardChart.ets ✓ |
| 占比（良品率） | 环形图 / 环形进度 | RunningDetailView ✓ |
| 缺陷排名 | 水平条形图 | DashboardView ✓ |
| 实时产量 | 数字指示器 | KpiCard ✓ |
| 设备状态分布 | 状态点 + 列表 | StationCard ✓ |

### 10.2 图表规范

| 规则 | 说明 |
|------|------|
| 颜色无障碍 | 不使用红/绿作为唯一区分 |
| 图例可见 | 图例靠近图表，不在滚动区域外 |
| 空数据 | 显示 "暂无数据" + 引导文案 |
| 加载态 | 骨架屏/占位符，非空白坐标轴 |
| 响应式 | 小屏幕简化图表，减少刻度 |
| 触摸交互 | 图表可交互元素触摸目标 ≥ 44vp |
| 数据标签 | 小数据集直接标注，减少视线移动 |
| 网格线 | 低对比度（gray-200），不与数据线竞争 |
| 动画 | 入场动画尊重 reduced-motion |

### 10.3 图表色板

```
chartBlue:   #1890ff
chartGreen:  #52c41a
chartOrange: #faad14
chartRed:    #f5222d
chartPurple: #722ed1
chartTeal:   #13c2c2
```

---

## 11. 无障碍规范

### 11.1 对比度要求

| 元素 | 最小对比度 | 标准 |
|------|-----------|------|
| 正文文字 (≥14vp) | 4.5:1 | WCAG AA |
| 大文字 (≥18vp) | 3:1 | WCAG AA |
| UI 组件/图标 | 3:1 | WCAG AA |

### 11.2 触摸目标

- 所有交互元素 ≥ **44 × 44vp**
- 图标小于 44vp 时扩展点击区域（hitSlop）
- 触摸目标之间间距 ≥ 8vp

### 11.3 颜色依赖

- 颜色不是唯一的信息指示器
- 状态信息 = 颜色 + 图标/形状 + 文字标签
- 错误信息 = 红色 + 错误图标 + 错误描述文字

### 11.4 屏幕阅读器

- 所有有意义的图片/图标提供 accessibilityLabel
- 表单字段有标签和错误描述
- 焦点顺序匹配视觉顺序
- 模态框打开时焦点移入，关闭时焦点恢复

### 11.5 动态文本

- 支持系统文字缩放（Dynamic Type）
- 文字缩放时避免截断（优先换行）
- 最大字号下布局不破坏

---

## 12. 暗色模式策略

### 设计目标

MES 项目作为工业应用，暗色模式适用于：
- 车间低光环境（夜班）
- 减少屏幕光对操作员的干扰
- OLED 设备节能

### 实施路径

**Phase 1（当前）**: 建立设计令牌系统
- 所有颜色通过 `Colors` 类引用
- 预留在令牌层切换 light/dark 的架构

**Phase 2（后续）**: 定义暗色映射
- 为每个语义令牌定义 dark mode 对应色值
- 表面色：`#FFFFFF` → `#1A1A2E`（深色背景）
- 背景色：`#F5F7FA` → `#0F172A`（更深背景）
- 文字色：`#1A1A2E` → `#EDEDEF`（亮色文字）
- 保持品牌色 `#1565C0` 并降低饱和度

**Phase 3（后续）**: 视图适配
- 逐个页面将硬编码色值替换为令牌引用
- 在令牌层添加 `Colors.isDarkMode` 切换逻辑
- 测试所有页面的暗色效果

### 暗色模式颜色指南

| 元素 | 亮色模式 | 暗色模式 |
|------|---------|---------|
| 页面背景 | `#F5F7FA` | `#0F172A` |
| 卡片表面 | `#FFFFFF` | `#1E293B` |
| 主文字 | `#1A1A2E` | `#EDEDEF` |
| 次要文字 | `#5A5A6E` | `#94A3B8` |
| 辅助文字 | `#9A9AA8` | `#64748B` |
| 边框 | `#E8EBF0` | `#334155` |
| 品牌色 | `#1565C0` | `#42A5F5`（降低饱和度） |
| 成功 | `#4CAF50` | `#66BB6A` |
| 错误 | `#F44336` | `#EF5350` |
| 警告 | `#FF9800` | `#FFA726` |

---

## 13. 文件清单

### 设计令牌文件

| 文件 | 路径 | 说明 |
|------|------|------|
| ColorTokens.ets | `common/utils/src/main/ets/tokens/ColorTokens.ets` | 色彩令牌（三层架构，80+ 常量） |
| SpacingTokens.ets | `common/utils/src/main/ets/tokens/SpacingTokens.ets` | 间距令牌（4dp 网格 + 语义间距） |
| TypographyTokens.ets | `common/utils/src/main/ets/tokens/TypographyTokens.ets` | 排版令牌（字号/字重/行高/预设样式） |
| ShadowTokens.ets | `common/utils/src/main/ets/tokens/ShadowTokens.ets` | 阴影令牌（4 级立面 + 特殊阴影） |

### 导出入口

| 文件 | 说明 |
|------|------|
| `common/utils/Index.ets` | 已添加 4 个令牌模块的 export |

### 使用方式

```typescript
import { Colors, Spacing, Typography, Shadows } from '@ohos/utils';

// 使用色彩
Text('标题').fontColor(Colors.textPrimary);

// 使用间距
Column().padding(Spacing.cardPaddingH);

// 使用排版
Text('页面标题').fontSize(Typography.title).fontWeight(Typography.weightBold);

// 使用阴影
Column().shadow(Shadows.card);

// 使用状态色
Text('生产中').fontColor(Colors.statusFgMap['生产中']);
```

---

## 附录 A: ui-ux-pro-max 设计系统输出

以下为 `search.py --design-system` 对 MES 项目的原始推荐：

| 维度 | 推荐 |
|------|------|
| Pattern | Real-Time / Operations Landing |
| Style | Data-Dense Dashboard |
| Primary | `#334155` (Industrial slate) |
| Accent/CTA | `#059669` (Stock green) |
| Background | `#F8FAFC` |
| Foreground | `#0F172A` |
| Heading Font | Fira Code |
| Body Font | Fira Sans |
| Key Effects | Hover tooltips, chart zoom, row highlighting, smooth filters |
| Anti-patterns | Ornate design, No filtering |

> 注：本项目已保留 `#1565C0` 蓝色作为品牌色（已稳定使用），在推荐色板基础上做了适配调整。

## 附录 B: 参考资源

- [Material Design 3](https://m3.material.io/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [HarmonyOS ArkUI 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui-overview)x
