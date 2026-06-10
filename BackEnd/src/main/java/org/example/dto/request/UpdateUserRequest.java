package org.example.dto.request;

import lombok.Data;

@Data
public class UpdateUserRequest {

    private String name;

    private String role;

    private Long workshopId;

    private Long teamId;

    private String status;

    private String password;
}
