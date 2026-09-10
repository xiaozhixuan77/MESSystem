**工业管理 APP**

**（柔性组装 MES 教学 / 仿真版）**

**需求文档**

*—— 面向鸿蒙端开发者的业务上手手册 ——*

版本：V1.0

日期：2026 年 5 月

原型地址：demo.niubi748.top

*目标读者：鸿蒙端开发者 + Java 后端开发者（工业业务零基础）*

# **阅读指南**

本文档基于 demo.niubi748.top 原型站点的逐页调研整理，是一份业务说明 + 需求规格 + 数据/接口/前端落地建议的三合一文档。建议按下面的顺序阅读：

- **第一遍 **—— 看第 1 章术语扫盲 + 第 2 章项目总览，先把脑子里的工厂模型搭起来。
- **第二遍 **—— 看第 3 章角色矩阵 + 第 5 章工单状态机，理解四个角色之间的协作链路。
- **第三遍 **—— 看第 4 章数据模型 + 第 11 章接口清单，开始建表、画 API。
- **第四遍 **—— 看第 6 章各角色页面 + 第 7 章产线仿真，确定 ArkUI 页面结构。
- **第五遍（重要）** —— 看第 9 章实时状态同步机制，这是本项目最容易踩坑的部分，必须搞清楚。

**特别说明  **本应用是一个 “多角色实时协同 + 产线实时仿真” 应用，不是简单 CRUD。原型已通过 “同时打开两个浏览器窗口” 实测验证了状态同步行为，详见第 9 章。

# **第 1 章 行业关键词扫盲（程序员视角）**

这一章把你在原型里能看到、以及后面和业务方沟通会反复听到的工业术语，全部用 “程序员能听懂的话” 翻译一遍。开发时把这当成你的领域字典。

| **术语** | **程序员视角解释** |
| --- | --- |
| MES（Manufacturing Execution System，制造执行系统） | 介于 ERP（管钱、管订单）和 PLC/SCADA（管设备）之间的 “中间件”。它把 “老板下的订单” 拆成 “车间一步步做的事情”，并实时记录每一件产品在哪一道工序、是谁做的、合格不合格。本项目就是一个缩小版 MES。 |
| 工艺（Process / Routing） | 一个产品要经历的 “加工步骤模板”。如无线充电器的工艺 = 上料 → 主板组装 → 后盖组装 → 螺丝锁付 → 激光打标 → 成品检测 → 下料。可以理解为 “产品 → 工序步骤” 的关联表，是创建工单时的模板 / 蓝本。 |
| 工艺路线（Process Route） | 上面 “工艺” 挂在某个具体工单上的有序工序列表实例。可以理解为 List<Operation>，每个 Operation 有顺序号、工序名、对应工作站。 |
| 工序（Operation / OP） | 工艺路线里的单步，如 OP10 上料、OP20 主板组装。OP 后面跟的数字一般是顺序号（10、20、30…，留间隔方便后续插入新工序）。 |
| 柔性组装 / 柔性产线（Flexible Assembly Line） | 同一条产线能在 “不修改硬件” 的前提下，通过切换 “工艺” 来生产不同产品。对立概念是 “刚性产线”—— 只能生产一种产品。本系统的核心仿真对象就是这条柔性组装线。 |
| 工单（Work Order / MO，Manufacturing Order） | 一次具体的生产任务实例：什么产品、做多少件、什么时候做、由谁做、走哪条产线、走哪条工艺。可类比为一张 “生产订单”，由状态机驱动。原型中编号 MO000001 形式。 |
| 试产 / 量产 / 返工（工单类型） | 试产：小批量验证工艺是否走得通；量产：常规大批量生产；返工：质检不合格的产品重新走一遍工序。 |
| 派工（Dispatch） | 班组长把 “已创建但没人做” 的工单，指派给某个操作员的动作。本项目约定 “一个工单只能派给一个操作员”。 |
| 报工（Production Reporting） | 操作员 / 系统在完成一批生产后，向 MES 上报 “我做了多少件、几件良品、几件 NG、用了多少工时”。这是写入 “生产业绩” 的关键动作，后续工资计算、产能统计都依赖它。 |
| 良品 / NG（Good / No Good） | 合格品 / 不合格品。NG 是工厂里的通用缩写，保留英文不要翻译。 |
| 抽检（Sampling Inspection） | 不做 100% 检验，按比例（原型里 5%~10%）抽几件做质量判定。质检员的核心工作。 |
| 质检看板 / Dashboard | 用大屏展示的实时生产 / 质量统计页。原型显示：今日计划达成率、累计投入、累计产出、累计废品、产品完工占比、工序完工占比。 |
| 车间（Workshop） | 物理上的厂房单位。原型里有：机加工车间、柔性车间、智能组装车间、SMT 车间。 |
| 产线 / 资源（Production Line / Resource） | 车间内部一条具体生产线。原型里 “资源” 基本等同于 “产线” 的下拉项（柔性线、SMT 线…）。 |
| 工作站（Workstation / Station） | 产线上的一个工位，对应一台设备，如 OP10 上料、OP40 螺丝锁付。每个工作站有：设备状态、工作状态、传送带状态、已加工件数、产出 / NG 等。 |
| SMT（Surface Mount Technology，表面贴装） | 把电子元件贴到 PCB 板上的工艺，常见于手机 / 充电器主板生产。原型里有一条 SMT 产线。 |
| SN（Serial Number，序列号） | 每一件产品的唯一识别码，扫码用于 “开工 / 报工 / 追溯”。 |
| 整线启动 / 停止 / 复位 / 异常上报 | 产线级 4 个核心动作：启动让产线流转、停止暂停所有工作站、复位回到初始、异常上报弹框输入描述并提交。 |
| OEE（Overall Equipment Effectiveness） | 设备综合效率 = 时间开动率 × 性能开动率 × 良品率。原型里没显示，但你后端日后大概率会被要求做这个指标，字段先预留。 |
| BOM（Bill of Materials，物料清单） | 一个产品由哪些零件组成的清单。原型未暴露，但 “上料” 环节理论上要按 BOM 扣减原料库存。建议数据模型中预留。 |
| SOP（Standard Operating Procedure，标准作业指导书） | 每个工序的 “作业指导文档”。原型未显示，但实际开发常被要求 “扫码弹 SOP 给操作员看”，建议预留接口。 |
| RBAC（Role Based Access Control） | 基于角色的权限控制。本系统四个角色，每个 API 上挂权限码，登录后根据角色加载权限码集合。 |
| WebSocket / SSE / MQTT | 三种服务端推送协议。本系统的产线实时状态强烈建议 WebSocket；真实工厂场景里 PLC 设备一般走 MQTT，由后端转 WebSocket 到 APP。 |

