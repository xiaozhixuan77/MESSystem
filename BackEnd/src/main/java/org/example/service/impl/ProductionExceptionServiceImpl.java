package org.example.service.impl;

import org.example.entity.ProductionException;
import org.example.mapper.ProductionExceptionMapper;
import org.example.service.ProductionExceptionService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 生产异常表 服务实现类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Service
public class ProductionExceptionServiceImpl extends ServiceImpl<ProductionExceptionMapper, ProductionException> implements ProductionExceptionService {

}
