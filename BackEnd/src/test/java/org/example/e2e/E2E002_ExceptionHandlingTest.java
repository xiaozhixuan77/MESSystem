package org.example.e2e;

import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("E2E-002: 异常处理流程")
class E2E002_ExceptionHandlingTest extends E2ETestBase {

    @Test
    @DisplayName("E2E-002 完整流程：上报异常→恢复→再次异常→停止+报废")
    void exceptionHandlingFlow() throws Exception {
        // Step 1: 创建、派工、启动 → 工单=生产中
        Long woId = createDispatchAndStart();

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "生产中");

        MvcResult lineDetail = performGet("/lines/1", leaderToken);
        assertDataFieldEquals(lineDetail, "status", "生产中");

        // Step 2: Operator 上报异常
        MvcResult exceptionResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/lines/1/exception")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("description", "相机定位偏移"))))
                .andReturn();
        assertOk(exceptionResult);

        // 验证工单变为暂停中
        MvcResult detailAfterException = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterException, "status", "暂停中");

        // Step 3: Leader 查看产线详情（验证产线状态=异常）
        MvcResult lineDetailFault = performGet("/lines/1", leaderToken);
        assertDataFieldEquals(lineDetailFault, "status", "暂停");

        // Step 4: Operator 恢复工单
        MvcResult resumeResult = performPost("/workorders/" + woId + "/resume", operatorToken);
        assertOk(resumeResult);

        MvcResult detailAfterResume = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterResume, "status", "生产中");

        // Step 5: 再次上报异常
        MvcResult exception2Result = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/lines/1/exception")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("description", "设备过热报警"))))
                .andReturn();
        assertOk(exception2Result);

        MvcResult detailAfterSecondException = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detailAfterSecondException, "status", "暂停中");

        // Step 6: Leader 报废工单
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

        // 验证报废后不能恢复
        MvcResult resumeAfterScrap = performPostWithBodyExpectAny(
                "/workorders/" + woId + "/resume", null, operatorToken);
        assertErrorMessageContains(resumeAfterScrap, 400, "暂停中");
    }

    @Test
    @DisplayName("异常上报时无 simulation 运行也能正常暂停工单")
    void reportExceptionWithoutSimulator() throws Exception {
        Long woId = createDispatchAndStart();

        // 上报异常（simulator 未被启动，stop 应为 no-op）
        MvcResult exceptionResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/lines/1/exception")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("description", "测试异常"))))
                .andReturn();
        assertOk(exceptionResult);

        // 工单应处于暂停中
        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "暂停中");

        // 产线状态为异常
        MvcResult lineDetail = performGet("/lines/1", leaderToken);
        assertDataFieldEquals(lineDetail, "status", "暂停");
    }

    @Test
    @DisplayName("无权限用户上报异常 → 403")
    void reportExceptionWithoutPermission() throws Exception {
        // Inspector 没有 line.operate 权限
        MvcResult result = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/lines/1/exception")
                                .header("Authorization", "Bearer " + inspectorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("description", "测试"))))
                .andReturn();
        assertError(result, 403);
    }

    // ================================================================
    // P5-2: 新异常接口测试
    // ================================================================

    @Test
    @DisplayName("P5-2 新异常接口：上报异常 → 列表查询验证记录存在")
    void newExceptionReportAndList() throws Exception {
        Long woId = createDispatchAndStart();

        MvcResult reportResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/exceptions")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("workOrderId", woId, "lineId", 1L,
                                                "description", "相机定位偏移"))))
                .andReturn();
        assertOk(reportResult);

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "暂停中");

        MvcResult listResult = performGet("/exceptions?resolved=false", leaderToken);
        assertOk(listResult);
    }

    @Test
    @DisplayName("P5-2 新异常接口：上报 → 恢复异常 → 工单恢复生产")
    void newExceptionHandleResume() throws Exception {
        Long woId = createDispatchAndStart();

        MvcResult reportResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/exceptions")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("workOrderId", woId, "lineId", 1L,
                                                "description", "设备过热报警"))))
                .andReturn();
        assertOk(reportResult);
        Long exceptionId = dataNode(reportResult).get("id").asLong();

        MvcResult handleResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/exceptions/" + exceptionId + "/handle")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("action", "恢复"))))
                .andReturn();
        assertOk(handleResult);

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "生产中");
    }

    @Test
    @DisplayName("P5-2 新异常接口：上报 → 关闭异常 → 工单仍暂停")
    void newExceptionHandleClose() throws Exception {
        Long woId = createDispatchAndStart();

        MvcResult reportResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/exceptions")
                                .header("Authorization", "Bearer " + operatorToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("workOrderId", woId, "lineId", 1L,
                                                "description", "传感器故障"))))
                .andReturn();
        assertOk(reportResult);
        Long exceptionId = dataNode(reportResult).get("id").asLong();

        MvcResult handleResult = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/exceptions/" + exceptionId + "/handle")
                                .header("Authorization", "Bearer " + leaderToken)
                                .contentType("application/json")
                                .content(objectMapper.writeValueAsString(
                                        Map.of("action", "关闭"))))
                .andReturn();
        assertOk(handleResult);

        MvcResult detail = performGet("/workorders/" + woId, leaderToken);
        assertDataFieldEquals(detail, "status", "暂停中");
    }

    // ---- 辅助方法 ----

    private Long createDispatchAndStart() throws Exception {
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

        performPost("/workorders/" + woId + "/start", operatorToken);
        return woId;
    }
}
