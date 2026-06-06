package org.example.vo;

import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
public class WorkOrderDetailVO extends WorkOrderVO {
    private String source;
    private LocalDateTime dispatchTime;
    private LocalDateTime actualStartTime;
    private LocalDateTime actualEndTime;
    private LocalDateTime pauseTime;
    private Integer reportedQtyGood;
    private Integer reportedQtyNg;
    private BigDecimal reportedHours;
    private String exceptionNote;
    private Long createdBy;
    private String createdByName;
    private Long sourceWorkorderId;
    private List<WorkOrderRouteStepVO> routeSteps;
    private String processName;
    private Integer stationTotalOutput;
    private Integer stationTotalNg;
    private Integer stationProcessedCount;
    private Long elapsedSeconds;
}
