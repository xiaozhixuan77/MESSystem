# 后端 MySQL 数据库设计书

## 1. 概述

本文档定义工业管理 APP 后端服务的数据库表结构、字段说明、索引设计与关联关系。

**数据库**：MySQL 8.0
**编码**：UTF-8（utf8mb4）
**关联文档**：[后端需求分析](../需求分析/后端需求分析.md)、[后端SpringBoot设计书](../设计书/后端SpringBoot设计书.md)、[后端接口设计](../接口设计/后端接口设计.md)

## 2. 公共字段规范

所有表均包含以下公共字段：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键，自增 |
| created_at | DATETIME | 创建时间，默认 CURRENT_TIMESTAMP |
| updated_at | DATETIME | 更新时间，默认 CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| version | INT | 乐观锁版本号，默认 0 |
| is_deleted | TINYINT | 软删除标记，0=未删除，1=已删除，默认 0 |

## 3. 数据表设计

### 3.1 user（人员表）

存储系统所有人员信息。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| employee_no | VARCHAR(32) | NOT NULL, UNIQUE | 工号 |
| name | VARCHAR(64) | NOT NULL | 姓名 |
| role | VARCHAR(32) | NOT NULL | 角色：admin/leader/operator/inspector |
| team_id | BIGINT | FK | 所属班组 |
| workshop_id | BIGINT | FK | 所属车间 |
| status | VARCHAR(16) | NOT NULL, DEFAULT '在岗' | 状态：在岗/离岗 |
| avatar_url | VARCHAR(255) | NULL | 头像 URL |
| password_hash | VARCHAR(255) | NOT NULL | 密码哈希 |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_employee_no` (`employee_no`)
- INDEX `idx_role` (`role`)
- INDEX `idx_team_id` (`team_id`)
- INDEX `idx_workshop_id` (`workshop_id`)

### 3.2 workshop（车间表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| name | VARCHAR(64) | NOT NULL | 车间名称 |

**初始数据**：
- 机加工车间
- 柔性车间
- 智能组装车间
- SMT 车间

### 3.3 production_line（产线/资源表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| name | VARCHAR(64) | NOT NULL | 产线名称 |
| workshop_id | BIGINT | NOT NULL, FK | 所属车间 |
| current_process_id | BIGINT | FK | 当前正在跑的工艺 |
| current_workorder_id | BIGINT | FK | 当前激活的工单 |
| status | VARCHAR(32) | NOT NULL, DEFAULT '空闲' | 空闲/生产中/暂停中/异常/停机 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_workshop_id` (`workshop_id`)
- INDEX `idx_status` (`status`)

### 3.4 process（工艺表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| code | VARCHAR(32) | NOT NULL, UNIQUE | 工艺编码 |
| name | VARCHAR(64) | NOT NULL | 工艺名称（如：无线充电器组装） |
| applicable_product_codes | VARCHAR(255) | NULL | 适用产品编码，逗号分隔 |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_code` (`code`)

### 3.5 process_step（工序/工艺步骤表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| process_id | BIGINT | NOT NULL, FK | 所属工艺 |
| seq_no | INT | NOT NULL | 顺序号：10/20/30... |
| op_code | VARCHAR(16) | NOT NULL | OP 编码：OP10/OP20... |
| name | VARCHAR(64) | NOT NULL | 工序名称 |
| default_station_id | BIGINT | FK | 默认工作站 |
| description | VARCHAR(255) | NULL | 描述 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_process_id` (`process_id`)
- INDEX `idx_seq_no` (`process_id`, `seq_no`)

