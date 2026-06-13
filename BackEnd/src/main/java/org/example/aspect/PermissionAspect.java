package org.example.aspect;

import org.example.exception.BusinessException;
import org.example.security.RequiresPermission;
import org.example.service.UserService;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

@Aspect
@Component
public class PermissionAspect {

    private final UserService userService;

    public PermissionAspect(UserService userService) {
        this.userService = userService;
    }

    @Around("@annotation(requiresPermission)")
    public Object checkPermission(ProceedingJoinPoint point, RequiresPermission requiresPermission) throws Throwable {
        String permission = requiresPermission.value();
        Long userId = getCurrentUserId();

        if (userId == null) {
            throw new BusinessException(401, "未登录");
        }

        Set<String> permissions = getPermissionsFromSecurityContext();
        if (permissions.isEmpty()) {
            // fallback: JWT 不含权限时查 DB（兼容旧 token）
            permissions = userService.getUserPermissions(userId);
        }

        if (permissions.contains("*")) {
            return point.proceed();
        }

        if (!permissions.contains(permission)) {
            throw new BusinessException(403, "无权限执行此操作: " + permission);
        }

        return point.proceed();
    }

    /**
     * 从 SecurityContext 中获取 JWT 携带的权限集。
     * 权限以逗号分隔字符串存储在 Authentication.details 中。
     */
    private Set<String> getPermissionsFromSecurityContext() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            return Collections.emptySet();
        }
        Object details = authentication.getDetails();
        if (details instanceof String permStr && !permStr.isEmpty()) {
            return new HashSet<>(Arrays.asList(permStr.split(",")));
        }
        return Collections.emptySet();
    }

    private Long getCurrentUserId() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof UserDetails userDetails) {
            return Long.valueOf(userDetails.getUsername());
        }
        return null;
    }
}
