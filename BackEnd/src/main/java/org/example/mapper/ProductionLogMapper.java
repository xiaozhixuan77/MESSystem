package org.example.mapper;

import org.example.entity.ProductionLog;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * <p>
 * 产线运行日志表 Mapper 接口
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Mapper
public interface ProductionLogMapper extends BaseMapper<ProductionLog> {

}
