package org.example.dto.response;

import org.example.vo.UserVO;
import lombok.Data;

@Data
public class LoginResponse {

    private String token;
    private String role;
    private String permissions;
    private UserVO user;
}
