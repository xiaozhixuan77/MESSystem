package org.example.e2e;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderReportRequest;
import org.example.dto.request.WorkOrderUpdateRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("E2E-001: 完整工单生命周期")
class E2E001_FullLifecycleTest extends E2ETestBase {

    @Test
    @DisplayName("E2E-001 完整流程：创建→派工→启动→暂停→恢复→完成→报工→确认→删除")
    void fullLifecycle() throws Exception {
        // Step 1: Leader 登录（已在 setUpBase 中完成）
        assertNotNull(leaderToken);
        JsonNode leaderLoginData = dataNode(performGet("/me", leaderToken));
        assertEquals("leader", leaderLoginData.get("role").asText());

        // Step 2: Leader 创建工单
        WorkOrderCreateRequest createReq = new WorkOrderCreateRequest();
        createReq.setType("量产");
        createReq.setWorkshopId(2L);  // 柔性车间
        createReq.setLineId(1L);      // 柔性组装线
        createReq.setProductId(1L);   // 无线充电器
        createReq.setPlanQty(100);

        MvcResult createResult = performPostWithBody("/workorders", createReq, leaderToken);
        assertOk(createResult);
        Long woId = extractDataId(createResult);
        assertNotNull(woId);
        assertDataFieldEquals(createResult, "status", "待派工");
        JsonNode woData = dataNode(createResult);
        assertTrue(woData.get("code").asText().startsWith("MO"));

        // Step 3: Leader 派工给 OP001
        DispatchRequest dispatchReq = new DispatchRequest();
        dispatchReq.setOperatorId(3L);  // OP001

        MvcResult dispatchResult = performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);
        assertOk(dispatchResult);

