package org.example.vo;

import lombok.Data;

@Data
public class ProductionExceptionVO {
    private Long id;
    private Long workOrderId;
    private String workOrderCode;
    private Long lineId;
    private String lineName;
    private Long stationId;
    private String stationName;
    private Long reporterId;
    private String reporterName;
    private String reportTime;
    private String description;
    private Long handledBy;
    private String handlerName;
    private String handleTime;
    private String handleAction;
    private Byte resolved;
    private String createdAt;
}
