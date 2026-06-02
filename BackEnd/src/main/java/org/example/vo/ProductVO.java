package org.example.vo;

import lombok.Data;

@Data
public class ProductVO {
    private Long id;
    private String code;
    private String name;
    private Long defaultProcessId;
}
