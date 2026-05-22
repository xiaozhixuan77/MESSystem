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

        Set<String> permissions = userService.getUserPermissions(userId);

        if (permissions.contains("*")) {
            return point.proceed();
        }

        if (!permissions.contains(permission)) {
            throw new BusinessException(403, "无权限执行此操作: " + permission);
        }

        return point.proceed();
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
