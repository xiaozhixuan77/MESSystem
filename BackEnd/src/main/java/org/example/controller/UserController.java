package org.example.controller;

import org.example.constant.ErrorMessages;
import org.example.constant.UserStatus;
import org.example.dto.request.CreateUserRequest;
import org.example.dto.request.UpdateUserRequest;
import org.example.dto.response.R;
import org.example.entity.User;
import org.example.exception.BusinessException;
import org.example.security.RequiresPermission;
import org.example.service.UserService;
import org.example.vo.UserVO;
import org.example.websocket.LineBroadcaster;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class UserController {

    private final UserService userService;
    private final BCryptPasswordEncoder passwordEncoder;
    private final LineBroadcaster lineBroadcaster;

    public UserController(UserService userService,
                          BCryptPasswordEncoder passwordEncoder,
                          LineBroadcaster lineBroadcaster) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.lineBroadcaster = lineBroadcaster;
    }

    @GetMapping("/users")
    @RequiresPermission("user.view")
    public R<List<UserVO>> list(@RequestParam(required = false) String role,
                                 @RequestParam(required = false) String keyword,
                                 @RequestParam(required = false) String status) {
        var query = userService.lambdaQuery();
        if (role != null && !role.isEmpty()) {
            query = query.eq(User::getRole, role);
        }
        if (keyword != null && !keyword.isEmpty()) {
            query = query.and(w -> w.like(User::getName, keyword).or().like(User::getEmployeeNo, keyword));
        }
        if (status != null && !status.isEmpty()) {
            query = query.eq(User::getStatus, status);
        }
        List<User> users = query.list();
        List<UserVO> vos = users.stream().map(this::toVO).collect(Collectors.toList());
        return R.ok(vos);
    }

    @PostMapping("/users")
    @RequiresPermission("user.create")
    public R<UserVO> create(@Valid @RequestBody CreateUserRequest req) {
        User exist = userService.getByEmployeeNo(req.getEmployeeNo());
        if (exist != null) {
            throw new BusinessException(400, ErrorMessages.EMPLOYEE_NO_EXISTS);
        }
        User user = new User();
        user.setEmployeeNo(req.getEmployeeNo());
        user.setName(req.getName());
        user.setRole(req.getRole());
        user.setWorkshopId(req.getWorkshopId());
        user.setTeamId(req.getTeamId());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setStatus(UserStatus.ACTIVE.getLabel());
        userService.save(user);
        return R.ok(toVO(user));
    }

    @PutMapping("/users/{id}")
    @RequiresPermission("user.update")
    public R<UserVO> update(@PathVariable Long id, @RequestBody UpdateUserRequest req) {
        if (req.getName() == null && req.getRole() == null && req.getWorkshopId() == null
                && req.getTeamId() == null && req.getStatus() == null
                && (req.getPassword() == null || req.getPassword().isEmpty())) {
            throw new BusinessException(400, ErrorMessages.UPDATE_FIELD_REQUIRED);
        }
        User user = userService.getById(id);
        if (user == null) {
            throw new BusinessException(404, ErrorMessages.USER_NOT_FOUND);
        }
        if (req.getName() != null) user.setName(req.getName());
        if (req.getRole() != null) user.setRole(req.getRole());
        if (req.getWorkshopId() != null) user.setWorkshopId(req.getWorkshopId());
        if (req.getTeamId() != null) user.setTeamId(req.getTeamId());
        String oldStatus = user.getStatus();
        if (req.getStatus() != null) {
            user.setStatus(req.getStatus());
        }
        if (req.getPassword() != null && !req.getPassword().isEmpty()) {
            user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        }
        userService.updateById(user);

        if (req.getStatus() != null && !req.getStatus().equals(oldStatus)) {
            lineBroadcaster.broadcastUserStatusChanged(
                    user.getId(), user.getEmployeeNo(), user.getName(), req.getStatus());
        }

        return R.ok(toVO(user));
    }

    @DeleteMapping("/users/{id}")
    @RequiresPermission("user.delete")
    public R<Void> delete(@PathVariable Long id) {
        boolean removed = userService.removeById(id);
        if (!removed) {
            throw new BusinessException(404, ErrorMessages.USER_NOT_FOUND);
        }
        return R.ok();
    }

    private UserVO toVO(User u) {
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
    }
}