### 3.6 workstation（工作站表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| code | VARCHAR(32) | NOT NULL, UNIQUE | 工作站编码：WS-FLX-OP10 |
| name | VARCHAR(64) | NOT NULL | 工作站名称 |
| production_line_id | BIGINT | NOT NULL, FK | 所属产线 |
| equipment_code | VARCHAR(32) | NULL | 设备编码 |
| current_process_id | BIGINT | FK | 当前工艺 |
| device_status | VARCHAR(32) | NOT NULL, DEFAULT '待机' | 运行中/待机/故障 |
| work_status | VARCHAR(64) | NULL | 机械臂上料/出料等待/工作台固定... |
| conveyor_status | VARCHAR(16) | NULL | 正转/反转/停 |
| processed_count | INT | NOT NULL, DEFAULT 0 | 已加工件数 |
| raw_count | INT | NOT NULL, DEFAULT 0 | 原料数 |
| finished_count | INT | NOT NULL, DEFAULT 0 | 完工数 |
| ng_count | INT | NOT NULL, DEFAULT 0 | NG 数 |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_code` (`code`)
- INDEX `idx_line_id` (`production_line_id`)

### 3.7 product（产品表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| code | VARCHAR(32) | NOT NULL, UNIQUE | 产品编码：PROD-WC-001 |
| name | VARCHAR(64) | NOT NULL | 产品名称 |
| default_process_id | BIGINT | FK | 默认工艺 |
| bom_id | BIGINT | NULL | BOM ID（预留） |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_code` (`code`)

### 3.8 work_order（工单表 ★ 核心）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| code | VARCHAR(32) | NOT NULL, UNIQUE | 工单号：MO000001 |
| type | VARCHAR(16) | NOT NULL | 试产/量产/返工 |
| workshop_id | BIGINT | NOT NULL, FK | 所属车间 |
| line_id | BIGINT | NOT NULL, FK | 产线 |
| product_id | BIGINT | NOT NULL, FK | 产品 |
| process_id | BIGINT | NOT NULL, FK | 工艺 |
| plan_qty | INT | NOT NULL | 计划数量 |
| plan_start_time | DATETIME | NULL | 计划开始时间 |
| plan_end_time | DATETIME | NULL | 计划结束时间 |
| status | VARCHAR(32) | NOT NULL, DEFAULT '待派工' | 待派工/已派工/生产中/暂停中/生产完成/已报工/完工/报废 |
| source | VARCHAR(32) | NULL | Web 创建/APP 创建 |
| operator_id | BIGINT | FK | 操作员 |
| dispatch_time | DATETIME | NULL | 派工时间 |
| actual_start_time | DATETIME | NULL | 实际开始时间 |
| actual_end_time | DATETIME | NULL | 实际结束时间 |
| reported_qty_good | INT | NULL | 申报良品数 |
| reported_qty_ng | INT | NULL | 申报 NG 数 |
| reported_hours | DECIMAL(10,2) | NULL | 申报工时 |
| exception_note | VARCHAR(500) | NULL | 异常说明 |
| created_by | BIGINT | FK | 创建人 |
| source_workorder_id | BIGINT | FK | 源工单 ID（返工关联） |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_code` (`code`)
- INDEX `idx_status` (`status`)
- INDEX `idx_operator_id` (`operator_id`)
- INDEX `idx_line_id` (`line_id`)
- INDEX `idx_created_by` (`created_by`)
- INDEX `idx_type_status` (`type`, `status`)
- INDEX `idx_status_created_at` (`status`, `created_at`)  -- 高频查询优化：工作台按状态筛选+时间排序

### 3.9 work_order_route_step（工单工艺路线快照表）

工艺日后会改，但历史工单要按当时的工艺留存。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| work_order_id | BIGINT | NOT NULL, FK | 所属工单 |
| seq_no | INT | NOT NULL | 顺序号 |
| op_code | VARCHAR(16) | NOT NULL | OP 编码 |
| name | VARCHAR(64) | NOT NULL | 工序名称 |
| station_id | BIGINT | FK | 工作站 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_work_order_id` (`work_order_id`)

