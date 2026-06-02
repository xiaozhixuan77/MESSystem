package org.example.controller;

import org.example.dto.response.R;
import org.example.entity.User;
import org.example.service.UserService;
import org.example.vo.UserVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/users")
    public R<List<UserVO>> list(@RequestParam(required = false) String role) {
        var query = userService.lambdaQuery()
                .eq(User::getIsDeleted, 0);
        if (role != null && !role.isEmpty()) {
            query = query.eq(User::getRole, role);
        }
        List<User> users = query.list();
        List<UserVO> vos = users.stream().map(u -> {
            UserVO vo = new UserVO();
            vo.setId(u.getId());
            vo.setEmployeeNo(u.getEmployeeNo());
            vo.setName(u.getName());
            vo.setRole(u.getRole());
            vo.setWorkshopId(u.getWorkshopId());
            vo.setTeamId(u.getTeamId());
            vo.setStatus(u.getStatus());
            vo.setAvatarUrl(u.getAvatarUrl());
            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }
}
