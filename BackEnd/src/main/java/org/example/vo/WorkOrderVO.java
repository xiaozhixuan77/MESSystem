package org.example.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class WorkOrderVO {
    private Long id;
    private String code;
    private String type;
    private Long workshopId;
    private Long lineId;
    private Long productId;
    private String productName;
    private Long processId;
    private Integer planQty;
    private String status;
    private Long operatorId;
    private String operatorName;
    private LocalDateTime planStartTime;
    private LocalDateTime planEndTime;
    private LocalDateTime createdAt;
}
