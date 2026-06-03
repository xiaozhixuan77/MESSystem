package org.example.vo;

import lombok.Data;

import java.util.List;

@Data
public class LineDetailVO {
    private Long id;
    private String name;
    private Long workshopId;
    private String workshopName;
    private String status;
    private Long currentProcessId;
    private Long currentWorkorderId;
    private String createdAt;
    private List<StationVO> stations;
    private WorkOrderSummary activeWorkOrder;

    @Data
    public static class WorkOrderSummary {
        private Long id;
        private String code;
        private String productName;
        private String processName;
        private Integer planQty;
        private String status;
    }
}
