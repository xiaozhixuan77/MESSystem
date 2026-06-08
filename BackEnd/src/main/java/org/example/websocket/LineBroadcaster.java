package org.example.websocket;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import org.example.simulator.StationState;

import org.example.entity.ProductionException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 产线实时广播器 — 封装 SimpMessagingTemplate，
 * 将仿真状态变更推送到 STOMP 订阅客户端。
 */
@Component
public class LineBroadcaster {

    private static final Logger log = LoggerFactory.getLogger(LineBroadcaster.class);

    private final SimpMessagingTemplate messagingTemplate;

    public LineBroadcaster(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * 每 Tick 推送工作站计数快照到 /topic/lines/{lineId}/stations。
     */
    public void broadcastStationUpdate(Long lineId, List<StationState> stations) {
        Map<String, Object> message = new HashMap<>();
        message.put("type", "STATION_UPDATE");
        message.put("lineId", lineId);
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", stations);

        messagingTemplate.convertAndSend("/topic/lines/" + lineId + "/stations", message);
        log.debug("工作站状态已广播: lineId={}, count={}", lineId, stations.size());
    }

    /**
     * 产线状态变更（启动/停止/复位）推送到 /topic/lines/{lineId}。
     */
    public void broadcastLineStatus(Long lineId, String status, Long workOrderId,
                                     int finishedCount, int ngCount, String woStatus,
                                     String workOrderCode, Integer planQty) {
        Map<String, Object> statusData = new HashMap<>();
        statusData.put("status", status);
        statusData.put("workOrderId", workOrderId);
        statusData.put("finishedCount", finishedCount);
        statusData.put("ngCount", ngCount);
        statusData.put("woStatus", woStatus);
        statusData.put("workOrderCode", workOrderCode);
        statusData.put("planQty", planQty);

        Map<String, Object> message = new HashMap<>();
        message.put("type", "LINE_STATUS");
        message.put("lineId", lineId);
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", statusData);

        messagingTemplate.convertAndSend("/topic/lines/" + lineId, message);
        log.info("产线状态已广播: lineId={}, status={}", lineId, status);
    }

    /**
     * 工单状态变更广播 → /topic/lines/{lineId}/workorders。
     */
    public void broadcastWorkOrderUpdate(Long lineId, Long workOrderId,
                                          String workOrderCode, String status,
                                          Map<String, Object> extra) {
        Map<String, Object> data = new HashMap<>();
        data.put("workOrderId", workOrderId);
        data.put("workOrderCode", workOrderCode);
        data.put("status", status);
        if (extra != null && !extra.isEmpty()) {
            data.put("extra", extra);
        }

        Map<String, Object> message = new HashMap<>();
        message.put("type", "WORKORDER_UPDATE");
        message.put("lineId", lineId);
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/lines/" + lineId + "/workorders", message);
        log.debug("WORKORDER_UPDATE 已广播 lineId={} woId={} status={}", lineId, workOrderId, status);
    }

    /**
     * 点对点私有消息，发送到 /user/{userId}/{destination}。
     */
    public void sendToUser(Long userId, String destination, Object payload) {
        Map<String, Object> message = new HashMap<>();
        message.put("type", "USER_MESSAGE");
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", payload);
        messagingTemplate.convertAndSendToUser(userId.toString(), destination, message);
        log.debug("私有消息已发送: userId={}, destination={}", userId, destination);
    }

    /**
     * 异常上报广播 → /topic/exceptions。
     */
    public void broadcastExceptionReported(ProductionException ex) {
        Map<String, Object> data = new HashMap<>();
        data.put("exceptionId", ex.getId());
        data.put("workOrderId", ex.getWorkOrderId());
        data.put("lineId", ex.getLineId());
        data.put("stationId", ex.getStationId());
        data.put("reporterId", ex.getReporterId());
        data.put("reportTime", ex.getReportTime() != null ? ex.getReportTime().toString() : null);
        data.put("description", ex.getDescription());
        data.put("resolved", ex.getResolved());

        Map<String, Object> message = new HashMap<>();
        message.put("type", "EXCEPTION_REPORTED");
        message.put("lineId", ex.getLineId());
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/exceptions", message);
        log.info("异常上报已广播: exceptionId={}, lineId={}", ex.getId(), ex.getLineId());
    }

    /**
     * 异常处理广播 → /topic/exceptions。
     */
    public void broadcastExceptionHandled(ProductionException ex) {
        Map<String, Object> data = new HashMap<>();
        data.put("exceptionId", ex.getId());
        data.put("workOrderId", ex.getWorkOrderId());
        data.put("lineId", ex.getLineId());
        data.put("handledBy", ex.getHandledBy());
        data.put("handleTime", ex.getHandleTime() != null ? ex.getHandleTime().toString() : null);
        data.put("handleAction", ex.getHandleAction());
        data.put("resolved", ex.getResolved());

        Map<String, Object> message = new HashMap<>();
        message.put("type", "EXCEPTION_HANDLED");
        message.put("lineId", ex.getLineId());
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/exceptions", message);
        log.info("异常处理已广播: exceptionId={}, action={}", ex.getId(), ex.getHandleAction());
    }
}