# **第 2 章 项目总览**

## **2.1 项目定位**

一个面向 “柔性组装产线” 的轻量级 MES 教学 / 仿真 APP。

- 移动端为主，分辨率 393×852（鸿蒙 ArkUI 实现）。
- 4 个角色：班组长、操作员、质检员、管理员。
- 底部统一 4 个 Tab：工作台 / 数据 / 工单 / 我的。同一套页面，按角色做权限过滤。
## **2.2 核心业务闭环**

管理员维护基础数据 (产线 / 工艺 / 人员)

        ↓

班组长创建工单 → 派工给操作员

        ↓

操作员去产线启动整线生产 (整线按工艺顺序流转)

        ↓

生产完成 → 操作员报工 (录入良品 / NG / 工时)

        ↓

质检员对已报工工单抽检 → 录入抽检结果

        ↓

班组长确认工时 → 工单完结

## **2.3 演示账号（原型提供）**

| **角色** | **姓名** | **账号** | **密码** |
| --- | --- | --- | --- |
| 管理员 | 张建国 | admin | 123456 |
| 班组长 | 王志刚 | leader | 123456 |
| 操作员 | 刘伟 / 李强 / 赵敏 | operator | 123456 |
| 质检员 | 陈静 | inspector | 123456 |

## **2.4 系统四个角色一句话职责**

| **角色** | **核心职责** |
| --- | --- |
| 班组长 (Leader) | 维护本班组工单：创建、修改、派工、确认工时、报废；处理异常；可只读查看所有产线和看板。 |
| 操作员 (Operator) | 执行被派给自己的工单：扫 SN 开工 → 启动整线 → 监控运行 → 异常上报 → 报工。 |
| 质检员 (Inspector) | 对已报工的工单做抽检；录入抽检结果（良品 / NG / 不良类型）；只读看产线运行。 |
| 管理员 (Admin) | 全权限：人员管理、产线 / 工艺基础数据维护、全局工单总览、所有操作均可执行。 |

**特别强调  **本应用是一个 “多角色实时协同 + 产线实时仿真” 应用，不是简单 CRUD。详见第 9 章实测验证。

# **第 3 章 角色与权限矩阵**

这张矩阵是后端 RBAC 建表的依据。建议建一张 role_permission 表，每个 API 方法上加注解 @RequiresPermission("workorder.dispatch")。

| **模块 / 动作** | **班组长** | **操作员** | **质检员** | **管理员** |
| --- | --- | --- | --- | --- |
| 查看本班组工单 | ✔ | — | — | ✔ 全部 |
| 查看自己关联的工单 | — | ✔ | — | ✔ |
| 查看待抽检 / 已报工工单 | — | — | ✔ | ✔ |
| 新增 / 修改 / 复制工单 | ✔ | ✘ | ✘ | ✔ |
| 派工 | ✔ | ✘ | ✘ | ✔ |
| 启动 / 停止 / 复位整线 | ✔（异常处理） | ✔（生产时） | ✘ 只读 | ✔ |
| 异常上报 | ✔ | ✔ | ✘ | ✔ |
| 异常处理（恢复 / 报废） | ✔ | ✘ | ✘ | ✔ |
| 报工 | ✘ | ✔ | ✘ | ✔ |
| 抽检录入 | ✘ | ✘ | ✔ | ✔ |
| 确认工时 / 报废 | ✔ | ✘ | ✘ | ✔ |
| 质检看板 | ✔ 只读 | ✔ 只读 | ✔ 只读 | ✔ |
| 人员管理（增删改） | ✘ | ✘ | ✘ | ✔ |
| 产线 & 工艺管理 | 只读 | 只读 | 只读 | ✔ |

“只读” 表示能进入页面但所有操作按钮置灰；“—” 表示该页面对该角色不开放入口。

# **第 4 章 核心数据模型**

下面是 “最小够用” 模型，字段名尽量贴近原型显示的中文含义。所有表都建议带 id、created_at、updated_at、version（乐观锁）、is_deleted（软删除）公共列。

### **4.1 user（人员）**

id            BIGINT  PK

employee_no   VARCHAR  工号

name          VARCHAR

role          ENUM(admin / leader / operator / inspector)

team_id       BIGINT   所属班组

workshop_id   BIGINT   所属车间

status        ENUM(在岗 / 离岗)

avatar_url    VARCHAR

password_hash VARCHAR

### **4.2 workshop（车间）**

id, name  // 机加工车间 / 柔性车间 / 智能组装车间 / SMT 车间

### **4.3 production_line（产线 / 资源）**

id

name                   柔性组装线 / 智能组装线 / SMT 产线 / 机加工线

workshop_id

current_process_id     当前正在跑的工艺

current_workorder_id   当前激活的工单

status                 空闲 / 生产中 / 暂停 / 异常 / 停机

supported_process_ids  多对多，该产线支持的工艺

### **4.4 process（工艺）**

id, code, name (例如 "无线充电器组装")

applicable_product_codes   该工艺可用于哪些产品

### **4.5 process_step（工序 / 工艺步骤）**

id, process_id

seq_no             10 / 20 / 30 ...

op_code            OP10

name               上料

default_station_id 默认工作站

description

