# MESSystem — 制造执行系统（MES）工业管理应用

基于 Spring Boot 3.2.5 + HarmonyOS ArkUI V2 的前后端一体制造执行系统，覆盖工单全生命周期、产线实时监控、质量检验与异常处理，支持 Docker Compose 一键编排。

## 功能特性

| 模块 | 功能 |
|------|------|
| 登录 | JWT 认证、记住登录、多角色快捷入口 |
| 首页 | 生产数据看板（按角色定制：班长 / 操作工 / 质检 / 管理员） |
| 工单 | 完整状态机（待派工 → 已派工 → 生产中 ⇄ 暂停中 → 生产完成 → 已报工 → 完工，可分支报废）、按工艺过滤 |
| 产线 / 车间 | 产线增删改、工位实时状态、WebSocket 推送 |
| 质检 | 检验录入与记录 |
| 异常 | 异常上报与处理 |
| 用户 | 用户管理 CRUD、RBAC 权限控制 |
| 实时推送 | STOMP over WebSocket（产线 / 异常 / 首页 / 用户等 9 类广播） |
| 产线模拟器 | 7 工位（OP10–OP70）自动生产模拟（良品率可配置） |

## 技术架构

### 后端 — Spring Boot 3.2.5 (Java 17)

- MyBatis-Plus 3.5.5（Lambda 查询，运行时生成 CRUD，13 个实体）
- MySQL 8.0 + Redis 7（Docker Compose 编排），13 张表，`production_log` 按月分区
- JWT 认证链 + `@RequiresPermission` 注解式 RBAC（AOP 校验，`"*"` 为管理员通配）
- STOMP WebSocket 实时推送（内存代理，`/ws` 端点 + SockJS）
- 工单状态机（`WorkOrderServiceImpl` 完整实现）、生产线模拟器（`ScheduledExecutorService` 驱动）
- 配置分 Profile：`dev`（本地默认）/ `prod`（全环境变量，`JWT_SECRET` 必填）/ `test`（H2 内存库）
- 测试：14 个 E2E + 2 个基类 + 2 个单测，H2 内存库运行，无需 Docker

### 前端 — HarmonyOS ArkUI V2 (API 22)

- 11 模块架构（4 common + 6 feature + 1 HAP），严格单向依赖规则
- MVVM：Model → ViewModel（`@ObservedV2` + `@Trace`）→ View（`@ComponentV2`）
- 4 个 Tab 各自独立 `Navigation` + `NavPathStack` 导航
- 自实现 STOMP over WebSocket 客户端（指数退避重连、心跳、订阅重放）
- 响应式布局（sm / md / lg 断点：底部 Tab / 侧栏导航）

## 项目结构

```
MES/
├── BackEnd/              # Spring Boot 后端（org.example，13 个核心包）
├── FrontEnd/             # HarmonyOS 前端（11 模块：datastore/network/uicomponents/utils + login/home/workorder/production/quality/user + products/default）
├── docker-compose.yml    # MySQL 8.0 + Redis 7 + backend
├── 资料/                 # 设计文档（需求 / 设计书 / 接口 / 数据库 / 测试 / 对话记录）
├── UI设计原型/           # 24 个 HTML 高保真原型 + NAVIGATION.md 索引
└── reports/              # 交付报告、测试报告
```

## 快速开始

### Docker Compose（推荐）

```bash
cp .env.example .env     # 修改 MYSQL_ROOT_PASSWORD 与 JWT_SECRET 为安全值
docker-compose up -d     # 启动 MySQL + Redis + 后端
```

健康检查：`POST http://localhost:8080/auth/login`

### 后端本地运行

```bash
cd BackEnd
mvn spring-boot:run                     # 运行（需本地 MySQL + Redis）
mvn test                                # 全部测试（H2，无需 Docker）
mvn package -DskipTests                 # 打包（target/*.jar）
```

### 前端

```bash
cd FrontEnd
ohpm install                            # 安装依赖
hvigor assembleDebug                    # 构建 debug HAP
```

使用 DevEco Studio 打开 `FrontEnd/` 目录，在模拟器或真机运行。

## 文档索引

| 文档 | 路径 |
|------|------|
| 需求文档 V1.0 | `资料/工业管理APP_需求文档_V1.0.md` |
| 后端设计书 | `资料/项目设计/设计书/后端SpringBoot设计书.md` |
| 前端设计书 | `资料/项目设计/设计书/前端Harmony设计书.md` |
| 数据库设计 | `资料/项目设计/数据库设计/后端MySQL设计书.md` |
| 接口设计 | `资料/项目设计/接口设计/` |
| 测试设计 | `资料/项目设计/测试设计/` |
| 项目实施计划 | `资料/项目设计/项目实施计划书.md` |
| UI 原型索引 | `UI设计原型/NAVIGATION.md` |
| 交付 / 测试报告 | `reports/` |
| 开发对话记录 | `资料/对话记录/`（P1–P5） |

## 提交规范

中文 Conventional Commits，9 种 type × 13 种 scope，详见 `资料/项目设计/git-commit-template.md`。

## 说明

个人实训 / 学习项目，仅供学习交流使用。