### 3.10 production_exception（生产异常表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| work_order_id | BIGINT | NOT NULL, FK | 关联工单 |
| line_id | BIGINT | NOT NULL, FK | 产线 |
| station_id | BIGINT | FK | 工作站（整线异常时为空） |
| reporter_id | BIGINT | NOT NULL, FK | 上报人 |
| report_time | DATETIME | NOT NULL | 上报时间 |
| description | VARCHAR(500) | NOT NULL | 异常描述 |
| handled_by | BIGINT | FK | 处理人 |
| handle_time | DATETIME | NULL | 处理时间 |
| handle_action | VARCHAR(32) | NULL | 恢复/关闭 |
| resolved | TINYINT | NOT NULL, DEFAULT 0 | 是否已解决 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_work_order_id` (`work_order_id`)
- INDEX `idx_line_id` (`line_id`)
- INDEX `idx_resolved` (`resolved`)

### 3.11 inspection_record（抽检记录表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| work_order_id | BIGINT | NOT NULL, FK | 关联工单 |
| inspector_id | BIGINT | NOT NULL, FK | 质检员 |
| inspect_time | DATETIME | NOT NULL | 抽检时间 |
| sample_qty | INT | NOT NULL | 抽检数量 |
| sample_good | INT | NOT NULL | 抽检良品数 |
| sample_ng | INT | NOT NULL | 抽检 NG 数 |
| defect_types | VARCHAR(255) | NULL | JSON：外观缺陷/尺寸偏差/功能失效/装配不良 |
| defect_description | VARCHAR(500) | NULL | 不良描述 |
| conclusion | VARCHAR(16) | NOT NULL | 通过/不通过 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_work_order_id` (`work_order_id`)
- INDEX `idx_inspector_id` (`inspector_id`)

### 3.12 production_log（产线运行日志表）

实时同步的关键表，每一次状态变化都落一条日志。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| line_id | BIGINT | NOT NULL, FK | 产线 |
| station_id | BIGINT | FK | 工作站 |
| work_order_id | BIGINT | FK | 工单 |
| event_type | VARCHAR(32) | NOT NULL | 启动/停止/复位/加工/出料/异常 |
| product_sn | VARCHAR(64) | NULL | 产品序列号 |
| event_time | DATETIME | NOT NULL | 事件时间 |
| payload | JSON | NULL | 扩展 JSON 数据 |

**索引**：
- PRIMARY KEY (`id`)
- INDEX `idx_line_id` (`line_id`)
- INDEX `idx_event_time` (`event_time`)
- INDEX `idx_work_order_id` (`work_order_id`)

### 3.13 role_permission（角色权限表）

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| role | VARCHAR(32) | NOT NULL | 角色 |
| permission | VARCHAR(64) | NOT NULL | 权限码 |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_role_permission` (`role`, `permission`)

### 3.14 line_process_support（产线支持工艺关联表）

产线与工艺的多对多关联表，表示某条产线可以执行哪些工艺。

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| id | BIGINT | PK, AI | 主键 |
| line_id | BIGINT | NOT NULL, FK | 产线 ID |
| process_id | BIGINT | NOT NULL, FK | 工艺 ID |

**索引**：
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_line_process` (`line_id`, `process_id`)

## 4. ER 关系图

```
workshop (1) ───<N>─── production_line (1) ───<N>─── workstation
                           │ (N:1)         │ (N:M)  ← line_process_support
                           ▼               ▼
                        process (1) ───<N>─── process_step
                           │ (N:1)
                           ▼
                        product
                           
work_order (N:1) ─── production_line
work_order (N:1) ─── product
work_order (N:1) ─── process
work_order (N:1) ─── user (operator)
work_order (1) ───<N>─── work_order_route_step
work_order (1) ───<N>─── production_exception
work_order (1) ───<N>─── inspection_record
work_order (1) ───<N>─── production_log

user (N:1) ─── workshop
user (N:1) ─── team (预留)
```

## 5. 建表 SQL

