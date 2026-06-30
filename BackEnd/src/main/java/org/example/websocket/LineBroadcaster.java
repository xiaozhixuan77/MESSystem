package org.example.websocket;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import org.example.simulator.StationState;

import org.example.entity.InspectionRecord;
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

    /**
     * 抽检记录变更广播 → /topic/inspections。
     */
    public void broadcastInspectionUpdate(InspectionRecord record) {
        Map<String, Object> data = new HashMap<>();
        data.put("id", record.getId());
        data.put("workOrderId", record.getWorkOrderId());
        data.put("status", record.getStatus());
        data.put("sampleQty", record.getSampleQty());
        data.put("sampleGood", record.getSampleGood());
        data.put("sampleNg", record.getSampleNg());
        data.put("conclusion", record.getConclusion());
        data.put("inspectTime", record.getInspectTime() != null ? record.getInspectTime().toString() : null);

        Map<String, Object> message = new HashMap<>();
        message.put("type", "INSPECTION_UPDATE");
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/inspections", message);
        log.info("抽检记录已广播: id={}, status={}", record.getId(), record.getStatus());
    }

    /**
     * 用户状态变更广播 → /topic/users。
     */
    public void broadcastUserStatusChanged(Long userId, String employeeNo, String name, String status) {
        Map<String, Object> data = new HashMap<>();
        data.put("userId", userId);
        data.put("employeeNo", employeeNo);
        data.put("name", name);
        data.put("status", status);

        Map<String, Object> message = new HashMap<>();
        message.put("type", "USER_STATUS_CHANGED");
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/users", message);
        log.debug("用户状态已广播: userId={}, status={}", userId, status);
    }

    /**
     * 主页摘要刷新信号 → /topic/home。
     * 当工单状态、异常、抽检等影响主页待办卡片的数据变更时调用。
     */
    public void broadcastHomeRefresh(String trigger) {
        Map<String, Object> data = new HashMap<>();
        data.put("trigger", trigger);

        Map<String, Object> message = new HashMap<>();
        message.put("type", "HOME_REFRESH");
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/home", message);
        log.debug("HOME_REFRESH 已广播: trigger={}", trigger);
    }

    /**
     * 产线列表变更广播（新增/编辑/删除）→ /topic/lines。
     * 通知所有客户端重新加载产线列表。
     */
    public void broadcastLineListChanged(String action, Long lineId) {
        Map<String, Object> data = new HashMap<>();
        data.put("action", action);
        data.put("lineId", lineId);

        Map<String, Object> message = new HashMap<>();
        message.put("type", "LINE_LIST_CHANGED");
        message.put("timestamp", System.currentTimeMillis());
        message.put("data", data);

        messagingTemplate.convertAndSend("/topic/lines", message);
        log.info("LINE_LIST_CHANGED 已广播: action={}, lineId={}", action, lineId);
    }
}
