package org.example.vo;

import lombok.Data;

@Data
public class InspectionRecordVO {
    private Long id;
    private Long workOrderId;
    private Long inspectorId;
    private String inspectTime;
    private Integer sampleQty;
    private Integer sampleGood;
    private Integer sampleNg;
    private String defectTypes;
    private String defectDescription;
    private String conclusion;
    private String status;
    private String workOrderCode;
    private String productName;
    private String processName;
    private Integer reportedQtyGood;
    private Integer reportedQtyNg;
    private Integer planQty;
    private String inspectorName;
}
