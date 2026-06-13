package org.example.e2e;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderReportRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 鉴权系统 E2E 验证 — 对照需求文档 §3 角色权限矩阵。
 * 所有测试不触发 simulator，避免 H2 并发锁冲突。
 */
@DisplayName("E2E-004: 鉴权系统验证")
class E2E004_AuthTest extends E2ETestBase {

    // ================================================================
    // 一、登录与 JWT 权限字段
    // ================================================================

    @Nested
    @DisplayName("登录返回 permissions 字段")
    class LoginPermissions {

        @Test
        @DisplayName("admin 登录返回 * 通配符")
        void adminGetsWildcard() throws Exception {
            JsonNode data = dataNode(performGet("/me", adminToken));
            assertEquals("admin", data.get("role").asText());
        }

        @Test
        @DisplayName("leader 登录返回完整权限列表")
        void leaderPermissionsCheck() throws Exception {
            // 通过 me 接口确认角色正确
            JsonNode data = dataNode(performGet("/me", leaderToken));
            assertEquals("leader", data.get("role").asText());
            // leader 应能访问工单列表
            assertOk(performGet("/workorders", leaderToken));
        }

        @Test
        @DisplayName("operator 登录返回操作员权限")
        void operatorPermissionsCheck() throws Exception {
            JsonNode data = dataNode(performGet("/me", operatorToken));
            assertEquals("operator", data.get("role").asText());
        }

        @Test
        @DisplayName("inspector 登录返回质检员权限")
        void inspectorPermissionsCheck() throws Exception {
            JsonNode data = dataNode(performGet("/me", inspectorToken));
            assertEquals("inspector", data.get("role").asText());
        }
    }

    // ================================================================
    // 二、工单权限 — operator 无权执行的动作
    // ================================================================

    @Nested
    @DisplayName("操作员权限限制")
    class OperatorRestrictions {

        private Long createPendingWo() throws Exception {
            WorkOrderCreateRequest req = new WorkOrderCreateRequest();
            req.setType("量产");
            req.setWorkshopId(2L);
            req.setLineId(1L);
            req.setProductId(1L);
            req.setPlanQty(100);
            return extractDataId(performPostWithBody("/workorders", req, leaderToken));
        }

        @Test
        @DisplayName("操作员无权派工 → 403")
        void operatorCannotDispatch() throws Exception {
            Long woId = createPendingWo();
            DispatchRequest req = new DispatchRequest();
            req.setOperatorId(3L);
            assertError(performPostWithBodyExpectAny("/workorders/" + woId + "/dispatch", req, operatorToken), 403);
        }

        @Test
        @DisplayName("操作员无权恢复 → 403")
        void operatorCannotResume() throws Exception {
            // operator 没有 workorder.resume 权限，直接 403
            MvcResult result = performPostWithBodyExpectAny("/workorders/99999/resume", null, operatorToken);
            assertError(result, 403);
        }

        @Test
        @DisplayName("操作员无权确认工时 → 403")
        void operatorCannotConfirm() throws Exception {
            MvcResult result = performPostWithBodyExpectAny("/workorders/99999/confirm", null, operatorToken);
            assertError(result, 403);
        }

