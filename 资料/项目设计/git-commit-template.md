# Git 提交信息模板

## 仓库位置

Git 仓库统一放在 `E:\MESSystem\MES`（项目根目录下的 `MES/` 文件夹）。

**日常操作路径**：
```bash
cd E:\MESSystem\MES

git add .
git commit -m "<type>(<scope>): <主题>"
```

**提交模板文件本身**：`E:\MESSystem\资料\项目设计\git-commit-template.md`

## 格式

```
<type>(<scope>): <主题>

<正文>

<页脚>
```

## 类型（type）

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(backend): 添加工单派工接口` |
| `fix` | 修复缺陷 | `fix(frontend): 修复 WebSocket 重连死循环` |
| `docs` | 文档变动 | `docs(api): 更新 REST 接口文档` |
| `style` | 代码格式（不影响功能） | `style(frontend): ArkTS 代码格式化` |
| `refactor` | 重构 | `refactor(backend): 抽离工单状态机服务` |
| `test` | 测试相关 | `test(backend): 添加工单服务单元测试` |
| `chore` | 构建/工具/配置 | `chore(deps): 升级 Spring Boot 至 3.2.0` |
| `docker` | Docker 相关 | `docker(deploy): 优化 Dockerfile 构建缓存` |
| `perf` | 性能优化 | `perf(simulator): 降低仿真 Tick CPU 占用 30%` |

## 作用域（scope）

| 作用域 | 说明 |
|--------|------|
| `backend` | 后端 Java 代码 |
| `frontend` | 前端 ArkTS 代码 |
| `db` | 数据库脚本/Schema |
| `api` | 接口定义/文档 |
| `auth` | 认证授权模块 |
| `simulator` | 产线仿真器 |
| `websocket` | WebSocket 实时通信 |
| `ui` | UI 组件/页面 |
| `deploy` | 部署相关 |
| `integration` | 前后端联调 |
| `security` | 安全问题 |
| `all` | 影响前后端全局 |
| `project` | 项目级文档/配置 |

## 主题

- 不超过 50 字
- 使用祈使语气，明确说明"做了什么"
- 末尾不加句号

## 正文

- 说明"为什么做"和"怎么做"
- 与主题之间空一行

## 页脚

- 引用 Issue：`Closes #123`
- 破坏性变更：`BREAKING CHANGE: xxx`

## 示例

```
feat(backend): 添加工单状态机流转接口

实现派工/开工/暂停/恢复/报工/确认/报废接口，
增加乐观锁和 RBAC 权限校验。

Closes #15
```

```
fix(websocket): 统一广播消息格式

业务接口与仿真器使用不同广播入口，导致客户端解析异常。
统一通过 LineBroadcaster 广播，并增加消息版本和事件 ID。
```

## 禁止示例

```
# 错误：没有类型
update code

# 错误：没有作用域
feat: 新增功能

# 错误：主题不明确
fix(frontend): 修复 bug

# 错误：一次提交做多件事
feat(backend): 新增接口并修复 bug 且更新文档
```
