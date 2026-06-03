package org.example.simulator;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.entity.ProductionLog;
import org.example.entity.Workstation;
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
    private final ObjectMapper objectMapper;

    public SimulatorTickService(WorkstationService workstationService,
                                 ProductionLogService productionLogService,
                                 ObjectMapper objectMapper) {
        this.workstationService = workstationService;
        this.productionLogService = productionLogService;
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
