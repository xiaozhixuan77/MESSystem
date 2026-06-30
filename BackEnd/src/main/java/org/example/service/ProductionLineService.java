package org.example.service;

import org.example.dto.request.CreateProductionLineRequest;
import org.example.dto.request.UpdateProductionLineRequest;
import org.example.entity.ProductionLine;
import org.example.vo.ProductionLineVO;
import com.baomidou.mybatisplus.extension.service.IService;

public interface ProductionLineService extends IService<ProductionLine> {

    ProductionLineVO createLine(CreateProductionLineRequest request);

    ProductionLineVO updateLine(Long id, UpdateProductionLineRequest request);

    void deleteLine(Long id);
}