```sql
CREATE DATABASE IF NOT EXISTS mes_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mes_db;

-- 1. 车间表
CREATE TABLE workshop (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0
);

-- 2. 工艺表
CREATE TABLE process (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    applicable_product_codes VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0
);

-- 3. 产品表
CREATE TABLE product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    default_process_id BIGINT,
    bom_id BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_default_process_id (default_process_id)
);

-- 4. 产线表
CREATE TABLE production_line (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    workshop_id BIGINT NOT NULL,
    current_process_id BIGINT,
    current_workorder_id BIGINT,
    status VARCHAR(32) NOT NULL DEFAULT '空闲',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_workshop_id (workshop_id),
    INDEX idx_status (status)
);

-- 5. 工序表
CREATE TABLE process_step (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    process_id BIGINT NOT NULL,
    seq_no INT NOT NULL,
    op_code VARCHAR(16) NOT NULL,
    name VARCHAR(64) NOT NULL,
    default_station_id BIGINT,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_process_id (process_id),
    INDEX idx_seq_no (process_id, seq_no)
);

-- 6. 工作站表
CREATE TABLE workstation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    production_line_id BIGINT NOT NULL,
    equipment_code VARCHAR(32),
    current_process_id BIGINT,
    device_status VARCHAR(32) NOT NULL DEFAULT '待机',
    work_status VARCHAR(64),
    conveyor_status VARCHAR(16),
    processed_count INT NOT NULL DEFAULT 0,
    raw_count INT NOT NULL DEFAULT 0,
    finished_count INT NOT NULL DEFAULT 0,
    ng_count INT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_line_id (production_line_id)
);

-- 7. 人员表
CREATE TABLE user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_no VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    role VARCHAR(32) NOT NULL,
    team_id BIGINT,
    workshop_id BIGINT,
    status VARCHAR(16) NOT NULL DEFAULT '在岗',
    avatar_url VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_role (role),
    INDEX idx_team_id (team_id),
    INDEX idx_workshop_id (workshop_id)
);

-- 8. 工单表（核心）
CREATE TABLE work_order (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    type VARCHAR(16) NOT NULL,
    workshop_id BIGINT NOT NULL,
    line_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    process_id BIGINT NOT NULL,
    plan_qty INT NOT NULL,
    plan_start_time DATETIME,
    plan_end_time DATETIME,
    status VARCHAR(32) NOT NULL DEFAULT '待派工',
    source VARCHAR(32),
    operator_id BIGINT,
    dispatch_time DATETIME,
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    reported_qty_good INT,
    reported_qty_ng INT,
    reported_hours DECIMAL(10,2),
    exception_note VARCHAR(500),
    created_by BIGINT,
    source_workorder_id BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_status (status),
    INDEX idx_operator_id (operator_id),
    INDEX idx_line_id (line_id),
    INDEX idx_created_by (created_by),
    INDEX idx_type_status (type, status),
    INDEX idx_status_created_at (status, created_at)
);

-- 9. 工单工艺路线快照表
CREATE TABLE work_order_route_step (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    seq_no INT NOT NULL,
    op_code VARCHAR(16) NOT NULL,
    name VARCHAR(64) NOT NULL,
    station_id BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_work_order_id (work_order_id)
);

-- 10. 生产异常表
CREATE TABLE production_exception (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    line_id BIGINT NOT NULL,
    station_id BIGINT,
    reporter_id BIGINT NOT NULL,
    report_time DATETIME NOT NULL,
    description VARCHAR(500) NOT NULL,
    handled_by BIGINT,
    handle_time DATETIME,
    handle_action VARCHAR(32),
    resolved TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_work_order_id (work_order_id),
    INDEX idx_line_id (line_id),
    INDEX idx_resolved (resolved)
);

-- 11. 抽检记录表
CREATE TABLE inspection_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    inspector_id BIGINT NOT NULL,
    inspect_time DATETIME NOT NULL,
    sample_qty INT NOT NULL,
    sample_good INT NOT NULL,
    sample_ng INT NOT NULL,
    defect_types VARCHAR(255),
    defect_description VARCHAR(500),
    conclusion VARCHAR(16) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    INDEX idx_work_order_id (work_order_id),
    INDEX idx_inspector_id (inspector_id)
);

-- 12. 产线运行日志表（按月 RANGE 分区，解决数据量大问题）
CREATE TABLE production_log (
    id BIGINT AUTO_INCREMENT,
    line_id BIGINT NOT NULL,
    station_id BIGINT,
    work_order_id BIGINT,
    event_type VARCHAR(32) NOT NULL,
    product_sn VARCHAR(64),
    event_time DATETIME NOT NULL,
    payload JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    PRIMARY KEY (id, event_time),
    INDEX idx_line_id (line_id),
    INDEX idx_event_time (event_time),
    INDEX idx_work_order_id (work_order_id)
) PARTITION BY RANGE (YEAR(event_time) * 100 + MONTH(event_time)) (
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION p202503 VALUES LESS THAN (202504),
    PARTITION p202504 VALUES LESS THAN (202505),
    PARTITION p202505 VALUES LESS THAN (202506),
    PARTITION p202506 VALUES LESS THAN (202507),
    PARTITION p202507 VALUES LESS THAN (202508),
    PARTITION p202508 VALUES LESS THAN (202509),
    PARTITION p202509 VALUES LESS THAN (202510),
    PARTITION p202510 VALUES LESS THAN (202511),
    PARTITION p202511 VALUES LESS THAN (202512),
    PARTITION p202512 VALUES LESS THAN (202601),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- 13. 角色权限表
CREATE TABLE role_permission (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role VARCHAR(32) NOT NULL,
    permission VARCHAR(64) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0,
    is_deleted TINYINT DEFAULT 0,
    UNIQUE KEY uk_role_permission (role, permission)
);

-- 产线支持工艺关联表（多对多）
CREATE TABLE line_process_support (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    line_id BIGINT NOT NULL,
    process_id BIGINT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_line_process (line_id, process_id)
);
```

