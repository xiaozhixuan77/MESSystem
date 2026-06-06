package org.example.e2e;

import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderReportRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("E2E-003: 报废流程")
class E2E003_ScrapFlowTest extends E2ETestBase {

    @Test
    @DisplayName("E2E-003 场景一：暂停中状态报废 → 终态不可操作")
    void scrapFromPaused() throws Exception {
        // Step 1: 创建→派工→启动→暂停 → 工单=暂停中
        Long woId = createDispatchStartAndPause();

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "暂停中");

        // Step 2: Leader 报废工单
        MvcResult scrapResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/workorders/" + woId + "/scrap")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("reason", "设备故障无法修复"))))
                .andReturn();
        assertOk(scrapResult);

        MvcResult detailAfterScrap = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterScrap, "status", "报废");

        // Step 3: 尝试操作已报废工单 → 400
        MvcResult resumeAttempt = performPostWithBodyExpectAny(
                "/workorders/" + woId + "/resume", null, operatorToken);
        assertErrorMessageContains(resumeAttempt, 400, "暂停中");

        MvcResult startAttempt = performPostWithBodyExpectAny(
                "/workorders/" + woId + "/start", null, operatorToken);
        assertErrorMessageContains(startAttempt, 400, "不支持启动");

        // Step 4: Leader 尝试修改已报废工单 → 400
        MvcResult updateAttempt = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .put("/workorders/" + woId)
                                .characterEncoding("UTF-8")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("planQty", 200, "version", 0))))
                .andReturn();
        assertErrorMessageContains(updateAttempt, 400, "待派工");
    }

    @Test
    @DisplayName("E2E-003 场景二：已报工状态报废 → 终态不可删除")
    void scrapFromReported() throws Exception {
        // Step 5: 创建第二个工单→派工→启动→完成→报工 → 工单=已报工
        Long woId = createDispatchStartCompleteAndReport();

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "已报工");

        // Step 6: Leader 报废已报工工单
        MvcResult scrapResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/workorders/" + woId + "/scrap")
                                .characterEncoding("UTF-8")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("reason", "客户取消订单"))))
                .andReturn();
        assertOk(scrapResult);

        MvcResult detailAfterScrap = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterScrap, "status", "报废");

        // Step 7: 尝试恢复已报废工单 → 400
        MvcResult resumeAttempt = performPostWithBodyExpectAny(
                "/workorders/" + woId + "/resume", null, operatorToken);
        assertErrorMessageContains(resumeAttempt, 400, "暂停中");
    }

    @Test
    @DisplayName("报废后删除工单（从暂停中报废）")
    void scrapThenDeleteFromPaused() throws Exception {
        Long woId = createDispatchStartAndPause();

        // 报废
        mockMvc.perform(
                org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .post("/workorders/" + woId + "/scrap")
                        .header("Authorization", "Bearer " + leaderToken)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(
                                Map.of("reason", "报废原因"))))
                .andReturn();

        // 删除
        MvcResult deleteResult = performDelete("/workorders/" + woId, adminToken);
        assertOk(deleteResult);

        // 验证已删除
        MvcResult notFound = performGetExpectAny("/workorders/" + woId, adminToken);
        assertEquals(404, responseCode(notFound));
    }

    @Test
    @DisplayName("报废后删除工单（从已报工报废）")
    void scrapThenDeleteFromReported() throws Exception {
        Long woId = createDispatchStartCompleteAndReport();

        // 报废
        mockMvc.perform(
                org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .post("/workorders/" + woId + "/scrap")
                        .header("Authorization", "Bearer " + leaderToken)
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(
                                Map.of("reason", "客户取消订单"))))
                .andReturn();

        // 删除
        MvcResult deleteResult = performDelete("/workorders/" + woId, adminToken);
        assertOk(deleteResult);
    }

    @Test
    @DisplayName("非暂停中/已报工状态报废 → 400")
    void scrapFromInvalidState() throws Exception {
        // 创建工单（待派工状态）
        WorkOrderCreateRequest createReq = new WorkOrderCreateRequest();
        createReq.setType("量产");
        createReq.setWorkshopId(2L);
        createReq.setLineId(1L);
        createReq.setProductId(1L);
        createReq.setPlanQty(100);

        MvcResult createResult = performPostWithBody("/workorders", createReq, leaderToken);
        Long woId = extractDataId(createResult);

        // 尝试报废待派工工单 → 400
        MvcResult scrapAttempt = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/workorders/" + woId + "/scrap")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("reason", "测试"))))
                .andReturn();
        assertErrorMessageContains(scrapAttempt, 400, "暂停中");
    }

    @Test
    @DisplayName("完工状态不可报废 → 400")
    void scrapFromCompleted() throws Exception {
        Long woId = createDispatchStartCompleteAndReport();

        // 确认完工
        performPost("/workorders/" + woId + "/confirm", leaderToken);

        // 尝试报废已完工工单 → 400
        MvcResult scrapAttempt = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/workorders/" + woId + "/scrap")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("reason", "测试"))))
                .andReturn();
        assertErrorMessageContains(scrapAttempt, 400, "暂停中");
    }

    // ---- 辅助方法 ----

    private Long createAndDispatch() throws Exception {
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

    private Long createDispatchStartAndPause() throws Exception {
        Long woId = createAndDispatch();
        performPost("/workorders/" + woId + "/start", operatorToken);
        performPost("/workorders/" + woId + "/pause", operatorToken);
        return woId;
    }

    private Long createDispatchStartCompleteAndReport() throws Exception {
        Long woId = createAndDispatch();
        performPost("/workorders/" + woId + "/start", operatorToken);
        performPost("/workorders/" + woId + "/complete", operatorToken);

        WorkOrderReportRequest reportReq = new WorkOrderReportRequest();
        reportReq.setGood(95);
        reportReq.setNg(5);
        reportReq.setHours(new BigDecimal("8"));
        performPostWithBody("/workorders/" + woId + "/report", reportReq, operatorToken);

        return woId;
    }
}
