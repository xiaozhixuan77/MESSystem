package org.example.websocket;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

/**
 * WebSocket 会话生命周期监听器 — 记录连接/断开事件，便于排障与监控。
 */
@Component
public class WebSocketEventListener {

    private static final Logger log = LoggerFactory.getLogger(WebSocketEventListener.class);

    @EventListener
    public void onConnected(SessionConnectedEvent event) {
        String sessionId = event.getMessage().getHeaders().get("simpSessionId", String.class);
        Object user = event.getUser();
        log.info("WebSocket 连接建立: sessionId={}, user={}", sessionId,
                user != null ? user : "匿名");
    }

    @EventListener
    public void onDisconnected(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();
        log.info("WebSocket 连接断开: sessionId={}, status={}", sessionId, event.getCloseStatus());
    }
}
