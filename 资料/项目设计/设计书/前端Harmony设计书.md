# 前端 HarmonyOS ArkUI 设计书

## 1. 概述

本文档定义工业管理 APP 前端的技术架构、页面结构、状态管理、组件设计与实时通信方案。

**技术栈**：HarmonyOS + ArkTS + ArkUI（V2 状态管理）
**目标设备**：Phone（393×852）为主，预留平板/折叠屏扩展
**HarmonyOS API**：API 22（SDK 6.0.2(22)）
**架构模式**：MVVM（Model-View-ViewModel）
**状态管理**：ArkUI V2（`@Local` / `@Param` / `@Event` / `@Trace` / `@ObservedV2`）
**导航路由**：Navigation + NavPathStack
**模块架构**：common → features → products（多端部署规范）
**关联文档**：[前端需求分析](../需求分析/前端需求分析.md)、[前端接口设计](../接口设计/前端接口设计.md)、[前端UI设计](../UI设计/前端UI设计/前端UI设计书.md)、[后端SpringBoot设计书](后端SpringBoot设计书.md)

## 2. 工程架构

### 2.1 三层架构定义

参考知识库 [HarmonyOS ArkTS 架构学习记录](../../../../ObsidianKu/Claude知识库/技术栈/前端/HarmonyOS ArkTS 架构学习记录.md) 的分层规范，采用 **common → features → products** 三层架构，符合 HarmonyOS 官方推荐的多端部署工程规范。

#### 2.1.1 分层总览

| 层级 | 名称 | 编译输出 | 职责 | 对应目录 |
|:---|:---|:---|:---|:---|
| **第一层** | 公共能力层（common） | HAR / HSP | 数据模型、网络请求、公共组件、工具类、常量 | `common/` |
| **第二层** | 基础特性层（features） | HAR / HSP / Feature HAP | 业务页面、ViewModel、业务组件 | `features/*/` |
| **第三层** | 产品定制层（products） | Entry HAP | 应用入口、导航路由、设备适配布局 | `products/default/` |

**依赖方向（严格单向）**：

```
products/default （产品定制层 · 默认设备泛类）
      │
      ├──────────────┬──────────────┬──────────────┐
      ▼              ▼              ▼              ▼
features/login  features/home  features/workorder  ... （基础特性层）
      │              │              │
      └──────────────┴──────────────┘
                     │
                     ▼
              common/ （公共能力层）
```

- `common` 无外部依赖，向 `features` 和 `products` 提供基础能力
- `features` 可依赖 `common`，各 feature 模块之间**禁止横向调用**
- `products/default` 可依赖 `common` 和所有 `features`；`products` 层各子目录之间**禁止横向调用**
- 严禁反向依赖（如 `common` 不可引用 `features`，`features` 不可引用 `products`）

#### 2.1.2 第一层：公共能力层（common）

承载全应用共享的基础能力，**不包含任何业务逻辑**。

| 目录 | 内容 | 示例 |
|------|------|------|
| `components/` | 公共 UI 组件 | StatusTag、WorkOrderCard、StationCard、KpiCard |
| `models/` | 数据模型与枚举 | WorkOrderModel、UserModel、StationModel、RoleEnum |
| `utils/` | 工具类 | PermissionUtil、DateUtil、FormatUtil、BreakpointUtil、PreferencesUtil |
| `api/` | 网络接口封装 | HttpClient、AuthApi、WorkOrderApi、LineApi、QualityApi、WebSocketService |
| `constants/` | 常量定义 | ApiConstants、RoleConstants、StatusConstants |

**对外暴露方式**：`common/Index.ets` 统一导出（与 `src/` 同级，作为 HAR 模块主入口）

```typescript
// common/Index.ets
export { StatusTag } from './src/main/ets/components/StatusTag';
export { WorkOrderCard } from './src/main/ets/components/WorkOrderCard';
export { WorkOrderModel } from './src/main/ets/models/WorkOrderModel';
export { UserModel } from './src/main/ets/models/UserModel';
export { HttpClient } from './src/main/ets/api/HttpClient';
export { AuthApi } from './src/main/ets/api/AuthApi';
export { PermissionUtil } from './src/main/ets/utils/PermissionUtil';
export { RoleConstants } from './src/main/ets/constants/RoleConstants';
```

#### 2.1.3 第二层：基础特性层（features）

按业务领域拆分为独立模块，每个 feature 是一个完整自闭合的业务单元，包含自己的 Page + ViewModel。

| 模块 | 业务领域 | 包含页面 | ViewModel |
|------|---------|---------|-----------|
| `features/login` | 登录认证 | LoginPage | LoginViewModel |
| `features/home` | 工作台 | LeaderHomePage、OperatorHomePage、InspectorHomePage、AdminHomePage | HomeViewModel |
| `features/workorder` | 工单管理 | WorkOrderListPage、WorkOrderAddPage、WorkOrderEditPage、WorkOrderCopyPage、6个详情页 | WorkOrderViewModel |
| `features/production` | 生产执行 | ProductionTasksPage、LineListPage、LineDetailPage、StationDetailPage | ProductionViewModel |
| `features/quality` | 质检管理 | InspectionListPage、InspectionDetailPage、DashboardPage | QualityViewModel |
| `features/user` | 人员与账号 | EmployeeListPage、ProfilePage | UserViewModel |

**feature 模块内部结构**：

按 MVVM 分层，每个 feature 模块内部划分为 `View/`、`ViewModel/`、`Model/` 三个子目录：

