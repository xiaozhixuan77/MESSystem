package org.example.e2e;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("SNC-003: 报工同步测试")
class SNC003_ReportSyncTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(SNC003_ReportSyncTest.class);

    @Test
    @DisplayName("SNC-003 报工后 WORKORDER_UPDATE 消息延迟 < 2s")
    void reportSyncLatency() throws Exception {
        // Step 1: 完整生命周期到生产完成
        Long woId = createDispatchStartAndComplete();

        // Step 2: 质检员连接 STOMP，订阅产线工单更新
        WebSocketStompClient stompClient = createStompClient();
        StompSession inspectorSession = connectStomp(stompClient, inspectorToken);

        BlockingQueue<Map<String, Object>> woUpdateMsgs =
                subscribeAndCollect(inspectorSession, "/topic/lines/1/workorders");
        Thread.sleep(200);

        // Step 3: 操作员提交报工，记录时间
        Map<String, Object> reportReq = Map.of(
                "good", 8,
                "ng", 2,
                "hours", 8.0,
                "note", "生产完成"
        );
        long t0 = System.currentTimeMillis();
        ResponseEntity<Map> reportResp = httpPost("/workorders/" + woId + "/report",
                reportReq, operatorToken);
        assertHttpOk(reportResp);

        // Step 4: 等待 WORKORDER_UPDATE 消息
        Map<String, Object> msg = woUpdateMsgs.poll(5, TimeUnit.SECONDS);
        long t1 = System.currentTimeMillis();
        assertNotNull(msg, "应在 5s 内收到 WORKORDER_UPDATE 消息");

        long latency = t1 - t0;
        log.info("SNC-003 报工同步延迟: {}ms", latency);

        // Step 5: 验证消息内容
        assertEquals("WORKORDER_UPDATE", msg.get("type"));
        @SuppressWarnings("unchecked")
        Map<String, Object> woData = (Map<String, Object>) msg.get("data");
        assertEquals(woId, ((Number) woData.get("workOrderId")).longValue());
        assertEquals("已报工", woData.get("status"));

        // Step 6: 延迟断言
        assertTrue(latency < 2000,
                "SNC-003 报工同步延迟 " + latency + "ms 超过 2s 阈值");

        log.info("SNC-003 验收通过: 报工同步延迟 {}ms < 2000ms", latency);

        stompClient.stop();
    }

    @Test
    @DisplayName("SNC-003 报工后工单状态和报工数据正确")
    void reportUpdatesStatusAndData() throws Exception {
        // Step 1: 完整生命周期到生产完成
        Long woId = createDispatchStartAndComplete();

        // Step 2: 操作员提交报工
        Map<String, Object> reportReq = Map.of(
                "good", 8,
                "ng", 2,
                "hours", 7.5,
                "note", "产线正常"
        );
        ResponseEntity<Map> reportResp = httpPost("/workorders/" + woId + "/report",
                reportReq, operatorToken);
        assertHttpOk(reportResp);

        // Step 3: 质检员查询工单详情
        ResponseEntity<Map> detailResp = httpGet("/workorders/" + woId, inspectorToken);
        assertHttpOk(detailResp);
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) detailResp.getBody().get("data");
        assertEquals("已报工", data.get("status"));
        assertEquals(8, ((Number) data.get("reportedQtyGood")).intValue());
        assertEquals(2, ((Number) data.get("reportedQtyNg")).intValue());
    }

    // ---- 辅助方法 ----

    private Long createDispatchStartAndComplete() {
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
        ResponseEntity<Map> dispatchResp = httpPost("/workorders/" + woId + "/dispatch",
                dispatchReq, leaderToken);
        assertHttpOk(dispatchResp);

        // 开工（启动产线模拟）
        Map<String, Object> startReq = Map.of("workOrderId", woId);
        ResponseEntity<Map> startResp = httpPost("/lines/1/start", startReq, operatorToken);
        assertHttpOk(startResp);

        // 立即完成生产（跳过模拟器等待）
        ResponseEntity<Map> completeResp = httpPostVoid("/workorders/" + woId + "/complete",
                operatorToken);
        assertHttpOk(completeResp);

        return woId;
    }
}