### **4.6 workstation（工作站）**

id

code              WS-FLX-OP10

name              OP10 上料

production_line_id

equipment_code

current_process_id

device_status     运行中 / 待机 / 故障

work_status       机械臂上料 / 出料等待 / 工作台固定 / ...

conveyor_status   正转 / 反转 / 停

processed_count

raw_count

finished_count

ng_count

### **4.7 product（产品）**

id, code (PROD-WC-001), name (无线充电器)

default_process_id, bom_id (预留)

### **4.8 work_order（工单 ★ 核心）**

id, code (MO000001)

type                试产 / 量产 / 返工

workshop_id, line_id, product_id, process_id

plan_qty, plan_start_time, plan_end_time

status              待派工 / 已派工 / 生产中 / 暂停中 /

                    生产完成 / 已报工 / 完工 / 报废

source              Web 创建 / APP 创建

operator_id, dispatch_time

actual_start_time, actual_end_time

reported_qty_good, reported_qty_ng, reported_hours

exception_note, created_by

### **4.9 work_order_route_step（工单工艺路线快照）**

工艺日后会改，但历史工单要 “按当时的工艺” 留存。这是一张快照表 —— 类似订单系统快照商品价格。

id, work_order_id

seq_no, op_code, name, station_id

### **4.10 production_exception（生产异常）**

id, work_order_id, line_id

station_id   (可空，整线异常时为空)

reporter_id, report_time, description

handled_by, handle_time

handle_action  恢复 / 报废

resolved       (bool)

### **4.11 inspection_record（抽检记录）**

id, work_order_id, inspector_id, inspect_time

sample_qty, sample_good, sample_ng

defect_types   JSON: 外观缺陷 / 尺寸偏差 / 功能失效 / 装配不良

defect_description

conclusion     通过 / 不通过

### **4.12 production_log（产线运行日志，供产线详情页实时刷数据）**

这张表是 “实时同步” 的关键 —— 每一次状态变化都落一条日志，再由 WebSocket 把日志广播给所有订阅了该产线的窗口。

id, line_id, station_id, work_order_id

event_type     启动 / 停止 / 复位 / 加工 / 出料 / 异常

product_sn

event_time

payload (JSON)

# **第 5 章 工单状态机（核心）**

这是整个 APP 的灵魂。所有页面变体（待派工 / 已派工 / 生产中 / 待报工 / 已报工 / 暂停 / 完工 / 报废）都是它的状态。

```
┌──── 报废 (终态) ────┐
│                       │
[待派工] ─派工→ [已派工] ─操作员开工→ [生产中] ─整线完成→ [生产完成 / 待报工]
│                                  │                       │
│                            异常上报↓             操作员报工↓
│                              [暂停中] ─恢复→[生产中]   [已报工]
│                                                              │ 质检抽检
│  仅在 “待派工” 状态可修改                                    ↓
│                                                        班组长确认工时
│                                                              ↓
└─                                                          [完工] (终态)
```

## **5.1 状态转换 REST 接口**

| **接口** | **含义** | **触发状态** |
| --- | --- | --- |
| POST /workorders | 创建工单 | → 待派工 |
| POST /workorders/{id}/dispatch  body={operatorId} | 派工 | → 已派工 |
| POST /workorders/{id}/start | 开始生产 | → 生产中 |
| POST /workorders/{id}/pause  body={reason} | 暂停（异常） | → 暂停中 |
| POST /workorders/{id}/resume | 恢复 | → 生产中 |
| POST /workorders/{id}/scrap | 报废 | → 报废 |
| POST /workorders/{id}/report  body={good,ng,hours,note} | 报工 | → 已报工 |
| POST /workorders/{id}/confirm | 确认完工 | → 完工 |

## **5.2 状态机校验要点（后端必做）**

- 修改工单：只允许在 “待派工” 状态，其它状态直接 403。
- 派工：只允许在 “待派工” 状态；同一操作员同一时间只能持有一个 “已派工 / 生产中 / 暂停中” 的工单。
- 开工：只有被指定的 operator 才能调 start；产线必须空闲。
- 报工：只有 “生产完成” 才能报工；good + ng ≤ plan_qty。
- 确认工时：建议要求至少一条 inspection_record 才能 confirm（业务校验）。
- 报废：从 “暂停中” 或 “已报工” 都可报废；终态后不可再改。

# **第 6 章 各角色页面与功能详解**

同一个 HTML 页面会出现在多个角色下，权限 / 可见区域由 role 参数和后端鉴权双重控制。下面列的是每个角色 “看得到 + 能进入” 的页面集合。

## **6.1 班组长（15 个页面）**

| **页面** | **URL** | **功能** | **关键接口** |
| --- | --- | --- | --- |
| 工作台 | home.html?role=leader | 三个快捷入口（基础数据 / 工单 / 质检看板）+ 待办与进度（待派工、异常待处理） | GET /todos?role=leader |
| 本班组工单管理 | workorder-list-leader.html | 列表：本班组所有工单；搜索（工单号）；筛选（类型 / 状态 / 产线）；每条有 “状态变更” “复制新增” | GET /workorders?teamId= |
| 新增工单 | workorder-add.html | 字段：工单号(自生成)、类型、车间、资源、产品编码、产品名(自带出)、计划数量、计划开始 / 结束、工艺路线(选完产品自带出，只读) | POST /workorders |
| 修改工单 | workorder-edit.html | 仅 “待派工” 可改；工单号不可改 | PUT /workorders/{id} |
| 复制新增 | workorder-copy.html | 复制源工单除工单号外所有字段，工艺路线只读 | POST /workorders?copyFrom= |
| 待派工详情 / 派工 | workorder-detail-pending.html | 工单详情 + 操作员单选 + 确认派工 | POST /workorders/{id}/dispatch |
| 已派工查看 | workorder-detail-assigned.html | 只读，展示已派工操作员、派工时间 | — |
| 生产中查看 | workorder-detail-running.html | 只读，展示实际开始时间 | — |
| 待报工查看 | workorder-detail-completed.html | 显示自动生产结果：总产出 / 良品 / NG / 产线运行时长 | — |
| 已报工 / 确认工时 | workorder-detail-reported.html | 显示申报工时、良品、NG、异常说明、质检状态；按钮：确认完工 / 报废 | POST /workorders/{id}/confirm |
| 暂停 / 恢复 / 报废 | workorder-detail-paused.html | 显示暂停原因 / 时间；按钮：恢复 / 报废 | POST /workorders/{id}/resume |
| 产线数据 | master-lines.html | 所有产线卡片（仅柔性线 “生产中”，其余只读展示）；两个 Tab：产线与工艺 / 人员 | GET /lines |
| 产线详情 / 异常处理 | master-line-detail.html | 整线状态卡 + 7 个工作站 + 整线 4 操作 | POST /lines/{id}/{action} |
| 工作站人员 | master-station-employees.html | 工作站详情：设备 / 工作 / 传送带状态、已加工件数、产出统计 + 启动 / 停止 / 复位 / 异常上报 | POST /stations/{id}/{action} |
| 质检看板查看 | qa-dashboard.html | 只读看板 | GET /dashboard |

