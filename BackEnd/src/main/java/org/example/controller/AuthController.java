package org.example.controller;

import org.example.dto.request.LoginRequest;
import org.example.dto.response.LoginResponse;
import org.example.dto.response.R;
import org.example.entity.User;
import org.example.security.JwtTokenProvider;
import org.example.service.UserService;
import org.example.vo.UserVO;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserService userService;

    public AuthController(AuthenticationManager authenticationManager,
                          JwtTokenProvider jwtTokenProvider,
                          UserService userService) {
        this.authenticationManager = authenticationManager;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userService = userService;
    }

    @PostMapping("/auth/login")
    public R<LoginResponse> login(@RequestBody LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getUsername(),
                            request.getPassword()
                    )
            );

            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            Long userId = Long.valueOf(userDetails.getUsername());
            String role = userDetails.getAuthorities().iterator().next().getAuthority();

            String token = jwtTokenProvider.createToken(userId, role);

            User user = userService.getById(userId);
            UserVO userVO = new UserVO();
            userVO.setId(user.getId());
            userVO.setEmployeeNo(user.getEmployeeNo());
            userVO.setName(user.getName());
            userVO.setRole(user.getRole());
            userVO.setWorkshopId(user.getWorkshopId());
            userVO.setTeamId(user.getTeamId());
            userVO.setStatus(user.getStatus());
            userVO.setAvatarUrl(user.getAvatarUrl());

            LoginResponse response = new LoginResponse();
            response.setToken(token);
            response.setRole(role);
            response.setUser(userVO);

            return R.ok(response);
        } catch (BadCredentialsException e) {
            return R.error(400, "用户名或密码错误");
        }
    }

    @PostMapping("/auth/logout")
    public R<Void> logout() {
        return R.ok();
    }

    @GetMapping("/me")
    public R<UserVO> me() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return R.error(401, "未登录");
        }

        Object principal = authentication.getPrincipal();
        if (!(principal instanceof UserDetails userDetails)) {
            return R.error(401, "未登录");
        }

        Long userId = Long.valueOf(userDetails.getUsername());
        User user = userService.getById(userId);
        if (user == null) {
            return R.error(404, "用户不存在");
        }

        UserVO userVO = new UserVO();
        userVO.setId(user.getId());
        userVO.setEmployeeNo(user.getEmployeeNo());
        userVO.setName(user.getName());
        userVO.setRole(user.getRole());
        userVO.setWorkshopId(user.getWorkshopId());
        userVO.setTeamId(user.getTeamId());
        userVO.setStatus(user.getStatus());
        userVO.setAvatarUrl(user.getAvatarUrl());

        return R.ok(userVO);
    }
}
