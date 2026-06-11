package org.example.simulator;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.entity.ProductionLog;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.mapper.WorkOrderMapper;
import org.example.service.ProductionLogService;
import org.example.service.WorkstationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Tick 持久化服务 — 将单次 Tick 的 DB 写入操作封装在同一个事务中，
 * 确保工作站计数器更新与生产日志落盘原子执行。
 */
@Service
public class SimulatorTickService {

    private static final Logger log = LoggerFactory.getLogger(SimulatorTickService.class);

    private final WorkstationService workstationService;
    private final ProductionLogService productionLogService;
    private final WorkOrderMapper workOrderMapper;
    private final ObjectMapper objectMapper;

    public SimulatorTickService(WorkstationService workstationService,
                                 ProductionLogService productionLogService,
                                 WorkOrderMapper workOrderMapper,
                                 ObjectMapper objectMapper) {
        this.workstationService = workstationService;
        this.productionLogService = productionLogService;
        this.workOrderMapper = workOrderMapper;
        this.objectMapper = objectMapper;
    }

    /**
     * 在事务中持久化 Tick 结果：更新工作站计数器 + 写入生产日志。
     * WebSocket 广播在事务提交后由调用方执行。
     */
    @Transactional(rollbackFor = Exception.class)
    public void persistTick(Long lineId, LineSimulator simulator, List<StationState> states) {
        List<Workstation> stations = simulator.getStations();
        workstationService.updateBatchById(stations);

        // 将最后一个工位的产出同步到工单，使操作员首页进度条实时更新
        if (!stations.isEmpty()) {
            Workstation lastStation = stations.get(stations.size() - 1);
            int finished = lastStation.getFinishedCount() != null ? lastStation.getFinishedCount() : 0;
            int ng = lastStation.getNgCount() != null ? lastStation.getNgCount() : 0;
            LambdaUpdateWrapper<WorkOrder> wrapper = new LambdaUpdateWrapper<>();
            wrapper.eq(WorkOrder::getId, simulator.getWorkOrderId())
                    .set(WorkOrder::getReportedQtyGood, finished)
                    .set(WorkOrder::getReportedQtyNg, ng);
            workOrderMapper.update(null, wrapper);
        }

        try {
            ProductionLog logEntry = new ProductionLog()
                    .setLineId(lineId)
                    .setWorkOrderId(simulator.getWorkOrderId())
                    .setEventType("加工")
                    .setEventTime(LocalDateTime.now())
                    .setPayload(objectMapper.writeValueAsString(states));
            productionLogService.save(logEntry);
        } catch (Exception e) {
            log.error("产线 {} 生产日志保存失败", lineId, e);
            throw new RuntimeException("生产日志保存失败", e);
        }
    }
}
