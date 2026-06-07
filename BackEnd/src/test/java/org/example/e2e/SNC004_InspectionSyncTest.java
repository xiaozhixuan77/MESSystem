package org.example.e2e;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("SNC-004: 抽检同步测试")
class SNC004_InspectionSyncTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(SNC004_InspectionSyncTest.class);

    @Test
    @DisplayName("SNC-004 抽检后 WORKORDER_UPDATE 消息延迟 < 2s")
    void inspectionSyncLatency() throws Exception {
        // Step 1: 完整生命周期到已报工
        Long woId = createDispatchStartCompleteAndReport();

        // Step 2: 班组长连接 STOMP，订阅产线工单更新
        WebSocketStompClient stompClient = createStompClient();
        StompSession leaderSession = connectStomp(stompClient, leaderToken);

        // 先清空报工产生的消息（如果有）
        BlockingQueue<Map<String, Object>> woUpdateMsgs =
                subscribeAndCollect(leaderSession, "/topic/lines/1/workorders");
        Thread.sleep(200);
        woUpdateMsgs.clear();

        // Step 3: 质检员提交抽检，记录时间
        Map<String, Object> inspectionReq = Map.of(
                "workOrderId", woId,
                "sampleQty", 5,
                "sampleGood", 5,
                "sampleNg", 0,
                "defectTypes", "[]",
                "defectDescription", "",
                "conclusion", "通过"
        );
        long t0 = System.currentTimeMillis();
        ResponseEntity<Map> inspResp = httpPost("/inspections", inspectionReq, inspectorToken);
        assertHttpOk(inspResp);

        // Step 4: 等待 WORKORDER_UPDATE 消息
        Map<String, Object> msg = woUpdateMsgs.poll(5, TimeUnit.SECONDS);
        long t1 = System.currentTimeMillis();
        assertNotNull(msg, "应在 5s 内收到抽检后的 WORKORDER_UPDATE 消息");

        long latency = t1 - t0;
        log.info("SNC-004 抽检同步延迟: {}ms", latency);

        // Step 5: 验证消息内容
        assertEquals("WORKORDER_UPDATE", msg.get("type"));
        @SuppressWarnings("unchecked")
        Map<String, Object> woData = (Map<String, Object>) msg.get("data");
        assertEquals(woId, ((Number) woData.get("workOrderId")).longValue());
        @SuppressWarnings("unchecked")
        Map<String, Object> extra = (Map<String, Object>) woData.get("extra");
        assertNotNull(extra, "应包含 inspectionId 和 conclusion");
        assertEquals("通过", extra.get("conclusion"));

        // Step 6: 延迟断言
        assertTrue(latency < 2000,
                "SNC-004 抽检同步延迟 " + latency + "ms 超过 2s 阈值");

        log.info("SNC-004 验收通过: 抽检同步延迟 {}ms < 2000ms", latency);

        stompClient.stop();
    }

    @Test
    @DisplayName("SNC-004 抽检结果持久化且可查询")
    void inspectionResultPersisted() throws Exception {
        // Step 1: 完整生命周期到已报工
        Long woId = createDispatchStartCompleteAndReport();

        // Step 2: 质检员提交抽检
        Map<String, Object> inspectionReq = Map.of(
                "workOrderId", woId,
                "sampleQty", 10,
                "sampleGood", 9,
                "sampleNg", 1,
                "defectTypes", "[\"外观缺陷\"]",
                "defectDescription", "外壳轻微划痕",
                "conclusion", "通过"
        );
        ResponseEntity<Map> inspResp = httpPost("/inspections", inspectionReq, inspectorToken);
        assertHttpOk(inspResp);

        // Step 3: 质检员查询抽检记录
        ResponseEntity<Map> listResp = httpGet("/inspections?workOrderId=" + woId, inspectorToken);
        assertHttpOk(listResp);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> list = (List<Map<String, Object>>) listResp.getBody().get("data");
        assertNotNull(list);
        assertFalse(list.isEmpty(), "应能查到抽检记录");

        Map<String, Object> record = list.get(0);
        assertEquals(10, ((Number) record.get("sampleQty")).intValue());
        assertEquals(9, ((Number) record.get("sampleGood")).intValue());
        assertEquals(1, ((Number) record.get("sampleNg")).intValue());
        assertEquals("通过", record.get("conclusion"));
        assertEquals(woId, ((Number) record.get("workOrderId")).longValue());
    }

    // ---- 辅助方法 ----

    private Long createDispatchStartCompleteAndReport() {
        // 创建工单
        Map<String, Object> createReq = Map.of(
                "type", "量产",
                "workshopId", 2,
                "lineId", 1,
                "productId", 1,
                "planQty", 10
        );
        ResponseEntity<Map> createResp = httpPost("/workorders", createReq, leaderToken);
        assertHttpOk(createResp);
        Long woId = extractId(createResp);

        // 派工
        Map<String, Object> dispatchReq = Map.of("operatorId", 3);
        httpPost("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);

        // 开工
        Map<String, Object> startReq = Map.of("workOrderId", woId);
        httpPost("/lines/1/start", startReq, operatorToken);

        // 完成生产
        httpPostVoid("/workorders/" + woId + "/complete", operatorToken);

        // 报工
        Map<String, Object> reportReq = Map.of(
                "good", 8, "ng", 2, "hours", 8.0, "note", "");
        httpPost("/workorders/" + woId + "/report", reportReq, operatorToken);

        return woId;
    }
}