```
features/workorder/
├── src/main/ets/
│   ├── View/                        # View 层
│   │   ├── WorkOrderListPage.ets      # 工单列表页面
│   │   ├── WorkOrderAddPage.ets       # 新增工单页面
│   │   ├── WorkOrderEditPage.ets      # 修改工单页面
│   │   ├── WorkOrderCopyPage.ets      # 复制工单页面
│   │   └── Detail/                    # 详情页面集合
│   │       ├── PendingDetailPage.ets    # 待派工
│   │       ├── AssignedDetailPage.ets   # 已派工
│   │       ├── RunningDetailPage.ets    # 生产中
│   │       ├── CompletedDetailPage.ets  # 生产完成
│   │       ├── ReportedDetailPage.ets   # 已报工（完工/报废终态共用）
│   │       └── PausedDetailPage.ets     # 暂停中
│   ├── ViewModel/                   # ViewModel 层
│   │   └── WorkOrderViewModel.ets     # 工单业务逻辑与状态
│   └── Model/                       # Model 层（模块内数据模型）
│       └── WorkOrderRouteModel.ets    # 工艺路线模型（仅本模块使用）
├── Index.ets                        # 模块导出入口（与 src 同级）
├── oh-package.json5
└── build-profile.json5
```

**feature 模块依赖配置**：

```json5
// features/workorder/oh-package.json5
{
  "name": "@ohos/workorder",
  "version": "1.0.0",
  "description": "工单管理模块",
  "main": "Index.ets",
  "dependencies": {
    "@ohos/common": "file:../../common"
  }
}
```

#### 2.1.4 第三层：产品定制层（products/default）

默认设备泛类，编译为 Entry HAP，是应用的**唯一入口**。负责导航路由、设备适配、全局状态初始化。**不包含任何业务逻辑代码**，只做"粘合剂"。

当前项目采用**单 Entry HAP + 断点适配**方案（`default` 泛类覆盖手机/平板/折叠屏）。未来如需针对平板或折叠屏独立打包，可创建同级 Entry HAP（如 `products/tablet/`）。

| 目录 | 职责 |
|------|------|
| `entryability/` | EntryAbility 入口，启动时初始化 Preferences |
| `pages/Index.ets` | 根页面：`@Provider` 全局状态 + `Navigation` + `NavDestination` 路由表 |
| `login/LoginPage.ets` | 登录页 NavDestination 包装器（内部引用 `features/login` 的 `LoginView`） |
| `main/MainPage.ets` | 主页 NavDestination 包装器 + 断点分发 |
| `product/phone/` | 手机布局（底部 TabBar） |
| `product/tablet/` | 平板布局（左侧导航栏） |
| `product/foldable/` | 折叠屏布局（宽导航 + 内容区） |

**products 层依赖配置**：

```json5
// products/default/oh-package.json5
{
  "dependencies": {
    "@ohos/login": "file:../../features/login",
    "@ohos/home": "file:../../features/home",
    "@ohos/workorder": "file:../../features/workorder",
    "@ohos/production": "file:../../features/production",
    "@ohos/quality": "file:../../features/quality",
    "@ohos/user": "file:../../features/user",
    "@ohos/common": "file:../../common"
  }
}
```

#### 2.1.5 完整工程目录

```
MES/FrontEnd/
├── common/                           # 第一层：公共能力层（HAR）
│   ├── Index.ets                     # 统一导出入口（与 src 同级）
│   └── src/main/ets/
│       ├── components/               # 公共组件
│       │   ├── StatusTag.ets
│       │   ├── WorkOrderCard.ets
│       │   ├── StationCard.ets
│       │   ├── KpiCard.ets
│       │   └── ExceptionCard.ets
│       ├── models/                   # 数据模型
│       │   ├── UserModel.ets
│       │   ├── WorkOrderModel.ets
│       │   ├── LineModel.ets
│       │   ├── StationModel.ets
│       │   └── InspectionModel.ets
│       ├── api/                      # 网络接口
│       │   ├── HttpClient.ets
│       │   ├── AuthApi.ets
│       │   ├── WorkOrderApi.ets
│       │   ├── LineApi.ets
│       │   ├── QualityApi.ets
│       │   ├── UserApi.ets
│       │   └── WebSocketService.ets
│       ├── utils/                    # 工具类
│       │   ├── DateUtil.ets
│       │   ├── FormatUtil.ets
│       │   ├── PermissionUtil.ets
│       │   ├── BreakpointUtil.ets
│       │   └── PreferencesUtil.ets
│       └── constants/                # 常量
│           ├── ApiConstants.ets
│           ├── RoleConstants.ets
│           └── StatusConstants.ets
│
├── features/                         # 第二层：基础特性层（HAR）
│   ├── login/
│   │   ├── Index.ets                 # 模块导出入口（与 src 同级）
│   │   └── src/main/ets/
│   │       ├── View/
│   │       │   └── LoginPage.ets
│   │       ├── ViewModel/
│   │       │   └── LoginViewModel.ets
│   │       └── Model/
│   │           └── LoginModel.ets
│   ├── home/
│   │   ├── Index.ets                 # 模块导出入口
│   │   └── src/main/ets/
│   │       ├── View/
│   │       │   ├── LeaderHomePage.ets
│   │       │   ├── OperatorHomePage.ets
│   │       │   ├── InspectorHomePage.ets
│   │       │   └── AdminHomePage.ets
│   │       └── ViewModel/
│   │           └── HomeViewModel.ets
│   ├── workorder/
│   │   ├── Index.ets                 # 模块导出入口
│   │   └── src/main/ets/
│   │       ├── View/
│   │       │   ├── WorkOrderListPage.ets
│   │       │   ├── WorkOrderAddPage.ets
│   │       │   ├── WorkOrderEditPage.ets
│   │       │   ├── WorkOrderCopyPage.ets
│   │       │   └── Detail/
│   │       │       ├── PendingDetailPage.ets
│   │       │       ├── AssignedDetailPage.ets
│   │       │       ├── RunningDetailPage.ets
│   │       │       ├── CompletedDetailPage.ets
│   │       │       ├── ReportedDetailPage.ets
│   │       │       └── PausedDetailPage.ets
│   │       ├── ViewModel/
│   │       │   └── WorkOrderViewModel.ets
│   │       └── Model/
│   │           └── WorkOrderRouteModel.ets
│   ├── production/
│   │   ├── Index.ets                 # 模块导出入口
│   │   └── src/main/ets/
│   │       ├── View/
│   │       │   ├── ProductionTasksPage.ets
│   │       │   ├── LineListPage.ets
│   │       │   ├── LineDetailPage.ets
│   │       │   └── StationDetailPage.ets
│   │       └── ViewModel/
│   │           └── ProductionViewModel.ets
│   ├── quality/
│   │   ├── Index.ets                 # 模块导出入口
│   │   └── src/main/ets/
│   │       ├── View/
│   │       │   ├── InspectionListPage.ets
│   │       │   ├── InspectionDetailPage.ets
│   │       │   └── DashboardPage.ets
│   │       └── ViewModel/
│   │           └── QualityViewModel.ets
│   └── user/
│       ├── Index.ets                 # 模块导出入口
│       └── src/main/ets/
│           ├── View/
│           │   ├── EmployeeListPage.ets
│           │   └── ProfilePage.ets
│           └── ViewModel/
│               └── UserViewModel.ets
│
└── products/default/                 # 第三层：产品定制层（Entry HAP · 默认设备泛类）
    └── src/main/ets/
        ├── entryability/
        │   └── EntryAbility.ets
        ├── pages/
        │   └── Index.ets             # 根页面（Navigation + NavPathStack + @Provider）
        ├── login/
        │   └── LoginPage.ets         # 登录页 NavDestination 包装器
        ├── main/
        │   └── MainPage.ets          # 主页 NavDestination 包装器 + 断点分发
        └── product/
            ├── phone/
            │   └── PhoneMainLayout.ets
            ├── tablet/
            │   └── TabletMainLayout.ets
            └── foldable/
                └── FoldableMainLayout.ets
```

