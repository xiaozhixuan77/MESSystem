package org.example.vo;

import lombok.Data;

@Data
public class WorkOrderRouteStepVO {
    private Long id;
    private Integer seqNo;
    private String opCode;
    private String name;
    private Long stationId;
}
