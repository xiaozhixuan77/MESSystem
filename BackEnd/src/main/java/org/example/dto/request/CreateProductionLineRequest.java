package org.example.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateProductionLineRequest {
    @NotBlank(message = "产线名称不能为空")
    private String name;

    @NotNull(message = "所属车间不能为空")
    private Long workshopId;

    @NotNull(message = "工艺不能为空")
    private Long currentProcessId;
}
