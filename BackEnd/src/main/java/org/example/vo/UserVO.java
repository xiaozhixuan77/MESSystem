package org.example.vo;

import lombok.Data;

@Data
public class UserVO {

    private Long id;
    private String employeeNo;
    private String name;
    private String role;
    private Long workshopId;
    private Long teamId;
    private String status;
    private String avatarUrl;
}
