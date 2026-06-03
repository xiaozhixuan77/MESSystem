package org.example.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class LineStartRequest {

    @NotNull(message = "工单ID不能为空")
    private Long workOrderId;
}
