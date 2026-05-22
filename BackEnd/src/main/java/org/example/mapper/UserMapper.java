package org.example.mapper;

import org.example.entity.User;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * <p>
 * 人员表 Mapper 接口
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

}
