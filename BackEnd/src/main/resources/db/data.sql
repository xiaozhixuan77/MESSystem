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
('leader', 'workorder.confirm'),
('leader', 'line.view'),
('operator', 'workorder.view_own'),
('operator', 'workorder.start'),
('operator', 'workorder.report'),
('operator', 'line.operate'),
('inspector', 'inspection.create'),
('inspector', 'workorder.view_inspection'),
('inspector', 'line.view');

-- --------------------------------------------------------
-- 9. line_process_support（产线支持工艺关联）
-- --------------------------------------------------------
INSERT INTO line_process_support (line_id, process_id) VALUES
(1, 1);