## 6. 数据初始化脚本

```sql
-- 初始化车间
INSERT INTO workshop (id, name) VALUES
(1, '机加工车间'),
(2, '柔性车间'),
(3, '智能组装车间'),
(4, 'SMT 车间');

-- 初始化工艺
INSERT INTO process (id, code, name) VALUES
(1, 'PROC-WC-001', '无线充电器组装'),
(2, 'PROC-SMT-001', 'SMT 贴片工艺');

-- 初始化工序（柔性组装线 7 站）
INSERT INTO process_step (id, process_id, seq_no, op_code, name) VALUES
(1, 1, 10, 'OP10', '上料'),
(2, 1, 20, 'OP20', '主板组装'),
(3, 1, 30, 'OP30', '后盖组装'),
(4, 1, 40, 'OP40', '螺丝锁付'),
(5, 1, 50, 'OP50', '激光打标'),
(6, 1, 60, 'OP60', '成品检测'),
(7, 1, 70, 'OP70', '下料');

-- 初始化产线
INSERT INTO production_line (id, name, workshop_id, status) VALUES
(1, '柔性组装线', 2, '空闲'),
(2, 'SMT 产线', 4, '空闲');

-- 初始化工作站
INSERT INTO workstation (id, code, name, production_line_id) VALUES
(1, 'WS-FLX-OP10', 'OP10 上料', 1),
(2, 'WS-FLX-OP20', 'OP20 主板组装', 1),
(3, 'WS-FLX-OP30', 'OP30 后盖组装', 1),
(4, 'WS-FLX-OP40', 'OP40 螺丝锁付', 1),
(5, 'WS-FLX-OP50', 'OP50 激光打标', 1),
(6, 'WS-FLX-OP60', 'OP60 成品检测', 1),
(7, 'WS-FLX-OP70', 'OP70 下料', 1);

-- 初始化产品
INSERT INTO product (id, code, name, default_process_id) VALUES
(1, 'PROD-WC-001', '无线充电器', 1);

-- 初始化演示账号（密码：123456，bcrypt 加密后）
INSERT INTO user (id, employee_no, name, role, workshop_id, status, password_hash) VALUES
(1, 'ADMIN001', '张建国', 'admin', 2, '在岗', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EO'),
(2, 'LEADER001', '王志刚', 'leader', 2, '在岗', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EO'),
(3, 'OP001', '刘伟', 'operator', 2, '在岗', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EO'),
(4, 'INS001', '陈静', 'inspector', 2, '在岗', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EO');

-- 初始化角色权限（与后端SpringBoot设计书 3.1.3 节一致）
INSERT INTO role_permission (role, permission) VALUES
('admin', '*'),
('leader', 'workorder.view_team'),
('leader', 'workorder.create'),
('leader', 'workorder.dispatch'),
('leader', 'workorder.pause'),
('leader', 'workorder.resume'),
('leader', 'workorder.confirm'),
('leader', 'workorder.scrap'),
('leader', 'line.view'),
('leader', 'line.operate'),
('leader', 'station.operate'),
('leader', 'exception.view'),
('leader', 'exception.handle'),
('leader', 'dashboard.view'),
('operator', 'workorder.view_own'),
('operator', 'workorder.start'),
('operator', 'workorder.pause'),
('operator', 'workorder.resume'),
('operator', 'workorder.report'),
('operator', 'line.view'),
('operator', 'line.operate'),
('operator', 'station.operate'),
('operator', 'exception.report'),
('operator', 'dashboard.view'),
('inspector', 'inspection.create'),
('inspector', 'workorder.view_inspection'),
('inspector', 'line.view'),
('inspector', 'dashboard.view');
```