### 2.2 模块依赖配置

```json5
// products/default/oh-package.json5
{
  "dependencies": {
    "@ohos/login": "file:../../features/login",
    "@ohos/home": "file:../../features/home",
    "@ohos/workorder": "file:../../features/workorder",
    "@ohos/production": "file:../../features/production",
    "@ohos/quality": "file:../../features/quality",
    "@ohos/user": "file:../../features/user",
    "@ohos/common": "file:../../common"
  }
}
```

## 3. MVVM 架构

### 3.1 分层定义

| 层级 | 目录 | 职责 |
|:---|:---|:---|
| **Model** | `common/models/`、`common/api/` | 数据模型定义、网络请求、本地存储（Preferences） |
| **View** | `features/*/src/main/ets/*Page.ets` | UI 构建与渲染、用户交互事件绑定 |
| **ViewModel** | `features/*/src/main/ets/*ViewModel.ets` | UI 状态管理、业务逻辑处理、数据转换 |

**分层原则**：
- View 不直接调用 API，通过 ViewModel 方法
- Model 通过数据变化通知 ViewModel，ViewModel 通过 `@Trace` 通知 View
- ViewModel 可独立测试，API 属性默认注入 mock 函数

### 3.2 ViewModel 清单

| ViewModel | 管理状态 |
|-----------|---------|
| `LoginViewModel` | 账号、密码、加载状态、登录结果 |
| `HomeViewModel` | 待办列表、KPI 数据、快捷入口 |
| `WorkOrderViewModel` | 工单列表、当前工单、状态机操作、筛选条件 |
| `ProductionViewModel` | 产线列表、当前产线、工作站状态、仿真控制 |
| `QualityViewModel` | 待抽检列表、抽检表单、看板数据 |
| `UserViewModel` | 人员列表、编辑表单、角色筛选 |

### 3.3 ViewModel 代码示例