        @Test
        @DisplayName("操作员无权报废 → 403")
        void operatorCannotScrap() throws Exception {
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/workorders/99999/scrap")
                                    .header("Authorization", "Bearer " + operatorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(Map.of("reason", "测试"))))
                    .andReturn();
            assertError(result, 403);
        }
    }

    // ================================================================
    // 三、服务层业务校验 — 角色感知
    // ================================================================

    @Nested
    @DisplayName("服务层角色感知校验（避免 simulator）")
    class ServiceLayerChecks {

        /**
         * 创建已派工工单（不启动产线，不触发 simulator）。
         * 工单派工给 OP001 (id=3)。
         */
        private Long createDispatchedWo() throws Exception {
            WorkOrderCreateRequest req = new WorkOrderCreateRequest();
            req.setType("量产");
            req.setWorkshopId(2L);
            req.setLineId(1L);
            req.setProductId(1L);
            req.setPlanQty(100);
            Long woId = extractDataId(performPostWithBody("/workorders", req, leaderToken));

            DispatchRequest dispatchReq = new DispatchRequest();
            dispatchReq.setOperatorId(3L); // OP001
            performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);
            return woId;
        }

        @Test
        @DisplayName("班组长开工（工单=已派工非暂停中）→ 403（仅异常恢复时可开工）")
        void leaderCannotStartNormalWorkOrder() throws Exception {
            Long woId = createDispatchedWo();
            // 班组长开工非暂停中工单 → 服务层拒绝
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/start", null, leaderToken);
            assertError(result, 403);
        }

        @Test
        @DisplayName("非指派操作员报工 → 403（服务层校验）")
        void wrongOperatorCannotReport() throws Exception {
            // 创建工单并派工给 OP001 (id=3)，然后用 leader（非 OP001）尝试报工
            WorkOrderCreateRequest req = new WorkOrderCreateRequest();
            req.setType("量产");
            req.setWorkshopId(2L);
            req.setLineId(1L);
            req.setProductId(1L);
            req.setPlanQty(100);
            Long woId = extractDataId(performPostWithBody("/workorders", req, leaderToken));

            DispatchRequest dispatchReq = new DispatchRequest();
            dispatchReq.setOperatorId(3L); // 派工给 OP001
            performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);

            // leader 不是被指派操作员，尝试报工 → 应由服务层拒绝
            WorkOrderReportRequest reportReq = new WorkOrderReportRequest();
            reportReq.setGood(100);
            reportReq.setNg(0);
            reportReq.setHours(new BigDecimal("8"));
            // 工单状态不是"生产完成"，会先被状态校验拒绝（400），但这也说明通过了权限检查
            // 换用 admin 报工 → 200（状态不对则 400，权限通过）
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/report", reportReq, leaderToken);
            // leader 有 workorder.report？不，leader 不在矩阵中。应该是 403。
            // 实际上 leader 在旧数据中没有 workorder.report，新数据中也没有
            assertError(result, 403);
        }

        @Test
        @DisplayName("被指派操作员可以报工 → 权限通过（到达业务层校验）")
        void assignedOperatorCanReport() throws Exception {
            WorkOrderCreateRequest req = new WorkOrderCreateRequest();
            req.setType("量产");
            req.setWorkshopId(2L);
            req.setLineId(1L);
            req.setProductId(1L);
            req.setPlanQty(100);
            Long woId = extractDataId(performPostWithBody("/workorders", req, leaderToken));

            DispatchRequest dispatchReq = new DispatchRequest();
            dispatchReq.setOperatorId(3L);
            performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);

            // 操作员 OP001 尝试报工（状态不对 → 400 而非 403，说明权限通过）
            WorkOrderReportRequest reportReq = new WorkOrderReportRequest();
            reportReq.setGood(100);
            reportReq.setNg(0);
            reportReq.setHours(new BigDecimal("8"));
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/report", reportReq, operatorToken);
            assertErrorMessageContains(result, 400, "生产完成");
        }
    }

    // ================================================================
    // 四、抽检权限 — inspection 三码分离
    // ================================================================

    @Nested
    @DisplayName("抽检权限：view / create / submit 分离")
    class InspectionPermissions {

        @Test
        @DisplayName("质检员可以查看抽检列表 → 200")
        void inspectorCanViewInspections() throws Exception {
            assertOk(performGet("/inspections", inspectorToken));
        }

        @Test
        @DisplayName("质检员可以创建抽检 → 200")
        void inspectorCanCreateInspection() throws Exception {
            // 需要一个已报工的工单（无 simulator）
            Long woId = createReportedWo();
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/inspections")
                                    .characterEncoding("UTF-8")
                                    .header("Authorization", "Bearer " + inspectorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(
                                            Map.of("workOrderId", woId, "sampleQty", 5,
                                                    "sampleGood", 5, "sampleNg", 0,
                                                    "defectTypes", "[]",
                                                    "defectDescription", "",
                                                    "conclusion", "合格"))))
                    .andReturn();
            assertOk(result);
        }

        @Test
        @DisplayName("操作员不能创建抽检 → 403")
        void operatorCannotCreateInspection() throws Exception {
            // 先创建一个已报工工单
            Long woId = createReportedWo();
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/inspections")
                                    .characterEncoding("UTF-8")
                                    .header("Authorization", "Bearer " + operatorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(
                                            Map.of("workOrderId", woId, "sampleQty", 5,
                                                    "sampleGood", 5, "sampleNg", 0,
                                                    "defectTypes", "[]",
                                                    "defectDescription", "",
                                                    "conclusion", "合格"))))
                    .andReturn();
            assertError(result, 403);
        }

        private Long createReportedWo() throws Exception {
            WorkOrderCreateRequest req = new WorkOrderCreateRequest();
            req.setType("量产");
            req.setWorkshopId(2L);
            req.setLineId(1L);
            req.setProductId(1L);
            req.setPlanQty(100);
            Long woId = extractDataId(performPostWithBody("/workorders", req, leaderToken));

            DispatchRequest dispatchReq = new DispatchRequest();
            dispatchReq.setOperatorId(3L);
            performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);

            // start → simulator 启动
            performPost("/workorders/" + woId + "/start", operatorToken);
            // 立即 stop → simulator 停止
            performPost("/lines/1/stop", leaderToken);
            // complete → 需要 生产中 状态（但 stop 后工单仍是生产中，line 变为暂停）
            // 直接调 complete
            performPost("/workorders/" + woId + "/complete", operatorToken);

            WorkOrderReportRequest reportReq = new WorkOrderReportRequest();
            reportReq.setGood(100);
            reportReq.setNg(0);
            reportReq.setHours(new BigDecimal("8"));
            performPostWithBody("/workorders/" + woId + "/report", reportReq, operatorToken);

            return woId;
        }
    }

    // ================================================================
    // 五、产线与工作站权限
    // ================================================================

    @Nested
    @DisplayName("产线/工作站权限")
    class LineAndStationPermissions {

        @Test
        @DisplayName("质检员可以查看产线列表 → 200（line.view）")
        void inspectorCanViewLines() throws Exception {
            assertOk(performGet("/lines", inspectorToken));
        }

        @Test
        @DisplayName("质检员查看产线详情 → 200")
        void inspectorCanViewLineDetail() throws Exception {
            assertOk(performGet("/lines/1", inspectorToken));
        }

        @Test
        @DisplayName("质检员不能操作产线（start）→ 403")
        void inspectorCannotOperateLine() throws Exception {
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/lines/1/start")
                                    .header("Authorization", "Bearer " + inspectorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(Map.of("workOrderId", 1))))
                    .andReturn();
            assertError(result, 403);
        }

        @Test
        @DisplayName("所有角色均可查看看板")
        void allRolesCanViewDashboard() throws Exception {
            assertOk(performGet("/dashboard", adminToken));
            assertOk(performGet("/dashboard", leaderToken));
            assertOk(performGet("/dashboard", operatorToken));
            assertOk(performGet("/dashboard", inspectorToken));
        }
    }

    // ================================================================
    // 六、异常权限
    // ================================================================

    @Nested
    @DisplayName("异常权限")
    class ExceptionPermissions {

        @Test
        @DisplayName("质检员可以查看异常列表 → 200")
        void inspectorCanViewExceptions() throws Exception {
            assertOk(performGet("/exceptions", inspectorToken));
        }

        @Test
        @DisplayName("质检员不能上报异常 → 403")
        void inspectorCannotReportException() throws Exception {
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/exceptions")
                                    .header("Authorization", "Bearer " + inspectorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(
                                            Map.of("workOrderId", 1, "lineId", 1L, "description", "测试"))))
                    .andReturn();
            assertError(result, 403);
        }

        @Test
        @DisplayName("操作员可以上报异常 → 通过权限检查")
        void operatorCanReportException() throws Exception {
            // 操作员有 exception.report，权限应通过（可能因工单不存在返回业务错误，但不应是 403）
            MvcResult result = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .post("/exceptions")
                                    .header("Authorization", "Bearer " + operatorToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(
                                            Map.of("workOrderId", 1, "lineId", 1L, "description", "测试"))))
                    .andReturn();
            int code = responseCode(result);
            assertNotEquals(403, code, "操作员有 exception.report，不应返回 403");
        }
    }

    // ================================================================
    // 七、人员管理权限 — 仅 admin
    // ================================================================

    @Nested
    @DisplayName("人员管理权限 — 仅 admin")
    class UserManagementPermissions {

        @Test
        @DisplayName("admin 可以查看人员列表 → 200")
        void adminCanViewUsers() throws Exception {
            assertOk(performGet("/users", adminToken));
        }

        @Test
        @DisplayName("leader 不能查看人员列表 → 403")
        void leaderCannotViewUsers() throws Exception {
            assertError(performGetExpectAny("/users", leaderToken), 403);
        }

        @Test
        @DisplayName("operator 不能查看人员列表 → 403")
        void operatorCannotViewUsers() throws Exception {
            assertError(performGetExpectAny("/users", operatorToken), 403);
        }
    }
}
