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

@DisplayName("SNC-001: 产线状态同步延迟测试")
class SNC001_LatencyTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(SNC001_LatencyTest.class);

    @Test
    @DisplayName("SNC-001 启动产线后 LINE_STATUS 消息延迟 < 2s")
    void lineStartSyncLatency() throws Exception {
        // Step 1: 创建工单并派工
        Long woId = createAndDispatchWorkOrder();

        // Step 2: 设备 A（班组长）连接 STOMP，订阅产线主题
        WebSocketStompClient stompClient = createStompClient();
        StompSession leaderSession = connectStomp(stompClient, leaderToken);

        BlockingQueue<Map<String, Object>> lineStatusMsgs =
                subscribeAndCollect(leaderSession, "/topic/lines/1");
        BlockingQueue<Map<String, Object>> stationUpdateMsgs =
                subscribeAndCollect(leaderSession, "/topic/lines/1/stations");

        // 等待订阅生效
        Thread.sleep(200);

        // Step 3: 设备 B（操作员）启动产线，记录时间
        Map<String, Object> startReq = Map.of("workOrderId", woId);
        long t0 = System.currentTimeMillis();
        ResponseEntity<Map> startResp = httpPost("/lines/1/start", startReq, operatorToken);
        assertHttpOk(startResp);

        // Step 4: 等待 LINE_STATUS 消息（超时 5s）
        Map<String, Object> lineMsg = lineStatusMsgs.poll(5, TimeUnit.SECONDS);
        long t1 = System.currentTimeMillis();
        assertNotNull(lineMsg, "应在 5s 内收到 LINE_STATUS 消息");

        long latency = t1 - t0;
        log.info("SNC-001 LINE_STATUS 延迟: {}ms (API调用 → 消息到达)", latency);

        // Step 5: 验证消息内容
        assertEquals("LINE_STATUS", lineMsg.get("type"));
        assertEquals(1, ((Number) lineMsg.get("lineId")).intValue());
        @SuppressWarnings("unchecked")
        Map<String, Object> statusData = (Map<String, Object>) lineMsg.get("data");
        assertEquals("生产中", statusData.get("status"));
        assertEquals("生产中", statusData.get("woStatus"));

        // Step 6: 验证 STATION_UPDATE 消息也到达
        Map<String, Object> stationMsg = stationUpdateMsgs.poll(3, TimeUnit.SECONDS);
        assertNotNull(stationMsg, "应在 3s 内收到 STATION_UPDATE 消息");
        assertEquals("STATION_UPDATE", stationMsg.get("type"));

        // Step 7: 延迟断言（验收标准 < 2000ms）
        assertTrue(latency < 2000,
                "SNC-001 同步延迟 " + latency + "ms 超过 2s 阈值");

        log.info("SNC-001 验收通过: LINE_STATUS 延迟 {}ms < 2000ms", latency);

        // Step 8: 清理 — 停止模拟器
        stompClient.stop();
        httpPostVoid("/lines/1/stop", operatorToken);
    }

    @Test
    @DisplayName("SNC-001 停止产线后 LINE_STATUS(暂停) 消息延迟 < 2s")
    void stopSyncLatency() throws Exception {
        Long woId = createDispatchAndStartLine();

        // 连接 STOMP 并订阅
        WebSocketStompClient stompClient = createStompClient();
        StompSession leaderSession = connectStomp(stompClient, leaderToken);

        BlockingQueue<Map<String, Object>> lineStatusMsgs =
                subscribeAndCollect(leaderSession, "/topic/lines/1");
        subscribeAndCollect(leaderSession, "/topic/lines/1/stations");
        Thread.sleep(200);

        // 清空启动时产生的消息（LINE_STATUS + STATION_UPDATE tick 消息）
        lineStatusMsgs.clear();

        // 停止产线，测量延迟
        long t0 = System.currentTimeMillis();
        ResponseEntity<Map> stopResp = httpPostVoid("/lines/1/stop", operatorToken);
        assertHttpOk(stopResp);

        Map<String, Object> stopMsg = lineStatusMsgs.poll(5, TimeUnit.SECONDS);
        long t1 = System.currentTimeMillis();
        assertNotNull(stopMsg, "应在 5s 内收到停止的 LINE_STATUS 消息");

        long latency = t1 - t0;
        log.info("SNC-001 停止 LINE_STATUS 延迟: {}ms", latency);

        assertEquals("LINE_STATUS", stopMsg.get("type"));
        @SuppressWarnings("unchecked")
        Map<String, Object> stopData = (Map<String, Object>) stopMsg.get("data");
        assertEquals("暂停", stopData.get("status"));

        assertTrue(latency < 2000,
                "停止同步延迟 " + latency + "ms 超过 2s 阈值");

        stompClient.stop();
    }

    // ---- 辅助方法 ----

    private Long createAndDispatchWorkOrder() {
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
        ResponseEntity<Map> dispatchResp = httpPost("/workorders/" + woId + "/dispatch", dispatchReq, leaderToken);
        assertHttpOk(dispatchResp);

        return woId;
    }

    private Long createDispatchAndStartLine() {
        Long woId = createAndDispatchWorkOrder();

        Map<String, Object> startReq = Map.of("workOrderId", woId);
        ResponseEntity<Map> startResp = httpPost("/lines/1/start", startReq, operatorToken);
        assertHttpOk(startResp);

        return woId;
    }
}
