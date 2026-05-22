package org.example.service.impl;

import org.example.entity.ProductionLog;
import org.example.mapper.ProductionLogMapper;
import org.example.service.ProductionLogService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 产线运行日志表 服务实现类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Service
public class ProductionLogServiceImpl extends ServiceImpl<ProductionLogMapper, ProductionLog> implements ProductionLogService {

}
