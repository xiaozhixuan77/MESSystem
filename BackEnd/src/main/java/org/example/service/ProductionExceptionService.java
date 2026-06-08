package org.example.service;

import org.example.entity.ProductionException;
import com.baomidou.mybatisplus.extension.service.IService;

public interface ProductionExceptionService extends IService<ProductionException> {

    ProductionException reportException(Long workOrderId, Long lineId, Long stationId,
                                        String description, Long reporterId);

    ProductionException handleException(Long exceptionId, String action, Long handlerId);
}
