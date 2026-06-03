package org.example.websocket;

import java.security.Principal;

/**
 * STOMP 用户主体 — 封装 userId 作为 WebSocket 会话的 Principal，
 * 用于 /user 前缀的私有消息路由。
 */
public class StompUserPrincipal implements Principal {

    private final Long userId;

    public StompUserPrincipal(Long userId) {
        this.userId = userId;
    }

    @Override
    public String getName() {
        return userId.toString();
    }

    public Long getUserId() {
        return userId;
    }
}
