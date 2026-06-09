package org.example.vo;

import lombok.Data;

import java.util.List;

@Data
public class HomeSummaryVO {
    private long pendingExceptionCount;
    private long pendingDispatchCount;
    private long pendingInspectionCount;
    private long activeWorkOrderCount;
    private long totalLineCount;
    private long totalUserCount;

    private List<ExceptionItem> recentExceptions;
    private List<DispatchItem> pendingDispatchItems;
    private List<InspectionItem> pendingInspectionItems;
    private long todayInspectionDone;
    private double todayInspectionPassRate;

    private TaskItem operatorActiveTask;
    private List<TaskItem> operatorPendingStartTasks;
    private List<TaskItem> operatorPendingReportTasks;

    @Data
    public static class ExceptionItem {
        private Long id;
        private Long workOrderId;
        private String workOrderCode;
        private Long lineId;
        private String lineName;
        private String description;
        private String reportTime;
    }

    @Data
    public static class DispatchItem {
        private Long id;
        private String code;
        private String type;
        private Integer planQty;
        private String createdAt;
    }

    @Data
    public static class InspectionItem {
        private Long id;
        private Long workOrderId;
        private String workOrderCode;
        private Integer sampleQty;
        private String inspectTime;
    }

    @Data
    public static class TaskItem {
        private Long id;
        private String code;
        private String type;
        private String status;
        private String lineName;
        private Integer planQty;
        private Integer reportedQtyGood;
        private Integer reportedQtyNg;
    }
}