```typescript
// features/workorder/src/main/ets/WorkOrderViewModel.ets
import { WorkOrderApi } from '@ohos/common';
import { WorkOrderModel } from '@ohos/common';

@ObservedV2
export class WorkOrderViewModel {
  @Trace workOrderList: WorkOrderModel[] = [];
  @Trace currentWorkOrder: WorkOrderModel | null = null;
  @Trace isLoading: boolean = false;
  @Trace statusFilter: string = '';
  @Trace errorMessage: string = '';

  async loadWorkOrders(role: string, filters?: object): Promise<void> {
    this.isLoading = true;
    try {
      this.workOrderList = await WorkOrderApi.getWorkOrders({ role, ...filters });
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async dispatch(operatorId: number): Promise<void> {
    if (!this.currentWorkOrder) return;
    this.isLoading = true;
    try {
      await WorkOrderApi.dispatchWorkOrder(this.currentWorkOrder.id, operatorId);
      this.currentWorkOrder.status = '已派工';
      this.currentWorkOrder.operatorId = operatorId;
    } finally {
      this.isLoading = false;
    }
  }

  async startProduction(): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.startWorkOrder(this.currentWorkOrder.id);
    this.currentWorkOrder.status = '生产中';
  }

  async pauseProduction(reason: string): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.pauseWorkOrder(this.currentWorkOrder.id, reason);
    this.currentWorkOrder.status = '暂停中';
  }

  async resumeProduction(): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.resumeWorkOrder(this.currentWorkOrder.id);
    this.currentWorkOrder.status = '生产中';
  }

  async report(good: number, ng: number, hours: number, note?: string): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.reportWorkOrder(this.currentWorkOrder.id, { good, ng, hours, note });
    this.currentWorkOrder.status = '已报工';
  }

  async confirm(): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.confirmWorkOrder(this.currentWorkOrder.id);
    this.currentWorkOrder.status = '完工';
  }

  async scrap(): Promise<void> {
    if (!this.currentWorkOrder) return;
    await WorkOrderApi.scrapWorkOrder(this.currentWorkOrder.id);
    this.currentWorkOrder.status = '报废';
  }

  canEdit(): boolean {
    return this.currentWorkOrder?.status === '待派工';
  }

  canDispatch(): boolean {
    return this.currentWorkOrder?.status === '待派工';
  }

  canStart(): boolean {
    return this.currentWorkOrder?.status === '已派工';
  }

  canPause(): boolean {
    return this.currentWorkOrder?.status === '生产中';
  }

  canResume(): boolean {
    return this.currentWorkOrder?.status === '暂停中';
  }

  canReport(): boolean {
    return this.currentWorkOrder?.status === '生产完成';
  }

  canConfirm(): boolean {
    return this.currentWorkOrder?.status === '已报工';
  }

  canScrap(): boolean {
    const s = this.currentWorkOrder?.status;
    return s === '暂停中' || s === '已报工';
  }
}
```

### 3.4 View 层绑定示例

```typescript
// features/workorder/src/main/ets/WorkOrderListPage.ets
import { WorkOrderViewModel } from './WorkOrderViewModel';
import { WorkOrderCard } from '@ohos/common';

@ComponentV2
export struct WorkOrderListPage {
  @Param role: string = '';
  @Event onNavigate: (name: string, params?: object) => void = () => {};

  private vm: WorkOrderViewModel = new WorkOrderViewModel();

  aboutToAppear(): void {
    this.vm.loadWorkOrders(this.role);
  }

  build() {
    Column() {
      // 搜索栏
      Search({ placeholder: '搜索工单号...' })
        .onSubmit((value: string) => {
          this.vm.loadWorkOrders(this.role, { keyword: value });
        });

      // 状态筛选
      StatusFilterBar({
        selectedStatus: this.vm.statusFilter,
        onSelect: (status: string) => {
          this.vm.statusFilter = status;
          this.vm.loadWorkOrders(this.role, { status });
        }
      });

      // 工单列表
      List() {
        ForEach(this.vm.workOrderList, (wo: WorkOrderModel) => {
          ListItem() {
            WorkOrderCard({
              workOrder: wo,
              role: this.role,
              onClick: () => {
                this.onNavigate('WorkOrderDetail', { id: wo.id, status: wo.status });
              }
            });
          }
        });
      };

      // 加载状态
      if (this.vm.isLoading) {
        LoadingProgress();
      }
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}
```

## 4. V2 状态管理装饰器

全面采用 V2 装饰器，**严禁混用 V1**。

| V1 装饰器 | V2 装饰器 | 使用场景 |
|-----------|-----------|---------|
| `@State` | `@Local` | 页面/组件内部状态 |
| `@Prop` | `@Param` | 父到子单向传参 |
| `@Link` | `@Param` + `@Event` | 父子双向同步（自定义事件回调） |
| `@Provide`/`@Consume` | `@Provider()`/`@Consumer()` | 跨层级共享 NavPathStack、全局状态 |
| `@Observed`/`@ObjectLink` | `@ObservedV2`/`@Trace` | ViewModel 类属性深度观测 |
| `@Watch` | `@Monitor` | 监听状态变化（高级场景） |

### 4.1 全局状态共享（导航栈 + 用户信息）

```typescript
// products/default/src/main/ets/pages/Index.ets
@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provider('currentUser') currentUser: UserModel = new UserModel();
  @Provider('currentRole') currentRole: string = '';

  @Builder
  PageMap(name: string) {
    if (name === 'LoginPage') { LoginPage() }
    else if (name === 'MainPage') { MainPage() }
  }

  async aboutToAppear(): Promise<void> {
    try {
      await PreferencesUtil.init();
      const token = PreferencesUtil.get('token');
      if (token) {
        this.currentRole = PreferencesUtil.get('role') || '';
        this.pageStack.replacePath({ name: 'MainPage' });
      } else {
        this.pageStack.replacePath({ name: 'LoginPage' });
      }
    } catch (e) {
      // Preferences 初始化失败（如首次启动），直接进入登录页
      this.pageStack.replacePath({ name: 'LoginPage' });
    }
  }

  build() {
    Navigation(this.pageStack) {
      Stack() {}
    }
    .hideTitleBar(true)
    .hideNavBar(true)
    .navDestination(this.PageMap);
  }
}
```

### 4.2 子页面消费全局状态

```typescript
// features/home/src/main/ets/LeaderHomePage.ets
@ComponentV2
export struct LeaderHomePage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

  private vm: HomeViewModel = new HomeViewModel();

  build() {
    NavDestination() {
      Column() {
        Text(`${this.currentUser.name} 的工作台`);
        // ... 工作台内容
      }
    }
  }
}
```

### 4.3 组件参数传递

