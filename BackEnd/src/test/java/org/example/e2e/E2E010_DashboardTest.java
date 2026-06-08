package org.example.e2e;

import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("E2E-010: 看板 KPI 接口")
class E2E010_DashboardTest extends E2ETestBase {

    @Test
    @DisplayName("scope=today 返回今日 KPI 数据")
    void dashboardToday() throws Exception {
        createDispatchAndStart();

        MvcResult result = performGet("/dashboard?scope=today", leaderToken);
        assertOk(result);

        JsonNode data = dataNode(result);
        assertTrue(data.get("totalInput").asInt() > 0, "totalInput 应大于 0");
        assertTrue(data.has("totalOutput"));
        assertTrue(data.has("totalNg"));
        assertTrue(data.has("todayPlanRate"));
        assertTrue(data.has("productCompletionRate"));
        assertTrue(data.has("stationCompletionRate"));
        assertTrue(data.get("monthlyRates") == null || data.get("monthlyRates").isNull(),
                "scope=today 时 monthlyRates 应为 null");
    }

    @Test
    @DisplayName("scope=month 返回月度趋势数据")
    void dashboardMonth() throws Exception {
        createDispatchAndStart();

        MvcResult result = performGet("/dashboard?scope=month", leaderToken);
        assertOk(result);

        JsonNode data = dataNode(result);
        assertTrue(data.get("totalInput").asInt() > 0);
        assertNotNull(data.get("monthlyRates"));
        assertFalse(data.get("monthlyRates").isNull(), "monthlyRates 不应为 null");
        assertTrue(data.get("monthlyRates").size() > 0, "monthlyRates 应有数据");

        JsonNode firstDay = data.get("monthlyRates").get(0);
        assertTrue(firstDay.has("day"));
        assertTrue(firstDay.has("rate"));
        assertEquals(1, firstDay.get("day").asInt(), "第一天 day 应为 1");
    }

    @Test
    @DisplayName("非法 scope → 400")
    void dashboardInvalidScope() throws Exception {
        MvcResult result = performGetExpectAny("/dashboard?scope=invalid", leaderToken);
        assertErrorMessageContains(result, 400, "scope");
    }

    @Test
    @DisplayName("所有角色均可访问看板")
    void dashboardAllRolesCanAccess() throws Exception {
        createDispatchAndStart();

        assertOk(performGet("/dashboard", adminToken));
        assertOk(performGet("/dashboard", leaderToken));
        assertOk(performGet("/dashboard", operatorToken));
        assertOk(performGet("/dashboard", inspectorToken));
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
