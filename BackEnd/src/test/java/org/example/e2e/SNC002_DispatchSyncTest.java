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

@DisplayName("SNC-002: 派工同步测试")
class SNC002_DispatchSyncTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(SNC002_DispatchSyncTest.class);

    @Test
    @DisplayName("SNC-002 派工后 WORKORDER_UPDATE 消息延迟 < 2s")
    void dispatchSyncLatency() throws Exception {
        // Step 1: 班组长先创建工单（避免创建广播混入派工消息队列）
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

        // Step 2: 操作员连接 STOMP，订阅产线工单更新
        WebSocketStompClient stompClient = createStompClient();
        StompSession operatorSession = connectStomp(stompClient, operatorToken);

        BlockingQueue<Map<String, Object>> woUpdateMsgs =
                subscribeAndCollect(operatorSession, "/topic/lines/1/workorders");
        Thread.sleep(200);

        // Step 3: 班组长派工给操作员，记录时间
        Map<String, Object> dispatchReq = Map.of("operatorId", 3);
        long t0 = System.currentTimeMillis();
        ResponseEntity<Map> dispatchResp = httpPost("/workorders/" + woId + "/dispatch",
                dispatchReq, leaderToken);
        assertHttpOk(dispatchResp);

        // Step 4: 等待 WORKORDER_UPDATE 消息（跳过可能残留的旧消息，找 status=已派工）
        Map<String, Object> msg = null;
        long deadline = System.currentTimeMillis() + 5000;
        while (System.currentTimeMillis() < deadline) {
            Map<String, Object> m = woUpdateMsgs.poll(1, TimeUnit.SECONDS);
            if (m != null && "WORKORDER_UPDATE".equals(m.get("type"))) {
                @SuppressWarnings("unchecked")
                Map<String, Object> d = (Map<String, Object>) m.get("data");
                if ("已派工".equals(d.get("status"))
                        && woId.equals(((Number) d.get("workOrderId")).longValue())) {
                    msg = m;
                    break;
                }
            }
        }
        long t1 = System.currentTimeMillis();
        assertNotNull(msg, "应在 5s 内收到派工的 WORKORDER_UPDATE 消息");

        long latency = t1 - t0;
        log.info("SNC-002 派工同步延迟: {}ms", latency);

        // Step 5: 验证消息内容
        assertEquals("WORKORDER_UPDATE", msg.get("type"));
        @SuppressWarnings("unchecked")
        Map<String, Object> woData = (Map<String, Object>) msg.get("data");
        assertEquals(woId, ((Number) woData.get("workOrderId")).longValue());
        assertEquals("已派工", woData.get("status"));

        // Step 6: 延迟断言
        assertTrue(latency < 2000,
                "SNC-002 派工同步延迟 " + latency + "ms 超过 2s 阈值");

        log.info("SNC-002 验收通过: 派工同步延迟 {}ms < 2000ms", latency);

        stompClient.stop();
    }

    @Test
    @DisplayName("SNC-002 派工后操作员可查询到已派工工单")
    void dispatchUpdatesStatusAndAssignee() throws Exception {
        // Step 1: 班组长创建工单并派工
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

        Map<String, Object> dispatchReq = Map.of("operatorId", 3);
        ResponseEntity<Map> dispatchResp = httpPost("/workorders/" + woId + "/dispatch",
                dispatchReq, leaderToken);
        assertHttpOk(dispatchResp);

        // Step 2: 操作员查询工单详情，验证状态和指派人
        ResponseEntity<Map> detailResp = httpGet("/workorders/" + woId, operatorToken);
        assertHttpOk(detailResp);
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) detailResp.getBody().get("data");
        assertEquals("已派工", data.get("status"));
        assertEquals(3, ((Number) data.get("operatorId")).intValue());

        // Step 3: 操作员查询工单列表，验证已派工工单可见
        ResponseEntity<Map> listResp = httpGet("/workorders?status=已派工", operatorToken);
        assertHttpOk(listResp);
        @SuppressWarnings("unchecked")
        java.util.List<Map<String, Object>> list = (java.util.List<Map<String, Object>>)
                listResp.getBody().get("data");
        assertNotNull(list);
        boolean found = list.stream().anyMatch(
                item -> woId.equals(((Number) item.get("id")).longValue()));
        assertTrue(found, "操作员应在已派工列表中看到刚派工的工单");
    }
}
