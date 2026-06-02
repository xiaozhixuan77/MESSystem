package org.example.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class WorkOrderCreateRequest {

    @NotNull(message = "工单类型不能为空")
    private String type;

    @NotNull(message = "车间ID不能为空")
    private Long workshopId;

    @NotNull(message = "产线ID不能为空")
    private Long lineId;

    @NotNull(message = "产品ID不能为空")
    private Long productId;

    @NotNull(message = "计划数量不能为空")
    @Positive(message = "计划数量必须大于0")
    private Integer planQty;

    private LocalDateTime planStartTime;

    private LocalDateTime planEndTime;
}
