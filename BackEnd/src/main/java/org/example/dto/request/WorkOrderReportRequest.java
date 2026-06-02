package org.example.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class WorkOrderReportRequest {

    @NotNull(message = "良品数不能为空")
    @PositiveOrZero(message = "良品数必须>=0")
    private Integer good;

    @NotNull(message = "NG数不能为空")
    @PositiveOrZero(message = "NG数必须>=0")
    private Integer ng;

    private BigDecimal hours;

    private String note;
}
