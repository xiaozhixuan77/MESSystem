package org.example.simulator;

import lombok.Getter;
import lombok.Setter;
import lombok.experimental.Accessors;

/**
 * 工作站状态快照 — 单次 Tick 后推送给 WebSocket 和日志落盘。
 */
@Getter
@Setter
@Accessors(chain = true)
public class StationState {
    private Long stationId;
    private String opCode;
    private String name;
    private String deviceStatus;
    private int processedCount;
    private int rawCount;
    private int finishedCount;
    private int ngCount;
}
