package org.example.service;

import org.example.entity.User;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.Set;

/**
 * <p>
 * 人员表 服务类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
public interface UserService extends IService<User> {

    User getByEmployeeNo(String employeeNo);

    Set<String> getUserPermissions(Long userId);
}