## **6.2 操作员（13 个页面）**

| **页面** | **功能要点** |
| --- | --- |
| 工作台 (operator) | “我的待办” —— 只展示自己关联的工单（去生产 / 生产中 / 待报工） |
| 我的工单 workorder-list-operator.html | 列表只显示 operator_id = currentUser.id 的工单 |
| 生产任务 production-tasks.html | 三个 Tab：待执行 / 进行中 / 已报工；卡片支持 SN 扫码开工与报工；队列展示等待物料、返工等优先项 |
| 已派工 / 开始生产 | 操作员可点 “开始生产” 调 POST /workorders/{id}/start |
| 生产中 | 只读查看进度，可跳转到产线 / 工作站详情 |
| 待报工 / 提交报工 | 显示 “自动生产结果”，操作员录入：实际良品、NG、工时、异常说明 → 提交报工 |
| 暂停状态查看 | 只读 |
| 产线执行详情 / 工作站状态 / 产线数据 | 同班组长视图，但操作权限仅在 “生产中” 开放（启动 / 停止 / 复位 / 异常上报） |
| 质检看板 | 只读 |
| 我的账号 profile.html | 头像、工号、角色、关于、退出登录 |
| 已报工工单查看 | 只读 |

**业务约束  **一个操作员同一时间只能 “激活” 一个工单（原型 “一对一派工” 已暗示）。后端在 start 接口里强校验。

## **6.3 质检员（11 个页面）**

| **页面** | **功能要点** |
| --- | --- |
| 工作台 (inspector) | 待办：① 当前产线运行状态卡；② 待抽检工单（已报工）；③ 故障日志待核查 |
| 质检工单 workorder-list-inspector.html | 列表只显示 “已报工 / 待抽检” 或与质检有关的工单，每条有 “去抽检” |
| 抽检详情 / 录入结果 qa-inspection-detail.html | 上方原工单（申报工时 / 良品 / NG）；下方录入：抽检数量、抽检良品、抽检 NG、不良原因描述、常见不良类型多选（外观缺陷 / 尺寸偏差 / 功能失效 / 装配不良）→ 提交 |
| 质检看板 / 产线数据 / 产线详情 / 工作站详情 | 全部只读 |
| 已报工 / 待报工 / 暂停状态 | 只读 |
| 我的账号 | 同上 |

**抽检规则  **建议抽检数量为批量的 5% ~ 10%；后端在提交时做校验；提交完成后向班组长推送一条 “可确认工时” 待办。

## **6.4 管理员（20 个页面，全权限）**

管理员看到的页面 ≈ 班组长 + 操作员 + 质检员 的并集，再加人员管理与全角色工单总览。

| **独有页面** | **功能** |
| --- | --- |
| 全局工作台 | 4 个 KPI 卡：产线总数(4)、人员总数(6)、活跃工单(3)、待处理异常(1)；快捷入口：全产线工单总览 / 人员管理 / 产线与工艺管理 |
| 全产线工单总览 workorder-list.html | 不限班组、不限角色 |
| 人员管理 employees.html | 列表 + 新增 + 编辑 + 删除；按角色 Tab 切换；搜索 “姓名或工号”；同时承担 “角色权限说明” 展示职责 |

人员管理字段：姓名、工号、登录账号、初始密码、角色、所属车间 / 班组、状态、头像。

# **第 7 章 产线仿真（柔性组装线）业务细节**

这是项目最有 “工业味” 的部分，也是原型里仿真做得最细的页面（master-line-detail.html、master-station-employees.html）。

## **7.1 柔性组装线的 7 个工作站固定顺序**

OP10 上料 → OP20 主板组装 → OP30 后盖组装 → OP40 螺丝锁付

       → OP50 激光打标 → OP60 成品检测 → OP70 下料

## **7.2 工作站实时数据契约**

每个工作站需要后端实时推送下列字段，前端用同一份模型渲染：

```json
{
"stationCode": "WS-FLX-OP40",
"deviceStatus": "运行中 | 待机 | 故障",
"workStatus":   "螺丝锁付加工 | 出料等待 | 工作台固定 | 异常停机 ...",
"conveyorStatus": "正转 | 反转 | 停",
"productSn":      "P019",
"processingSeconds": 0.0,
"raw": 82,
"good": 18,
"ng": 1
}
```

## **7.3 产线级 4 个动作**

- **启动**：所有工作站从待机 / 空闲变为运行；后端开启该产线的仿真定时任务，按 1 ~ 2Hz 推送状态。
- **停止**：所有工作站置为待机；仿真定时任务暂停。
- **复位**：清空当前 SN 上下文，所有计数器归零，回到初始。
- **异常上报**：弹窗输入 “异常描述” → 调 POST /exceptions，整线置为 “故障停机”，班组长收到待办。
## **7.4 异常处理逻辑**