```typescript
// common/src/main/ets/components/WorkOrderCard.ets
@ComponentV2
export struct WorkOrderCard {
  @Param workOrder: WorkOrderModel = new WorkOrderModel();
  @Param role: string = '';
  @Event onClick: () => void = () => {};
  @Event onDispatch: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text(this.workOrder.code)
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        StatusTag({ status: this.workOrder.status });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);

      Text(`产品：${this.workOrder.productName} | 数量：${this.workOrder.planQty}`);

      if (this.role === 'leader' && this.workOrder.status === '待派工') {
        Button('派工')
          .onClick(() => this.onDispatch());
      }
    }
    .padding(16)
    .backgroundColor('#fff')
    .borderRadius(8)
    .width('100%')
    .onClick(() => this.onClick());
  }
}
```

## 5. Navigation 导航架构

### 5.1 为什么不用旧版 Router？

| 特性 | 旧版 `@ohos/router` | Navigation + NavPathStack |
|------|-------------------|--------------------------|
| 架构模式 | 命令式，全局单例 | 声明式，组件化 |
| 参数传递 | URL Query 字符串 | 对象直接传递 |
| 栈管理 | 不可见，难控制 | 可视化，精准操控 |
| 生命周期 | 简单 | show/hide/ready 钩子 |
| 动效支持 | 基础 | 丰富的转场动画 |

### 5.2 路由表定义

```typescript
// products/default/src/main/ets/pages/Index.ets
@Builder
PageMap(name: string, param?: object) {
  if (name === 'LoginPage') {
    LoginPage();
  } else if (name === 'MainPage') {
    MainPage();
  }
}
```

### 5.3 页面跳转

```typescript
// 登录成功后跳转主页面（replacePath 避免栈累积）
this.pageStack.replacePath({ name: 'MainPage' });

// 跳转工单详情（带参数）
this.pageStack.pushPath({
  name: 'WorkOrderDetail',
  param: { workOrderId: 10086, status: '待派工' }
});

// 返回上一级
this.pageStack.pop();

// 登出返回登录页
this.pageStack.replacePath({ name: 'LoginPage' });
```

### 5.4 页面参数接收

```typescript
// features/workorder/src/main/ets/Detail/PendingDetailPage.ets
@ComponentV2
export struct PendingDetailPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    // 从 NavDestination 上下文获取路由参数
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    this.vm.loadDetail(this.workOrderId);
  }

  build() {
    NavDestination() {
      Column() {
        // 详情内容
      }
    }
  }
}
```

## 6. 多设备适配（断点系统）

### 6.1 断点定义

| 断点 | 宽度范围 (vp) | 典型设备 | 布局 |
|:---|:---|:---|:---|
| **sm** | < 600 | 手机竖屏 | 底部 TabBar |
| **md** | 600 - 839 | 手机横屏 / 平板竖屏 | 左侧导航栏 |
| **lg** | >= 840 | 平板横屏 / 折叠屏 | 宽导航 + 内容区 |

### 6.2 断点工具实现

```typescript
// common/src/main/ets/utils/BreakpointUtil.ets
export class BreakpointUtil {
  static getBreakpoint(width: number): string {
    if (width < 600) { return 'sm'; }
    else if (width < 840) { return 'md'; }
    else { return 'lg'; }
  }
}
```

### 6.3 布局分发

```typescript
// products/default/src/main/ets/main/MainPage.ets
@ComponentV2
export struct MainPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local currentBreakpoint: string = 'sm';

  async aboutToAppear(): Promise<void> {
    const win = await window.getLastWindow(getContext(this));
    const rect = win.getWindowProperties().windowRect;
    this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(rect.width));

    win.on('windowSizeChange', (size: window.Size) => {
      this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(size.width));
    });
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.currentBreakpoint === 'sm') {
          PhoneMainLayout();
        } else if (this.currentBreakpoint === 'md') {
          TabletMainLayout();
        } else {
          FoldableMainLayout();
        }
      }
    }
  }
}
```

### 6.4 手机布局（PhoneMainLayout）

```typescript
// products/default/src/main/ets/product/phone/PhoneMainLayout.ets
@ComponentV2
export struct PhoneMainLayout {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local currentIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.buildHomePage();
      }
      .tabBar(this.buildTabBar('工作台', $r('app.media.icon_home')));

      TabContent() {
        LineListPage();
      }
      .tabBar(this.buildTabBar('数据', $r('app.media.icon_data')));

      TabContent() {
        WorkOrderListPage({ role: this.currentRole });
      }
      .tabBar(this.buildTabBar('工单', $r('app.media.icon_order')));

      TabContent() {
        ProfilePage();
      }
      .tabBar(this.buildTabBar('我的', $r('app.media.icon_profile')));
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    });
  }

  @Builder
  buildHomePage() {
    if (this.currentRole === 'leader') {
      LeaderHomePage();
    } else if (this.currentRole === 'operator') {
      OperatorHomePage();
    } else if (this.currentRole === 'inspector') {
      InspectorHomePage();
    } else {
      AdminHomePage();
    }
  }

  @Builder
  buildTabBar(title: string, icon: Resource) {
    Column() {
      Image(icon).width(24).height(24);
      Text(title).fontSize(12);
    };
  }
}
```

## 7. 网络通信

### 7.1 HTTP 请求封装（V2 风格）

