package org.example.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ExceptionHandleRequest {

    @NotBlank(message = "处理动作不能为空")
    private String action;
}
