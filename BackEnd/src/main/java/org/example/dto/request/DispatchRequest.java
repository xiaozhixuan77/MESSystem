package org.example.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class DispatchRequest {

    @NotNull(message = "操作员ID不能为空")
    private Long operatorId;
}
