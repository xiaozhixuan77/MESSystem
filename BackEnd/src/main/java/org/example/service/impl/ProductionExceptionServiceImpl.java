package org.example.service.impl;

import org.example.entity.ProductionException;
import org.example.exception.BusinessException;
import org.example.mapper.ProductionExceptionMapper;
import org.example.service.ProductionExceptionService;
import org.example.service.WorkOrderService;
import org.example.websocket.LineBroadcaster;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class ProductionExceptionServiceImpl
        extends ServiceImpl<ProductionExceptionMapper, ProductionException>
        implements ProductionExceptionService {

    private final WorkOrderService workOrderService;
    private final LineBroadcaster lineBroadcaster;

    public ProductionExceptionServiceImpl(WorkOrderService workOrderService,
                                          LineBroadcaster lineBroadcaster) {
        this.workOrderService = workOrderService;
        this.lineBroadcaster = lineBroadcaster;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ProductionException reportException(Long workOrderId, Long lineId, Long stationId,
                                                String description, Long reporterId) {
        ProductionException ex = new ProductionException();
        ex.setWorkOrderId(workOrderId);
        ex.setLineId(lineId);
        ex.setStationId(stationId);
        ex.setReporterId(reporterId);
        ex.setReportTime(LocalDateTime.now());
        ex.setDescription(description);
        ex.setResolved((byte) 0);
        save(ex);

        workOrderService.pause(workOrderId, description);

        lineBroadcaster.broadcastExceptionReported(ex);

        return ex;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ProductionException handleException(Long exceptionId, String action, Long handlerId) {
        ProductionException ex = lambdaQuery()
                .eq(ProductionException::getId, exceptionId)
                .eq(ProductionException::getIsDeleted, 0)
                .last("FOR UPDATE")
                .one();
        if (ex == null) {
            throw new BusinessException(400, "异常记录不存在");
        }
        if (ex.getResolved() == 1) {
            throw new BusinessException(400, "该异常已处理");
        }
        if (!"恢复".equals(action) && !"关闭".equals(action)) {
            throw new BusinessException(400, "处理动作必须为\"恢复\"或\"关闭\"");
        }

        ex.setHandledBy(handlerId);
        ex.setHandleTime(LocalDateTime.now());
        ex.setHandleAction(action);
        ex.setResolved((byte) 1);
        updateById(ex);

        if ("恢复".equals(action)) {
            workOrderService.resume(ex.getWorkOrderId());
        }

        lineBroadcaster.broadcastExceptionHandled(ex);

        return ex;
    }
}
