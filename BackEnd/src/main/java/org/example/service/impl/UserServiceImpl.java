package org.example.service.impl;

import org.example.entity.RolePermission;
import org.example.entity.User;
import org.example.mapper.UserMapper;
import org.example.service.RolePermissionService;
import org.example.service.UserService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * <p>
 * 人员表 服务实现类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final RolePermissionService rolePermissionService;

    public UserServiceImpl(RolePermissionService rolePermissionService) {
        this.rolePermissionService = rolePermissionService;
    }

    @Override
    public User getByEmployeeNo(String employeeNo) {
        return lambdaQuery().eq(User::getEmployeeNo, employeeNo).one();
    }

    @Override
    public Set<String> getUserPermissions(Long userId) {
        User user = getById(userId);
        if (user == null || user.getRole() == null) {
            return Collections.emptySet();
        }

        return rolePermissionService.lambdaQuery()
                .eq(RolePermission::getRole, user.getRole())
                .list()
                .stream()
                .map(RolePermission::getPermission)
                .collect(Collectors.toSet());
    }
}
