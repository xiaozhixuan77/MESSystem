package org.example.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ExceptionReportRequest {

    @NotNull(message = "工单ID不能为空")
    private Long workOrderId;

    @NotNull(message = "产线ID不能为空")
    private Long lineId;

    private Long stationId;

    @NotBlank(message = "异常描述不能为空")
    private String description;
}
