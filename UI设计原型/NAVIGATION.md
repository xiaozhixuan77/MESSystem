# UI 原型导航目录

24 个 HTML 原型文件，按功能模块分组。每个文件自包含（内联 CSS + SVG），模拟 393×852 手机屏幕。

## 按功能模块检索

### 登录模块
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `01-login.html` | 登录 - 柔性组装MES | 账号密码登录表单，4 角色快速切换（班组长/操作员/质检员/管理员） |

### 工作台首页（按角色）
| 文件 | 角色 | 核心功能 |
|------|------|---------|
| `02-home-leader.html` | 班组长 | 待办事项、产线状态概览（4条线）、快捷入口 |
| `03-home-operator.html` | 操作员 | 当前任务、扫码开工 |
| `04-home-inspector.html` | 质检员 | KPI 指标、待抽检列表、产线监控 |
| `05-home-admin.html` | 管理员 | 全局 KPI、异常告警列表 |

### 工单管理
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `06-workorder-list.html` | 工单列表 | 状态筛选、搜索、卡片视图 |
| `12-workorder-add.html` | 新增工单 | 表单录入、工艺路线预览、复制模式 |

### 工单详情（按状态流转）
| 文件 | 状态 | 核心功能 |
|------|------|---------|
| `07-workorder-detail-pending.html` | 待派工 | 工艺流程展示、操作员选择、派工按钮 |
| `13-workorder-detail-assigned.html` | 已派工 | 派工信息、操作员列表、时间线 |
| `14-workorder-detail-running.html` | 生产中 | 进度环、实时产量、工作站状态 |
| `15-workorder-detail-completed.html` | 待报工 | 生产结果摘要、报工提交表单 |
| `16-workorder-detail-reported.html` | 已报工 | 报工数据、质检状态、确认/报废操作 |
| `17-workorder-detail-paused.html` | 暂停中 | 暂停原因、异常信息、恢复/报废按钮 |

### 产线管理
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `08-line-list.html` | 产线列表 | 4 条产线状态卡片、故障提醒标识 |
| `09-line-detail.html` | 产线详情 - L1柔性线 | 整线控制、6 个工作站列表、实时计数器 |

### 工作站
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `19-station-detail.html` | 工作站详情 - SMT贴片 | 设备状态动画、传送带、计数器、操作按钮 |

### 生产任务
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `18-production-tasks.html` | 生产任务 | 任务列表、状态标签（待执行/进行中/已报工）、SN 扫码 |

### 质量检验
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `10-inspection-input.html` | 抽检录入 | QC 抽检表单（数量、缺陷类型、备注） |
| `19-quality-dashboard.html` | 质检看板 | KPI 指标、趋势图、缺陷类型 TOP5 |
| `20-dashboard.html` | 质检看板 | KPI 指标、图表 |
| `20-qa-dashboard.html` | 质检看板 | 替代看板视图 |

### 人员管理
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `11-employee-list.html` | 人员管理 | 按角色筛选、搜索、人员卡片列表 |

### 个人中心
| 文件 | 标题 | 核心功能 |
|------|------|---------|
| `21-profile.html` | 个人中心 | 个人信息、统计数据、功能菜单、退出登录 |

---

## 按前端 Feature 模块映射

| 前端模块 | 对应原型文件 |
|----------|-------------|
| `@ohos/login` | `01-login.html` |
| `@ohos/home` | `02-home-leader.html`, `03-home-operator.html`, `04-home-inspector.html`, `05-home-admin.html` |
| `@ohos/workorder` | `06-workorder-list.html`, `07-*, 12-*, 13-*, 14-*, 15-*, 16-*, 17-*` (全部 workorder 文件) |
| `@ohos/production` | `08-line-list.html`, `09-line-detail.html`, `18-production-tasks.html`, `19-station-detail.html` |
| `@ohos/quality` | `10-inspection-input.html`, `19-quality-dashboard.html`, `20-dashboard.html`, `20-qa-dashboard.html` |
| `@ohos/user` | `11-employee-list.html`, `21-profile.html` |

## 注意

- **编号冲突**: `19` 和 `20` 各有两个文件（功能不同但同号）
- **未在 index.html 链接**: `19-quality-dashboard.html`、`20-qa-dashboard.html` 只能直接打开
- **index.html**: 设计稿预览入口，按 6 个分组展示所有页面的卡片链接
