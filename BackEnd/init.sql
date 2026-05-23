-- ========================================================
-- MES 数据库表结构（14 张表）
-- 字符集：utf8mb4 / 排序规则：utf8mb4_unicode_ci
-- 外键策略：ON DELETE SET NULL ON UPDATE CASCADE
-- ========================================================

SET NAMES utf8mb4;

-- --------------------------------------------------------
-- 1. workshop（车间表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS workshop (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    name            VARCHAR(64) NOT NULL COMMENT '车间名称',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version         INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted      TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='车间表';

-- --------------------------------------------------------
-- 2. process（工艺表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS process (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    code                    VARCHAR(32) NOT NULL COMMENT '工艺编码',
    name                    VARCHAR(64) NOT NULL COMMENT '工艺名称',
    applicable_product_codes VARCHAR(255) NULL COMMENT '适用产品编码，逗号分隔',
    created_at              DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at              DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version                 INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted              TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工艺表';

-- --------------------------------------------------------
-- 3. product（产品表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS product (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    code                VARCHAR(32) NOT NULL COMMENT '产品编码',
    name                VARCHAR(64) NOT NULL COMMENT '产品名称',
    default_process_id  BIGINT NULL COMMENT '默认工艺ID',
    bom_id              BIGINT NULL COMMENT 'BOM ID（预留）',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_code (code),
    INDEX idx_default_process_id (default_process_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品表';

ALTER TABLE product
    ADD CONSTRAINT fk_product_process
    FOREIGN KEY (default_process_id) REFERENCES process(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 4. production_line（产线/资源表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_line (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    name                VARCHAR(64) NOT NULL COMMENT '产线名称',
    workshop_id         BIGINT NOT NULL COMMENT '所属车间ID',
    current_process_id  BIGINT NULL COMMENT '当前正在跑的工艺ID',
    current_workorder_id BIGINT NULL COMMENT '当前激活的工单ID',
    status              VARCHAR(32) NOT NULL DEFAULT '空闲' COMMENT '状态：空闲/生产中/暂停/异常/停机',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    INDEX idx_workshop_id (workshop_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产线表';

ALTER TABLE production_line
    ADD CONSTRAINT fk_line_workshop
    FOREIGN KEY (workshop_id) REFERENCES workshop(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE production_line
    ADD CONSTRAINT fk_line_process
    FOREIGN KEY (current_process_id) REFERENCES process(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 5. workstation（工作站表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS workstation (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    code                VARCHAR(32) NOT NULL COMMENT '工作站编码',
    name                VARCHAR(64) NOT NULL COMMENT '工作站名称',
    production_line_id  BIGINT NOT NULL COMMENT '所属产线ID',
    equipment_code      VARCHAR(32) NULL COMMENT '设备编码',
    current_process_id  BIGINT NULL COMMENT '当前工艺ID',
    device_status       VARCHAR(32) NOT NULL DEFAULT '待机' COMMENT '设备状态：运行中/待机/故障',
    work_status         VARCHAR(64) NULL COMMENT '工作状态：机械臂上料/出料等待/工作台固定...',
    conveyor_status     VARCHAR(16) NULL COMMENT '传送带状态：正转/反转/停',
    processed_count     INT NOT NULL DEFAULT 0 COMMENT '已加工件数',
    raw_count           INT NOT NULL DEFAULT 0 COMMENT '原料数',
    finished_count      INT NOT NULL DEFAULT 0 COMMENT '完工数',
    ng_count            INT NOT NULL DEFAULT 0 COMMENT 'NG数',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_code (code),
    INDEX idx_line_id (production_line_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作站表';

ALTER TABLE workstation
    ADD CONSTRAINT fk_ws_line
    FOREIGN KEY (production_line_id) REFERENCES production_line(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE workstation
    ADD CONSTRAINT fk_ws_process
    FOREIGN KEY (current_process_id) REFERENCES process(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 6. process_step（工序/工艺步骤表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS process_step (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    process_id          BIGINT NOT NULL COMMENT '所属工艺ID',
    seq_no              INT NOT NULL COMMENT '顺序号：10/20/30...',
    op_code             VARCHAR(16) NOT NULL COMMENT 'OP编码：OP10/OP20...',
    name                VARCHAR(64) NOT NULL COMMENT '工序名称',
    default_station_id  BIGINT NULL COMMENT '默认工作站ID',
    description         VARCHAR(255) NULL COMMENT '描述',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    INDEX idx_process_id (process_id),
    INDEX idx_seq_no (process_id, seq_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工序表';

ALTER TABLE process_step
    ADD CONSTRAINT fk_step_process
    FOREIGN KEY (process_id) REFERENCES process(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE process_step
    ADD CONSTRAINT fk_step_station
    FOREIGN KEY (default_station_id) REFERENCES workstation(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 7. user（人员表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS user (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    employee_no     VARCHAR(32) NOT NULL COMMENT '工号',
    name            VARCHAR(64) NOT NULL COMMENT '姓名',
    role            VARCHAR(32) NOT NULL COMMENT '角色：admin/leader/operator/inspector',
    team_id         BIGINT NULL COMMENT '所属班组ID（预留）',
    workshop_id     BIGINT NULL COMMENT '所属车间ID',
    status          VARCHAR(16) NOT NULL DEFAULT '在岗' COMMENT '状态：在岗/离岗',
    avatar_url      VARCHAR(255) NULL COMMENT '头像URL',
    password_hash   VARCHAR(255) NOT NULL COMMENT '密码哈希',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version         INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted      TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_employee_no (employee_no),
    INDEX idx_role (role),
    INDEX idx_team_id (team_id),
    INDEX idx_workshop_id (workshop_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='人员表';

ALTER TABLE user
    ADD CONSTRAINT fk_user_workshop
    FOREIGN KEY (workshop_id) REFERENCES workshop(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 8. work_order（工单表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS work_order (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    code                VARCHAR(32) NOT NULL COMMENT '工单号',
    type                VARCHAR(16) NOT NULL COMMENT '类型：试产/量产/返工',
    workshop_id         BIGINT NOT NULL COMMENT '所属车间ID',
    line_id             BIGINT NOT NULL COMMENT '产线ID',
    product_id          BIGINT NOT NULL COMMENT '产品ID',
    process_id          BIGINT NOT NULL COMMENT '工艺ID',
    plan_qty            INT NOT NULL COMMENT '计划数量',
    plan_start_time     DATETIME NULL COMMENT '计划开始时间',
    plan_end_time       DATETIME NULL COMMENT '计划结束时间',
    status              VARCHAR(32) NOT NULL DEFAULT '待派工' COMMENT '状态：待派工/已派工/生产中/暂停中/生产完成/已报工/完工/报废',
    source              VARCHAR(32) NULL COMMENT '来源：Web创建/APP创建',
    operator_id         BIGINT NULL COMMENT '操作员ID',
    dispatch_time       DATETIME NULL COMMENT '派工时间',
    actual_start_time   DATETIME NULL COMMENT '实际开始时间',
    actual_end_time     DATETIME NULL COMMENT '实际结束时间',
    reported_qty_good   INT NULL COMMENT '申报良品数',
    reported_qty_ng     INT NULL COMMENT '申报NG数',
    reported_hours      DECIMAL(10,2) NULL COMMENT '申报工时',
    exception_note      VARCHAR(500) NULL COMMENT '异常说明',
    created_by          BIGINT NULL COMMENT '创建人ID',
    source_workorder_id BIGINT NULL COMMENT '源工单ID（返工关联）',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_code (code),
    INDEX idx_status (status),
    INDEX idx_operator_id (operator_id),
    INDEX idx_line_id (line_id),
    INDEX idx_created_by (created_by),
    INDEX idx_type_status (type, status),
    INDEX idx_status_created_at (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单表';

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_workshop
    FOREIGN KEY (workshop_id) REFERENCES workshop(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_line
    FOREIGN KEY (line_id) REFERENCES production_line(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_product
    FOREIGN KEY (product_id) REFERENCES product(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_process
    FOREIGN KEY (process_id) REFERENCES process(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_operator
    FOREIGN KEY (operator_id) REFERENCES user(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_created_by
    FOREIGN KEY (created_by) REFERENCES user(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE work_order
    ADD CONSTRAINT fk_wo_source
    FOREIGN KEY (source_workorder_id) REFERENCES work_order(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 9. work_order_route_step（工单工艺路线快照表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS work_order_route_step (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    work_order_id   BIGINT NOT NULL COMMENT '所属工单ID',
    seq_no          INT NOT NULL COMMENT '顺序号',
    op_code         VARCHAR(16) NOT NULL COMMENT 'OP编码',
    name            VARCHAR(64) NOT NULL COMMENT '工序名称',
    station_id      BIGINT NULL COMMENT '工作站ID',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version         INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted      TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    INDEX idx_work_order_id (work_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单工艺路线快照表';

ALTER TABLE work_order_route_step
    ADD CONSTRAINT fk_wors_wo
    FOREIGN KEY (work_order_id) REFERENCES work_order(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE work_order_route_step
    ADD CONSTRAINT fk_wors_station
    FOREIGN KEY (station_id) REFERENCES workstation(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 10. production_exception（生产异常表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_exception (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    work_order_id   BIGINT NOT NULL COMMENT '关联工单ID',
    line_id         BIGINT NOT NULL COMMENT '产线ID',
    station_id      BIGINT NULL COMMENT '工作站ID（整线异常时为空）',
    reporter_id     BIGINT NOT NULL COMMENT '上报人ID',
    report_time     DATETIME NOT NULL COMMENT '上报时间',
    description     VARCHAR(500) NOT NULL COMMENT '异常描述',
    handled_by      BIGINT NULL COMMENT '处理人ID',
    handle_time     DATETIME NULL COMMENT '处理时间',
    handle_action   VARCHAR(32) NULL COMMENT '处理动作：恢复/关闭',
    resolved        TINYINT NOT NULL DEFAULT 0 COMMENT '是否已解决：0-否，1-是',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version         INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted      TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    INDEX idx_work_order_id (work_order_id),
    INDEX idx_line_id (line_id),
    INDEX idx_resolved (resolved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='生产异常表';

ALTER TABLE production_exception
    ADD CONSTRAINT fk_pe_wo
    FOREIGN KEY (work_order_id) REFERENCES work_order(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE production_exception
    ADD CONSTRAINT fk_pe_line
    FOREIGN KEY (line_id) REFERENCES production_line(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE production_exception
    ADD CONSTRAINT fk_pe_station
    FOREIGN KEY (station_id) REFERENCES workstation(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE production_exception
    ADD CONSTRAINT fk_pe_reporter
    FOREIGN KEY (reporter_id) REFERENCES user(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE production_exception
    ADD CONSTRAINT fk_pe_handler
    FOREIGN KEY (handled_by) REFERENCES user(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 11. inspection_record（抽检记录表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS inspection_record (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    work_order_id       BIGINT NOT NULL COMMENT '关联工单ID',
    inspector_id        BIGINT NOT NULL COMMENT '质检员ID',
    inspect_time        DATETIME NOT NULL COMMENT '抽检时间',
    sample_qty          INT NOT NULL COMMENT '抽检数量',
    sample_good         INT NOT NULL COMMENT '抽检良品数',
    sample_ng           INT NOT NULL COMMENT '抽检NG数',
    defect_types        VARCHAR(255) NULL COMMENT '缺陷类型JSON：外观缺陷/尺寸偏差/功能失效/装配不良',
    defect_description  VARCHAR(500) NULL COMMENT '不良描述',
    conclusion          VARCHAR(16) NOT NULL COMMENT '结论：通过/不通过',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version             INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted          TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    INDEX idx_work_order_id (work_order_id),
    INDEX idx_inspector_id (inspector_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='抽检记录表';

ALTER TABLE inspection_record
    ADD CONSTRAINT fk_ir_wo
    FOREIGN KEY (work_order_id) REFERENCES work_order(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE inspection_record
    ADD CONSTRAINT fk_ir_inspector
    FOREIGN KEY (inspector_id) REFERENCES user(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 12. production_log（产线运行日志表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_log (
    id              BIGINT AUTO_INCREMENT,
    line_id         BIGINT NOT NULL COMMENT '产线ID',
    station_id      BIGINT NULL COMMENT '工作站ID',
    work_order_id   BIGINT NULL COMMENT '工单ID',
    event_type      VARCHAR(32) NOT NULL COMMENT '事件类型：启动/停止/复位/加工/出料/异常',
    product_sn      VARCHAR(64) NULL COMMENT '产品序列号',
    event_time      DATETIME NOT NULL COMMENT '事件时间',
    payload         JSON NULL COMMENT '扩展JSON数据',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version         INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted      TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (id, event_time),
    INDEX idx_line_id (line_id),
    INDEX idx_event_time (event_time),
    INDEX idx_work_order_id (work_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产线运行日志表'
PARTITION BY RANGE (YEAR(event_time) * 100 + MONTH(event_time)) (
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

ALTER TABLE production_log
    ADD CONSTRAINT fk_pl_line
    FOREIGN KEY (line_id) REFERENCES production_line(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE production_log
    ADD CONSTRAINT fk_pl_station
    FOREIGN KEY (station_id) REFERENCES workstation(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE production_log
    ADD CONSTRAINT fk_pl_wo
    FOREIGN KEY (work_order_id) REFERENCES work_order(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- --------------------------------------------------------
-- 13. role_permission（角色权限表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS role_permission (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    role        VARCHAR(32) NOT NULL COMMENT '角色',
    permission  VARCHAR(64) NOT NULL COMMENT '权限码',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version     INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted  TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_role_permission (role, permission)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限表';

-- --------------------------------------------------------
-- 14. line_process_support（产线支持工艺关联表）
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS line_process_support (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    line_id     BIGINT NOT NULL COMMENT '产线ID',
    process_id  BIGINT NOT NULL COMMENT '工艺ID',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    version     INT DEFAULT 0 COMMENT '乐观锁版本号',
    is_deleted  TINYINT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    UNIQUE KEY uk_line_process (line_id, process_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产线支持工艺关联表';

ALTER TABLE line_process_support
    ADD CONSTRAINT fk_lps_line
    FOREIGN KEY (line_id) REFERENCES production_line(id)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE line_process_support
    ADD CONSTRAINT fk_lps_process
    FOREIGN KEY (process_id) REFERENCES process(id)
    ON DELETE CASCADE ON UPDATE CASCADE;
-- ========================================================
-- MES 数据库初始化数据
-- 密码均为 123456，BCrypt 编码（strength=10）
-- 预计算哈希：$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva
-- ========================================================

SET NAMES utf8mb4;

-- --------------------------------------------------------
-- 1. workshop（车间）
-- --------------------------------------------------------
INSERT INTO workshop (id, name) VALUES
(1, '机加工车间'),
(2, '柔性车间'),
(3, '智能组装车间'),
(4, 'SMT 车间');

-- --------------------------------------------------------
-- 2. process（工艺）
-- --------------------------------------------------------
INSERT INTO process (id, code, name, applicable_product_codes) VALUES
(1, 'PROC-WC-001', '无线充电器组装', 'PROD-WC-001'),
(2, 'PROC-SMT-001', 'SMT 贴片工艺', NULL);

-- --------------------------------------------------------
-- 3. product（产品）
-- --------------------------------------------------------
INSERT INTO product (id, code, name, default_process_id, bom_id) VALUES
(1, 'PROD-WC-001', '无线充电器', 1, NULL);

-- --------------------------------------------------------
-- 4. production_line（产线）
-- --------------------------------------------------------
INSERT INTO production_line (id, name, workshop_id, current_process_id, current_workorder_id, status) VALUES
(1, '柔性组装线', 2, 1, NULL, '空闲'),
(2, 'SMT 产线', 4, 2, NULL, '空闲');

-- --------------------------------------------------------
-- 5. workstation（工作站）
-- --------------------------------------------------------
INSERT INTO workstation (id, code, name, production_line_id, equipment_code, current_process_id, device_status, work_status, conveyor_status, processed_count, raw_count, finished_count, ng_count) VALUES
(1, 'WS-FLX-OP10', '上料工位', 1, 'EQ-FLX-01', NULL, '待机', '机械臂上料', '停', 0, 0, 0, 0),
(2, 'WS-FLX-OP20', '主板组装工位', 1, 'EQ-FLX-02', NULL, '待机', '工作台固定', '停', 0, 0, 0, 0),
(3, 'WS-FLX-OP30', '后盖组装工位', 1, 'EQ-FLX-03', NULL, '待机', '机械臂装配', '停', 0, 0, 0, 0),
(4, 'WS-FLX-OP40', '螺丝锁付工位', 1, 'EQ-FLX-04', NULL, '待机', '自动锁螺丝', '停', 0, 0, 0, 0),
(5, 'WS-FLX-OP50', '激光打标工位', 1, 'EQ-FLX-05', NULL, '待机', '激光打标', '停', 0, 0, 0, 0),
(6, 'WS-FLX-OP60', '成品检测工位', 1, 'EQ-FLX-06', NULL, '待机', '视觉检测', '停', 0, 0, 0, 0),
(7, 'WS-FLX-OP70', '下料工位', 1, 'EQ-FLX-07', NULL, '待机', '出料等待', '停', 0, 0, 0, 0);

-- --------------------------------------------------------
-- 6. process_step（工序）
-- --------------------------------------------------------
INSERT INTO process_step (id, process_id, seq_no, op_code, name, default_station_id, description) VALUES
(1, 1, 10, 'OP10', '上料', 1, '将原料放置到工作台'),
(2, 1, 20, 'OP20', '主板组装', 2, '安装无线充电主板'),
(3, 1, 30, 'OP30', '后盖组装', 3, '安装后盖外壳'),
(4, 1, 40, 'OP40', '螺丝锁付', 4, '锁紧固定螺丝'),
(5, 1, 50, 'OP50', '激光打标', 5, '激光刻印产品标识'),
(6, 1, 60, 'OP60', '成品检测', 6, '功能与外观检测'),
(7, 1, 70, 'OP70', '下料', 7, '成品下料入库');

-- --------------------------------------------------------
-- 7. user（人员）
-- --------------------------------------------------------
INSERT INTO user (id, employee_no, name, role, team_id, workshop_id, status, avatar_url, password_hash) VALUES
(1, 'ADMIN001', '张建国', 'admin', NULL, 1, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(2, 'LEADER001', '王志刚', 'leader', NULL, 2, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(3, 'OP001', '刘伟', 'operator', NULL, 2, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(4, 'INS001', '陈静', 'inspector', NULL, 3, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva');

-- --------------------------------------------------------
-- 8. role_permission（角色权限）
-- --------------------------------------------------------
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

-- --------------------------------------------------------
-- 9. line_process_support（产线支持工艺关联）
-- --------------------------------------------------------
INSERT INTO line_process_support (line_id, process_id) VALUES
(1, 1);