```typescript
// common/src/main/ets/api/HttpClient.ets
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { preferencesUtil } from '../utils/PreferencesUtil';
import { emitter } from '@kit.BasicServicesKit';

const DEFAULT_BASE_URL = 'http://localhost:8080';

// 登录过期事件（products 层监听此事件执行 Navigation 跳转）
const LOGIN_EXPIRED_EVENT: emitter.InnerEvent = { eventId: 10001 };

class HttpClient {
  private http = http.createHttp();
  private baseUrl: string = DEFAULT_BASE_URL;
  private token: string = '';

  // 由 products 层在登录成功后调用，注入运行时配置
  configure(baseUrl: string, token: string): void {
    this.baseUrl = baseUrl || DEFAULT_BASE_URL;
    this.token = token || '';
  }

  // 清除登录态（401 时内部调用，避免直接依赖 Navigation）
  clearAuth(): void {
    this.token = '';
    preferencesUtil.delete('token');
    preferencesUtil.delete('currentUser');
    emitter.emit(LOGIN_EXPIRED_EVENT, { data: {} });
  }

  private getBaseUrl(): string {
    return this.baseUrl;
  }

  private getToken(): string {
    return this.token;
  }

  private async request<T>(
    method: http.RequestMethod,
    path: string,
    data?: object
  ): Promise<T> {
    const url = `${this.getBaseUrl()}${path}`;
    const token = this.getToken();

    try {
      const response = await this.http.request(url, {
        method,
        header: {
          'Content-Type': 'application/json',
          'Authorization': token ? `Bearer ${token}` : ''
        },
        extraData: data ? JSON.stringify(data) : '',
        connectTimeout: 10000,
        readTimeout: 30000
      });

      const result: ApiResponse<T> = JSON.parse(response.result as string);

      if (result.code !== 200) {
        if (result.code === 401) {
          this.clearAuth();
          throw new Error('登录已过期，请重新登录');
        } else if (result.code === 403) {
          promptAction.showToast({ message: '无权限执行此操作' });
          throw new Error(result.message);
        } else {
          promptAction.showToast({ message: result.message || '请求失败' });
          throw new Error(result.message);
        }
      }

      return result.data;
    } catch (error) {
      if (error instanceof SyntaxError) {
        promptAction.showToast({ message: '服务器响应异常' });
      } else if ((error as Error).message.includes('Network') || (error as Error).message.includes('timeout')) {
        promptAction.showToast({ message: '网络连接失败，请检查网络' });
      }
      throw error;
    }
  }

  async get<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path);
  }

  async post<T>(path: string, data?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path, data);
  }

  async put<T>(path: string, data?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, path, data);
  }

  // 预留：部分更新场景（当前后端统一使用 PUT，后续若新增 PATCH 端点时启用）
  async patch<T>(path: string, data?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.PATCH, path, data);
  }

  async delete<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.DELETE, path);
  }
}

export const httpClient = new HttpClient();
```

products 层需在登录成功后调用 `httpClient.configure(baseUrl, token)`，并在根页面监听登录过期事件：

```typescript
// products/default/src/main/ets/pages/Index.ets（登录过期监听示例）
aboutToAppear(): void {
  emitter.on(LOGIN_EXPIRED_EVENT, () => {
    this.pageStack.replacePath({ name: 'LoginPage' });
  });
}
```

### 7.2 WebSocket 单例服务

```typescript
// common/src/main/ets/api/WebSocketService.ets
import { webSocket } from '@kit.NetworkKit';

@ObservedV2
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private reconnectTimer: number = -1;
  private heartbeatTimer: number = -1;
  @Trace isConnected: boolean = false;

  static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  connect(url: string): void {
    this.ws = webSocket.createWebSocket();
    this.ws.connect(url);

    this.ws.on('open', () => {
      this.isConnected = true;
      this.startHeartbeat();
    });

    this.ws.on('message', (data: string) => {
      this.handleMessage(JSON.parse(data));
    });

    this.ws.on('close', () => {
      this.isConnected = false;
      this.scheduleReconnect(url);
    });

    this.ws.on('error', () => {
      this.isConnected = false;
      this.scheduleReconnect(url);
    });
  }

  subscribe(topic: string): void {
    this.send({ action: 'SUBSCRIBE', destination: topic });
  }

  unsubscribe(topic: string): void {
    this.send({ action: 'UNSUBSCRIBE', destination: topic });
  }

  private send(msg: object): void {
    if (this.ws && this.isConnected) {
      this.ws.send(JSON.stringify(msg));
    }
  }

  // 注：setInterval/setTimeout 在非 UI 线程受 ArkTS 严格限制。
  // 原型阶段可直接使用；生产环境应改用 @ohos.taskpool 或 worker 实现心跳与重连。
  private startHeartbeat(): void {
    this.heartbeatTimer = setInterval(() => {
      this.send({ type: 'ping' });
    }, 30000);
  }

  private scheduleReconnect(url: string): void {
    clearInterval(this.heartbeatTimer);
    this.reconnectTimer = setTimeout(() => {
      this.connect(url);
    }, 5000);
  }

  // V2 风格：使用静态 Map 管理 topic 监听器，避免 V1 AppStorage
  private static listeners: Map<string, Function> = new Map();

  static addListener(topic: string, handler: Function): void {
    WebSocketService.listeners.set(topic, handler);
  }

  static removeListener(topic: string): void {
    WebSocketService.listeners.delete(topic);
  }

  private handleMessage(msg: WebSocketMessage): void {
    const listener = WebSocketService.listeners.get(msg.topic);
    if (listener) {
      listener(msg.payload);
    }
  }
}

interface WebSocketMessage {
  topic: string;
  version: number;
  eventId: string;
  payload: object;
}
```

### 7.3 页面级 WebSocket 订阅管理