## 7. 优化落地

### 7.1 production_log 分区表管理

**自动新增下月分区（定时任务 / 事件调度器）**：

```sql
-- 查看当前分区
SELECT PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_NAME = 'production_log';

-- 添加新分区（每月初执行）
ALTER TABLE production_log ADD PARTITION (
    PARTITION p202601 VALUES LESS THAN (202602)
);

-- 归档历史分区（3 个月前的数据可迁移到归档表后删除分区）
CREATE TABLE production_log_archive LIKE production_log;
ALTER TABLE production_log_archive REMOVE PARTITIONING;

-- 导出旧分区数据（示例：2025年1月）
INSERT INTO production_log_archive
SELECT * FROM production_log PARTITION (p202501);

-- 确认无误后删除旧分区
ALTER TABLE production_log DROP PARTITION p202501;
```

**Spring Boot 中 MyBatis-Plus 分区表查询注意**：
- 所有查询必须包含 `event_time` 条件，否则将扫描全部分区
- `id` 单独不再全局唯一，业务查询以 `event_time` + `line_id` 为主

### 7.2 work_order 高频查询组合索引

已新增 `idx_status_created_at (status, created_at)` 索引，覆盖以下高频场景：

| 查询场景 | SQL 条件 | 索引覆盖 |
|---------|---------|---------|
| 班组长工作台-待派工 | `WHERE status = '待派工' ORDER BY created_at DESC` | 完全覆盖 |
| 操作员我的待办 | `WHERE status = '生产中' AND operator_id = ?` | `idx_status` 过滤 + 回表 |
| 工单列表筛选 | `WHERE status IN (...) AND created_at > ?` | 完全覆盖 |

**执行计划验证**：

```sql
EXPLAIN SELECT * FROM work_order
WHERE status = '待派工'
ORDER BY created_at DESC
LIMIT 20;
-- 预期：type=ref, key=idx_status_created_at, Extra=Using where; Using index
```

### 7.3 workstation 实时状态 Redis 缓存

**缓存策略**：写穿（Write-Through）+ 5 秒 TTL 兜底

| 缓存 Key | 类型 | 值 | 说明 |
|---------|------|---|------|
| `mes:line:{line_id}:status` | String | 空闲/生产中/暂停/异常/停机 | 产线整体状态 |
| `mes:line:{line_id}:workorder` | String | `{workorder_id}` | 当前激活工单 ID |
| `mes:station:{station_id}` | Hash | `{device_status, work_status, conveyor_status, processed_count, raw_count, finished_count, ng_count, updated_at}` | 工作站实时计数与状态 |

**状态同步时序**：

```
Simulator Tick(1Hz)
    → 更新内存状态
    → 写 Redis（Pipeline 批量 HSET）
    → 广播 WebSocket
    → 异步批量写 MySQL（每 5 秒 flush）
```

**Redis Hash 结构示例**：

```
HGETALL mes:station:1
1) "device_status"
2) "运行中"
3) "work_status"
4) "机械臂上料"
5) "processed_count"
6) "128"
7) "updated_at"
8) "2026-05-19T14:32:01"
```

**降级策略**：
- Redis 不可用时，直接读 `workstation` 表（有 `idx_line_id` 索引，性能可接受）
- 后端启动时从 MySQL 加载全量工作站状态到 Redis，预热缓存

---

## 8. 剩余优化建议

1. **inspection_record** 中 `defect_types` 当前使用 VARCHAR(255) 存储逗号分隔值；后续可改为 MySQL JSON 类型，便于按缺陷类型统计查询
