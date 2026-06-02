package org.example.vo;

import lombok.Data;

import java.util.List;

@Data
public class ProcessWithStepsVO {
    private Long id;
    private String code;
    private String name;
    private String applicableProductCodes;
    private List<ProcessStepVO> steps;
}
