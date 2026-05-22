package org.example.service.impl;

import org.example.entity.ProductionLine;
import org.example.mapper.ProductionLineMapper;
import org.example.service.ProductionLineService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 产线表 服务实现类
 * </p>
 *
 * @author MES Developer
 * @since 2026-05-22
 */
@Service
public class ProductionLineServiceImpl extends ServiceImpl<ProductionLineMapper, ProductionLine> implements ProductionLineService {

}
