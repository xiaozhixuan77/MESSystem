package org.example.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class InspectionCreateRequest {

    @NotNull(message = "工单ID不能为空")
    private Long workOrderId;

    @NotNull(message = "抽检数量不能为空")
    private Integer sampleQty;

    private Integer sampleGood;
    private Integer sampleNg;
    private String defectTypes;
    private String defectDescription;
    private String conclusion;
}