- 1. 操作员或工作站监测到异常（如 “相机定位偏移”）→ 调用异常上报。
- 2. 整线 / 工作站状态变为 “故障”。
- 3. 班组长工作台出现 “异常待处理” 红色待办卡。
- 4. 班组长进入产线详情：选 “复位”（清异常 → 继续生产）或 “停止 + 工单报废”（工单走 scrap）。
## **7.5 后端产线仿真器（建议设计）**

产线既然是 “仿真”，后端必须有一个定时任务来 “推进” 每个工作站的状态。推荐做法：

- 每条 “生产中” 的产线由一个独立 Scheduler 任务驱动（Spring @Scheduled 或 Quartz）。
- Tick 周期建议 1 秒：每个工作站按工艺设定的节拍递增 raw / good / ng / processed_count。
- 每次 tick 产生的变化写入 production_log 表，并通过 WebSocket 推送给所有订阅 /topic/lines/{id} 的客户端。
- 整线启动时初始化 Scheduler；停止 / 复位时取消任务；异常时挂起任务并广播异常事件。
- 注意防止重复启动（同一产线 ID 只能挂一个任务），可用 Redis SETNX 或 ConcurrentHashMap 做幂等。

# **第 8 章 质检看板指标定义**

| **指标** | **含义** | **计算建议** |
| --- | --- | --- |
| 今日计划达成率 | 今天计划数中已完成的比例 | Σ完工数 / Σ计划数（当天工单） |
| 累计投入 | 累计投入原料数 | Σ raw |
| 累计产出 | 累计产出总数 | Σ finished |
| 累计废品 | 累计 NG 数 | Σ ng |
| 产品完工占比 | 单产品完成率 | 完工数 / 计划数 |
| 工序完工占比 | 每个工序完成的批次比例 | 工序产出 / 工序计划 |
| 本月计划达成率 | 1 ~ 30 日柱状趋势 | 每日达成率序列 |

后端建议提供 GET /dashboard?scope=today|month 一次性返回上面所有字段。前端图表鸿蒙端用 @ohos/mpchart。

# **第 9 章 实时状态同步机制（原型已实测验证！必须实现）**

## **9.1 业务需求来源 —— 原型实测结论**

原型可以同时打开两个浏览器窗口：操作员在 A 窗口对产线做任何操作（启动 / 停止 / 异常上报），B 窗口（班组长 / 质检员 / 管理员）的产线详情页 2 秒内自动同步刷新 —— 所有工作站状态、计数、整线状态完全一致。

**实测验证 ✔  **已在原型中实测：点击 A tab 的 “停止” → B tab 立即变 “已选择 · 等待启动”；点击 A tab 的 “启动” → B tab 立即变 “生产中”。这是 demo.niubi748.top 原型已演示的真实行为。

*原型底层实现：把整条产线状态序列化成一个 JSON，存到 localStorage 的 prototype.flexLineState.v1 key，并监听浏览器的 storage 事件做跨窗口推送。这是用纯前端模拟 “实时多端协同” 的小技巧 —— 真实开发要用服务端推送替换它，业务语义保持一致。*

换句话说：原型用 localStorage 的 “跨窗口广播” 模拟了一个本应由服务端 WebSocket 完成的协同行为。我们做真实开发时，要把 “跨窗口” 升级为 “跨设备 / 跨用户”，技术换成 WebSocket，业务语义完全照搬。

## **9.2 必须实时同步的协作场景**

| **触发者** | **触发动作** | **同步对象** |
| --- | --- | --- |
| 操作员 | 启动 / 停止 / 复位整线 | 班组长（产线详情）、管理员（大屏）、质检员（待办） |
| 操作员 / 设备 | 异常上报 | 班组长 “异常待处理” 红色待办 |
| 工作站（仿真定时推进） | productId / duration / device 变化 | 任何打开产线详情的人 |
| 班组长 | 派工 | 被指派操作员的 “我的工单” 列表立即出现新工单 |
| 操作员 | 提交报工 | 质检员 “待抽检” 列表立即出现新条目 |
| 质检员 | 提交抽检 | 班组长 “已报工” 详情的 “质检状态” 实时变化 |
| 班组长 | 确认完工 / 报废 | 工单列表、看板、操作员 “我的工单” 全部刷新 |
| 管理员 | 修改人员、产线、工艺 | 各角色基础数据刷新 |

## **9.3 推送通道选型**

| **方案** | **适用场景** | **备注** |
| --- | --- | --- |
| WebSocket  ★ 首选 | 双向、低延迟、产线 1Hz 刷新最适合 | 鸿蒙用 @ohos.net.webSocket；后端用 Spring WebSocket + STOMP |
| SSE | 服务端单向推送（如待办通知） | 实现简单，但鸿蒙端支持不如 WS 成熟 |
| MQTT | 工厂级 IoT 设备直连 | 真实 PLC 数据走 MQTT broker，后端转发到 APP |
| HTTP 轮询 | WS 断线兜底降级 | 5 ~ 10 秒一次，仅作为 fallback |

## **9.4 推荐架构**

```
PLC / 工作站设备 ─MQTT─> 后端 (Spring Boot + EMQX / Mosquitto)
│
├─ MySQL / PostgreSQL（落盘，结构化数据）
├─ Redis（实时状态缓存 + Pub/Sub）
└─ WebSocket (STOMP) ─> 鸿蒙 APP / Web 端
```

在本教学 / 仿真版项目里，左侧的 PLC 链路可以省略 —— 用后端 Scheduler 模拟设备的状态推进即可（详见第 7.5 节）。但建议保留 MQTT 接入点和 Redis Pub/Sub 这一层，未来要接真实设备时改一个适配器就行。

## **9.5 WebSocket 频道（Topic）设计**