```typescript
// features/production/src/main/ets/LineDetailPage.ets
@ComponentV2
export struct LineDetailPage {
  @Param lineId: number = 0;
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Trace line: ProductionLine = new ProductionLine();
  @Trace stations: StationModel[] = [];

  private vm: ProductionViewModel = new ProductionViewModel();

  aboutToAppear(): void {
    // 先拉全量
    this.vm.loadLineDetail(this.lineId).then(() => {
      this.line = this.vm.currentLine;
      this.stations = this.vm.stations;
    });
    // 再订阅实时推送
    this.subscribeWS();
  }

  aboutToDisappear(): void {
    this.unsubscribeWS();
  }

  private subscribeWS(): void {
    const ws = WebSocketService.getInstance();
    ws.subscribe(`/topic/lines/${this.lineId}`);
    ws.subscribe(`/topic/lines/${this.lineId}/stations`);

    WebSocketService.addListener(`/topic/lines/${this.lineId}`, (payload: Object) => {
      this.line = payload as ProductionLine;
    });
    WebSocketService.addListener(`/topic/lines/${this.lineId}/stations`, (payload: Object) => {
      const data = payload as Record<string, Object>;
      this.stations = data['stations'] as StationModel[];
    });
  }

  private unsubscribeWS(): void {
    const ws = WebSocketService.getInstance();
    ws.unsubscribe(`/topic/lines/${this.lineId}`);
    ws.unsubscribe(`/topic/lines/${this.lineId}/stations`);

    WebSocketService.removeListener(`/topic/lines/${this.lineId}`);
    WebSocketService.removeListener(`/topic/lines/${this.lineId}/stations`);
  }

  build() {
    NavDestination() {
      Column() {
        LineStatusCard({ line: this.line });

        Row() {
          Button(this.line.status === '生产中' ? '停止' : '启动')
            .onClick(() => this.toggleLine());
          Button('复位')
            .onClick(() => this.resetLine());
          Button('异常上报')
            .onClick(() => this.reportException());
        };

        Grid() {
          ForEach(this.stations, (station: StationModel) => {
            GridItem() {
              StationCard({ station: station });
            }
          });
        }
        .columnsTemplate('1fr 1fr')
        .gap(12);
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
```

## 8. 核心组件设计

### 8.1 状态标签（StatusTag）

```typescript
// common/src/main/ets/components/StatusTag.ets
@ComponentV2
export struct StatusTag {
  @Param status: string = '';

  private getColor(): ResourceColor {
    const map: Record<string, ResourceColor> = {
      '待派工': '#999',
      '已派工': '#1890ff',
      '生产中': '#52c41a',
      '暂停中': '#faad14',
      '生产完成': '#722ed1',
      '已报工': '#13c2c2',
      '完工': '#52c41a',
      '报废': '#f5222d',
      '异常': '#f5222d'
    };
    return map[this.status] || '#999';
  }

  build() {
    Text(this.status)
      .fontSize(12)
      .fontColor(this.getColor())
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor(`${this.getColor()}20`)
      .borderRadius(4);
  }
}
```

### 8.2 工作站卡片（StationCard）

```typescript
// common/src/main/ets/components/StationCard.ets
@ComponentV2
export struct StationCard {
  @Param station: StationModel = new StationModel();
  @Param isActive: boolean = false;

  private getBorderColor(): ResourceColor {
    if (this.station.deviceStatus === '运行中') return '#52c41a';
    if (this.station.deviceStatus === '故障') return '#f5222d';
    return '#999';
  }

  build() {
    Column() {
      Text(this.station.opCode)
        .fontSize(14)
        .fontWeight(FontWeight.Bold);
      Text(this.station.name)
        .fontSize(12)
        .fontColor('#666');

      Row() {
        Circle({ width: 8, height: 8 })
          .fill(this.getBorderColor());
        Text(this.station.deviceStatus)
          .fontSize(12);
      };

      Row() {
        Text(`raw: ${this.station.rawCount}`);
        Text(`good: ${this.station.finishedCount}`);
        Text(`ng: ${this.station.ngCount}`);
      };
    }
    .padding(12)
    .backgroundColor(this.isActive ? '#e6f7ff' : '#fff')
    .borderRadius(8)
    .border({ width: { left: 3 }, color: this.getBorderColor() })
    .width('100%');
  }
}
```

### 8.3 图表组件（DashboardChart）

看板页使用图表展示 KPI 趋势。首选 `@ohos/mpchart`（若 API 22 环境下该库可用），否则降级为 ArkUI `Canvas` 自定义绘制。

```typescript
// common/src/main/ets/components/DashboardChart.ets
@ComponentV2
export struct DashboardChart {
  @Param monthlyRates: MonthlyRate[] = [];

  build() {
    // 方案 A：使用 @ohos/mpchart（若可用）
    // LineChart({ data: this.monthlyRates })

    // 方案 B：Canvas 自定义绘制（降级方案）
    Canvas(this.context)
      .width('100%')
      .height(200)
      .onReady(() => this.drawLineChart());
  }

  private drawLineChart(): void {
    // 使用 CanvasRenderingContext2D 绘制折线图
  }
}
```

**依赖配置（若使用 mpchart）**：

```json5
// default/oh-package.json5
{
  "dependencies": {
    "@ohos/mpchart": "^1.0.0"
  }
}
```

## 9. 权限控制

### 9.1 权限工具

