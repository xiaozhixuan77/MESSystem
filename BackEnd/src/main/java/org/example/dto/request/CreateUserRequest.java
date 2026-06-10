package org.example.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateUserRequest {

    @NotBlank(message = "工号不能为空")
    private String employeeNo;

    @NotBlank(message = "姓名不能为空")
    private String name;

    @NotBlank(message = "角色不能为空")
    private String role;

    private Long workshopId;

    private Long teamId;

    @NotBlank(message = "密码不能为空")
    private String password;
}