```
/topic/lines/{lineId}              产线整体状态（启停 / 当前工单 / 当前工艺）
/topic/lines/{lineId}/stations     该产线所有工作站状态（高频，1 ~ 2Hz）
/topic/workorders/{workOrderId}    单工单状态机变更
/topic/exceptions                  全局异常事件（管理员 / 班组长订阅）
/user/queue/todos                  按用户推送的 “我的待办” 变更（点对点）
/user/queue/notifications          按用户推送的系统通知
```

- 公共 topic（/topic/*）：所有订阅者都能收到，用于产线状态、异常等。
- 用户级 queue（/user/queue/*）：按 userId 路由，只发给本人，用于待办、个人通知。
## **9.6 消息体设计原则**

- **推完整快照，不推增量。**仿真场景下增量带来的复杂度远超它节省的带宽，且新连进来的客户端能立刻拿到最新状态。
- **带版本号 / 时间戳。**客户端用版本号判断新旧，丢弃过期消息。
- **幂等 ID。**客户端记录已处理的消息 ID，重连后服务端重放也不会重复刷新。
消息体示例（产线状态广播）：

```json
{
"topic": "/topic/lines/1",
"version": 1715762340123,
"eventId": "evt-7f8c-..."
"payload": {
"lineId": 1,
"status": "生产中",
"currentWorkorderId": 10086,
"currentProcessId": 3,
"stations": [
```

      { "stationCode": "WS-FLX-OP10", "deviceStatus": "运行中", "raw": 99, "good": 88, "ng": 1 },

      ...

```
]
}
}
```

## **9.7 服务端实现要点**

- 连接鉴权：WebSocket 握手时带 JWT，服务端解析后绑定 session ↔ userId，鉴权失败直接关闭连接。
- 状态变更接口（start / stop / dispatch 等）写入数据库后，立刻通过 SimpMessagingTemplate.convertAndSend 广播到对应 topic。
- 产线仿真 Scheduler 每次 tick 后也走同一个广播入口，保证 “业务接口” 与 “定时任务” 两条路推送格式一致。
- Redis Pub/Sub 用于多实例后端的横向扩展：一个实例发起广播，所有实例的 WebSocket 客户端都能收到。
- 并发写入：所有状态变更接口都加乐观锁，保证两个客户端同时点 “启动” 时只成功一次。
## **9.8 鸿蒙客户端实现要点**

- 封装一个全局 WebSocketService 单例，登录成功后启动，连接 /user/queue/notifications。
- 页面级订阅：进入产线详情时 SUBSCRIBE /topic/lines/{id} 和 /topic/lines/{id}/stations，aboutToDisappear 里 UNSUBSCRIBE，防止订阅泄漏。
- 收到消息后写入 AppStorage，所有页面通过 @StorageProp 响应式刷新。
- 乐观 UI：用户点 “启动整线” 后，先把按钮置灰，等服务端广播回 “产线生产中” 再确认最终状态；失败回滚。
- 心跳：每 30 秒发一次 ping，60 秒无 pong 视为断开，触发重连。
- 断线重连后：先调一次 REST 拉全量（GET /lines/{id}），再开始监听增量；不要依赖服务端补发历史消息。
- 冲突处理：如果两个角色同时操作（如班组长点 “复位”、操作员点 “启动”），以服务端响应为准，本地按服务端推回来的最终状态刷新。
## **9.9 一个完整的联动时序示例**

场景：操作员在窗口 A 点 “启动整线”，班组长在窗口 B 看产线详情，质检员在窗口 C 看质检看板。

操作员窗口 A            服务端                  班组长窗口 B           质检员窗口 C

```
│                       │                         │                      │
│ POST /lines/1/start   │                         │                      │
│──────────────────────>│                         │                      │
│                       │ 启动产线仿真任务         │                      │
│                       │ status: 空闲 → 生产中    │                      │
│                       │                         │                      │
│                       │ 广播 /topic/lines/1     │                      │
│ <─────────────────────│────────────────────────>│                      │
│   产线状态: 生产中     │   产线状态: 生产中       │                      │
│                       │                         │                      │
│                       │ 每秒 tick               │                      │
│                       │ 推送工作站计数变化       │                      │
│ <─────────────────────│────────────────────────>│                      │
│   raw=1 good=0        │   raw=1 good=0          │                      │
│                       │                         │                      │
│                       │ 产生良品                │                      │
│                       │ 广播 /topic/dashboard   │                      │
│                       │────────────────────────────────────────────────>│
│                       │                         │                      │ 累计产出 +1
```

## **9.10 联动开发的常见坑**

- 坑 1：用轮询代替推送 —— 体验差且服务端压力大。MES 仿真必须用 WebSocket。
- 坑 2：客户端订阅没解绑 —— 切换页面时旧订阅还在，导致一个客户端订阅一堆产线。务必在 aboutToDisappear 里 UNSUBSCRIBE。
- 坑 3：增量补丁 —— 一开始想省带宽推增量，最后被乱序、丢包、新连接没初始态搞崩溃。直接推完整快照最稳。
- 坑 4：没有断线重连 —— 鸿蒙端切后台、切网络后断开，回前台没自动重连，用户看到的是 “冻结的页面”。
- 坑 5：广播未做权限过滤 —— /user/queue/* 必须按 userId 分通道，不能把所有人的待办都推给所有人。
- 坑 6：业务接口和 Scheduler 用两套广播代码 —— 一定要走同一个广播入口，否则两边发出的消息格式不一致，客户端要写两套解析。

# **第 10 章 前端页面结构（鸿蒙 ArkUI）**

按你是鸿蒙开发者，给一份页面树作参照：

/entry/src/main/ets/pages

```
├─ Login/                            登录
├─ Home/
│   ├─ LeaderHome.ets                班组长工作台
│   ├─ OperatorHome.ets
│   ├─ InspectorHome.ets
│   └─ AdminHome.ets
├─ WorkOrder/
│   ├─ WorkOrderList.ets             列表（按角色过滤）
│   ├─ WorkOrderAdd.ets
│   ├─ WorkOrderEdit.ets
│   ├─ WorkOrderCopy.ets
│   └─ Detail/
│        ├─ PendingDetail.ets        待派工 / 派工
│        ├─ AssignedDetail.ets       已派工
│        ├─ RunningDetail.ets        生产中
│        ├─ CompletedDetail.ets      待报工
│        ├─ ReportedDetail.ets       已报工 / 确认工时
│        └─ PausedDetail.ets         暂停 / 恢复 / 报废
├─ Production/
│   ├─ ProductionTasks.ets           操作员工序任务
│   ├─ LineList.ets                  产线列表
│   ├─ LineDetail.ets                产线详情（含仿真，订阅 WS）
│   └─ StationDetail.ets             工作站详情
├─ Quality/
│   ├─ InspectionList.ets            质检工单列表
│   ├─ InspectionDetail.ets          抽检录入
│   └─ Dashboard.ets                 质检看板（订阅 WS）
├─ User/
│   ├─ EmployeeList.ets              人员管理（管理员）
│   └─ Profile.ets                   我的账号
└─ Common/
├─ BottomNavBar.ets              底部 4 tab
├─ TopBar.ets
├─ StatusTag.ets                 状态标签
└─ WebSocketService.ets          WS 单例服务
```

全局状态：建议用 AppStorage 存 currentUser、currentRole、token，所有页面通过 @StorageProp 注入。

WebSocket 服务封装为单例，在登录成功后启动；进入产线详情或看板时再按需 SUBSCRIBE 特定 topic，aboutToDisappear 时 UNSUBSCRIBE。

# **第 11 章 推荐后端接口清单（最小可用集）**

下面列了约 35 个最关键的接口，足以覆盖原型所有交互。

### **11.1 鉴权**

```
POST /auth/login        登录
POST /auth/logout       登出
GET  /me                获取当前用户信息
```

### **11.2 基础数据**

```
GET  /workshops                          车间
GET  /lines  (?role=...)                  产线
GET  /lines/{id}                          产线详情
GET  /lines/{id}/stations                 产线下的工作站
GET  /stations/{id}                       工作站详情
GET  /processes                           工艺
GET  /products                            产品
GET  /products/{code}/process             产品默认工艺路线
```

### **11.3 人员（管理员）**

```
GET    /users
POST   /users
PUT    /users/{id}
DELETE /users/{id}
```

### **11.4 工单**

```
GET  /workorders        (按 role / teamId / operatorId 过滤)
POST /workorders        (?copyFrom= 支持复制新增)
PUT  /workorders/{id}
GET  /workorders/{id}
POST /workorders/{id}/dispatch
POST /workorders/{id}/start
POST /workorders/{id}/pause
POST /workorders/{id}/resume
POST /workorders/{id}/scrap
POST /workorders/{id}/report
POST /workorders/{id}/confirm
```

### **11.5 产线 / 工作站操作**

```
POST /lines/{id}/start
POST /lines/{id}/stop
POST /lines/{id}/reset
POST /stations/{id}/start
POST /stations/{id}/stop
POST /stations/{id}/reset
```

### **11.6 异常**

```
POST /exceptions                上报
GET  /exceptions                列表（班组长待办）
POST /exceptions/{id}/handle    处理（恢复 / 报废）
```

### **11.7 质检**

```
GET  /inspections
POST /inspections
GET  /inspections/{id}
```

### **11.8 看板 / 待办**

```
GET  /dashboard?scope=today|month
GET  /todos                              我的待办（按角色返回）
```

### **11.9 实时通道（WebSocket，STOMP 协议）**

```
SUBSCRIBE /topic/lines/{lineId}
SUBSCRIBE /topic/lines/{lineId}/stations
SUBSCRIBE /topic/workorders/{workOrderId}
SUBSCRIBE /topic/exceptions
SUBSCRIBE /user/queue/todos
SUBSCRIBE /user/queue/notifications
```

# **第 12 章 原型中 “点不动按钮” 的业务推理补全**

原型里部分按钮在 HTML 上没接事件，下面把它们都补全了一份业务释义。

| **原型按钮** | **推理出的业务** |
| --- | --- |
| 修改工单 | 仅 “待派工” 状态可改，调 PUT /workorders/{id}，其它状态直接 403。 |
| 复制新增 | 复制源工单全部字段（除工单号、状态、操作员、实际时间），工艺路线不可编辑。 |
| 整线启动（操作员） | 校验当前工单状态必须 “已派工” 且 operator_id 等于当前用户；产线必须空闲；通过后调 POST /workorders/{id}/start + POST /lines/{id}/start。 |
| 整线停止 | 若当前没有正在生产的工单，直接置为待机；若有，置为暂停中并把工单切到 “暂停中”。 |
| 整线复位 | 异常处理后才显示；清空所有工作站计数器，工单状态保持不变。 |
| 确认完工 | 班组长在 “已报工” 状态点击，调 confirm 接口，建议要求至少一条质检记录。 |
| 报废 | 暂停 / 已报工 状态都可用，弹二次确认对话框，调 scrap 接口，工单进入终态。 |
| 扫码开工 (SN) | 操作员点击 → 进入扫码界面 → SN 注入工单 → 调 start。SN 用于追溯单件产品。 |
| 返工 | 若质检不通过，班组长可基于原工单创建 “返工” 工单（type=rework），数量为不通过数。 |

# **第 13 章 开发推进路线（建议执行顺序）**

作为一个 “只懂代码、不懂业务” 的开发者，建议按以下顺序推进，把风险大的部分前置：

### **Phase 1：搭骨架（1 ~ 2 周）**

- 后端：Spring Boot + MyBatis-Plus 起一个工程，把第 4 章 12 张表全部建出来；写一份数据库初始化脚本，预填管理员、4 个车间、4 条产线、7 个工作站、3 个产品、几条工艺。
- 后端：实现 /auth/login、/me 和最基础的 RBAC 拦截器。
- 前端：搭鸿蒙工程，做登录页 + 4 个角色工作台空壳，AppStorage 存 token / user / role。
- 前后端：约定 API 风格（统一 ResponseEntity<R<T>>、统一错误码）。
### **Phase 2：工单主链路（2 ~ 3 周）**

- 实现工单状态机的全部接口（create / dispatch / start / pause / resume / report / confirm / scrap）。
- 前端做工单列表 + 6 个详情变体页面（待派工 / 已派工 / 生产中 / 待报工 / 已报工 / 暂停）。
- 跑通：管理员造工单 → 班组长派工 → 操作员开工 → 报工 → 班组长确认。这一步通了，核心闭环就活了。
### **Phase 3：产线仿真（2 ~ 3 周，最难）**

- 写后端的 LineSimulator：每条 “生产中” 产线挂一个 1 秒 Tick 任务，按工艺顺序推进 7 个工作站。
- 引入 WebSocket（Spring + STOMP），做 /topic/lines/{id} 推送通道，前端先用一个简单页面接收并打印。
- 做产线详情页 + 工作站详情页的实时刷新；这一步通了，“工业味” 就有了。
### **Phase 4：多窗口联动验证（1 周，关键里程碑）**

- 用两台手机或两个鸿蒙模拟器，分别登录操作员和班组长，验证窗口 A 操作 → 窗口 B 同步变化（对标原型实测结果）。
- 做断线重连、订阅解绑、心跳等鲁棒性测试。
- 验收标准：A 操作 B 看到的延迟 < 2 秒，断网 30 秒后恢复能自动重连并拉全量。
### **Phase 5：质检 / 看板 / 异常（1 ~ 2 周）**

- 质检员抽检 → 班组长确认完工的链路打通。
- 看板接口 + 鸿蒙图表（mpchart）。
- 异常上报 + 班组长异常处理。
### **Phase 6：管理员后台与人员管理（1 周）**

- 人员 CRUD、产线 / 工艺基础数据维护、全局工单总览。
### **Phase 7：打磨（1 周）**

- 权限矩阵全量回归。
- 性能：仿真 Tick 在多产线并行时的 CPU 占用、WebSocket 推送频率。
- UI 细节、错误提示、空状态。
**总周期估算  **单人全栈大约 10 ~ 13 周；前后端各一人并行约 6 ~ 8 周。

# **附录 A：开发自查清单**

在开始编码前，对照下面的清单确认你已经搞清楚了所有关键点：

- ☐ 我能用一句话说清楚 MES 是什么。
- ☐ 我能默写工单状态机的 8 个状态和 8 个迁移动作。
- ☐ 我能说出柔性组装线的 7 个工序顺序。
- ☐ 我知道哪些动作必须广播给其它窗口（第 9.2 节那张表）。
- ☐ 我知道为什么工艺路线要做快照（不快照会有什么后果）。
- ☐ 我知道一个操作员同时只能持有一个 “激活” 工单。
- ☐ 我知道质检抽检比例的业务规则（5% ~ 10%）。
- ☐ 我知道异常上报后的处理路径（恢复 vs 报废）。
- ☐ 我能解释 “为什么实时推送不能用轮询”，并能说出 WebSocket / SSE / MQTT 各自的适用场景。
- ☐ 我知道原型用 localStorage 模拟实时同步，真实开发要换成 WebSocket，业务语义不变。
# **附录 B：词条速查（按字母序）**

| **缩写 / 术语** | **完整说法** | **一句话解释** |
| --- | --- | --- |
| BOM | Bill of Materials | 产品的零件清单 |
| MES | Manufacturing Execution System | 车间执行层中间件 |
| MO | Manufacturing Order | 工单（生产订单） |
| MQTT | Message Queuing Telemetry Transport | 物联网设备常用的轻量消息协议 |
| NG | No Good | 不合格品 |
| OEE | Overall Equipment Effectiveness | 设备综合效率 |
| OP | Operation | 工序 |
| RBAC | Role Based Access Control | 基于角色的权限控制 |
| SMT | Surface Mount Technology | 表面贴装工艺 |
| SN | Serial Number | 产品序列号 |
| SOP | Standard Operating Procedure | 标准作业指导书 |
| SSE | Server-Sent Events | 服务端推送协议（单向） |
| STOMP | Streaming Text Oriented Messaging Protocol | WebSocket 上常用的子协议，做发布订阅 |
| WS | WebSocket | 服务端推送协议（双向） |

# **附录 C：本文档与原型的差异说明**

原型只提供了静态页面演示，本文档在原型基础上补全了以下推理内容（开发时请以本文档为准）：

- 工单状态机的完整定义（原型只显示状态名，未显示迁移规则）。
- 数据模型 12 张表（原型没有数据库设计）。
- 实时状态同步机制：原型用 localStorage 模拟，本文档给出 WebSocket / STOMP 的生产级方案。
- 产线仿真器的后端实现思路（原型只展示前端动画）。
- 接口清单（原型没有 API 设计）。
- 点不动按钮的业务推理（修改 / 复制 / 报废 / 扫码开工等）。
# **附录 D：与业务方确认的 5 个未决问题**

以下是从原型中无法完全确定、建议开发前找业务方对齐的点：

| **问题** | **我的默认假设** |
| --- | --- |
| 返工工单是否独立于原工单单独计件？ | 是，type=rework，单独走完整状态机，但 source_workorder_id 关联原工单。 |
| 确认工时是否强校验存在 inspection_record？ | 建议强校验，但作为业务校验（前端禁用按钮 + 后端 400），不做数据库强约束。 |
| 一个工单在多条产线上跑，是否支持？ | 暂不支持。一个工单绑定一条产线，跨线生产用多个工单。 |
| 产线异常后，工单是 “暂停” 还是 “保持生产中”？ | 异常上报会把工单切到 “暂停中”，恢复后回到 “生产中”，报废则进终态。 |
| 报工时录入的工时是 “实际工时” 还是 “申报工时”？ | “申报工时”，可与系统计算的 “产线运行时长” 不一致，由班组长在确认时复核。 |