```typescript
// common/src/main/ets/utils/PermissionUtil.ets
export class PermissionUtil {
  static hasPermission(action: string, role: string): boolean {
    const permissions: Record<string, string[]> = {
      'workorder.view_team': ['admin', 'leader'],
      'workorder.view_own': ['admin', 'operator'],
      'workorder.view_inspection': ['admin', 'inspector'],
      'workorder.create': ['admin', 'leader'],
      'workorder.dispatch': ['admin', 'leader'],
      'workorder.start': ['admin', 'operator'],
      'workorder.pause': ['admin', 'operator', 'leader'],
      'workorder.resume': ['admin', 'operator', 'leader'],
      'workorder.report': ['admin', 'operator'],
      'workorder.confirm': ['admin', 'leader'],
      'workorder.scrap': ['admin', 'leader'],
      'line.view': ['admin', 'leader', 'operator', 'inspector'],
      'line.operate': ['admin', 'operator', 'leader'],
      'station.operate': ['admin', 'operator', 'leader'],
      'exception.report': ['admin', 'operator', 'leader'],
      'exception.view': ['admin', 'leader'],
      'exception.handle': ['admin', 'leader'],
      'inspection.create': ['admin', 'inspector'],
      'user.view': ['admin'],
      'user.create': ['admin'],
      'user.update': ['admin'],
      'user.delete': ['admin'],
      'dashboard.view': ['admin', 'leader', 'operator', 'inspector']
    };
    return (permissions[action] || []).includes(role);
  }
}
```

### 9.2 View 层按钮权限

```typescript
if (PermissionUtil.hasPermission('workorder.dispatch', this.currentRole)) {
  Button('派工')
    .onClick(() => this.vm.dispatch(selectedOperatorId));
} else {
  Button('派工')
    .enabled(false)
    .fontColor('#ccc');
}
```

## 10. 本地存储（Preferences）

```typescript
// common/src/main/ets/utils/PreferencesUtil.ets
import { preferences } from '@kit.ArkData';

class PreferencesUtil {
  private pref: preferences.Preferences | null = null;

  async init(): Promise<void> {
    this.pref = await preferences.getPreferences(getContext(), 'mes_prefs');
  }

  set(key: string, value: string): void {
    this.pref?.put(key, value);
    this.pref?.flush();
  }

  get(key: string): string {
    return this.pref?.get(key, '') as string || '';
  }

  delete(key: string): void {
    this.pref?.delete(key);
    this.pref?.flush();
  }
}

export const preferencesUtil = new PreferencesUtil();
```

## 11. 错误处理

```typescript
// common/src/main/ets/api/HttpClient.ets（续）
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  timestamp: number;
}

// ViewModel 中的错误处理
@ObservedV2
export class BaseViewModel {
  @Trace errorMessage: string = '';
  @Trace isLoading: boolean = false;

  protected async handleRequest<T>(fn: () => Promise<T>): Promise<T | null> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      return await fn();
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return null;
    } finally {
      this.isLoading = false;
    }
  }
}
```

## 12. 性能优化

- 列表使用 `LazyForEach` + `IDataSource` 实现虚拟滚动
- 图片使用 `Image` 组件缓存能力
- WebSocket 消息批量处理，减少 UI 刷新频率
- 页面离开时（`aboutToDisappear`）取消 WebSocket 订阅，释放资源
- 断点变化时使用条件渲染而非动态计算布局
- ViewModel 中大数据量操作使用 `@Monitor` 做细粒度监听（高级场景）

## 13. 注意事项

1. **严禁 V1/V2 混用**：组件声明为 `@ComponentV2` 后，不可使用 `@State` 等 V1 装饰器
2. **`@Param` 默认只读**：子组件直接修改会编译报错，需通过 `@Event` 通知父组件
3. **`@Local` 强制本地初始化**：不允许外部直接赋值，封装性更强
4. **复杂对象观测**：优先使用 `@ObservedV2` + `@Trace`，避免直接双向绑定
5. **Navigation 栈管理**：登录页和主页面使用 `replacePath` 而非 `pushPath`，避免栈深度累积
6. **多模块依赖**：严格遵循 `common` → `features` → `products` 单向依赖规则

## 14. 技术难点与解决方案

### 14.1 跨模块依赖管理

**问题**：多模块 HAR 依赖关系复杂，容易出现循环依赖或版本冲突。

**处理方式**：
- 严格遵循单向依赖：`common` → `features` → `products`
- 使用本地 `file:` 协议引用：`"@ohos/common": "file:../../common"`
- `common` 模块通过 `Index.ets` 统一暴露所有公共能力
- 各 feature 模块接口稳定，禁止横向调用

### 14.2 导航栈生命周期管理

**问题**：多模块共享同一个 `NavPathStack` 实例时，跨模块页面跳转可能出现栈状态不一致。

**处理方式**：
- 在唯一的 `@Entry` 根页面 `Index.ets` 中通过 `@Provider('pageStack')` 提供实例
- 子页面通过 `@Consumer('pageStack')` 消费，确保全局唯一栈
- 登录页和主页面使用 `replacePath` 而非 `pushPath`，避免栈深度累积
- 隐藏系统标题栏和导航栏，完全自定义导航体验

### 14.3 Mock 数据与单元测试

每个 ViewModel 的 API 属性默认注入 mock 函数，实现无需启动模拟器的单元测试。

```typescript
// 示例：LoginViewModel 支持 mock 注入
export class LoginViewModel {
  api: AuthAPI = new AuthAPIMock(); // 默认 mock
  // 生产环境可替换为真实实现
}
```

## 15. 参考文档

| 主题 | 链接 |
|------|------|
| **MVVM 架构** | [MVVM模式（状态管理V2）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-mvvm-v2) |
| **导航架构** | [Navigation 导航](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-architecture) |
| **V2 装饰器** | [ArkTS 状态管理V2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-v2) |
| **工程架构** | [多端部署概览](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-overview) |
| **分层架构** | [分层架构设计](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-layered-architecture-design) |
| **响应式布局** | [响应式布局](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-responsive-layout) |
