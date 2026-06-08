-- ========================================================
-- MES 数据库表结构 (H2 MySQL 兼容模式)
-- 注意: H2 中约束名/索引名必须全局唯一，所有名称已加表前缀
-- ========================================================

-- 1. workshop
CREATE TABLE IF NOT EXISTS workshop (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(64) NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    version         INT DEFAULT 0,
    is_deleted      TINYINT DEFAULT 0
);

-- 2. process
CREATE TABLE IF NOT EXISTS process (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    code                    VARCHAR(32) NOT NULL,
    name                    VARCHAR(64) NOT NULL,
    applicable_product_codes VARCHAR(255) NULL,
    created_at              DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME DEFAULT CURRENT_TIMESTAMP,
    version                 INT DEFAULT 0,
    is_deleted              TINYINT DEFAULT 0,
    UNIQUE KEY uk_process_code (code)
);

-- 3. product
CREATE TABLE IF NOT EXISTS product (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(64) NOT NULL,
    default_process_id  BIGINT NULL,
    bom_id              BIGINT NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    UNIQUE KEY uk_product_code (code),
    INDEX idx_product_default_process_id (default_process_id),
    FOREIGN KEY (default_process_id) REFERENCES process(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 4. production_line
CREATE TABLE IF NOT EXISTS production_line (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    name                VARCHAR(64) NOT NULL,
    workshop_id         BIGINT NOT NULL,
    current_process_id  BIGINT NULL,
    current_workorder_id BIGINT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT '空闲',
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    INDEX idx_line_workshop_id (workshop_id),
    INDEX idx_line_status (status),
    FOREIGN KEY (workshop_id) REFERENCES workshop(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (current_process_id) REFERENCES process(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 5. workstation
CREATE TABLE IF NOT EXISTS workstation (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(64) NOT NULL,
    production_line_id  BIGINT NOT NULL,
    equipment_code      VARCHAR(32) NULL,
    current_process_id  BIGINT NULL,
    device_status       VARCHAR(32) NOT NULL DEFAULT '待机',
    work_status         VARCHAR(64) NULL,
    conveyor_status     VARCHAR(16) NULL,
    processed_count     INT NOT NULL DEFAULT 0,
    raw_count           INT NOT NULL DEFAULT 0,
    finished_count      INT NOT NULL DEFAULT 0,
    ng_count            INT NOT NULL DEFAULT 0,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    UNIQUE KEY uk_ws_code (code),
    INDEX idx_ws_line_id (production_line_id),
    FOREIGN KEY (production_line_id) REFERENCES production_line(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (current_process_id) REFERENCES process(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 6. process_step
CREATE TABLE IF NOT EXISTS process_step (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    process_id          BIGINT NOT NULL,
    seq_no              INT NOT NULL,
    op_code             VARCHAR(16) NOT NULL,
    name                VARCHAR(64) NOT NULL,
    default_station_id  BIGINT NULL,
    description         VARCHAR(255) NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    INDEX idx_ps_process_id (process_id),
    INDEX idx_ps_seq_no (process_id, seq_no),
    FOREIGN KEY (process_id) REFERENCES process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (default_station_id) REFERENCES workstation(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 7. user
CREATE TABLE IF NOT EXISTS `user` (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_no     VARCHAR(32) NOT NULL,
    name            VARCHAR(64) NOT NULL,
    role            VARCHAR(32) NOT NULL,
    team_id         BIGINT NULL,
    workshop_id     BIGINT NULL,
    status          VARCHAR(16) NOT NULL DEFAULT '在岗',
    avatar_url      VARCHAR(255) NULL,
    password_hash   VARCHAR(255) NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    version         INT DEFAULT 0,
    is_deleted      TINYINT DEFAULT 0,
    UNIQUE KEY uk_user_employee_no (employee_no),
    INDEX idx_user_role (role),
    INDEX idx_user_team_id (team_id),
    INDEX idx_user_workshop_id (workshop_id),
    FOREIGN KEY (workshop_id) REFERENCES workshop(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 8. work_order
CREATE TABLE IF NOT EXISTS work_order (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    code                VARCHAR(32) NOT NULL,
    type                VARCHAR(16) NOT NULL,
    workshop_id         BIGINT NOT NULL,
    line_id             BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    process_id          BIGINT NOT NULL,
    plan_qty            INT NOT NULL,
    plan_start_time     DATETIME NULL,
    plan_end_time       DATETIME NULL,
    status              VARCHAR(32) NOT NULL DEFAULT '待派工',
    source              VARCHAR(32) NULL,
    operator_id         BIGINT NULL,
    dispatch_time       DATETIME NULL,
    actual_start_time   DATETIME NULL,
    actual_end_time     DATETIME NULL,
    pause_time          DATETIME NULL,
    reported_qty_good   INT NULL,
    reported_qty_ng     INT NULL,
    reported_hours      DECIMAL(10,2) NULL,
    exception_note      VARCHAR(500) NULL,
    created_by          BIGINT NULL,
    source_workorder_id BIGINT NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    UNIQUE KEY uk_wo_code (code),
    INDEX idx_wo_status (status),
    INDEX idx_wo_operator_id (operator_id),
    INDEX idx_wo_line_id (line_id),
    INDEX idx_wo_created_by (created_by),
    INDEX idx_wo_type_status (type, status),
    INDEX idx_wo_status_created_at (status, created_at),
    FOREIGN KEY (workshop_id) REFERENCES workshop(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (line_id) REFERENCES production_line(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (process_id) REFERENCES process(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (operator_id) REFERENCES `user`(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES `user`(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (source_workorder_id) REFERENCES work_order(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 9. work_order_route_step
CREATE TABLE IF NOT EXISTS work_order_route_step (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id   BIGINT NOT NULL,
    seq_no          INT NOT NULL,
    op_code         VARCHAR(16) NOT NULL,
    name            VARCHAR(64) NOT NULL,
    station_id      BIGINT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    version         INT DEFAULT 0,
    is_deleted      TINYINT DEFAULT 0,
    INDEX idx_wors_work_order_id (work_order_id),
    FOREIGN KEY (work_order_id) REFERENCES work_order(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (station_id) REFERENCES workstation(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 10. production_exception
CREATE TABLE IF NOT EXISTS production_exception (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id   BIGINT NOT NULL,
    line_id         BIGINT NOT NULL,
    station_id      BIGINT NULL,
    reporter_id     BIGINT NOT NULL,
    report_time     DATETIME NOT NULL,
    description     VARCHAR(500) NOT NULL,
    handled_by      BIGINT NULL,
    handle_time     DATETIME NULL,
    handle_action   VARCHAR(32) NULL,
    resolved        TINYINT NOT NULL DEFAULT 0,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    version         INT DEFAULT 0,
    is_deleted      TINYINT DEFAULT 0,
    INDEX idx_pe_work_order_id (work_order_id),
    INDEX idx_pe_line_id (line_id),
    INDEX idx_pe_resolved (resolved),
    FOREIGN KEY (work_order_id) REFERENCES work_order(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (line_id) REFERENCES production_line(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (station_id) REFERENCES workstation(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (reporter_id) REFERENCES `user`(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (handled_by) REFERENCES `user`(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 11. inspection_record
CREATE TABLE IF NOT EXISTS inspection_record (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_order_id       BIGINT NOT NULL,
    inspector_id        BIGINT NULL,
    inspect_time        DATETIME NULL,
    sample_qty          INT NOT NULL,
    sample_good         INT NOT NULL,
    sample_ng           INT NOT NULL,
    defect_types        VARCHAR(255) NULL,
    defect_description  VARCHAR(500) NULL,
    status              VARCHAR(16) NOT NULL DEFAULT '已抽检',
    conclusion          VARCHAR(16) NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    version             INT DEFAULT 0,
    is_deleted          TINYINT DEFAULT 0,
    INDEX idx_ir_work_order_id (work_order_id),
    INDEX idx_ir_inspector_id (inspector_id),
    FOREIGN KEY (work_order_id) REFERENCES work_order(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (inspector_id) REFERENCES `user`(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 12. production_log (H2 不支持分区，使用普通表)
CREATE TABLE IF NOT EXISTS production_log (
    id              BIGINT AUTO_INCREMENT,
    line_id         BIGINT NOT NULL,
    station_id      BIGINT NULL,
    work_order_id   BIGINT NULL,
    event_type      VARCHAR(32) NOT NULL,
    product_sn      VARCHAR(64) NULL,
    event_time      DATETIME NOT NULL,
    payload         CLOB NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    version         INT DEFAULT 0,
    is_deleted      TINYINT DEFAULT 0,
    PRIMARY KEY (id, event_time),
    INDEX idx_pl_line_id (line_id),
    INDEX idx_pl_event_time (event_time),
    INDEX idx_pl_work_order_id (work_order_id),
    FOREIGN KEY (line_id) REFERENCES production_line(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (station_id) REFERENCES workstation(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (work_order_id) REFERENCES work_order(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 13. role_permission
CREATE TABLE IF NOT EXISTS role_permission (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    role        VARCHAR(32) NOT NULL,
    permission  VARCHAR(64) NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    version     INT DEFAULT 0,
    is_deleted  TINYINT DEFAULT 0,
    UNIQUE KEY uk_role_permission (role, permission)
);

-- 14. line_process_support
CREATE TABLE IF NOT EXISTS line_process_support (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    line_id     BIGINT NOT NULL,
    process_id  BIGINT NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    version     INT DEFAULT 0,
    is_deleted  TINYINT DEFAULT 0,
    UNIQUE KEY uk_line_process (line_id, process_id),
    FOREIGN KEY (line_id) REFERENCES production_line(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (process_id) REFERENCES process(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ========================================================
-- 初始数据 (密码均为 123456, BCrypt)
-- ========================================================

INSERT INTO workshop (id, name) VALUES
(1, '机加工车间'),
(2, '柔性车间'),
(3, '智能组装车间'),
(4, 'SMT 车间');

INSERT INTO process (id, code, name, applicable_product_codes) VALUES
(1, 'PROC-WC-001', '无线充电器组装', 'PROD-WC-001'),
(2, 'PROC-SMT-001', 'SMT 贴片工艺', NULL);

INSERT INTO product (id, code, name, default_process_id, bom_id) VALUES
(1, 'PROD-WC-001', '无线充电器', 1, NULL);

INSERT INTO production_line (id, name, workshop_id, current_process_id, current_workorder_id, status) VALUES
(1, '柔性组装线', 2, 1, NULL, '空闲'),
(2, 'SMT 产线', 4, 2, NULL, '空闲');

INSERT INTO workstation (id, code, name, production_line_id, equipment_code, current_process_id, device_status, work_status, conveyor_status, processed_count, raw_count, finished_count, ng_count) VALUES
(1, 'WS-FLX-OP10', '上料工位', 1, 'EQ-FLX-01', NULL, '待机', '机械臂上料', '停', 0, 0, 0, 0),
(2, 'WS-FLX-OP20', '主板组装工位', 1, 'EQ-FLX-02', NULL, '待机', '工作台固定', '停', 0, 0, 0, 0),
(3, 'WS-FLX-OP30', '后盖组装工位', 1, 'EQ-FLX-03', NULL, '待机', '机械臂装配', '停', 0, 0, 0, 0),
(4, 'WS-FLX-OP40', '螺丝锁付工位', 1, 'EQ-FLX-04', NULL, '待机', '自动锁螺丝', '停', 0, 0, 0, 0),
(5, 'WS-FLX-OP50', '激光打标工位', 1, 'EQ-FLX-05', NULL, '待机', '激光打标', '停', 0, 0, 0, 0),
(6, 'WS-FLX-OP60', '成品检测工位', 1, 'EQ-FLX-06', NULL, '待机', '视觉检测', '停', 0, 0, 0, 0),
(7, 'WS-FLX-OP70', '下料工位', 1, 'EQ-FLX-07', NULL, '待机', '出料等待', '停', 0, 0, 0, 0);

INSERT INTO process_step (id, process_id, seq_no, op_code, name, default_station_id, description) VALUES
(1, 1, 10, 'OP10', '上料', 1, '将原料放置到工作台'),
(2, 1, 20, 'OP20', '主板组装', 2, '安装无线充电主板'),
(3, 1, 30, 'OP30', '后盖组装', 3, '安装后盖外壳'),
(4, 1, 40, 'OP40', '螺丝锁付', 4, '锁紧固定螺丝'),
(5, 1, 50, 'OP50', '激光打标', 5, '激光刻印产品标识'),
(6, 1, 60, 'OP60', '成品检测', 6, '功能与外观检测'),
(7, 1, 70, 'OP70', '下料', 7, '成品下料入库');

INSERT INTO `user` (id, employee_no, name, role, team_id, workshop_id, status, avatar_url, password_hash) VALUES
(1, 'ADMIN001', '张建国', 'admin', NULL, 1, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(2, 'LEADER001', '王志刚', 'leader', NULL, 2, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(3, 'OP001', '刘伟', 'operator', NULL, 2, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva'),
(4, 'INS001', '陈静', 'inspector', NULL, 3, '在岗', NULL, '$2a$10$9LLHytJcuDv3q13pyQyftuk/Wttx400E1e5Q/ui3lF0Kroob/tSva');

INSERT INTO role_permission (role, permission) VALUES
-- admin: 通配符 + 全部显式权限兜底
('admin', '*'),
('admin', 'dashboard.view'),
('admin', 'exception.report'),
('admin', 'exception.view'),
('admin', 'exception.handle'),
('admin', 'inspection.create'),
('admin', 'line.operate'),
('admin', 'workorder.create'),
('admin', 'workorder.dispatch'),
('admin', 'workorder.start'),
('admin', 'workorder.complete'),
('admin', 'workorder.pause'),
('admin', 'workorder.resume'),
('admin', 'workorder.report'),
('admin', 'workorder.confirm'),
('admin', 'workorder.scrap'),
('admin', 'workorder.delete'),
-- leader: 班组管理
('leader', 'workorder.view_team'),
('leader', 'workorder.create'),
('leader', 'workorder.dispatch'),
('leader', 'workorder.delete'),
('leader', 'workorder.pause'),
('leader', 'workorder.resume'),
('leader', 'workorder.confirm'),
('leader', 'workorder.scrap'),
('leader', 'line.view'),
('leader', 'line.operate'),
('leader', 'station.operate'),
('leader', 'exception.report'),
('leader', 'exception.view'),
('leader', 'exception.handle'),
('leader', 'dashboard.view'),
-- operator: 一线操作
('operator', 'workorder.view_own'),
('operator', 'workorder.start'),
('operator', 'workorder.complete'),
('operator', 'workorder.pause'),
('operator', 'workorder.resume'),
('operator', 'workorder.report'),
('operator', 'line.view'),
('operator', 'line.operate'),
('operator', 'station.operate'),
('operator', 'exception.report'),
('operator', 'dashboard.view'),
-- inspector: 质检抽检
('inspector', 'inspection.create'),
('inspector', 'workorder.view_inspection'),
('inspector', 'line.view'),
('inspector', 'dashboard.view');

INSERT INTO line_process_support (line_id, process_id) VALUES
(1, 1);
