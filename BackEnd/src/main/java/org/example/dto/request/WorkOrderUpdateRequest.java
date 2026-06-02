package org.example.dto.request;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class WorkOrderUpdateRequest {
    private String type;
    private Long workshopId;
    private Long lineId;
    private Long productId;
    private Integer planQty;
    private LocalDateTime planStartTime;
    private LocalDateTime planEndTime;
}
