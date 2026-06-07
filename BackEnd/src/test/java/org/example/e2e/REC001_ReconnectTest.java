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

@DisplayName("REC-001: WebSocket 断线重连测试")
class REC001_ReconnectTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(REC001_ReconnectTest.class);

    @Test
    @DisplayName("REC-001 断网后重连 — 全量拉取 + 增量消息续推")
    void reconnectAfterDisconnect() throws Exception {
        // Step 1: 创建工单、派工、开工
        Long woId = createDispatchAndStartLine();

        // Step 2: 操作员连接 STOMP，订阅工作站更新
        WebSocketStompClient client = createStompClient();
        StompSession session = connectStomp(client, operatorToken);

        BlockingQueue<Map<String, Object>> stationQueue =
                subscribeAndCollect(session, "/topic/lines/1/stations");
        Thread.sleep(300);

        // Step 3: 收集基线消息，确认仿真正常运行
        Map<String, Object> baseline = stationQueue.poll(3, TimeUnit.SECONDS);
        assertNotNull(baseline, "应收到 STATION_UPDATE 基线消息");
        assertEquals("STATION_UPDATE", baseline.get("type"));

        // Step 4: HTTP GET 记录断线前状态
        ResponseEntity<Map> beforeResp = httpGet("/lines/1", operatorToken);
        assertHttpOk(beforeResp);
        @SuppressWarnings("unchecked")
        Map<String, Object> beforeData = (Map<String, Object>) beforeResp.getBody().get("data");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> beforeStations =
                (List<Map<String, Object>>) beforeData.get("stations");
        int beforeOp10Processed = ((Number) beforeStations.get(0).get("processedCount")).intValue();
        log.info("REC-001 断线前 OP10 processedCount={}", beforeOp10Processed);

        // Step 5: 模拟断网 — 直接关闭 WebSocket 客户端
        client.stop();
        log.info("REC-001 已断开 WebSocket（模拟断网）");

        // Step 6: 离线等待（模拟 30s，测试用 4s，仿真继续运行）
        Thread.sleep(4000);

        // Step 7: 重连 — 新建 STOMP 客户端和会话
        WebSocketStompClient newClient = createStompClient();
        StompSession newSession = connectStomp(newClient, operatorToken);

        BlockingQueue<Map<String, Object>> newStationQueue =
                subscribeAndCollect(newSession, "/topic/lines/1/stations");
        Thread.sleep(300);

        // Step 8: 全量拉取 — HTTP GET 获取当前产线状态
        ResponseEntity<Map> afterResp = httpGet("/lines/1", operatorToken);
        assertHttpOk(afterResp);
        @SuppressWarnings("unchecked")
        Map<String, Object> afterData = (Map<String, Object>) afterResp.getBody().get("data");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> afterStations =
                (List<Map<String, Object>>) afterData.get("stations");
        int afterOp10Processed = ((Number) afterStations.get(0).get("processedCount")).intValue();
        log.info("REC-001 重连后 OP10 processedCount={}", afterOp10Processed);

        // Step 9: 验证离线期间仿真仍在运行（计数器有增长）
        assertTrue(afterOp10Processed > beforeOp10Processed,
                "离线期间仿真应继续运行，OP10 从 " + beforeOp10Processed
                        + " 增长到 " + afterOp10Processed);

        // Step 10: 验证增量消息续推
        Map<String, Object> incMsg = newStationQueue.poll(5, TimeUnit.SECONDS);
        assertNotNull(incMsg, "重连后应在 5s 内收到 STATION_UPDATE 增量消息");
        assertEquals("STATION_UPDATE", incMsg.get("type"));

        // Step 11: 验证增量消息与全量快照的一致性
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> incStations =
                (List<Map<String, Object>>) incMsg.get("data");
        int incOp10Processed = ((Number) incStations.get(0).get("processedCount")).intValue();
        assertTrue(incOp10Processed >= afterOp10Processed,
                "增量计数器应 >= 全量快照: inc=" + incOp10Processed
                        + " snapshot=" + afterOp10Processed);

        // Step 12: 验证持续推送（再收一条）
        Map<String, Object> msg2 = newStationQueue.poll(5, TimeUnit.SECONDS);
        assertNotNull(msg2, "应持续收到 STATION_UPDATE 消息");
        assertEquals("STATION_UPDATE", msg2.get("type"));

        log.info("REC-001 验收通过: 断线重连后全量拉取 + 增量续推正常");

        // 清理
        newClient.stop();
        httpPostVoid("/lines/1/stop", operatorToken);
    }

    @Test
    @DisplayName("REC-001 重连后 LINE_STATUS 频道也正常广播")
    void reconnectReceivesLineStatus() throws Exception {
        // Step 1: 开工
        Long woId = createDispatchAndStartLine();

        // Step 2: 首次连接，确认收到消息后断开
        WebSocketStompClient client = createStompClient();
        StompSession session = connectStomp(client, operatorToken);
        BlockingQueue<Map<String, Object>> lineQueue =
                subscribeAndCollect(session, "/topic/lines/1");
        Thread.sleep(200);
        lineQueue.clear();
        client.stop();

        // Step 3: 重连并订阅 LINE_STATUS
        WebSocketStompClient newClient = createStompClient();
        StompSession newSession = connectStomp(newClient, operatorToken);
        BlockingQueue<Map<String, Object>> newLineQueue =
                subscribeAndCollect(newSession, "/topic/lines/1");
        Thread.sleep(300);

        // Step 4: 停止仿真（触发 LINE_STATUS 广播），验证重连后订阅有效
        httpPostVoid("/lines/1/stop", operatorToken);

        Map<String, Object> statusMsg = newLineQueue.poll(5, TimeUnit.SECONDS);
        assertNotNull(statusMsg, "重连后应收到 LINE_STATUS 消息");
        assertEquals("LINE_STATUS", statusMsg.get("type"));

        @SuppressWarnings("unchecked")
        Map<String, Object> statusData = (Map<String, Object>) statusMsg.get("data");
        assertEquals("暂停", statusData.get("status"));

        log.info("REC-001 重连后 LINE_STATUS 验收通过");
        newClient.stop();
    }

    // ---- 辅助方法 ----

    private Long createDispatchAndStartLine() {
        Map<String, Object> createReq = Map.of(
                "type", "量产", "workshopId", 2, "lineId", 1,
                "productId", 1, "planQty", 10
        );
        ResponseEntity<Map> createResp = httpPost("/workorders", createReq, leaderToken);
        assertHttpOk(createResp);
        Long woId = extractId(createResp);

        httpPost("/workorders/" + woId + "/dispatch",
                Map.of("operatorId", 3), leaderToken);
        httpPost("/lines/1/start", Map.of("workOrderId", woId), operatorToken);

        return woId;
    }
}
