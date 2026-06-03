package org.example.vo;

import lombok.Data;

@Data
public class StationVO {
    private Long id;
    private String opCode;
    private String name;
    private String equipmentCode;
    private String deviceStatus;
    private String workStatus;
    private String conveyorStatus;
    private int processedCount;
    private int rawCount;
    private int finishedCount;
    private int ngCount;
}
