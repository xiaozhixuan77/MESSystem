package org.example.vo;

import lombok.Data;

@Data
public class ProductionLineVO {
    private Long id;
    private String name;
    private Long workshopId;
    private String status;
    private String workshopName;
    private String createdAt;
}