        // 验证派工后状态
        MvcResult detailAfterDispatch = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterDispatch, "status", "已派工");

        // Step 4: Operator 登录（已在 setUpBase 中完成）
        assertNotNull(operatorToken);

        // Step 5: Operator 查看工单列表
        MvcResult listResult = performGet("/workorders?status=已派工", operatorToken);
        assertOk(listResult);
        JsonNode listData = dataNode(listResult);
        assertTrue(listData.isArray() && listData.size() > 0);

        // Step 6: Operator 开始生产
        MvcResult startResult = performPost("/workorders/" + woId + "/start", operatorToken);
        assertOk(startResult);

        MvcResult detailAfterStart = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterStart, "status", "生产中");

        // Step 7: Leader 查看产线详情（验证产线状态=生产中）
        MvcResult lineDetail = performGet("/lines/1", leaderToken);
        assertDataFieldEquals(lineDetail, "status", "生产中");

        // Step 8: Operator 暂停生产
        MvcResult pauseResult = performPost("/workorders/" + woId + "/pause", operatorToken);
        assertOk(pauseResult);

        MvcResult detailAfterPause = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterPause, "status", "暂停中");

        // Step 9: Leader 查看产线详情（验证产线=暂停中）
        MvcResult lineDetailPaused = performGet("/lines/1", leaderToken);
        assertDataFieldEquals(lineDetailPaused, "status", "暂停");

        // Step 10: Operator 恢复生产
        MvcResult resumeResult = performPost("/workorders/" + woId + "/resume", operatorToken);
        assertOk(resumeResult);

        MvcResult detailAfterResume = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterResume, "status", "生产中");

        // Step 11: Operator 完成生产
        MvcResult completeResult = performPost("/workorders/" + woId + "/complete", operatorToken);
        assertOk(completeResult);

        MvcResult detailAfterComplete = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterComplete, "status", "生产完成");

        // Step 12: Operator 报工（good=95, ng=5, hours=8）
        WorkOrderReportRequest reportReq = new WorkOrderReportRequest();
        reportReq.setGood(95);
        reportReq.setNg(5);
        reportReq.setHours(new BigDecimal("8"));

        MvcResult reportResult = performPostWithBody("/workorders/" + woId + "/report", reportReq, operatorToken);
        assertOk(reportResult);

        MvcResult detailAfterReport = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterReport, "status", "已报工");

        // 验证报工数据
        JsonNode reportedData = dataNode(detailAfterReport);
        assertNotNull(reportedData.get("reportedQtyGood"));
        assertEquals(95, reportedData.get("reportedQtyGood").asInt());
        assertEquals(5, reportedData.get("reportedQtyNg").asInt());

        // Step 13: Inspector 登录（已在 setUpBase 中完成）
        assertNotNull(inspectorToken);

        // Step 14: Inspector 查看已报工工单
        MvcResult inspectorList = performGet("/workorders?status=已报工", inspectorToken);
        assertOk(inspectorList);

        // Step 15: Leader 确认完工
        MvcResult confirmResult = performPost("/workorders/" + woId + "/confirm", leaderToken);
        assertOk(confirmResult);

        MvcResult detailAfterConfirm = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterConfirm, "status", "完工");

        // Step 16: Operator 查看我的工单（状态同步为完工）
        MvcResult operatorList = performGet("/workorders", operatorToken);
        assertOk(operatorList);

        // Step 17: Admin 删除工单
        MvcResult deleteResult = performDelete("/workorders/" + woId, adminToken);
        assertOk(deleteResult);

        // 验证删除后查询返回 404
        MvcResult notFoundResult = performGetExpectAny("/workorders/" + woId, adminToken);
        assertEquals(404, responseCode(notFoundResult));
    }

    // ---- 状态转换错误场景 ----

    @Nested
    @DisplayName("状态转换错误场景")
    class ErrorScenarios {

        @Test
        @DisplayName("非待派工状态派工 → 400")
        void dispatchWhenNotPending() throws Exception {
            // 创建并派工
            Long woId = createAndDispatchWorkOrder();

            // 尝试再次派工（已是已派工状态）
            DispatchRequest req = new DispatchRequest();
            req.setOperatorId(3L);
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/dispatch", req, leaderToken);
            assertErrorMessageContains(result, 400, "待派工");
        }

        @Test
        @DisplayName("非指派操作员启动 → 403")
        void startByWrongOperator() throws Exception {
            Long woId = createAndDispatchWorkOrder();

            // 用 admin（非指派操作员）尝试启动
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/start", null, adminToken);
            assertError(result, 403);
        }

        @Test
        @DisplayName("报工数量超计划 → 400")
        void reportExceedingPlanQty() throws Exception {
            Long woId = createDispatchStartAndComplete();

            // good + ng > planQty (100)
            WorkOrderReportRequest req = new WorkOrderReportRequest();
            req.setGood(80);
            req.setNg(30);  // 80+30=110 > 100
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/report", req, operatorToken);
            assertErrorMessageContains(result, 400, "计划");
        }

        @Test
        @DisplayName("派工给持有激活工单的操作员 → 400")
        void dispatchToOperatorWithActiveOrder() throws Exception {
            // 创建第一个工单并派工给 OP001，然后启动
            Long woId1 = createDispatchAndStartWorkOrder();

            // 创建第二个工单并尝试派工给同一个操作员
            WorkOrderCreateRequest createReq = new WorkOrderCreateRequest();
            createReq.setType("量产");
            createReq.setWorkshopId(2L);
            createReq.setLineId(1L);
            createReq.setProductId(1L);
            createReq.setPlanQty(50);

            MvcResult createResult = performPostWithBody("/workorders", createReq, leaderToken);
            Long woId2 = extractDataId(createResult);

            DispatchRequest dispatchReq = new DispatchRequest();
            dispatchReq.setOperatorId(3L);  // OP001 已有激活工单
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId2 + "/dispatch", dispatchReq, leaderToken);
            assertErrorMessageContains(result, 400, "激活");
        }

        @Test
        @DisplayName("乐观锁版本冲突 → 409")
        void optimisticLockConflict() throws Exception {
            // 仅创建工单（不派工，保持待派工状态才可修改）
            WorkOrderCreateRequest createReq = new WorkOrderCreateRequest();
            createReq.setType("量产");
            createReq.setWorkshopId(2L);
            createReq.setLineId(1L);
            createReq.setProductId(1L);
            createReq.setPlanQty(100);

            MvcResult createResult = performPostWithBody("/workorders", createReq, leaderToken);
            Long woId = extractDataId(createResult);

            // 获取当前版本
            MvcResult detail = performGet("/workorders/" + woId, leaderToken);
            int version = dataNode(detail).get("version").asInt();

            // 使用正确的版本号第一次更新
            WorkOrderUpdateRequest updateReq = new WorkOrderUpdateRequest();
            updateReq.setPlanQty(200);
            updateReq.setVersion(version);
            performPutWithBody("/workorders/" + woId, updateReq, leaderToken);

            // 用过期版本号再次更新 → 409
            WorkOrderUpdateRequest staleReq = new WorkOrderUpdateRequest();
            staleReq.setPlanQty(300);
            staleReq.setVersion(version);  // 过期版本号
            MvcResult conflictResult = mockMvc.perform(
                            org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                    .put("/workorders/" + woId)
                                    .characterEncoding("UTF-8")
                                    .header("Authorization", "Bearer " + leaderToken)
                                    .contentType("application/json")
                                    .content(objectMapper.writeValueAsString(staleReq)))
                    .andReturn();
            assertError(conflictResult, 409);
        }

        @Test
        @DisplayName("非生产完成状态报工 → 400")
        void reportWhenNotCompleted() throws Exception {
            Long woId = createAndDispatchWorkOrder();

            WorkOrderReportRequest req = new WorkOrderReportRequest();
            req.setGood(10);
            req.setNg(0);
            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/report", req, operatorToken);
            assertErrorMessageContains(result, 400, "生产完成");
        }

        @Test
        @DisplayName("非已报工状态确认完工 → 400")
        void confirmWhenNotReported() throws Exception {
            Long woId = createAndDispatchWorkOrder();

            MvcResult result = performPostWithBodyExpectAny("/workorders/" + woId + "/confirm", null, leaderToken);
            assertErrorMessageContains(result, 400, "已报工");
        }
    }

    // ---- 辅助方法 ----

    private Long createAndDispatchWorkOrder() throws Exception {
        WorkOrderCreateRequest createReq = new WorkOrderCreateRequest();
        createReq.setType("量产");
        createReq.setWorkshopId(2L);
        createReq.setLineId(1L);
        createReq.setProductId(1L);
        createReq.setPlanQty(100);

        MvcResult result = performPostWithBody("/workorders", createReq, leaderToken);
        Long woId = extractDataId(result);

        DispatchRequest dispatchReq = new DispatchRequest();
        dispatchReq.setOperatorId(3L);
        performPostWithBody("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);

        return woId;
    }

    private Long createDispatchAndStartWorkOrder() throws Exception {
        Long woId = createAndDispatchWorkOrder();
        performPost("/workorders/" + woId + "/start", operatorToken);
        return woId;
    }

    private Long createDispatchStartAndComplete() throws Exception {
        Long woId = createDispatchAndStartWorkOrder();
        performPost("/workorders/" + woId + "/complete", operatorToken);
        return woId;
    }
}
