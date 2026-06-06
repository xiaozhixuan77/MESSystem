package org.example.e2e;

import org.junit.jupiter.api.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.web.socket.messaging.WebSocketStompClient;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 工单 WebSocket 实时推送端到端验证。
 * 走完整工单生命周期，验证每一步都广播 WORKORDER_UPDATE 到 /topic/lines/{id}/workorders。
 */
@DisplayName("工单 WebSocket 实时推送验证")
class WorkOrderWebSocketTest extends SNCTestBase {

    private static final Logger log = LoggerFactory.getLogger(WorkOrderWebSocketTest.class);

    private WebSocketStompClient stompClient;
    private StompSession stompSession;
    private BlockingQueue<Map<String, Object>> msgs;

    @BeforeEach
    void connectAndSubscribe() throws Exception {
        stompClient = createStompClient();
        stompSession = connectStomp(stompClient, leaderToken);
        msgs = subscribeAndCollect(stompSession, "/topic/lines/1/workorders");
        Thread.sleep(200);
    }

    @AfterEach
    void cleanup() {
        try {
            stompClient.stop();
        } catch (Exception ignored) {
        }
    }

    /**
     * 从队列中取一条消息并断言。
     */
    private Map<String, Object> expectMsg(Long woId, String status) throws Exception {
        Map<String, Object> msg = msgs.poll(5, TimeUnit.SECONDS);
        assertNotNull(msg, "应收到 WORKORDER_UPDATE: " + status);
        assertWorkOrderUpdate(msg, woId, status);
        return msg;
    }

    @Test
    @DisplayName("完整生命周期：待派工→已派工→生产中→暂停中→生产中→生产完成→已报工→完工")
    void fullLifecycleAllBroadcasts() throws Exception {
        // === Step 1: 创建工单（不产生广播） ===
        Map<String, Object> createReq = Map.of(
                "type", "量产", "workshopId", 2, "lineId", 1, "productId", 1, "planQty", 10
        );
        ResponseEntity<Map> createResp = httpPost("/workorders", createReq, leaderToken);
        assertHttpOk(createResp);
        Long woId = extractId(createResp);
        log.info("=== [创建] id={} code={} ===", woId, extractField(createResp, "code"));

        // === Step 2: 派工 → 应收到 "已派工" ===
        httpPost("/workorders/" + woId + "/dispatch", Map.of("operatorId", 3), leaderToken);
        expectMsg(woId, "已派工");
        log.info("=== [OK] 派工 → 已派工 ===");

        // === Step 3: 启动 → 应收到 "生产中" ===
        httpPost("/lines/1/start", Map.of("workOrderId", woId), operatorToken);
        expectMsg(woId, "生产中");
        log.info("=== [OK] 启动 → 生产中 ===");

        // === Step 4: 暂停 → 应收到 "暂停中" ===
        httpPostVoid("/lines/1/stop", operatorToken);
        expectMsg(woId, "暂停中");
        log.info("=== [OK] 暂停 → 暂停中 ===");

        // === Step 5: 恢复 → 应收到 "生产中" ===
        httpPost("/lines/1/start", Map.of("workOrderId", woId), operatorToken);
        expectMsg(woId, "生产中");
        log.info("=== [OK] 恢复 → 生产中 ===");

        // === Step 6: 完成生产(手动) → 应收到 "生产完成" ===
        // 注意: workOrderService.complete() 会内部停止模拟器，不需要先 stop
        httpPostVoid("/workorders/" + woId + "/complete", operatorToken);
        expectMsg(woId, "生产完成");
        log.info("=== [OK] 完成 → 生产完成 ===");

        // === Step 7: 报工 → 应收到 "已报工"，含 extra ===
        httpPost("/workorders/" + woId + "/report",
                Map.of("good", 10, "ng", 0, "hours", 1), operatorToken);
        Map<String, Object> reportMsg = expectMsg(woId, "已报工");
        @SuppressWarnings("unchecked")
        Map<String, Object> extra = (Map<String, Object>) ((Map<String, Object>) reportMsg.get("data")).get("extra");
        assertNotNull(extra, "报工消息应包含 extra");
        assertEquals(10, ((Number) extra.get("good")).intValue());
        assertEquals(0, ((Number) extra.get("ng")).intValue());
        log.info("=== [OK] 报工 → 已报工 (good=10 ng=0) ===");

        // === Step 8: 确认完工 → 应收到 "完工" ===
        httpPostVoid("/workorders/" + woId + "/confirm", leaderToken);
        expectMsg(woId, "完工");
        log.info("=== [OK] 确认 → 完工 ===");

        log.info("=== 全部 7 步 WORKORDER_UPDATE 广播验证通过 ===");
    }

