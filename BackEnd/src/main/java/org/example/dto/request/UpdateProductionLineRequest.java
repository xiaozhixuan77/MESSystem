package org.example.dto.request;

import lombok.Data;

@Data
public class UpdateProductionLineRequest {
    private String name;
    private Long workshopId;
    private Long currentProcessId;
}