    @Test
    @DisplayName("报废流程：创建→派工→启动→暂停→报废")
    void scrapFlowBroadcast() throws Exception {
        // 创建 → 派工 → 启动（3 个 API 调用，2 个广播：派工+启动）
        Long woId = createDispatchAndStartLine();
        // 清掉 dispatch 和 start 两条消息
        expectMsg(woId, "已派工");
        expectMsg(woId, "生产中");

        // 暂停
        httpPostVoid("/lines/1/stop", operatorToken);
        expectMsg(woId, "暂停中");
        log.info("=== [OK] 暂停 ===");

        // 报废
        httpPost("/workorders/" + woId + "/scrap",
                Map.of("reason", "设备故障无法修复"), leaderToken);
        Map<String, Object> scrapMsg = expectMsg(woId, "报废");
        @SuppressWarnings("unchecked")
        Map<String, Object> scrapExtra = (Map<String, Object>) ((Map<String, Object>) scrapMsg.get("data")).get("extra");
        assertNotNull(scrapExtra, "报废消息应包含 extra");
        assertEquals("设备故障无法修复", scrapExtra.get("reason"));
        log.info("=== [OK] 报废 → 报废 (reason=设备故障无法修复) ===");
    }

    @Test
    @DisplayName("报工后报废流程")
    void scrapFromReportedBroadcast() throws Exception {
        // 创建 → 派工 → 启动 → 完成 → 报工
        Long woId = createDispatchAndStartLine();
        expectMsg(woId, "已派工");
        expectMsg(woId, "生产中");

        // 完成生产
        httpPostVoid("/workorders/" + woId + "/complete", operatorToken);
        expectMsg(woId, "生产完成");

        // 报工
        httpPost("/workorders/" + woId + "/report",
                Map.of("good", 10, "ng", 0, "hours", 1), operatorToken);
        expectMsg(woId, "已报工");

        // 从"已报工"状态报废
        httpPost("/workorders/" + woId + "/scrap",
                Map.of("reason", "客户取消订单"), leaderToken);
        Map<String, Object> scrapMsg = expectMsg(woId, "报废");
        @SuppressWarnings("unchecked")
        Map<String, Object> scrapExtra = (Map<String, Object>) ((Map<String, Object>) scrapMsg.get("data")).get("extra");
        assertNotNull(scrapExtra);
        assertEquals("客户取消订单", scrapExtra.get("reason"));
        log.info("=== [OK] 报工后报废验证通过 ===");
    }

    @Test
    @DisplayName("多客户端同时收到同一 WORKORDER_UPDATE")
    void multipleSubscribersReceiveSameMessage() throws Exception {
        // 第二个 STOMP 客户端（模拟质检员）
        WebSocketStompClient stompClient2 = createStompClient();
        StompSession session2 = connectStomp(stompClient2, inspectorToken);
        BlockingQueue<Map<String, Object>> msgs2 =
                subscribeAndCollect(session2, "/topic/lines/1/workorders");
        Thread.sleep(200);

        // 创建 → 派工 → 启动
        Long woId = createDispatchAndStartLine();
        // 两个队列都清掉 dispatch + start 消息
        expectMsgFrom(msgs, woId, "已派工");
        expectMsgFrom(msgs, woId, "生产中");
        expectMsgFrom(msgs2, woId, "已派工");
        expectMsgFrom(msgs2, woId, "生产中");

        // 暂停
        httpPostVoid("/lines/1/stop", operatorToken);

        // 两个客户端都应收到暂停广播
        Map<String, Object> msg1 = msgs.poll(5, TimeUnit.SECONDS);
        Map<String, Object> msg2 = msgs2.poll(5, TimeUnit.SECONDS);
        assertNotNull(msg1, "客户端1应收到暂停广播");
        assertNotNull(msg2, "客户端2应收到暂停广播");
        assertWorkOrderUpdate(msg1, woId, "暂停中");
        assertWorkOrderUpdate(msg2, woId, "暂停中");
        log.info("=== [OK] 多客户端同步广播: 两端都收到 暂停中 ===");

        stompClient2.stop();
    }

    // ---- 辅助 ----

    private void expectMsgFrom(BlockingQueue<Map<String, Object>> q,
                                Long woId, String status) throws Exception {
        Map<String, Object> msg = q.poll(5, TimeUnit.SECONDS);
        assertNotNull(msg, "应收到 WORKORDER_UPDATE: " + status);
        assertWorkOrderUpdate(msg, woId, status);
    }

    private void assertWorkOrderUpdate(Map<String, Object> msg,
                                        Long expectedWoId, String expectedStatus) {
        assertEquals("WORKORDER_UPDATE", msg.get("type"));
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) msg.get("data");
        assertNotNull(data);
        assertEquals(expectedWoId,
                data.get("workOrderId") instanceof Integer
                        ? ((Integer) data.get("workOrderId")).longValue()
                        : (Long) data.get("workOrderId"));
        assertEquals(expectedStatus, data.get("status"));
    }

    private Long createDispatchAndStartLine() {
        ResponseEntity<Map> createResp = httpPost("/workorders", Map.of(
                "type", "量产", "workshopId", 2, "lineId", 1, "productId", 1, "planQty", 10
        ), leaderToken);
        assertHttpOk(createResp);
        Long woId = extractId(createResp);

        httpPost("/workorders/" + woId + "/dispatch", Map.of("operatorId", 3), leaderToken);
        httpPost("/lines/1/start", Map.of("workOrderId", woId), operatorToken);
        return woId;
    }
}
