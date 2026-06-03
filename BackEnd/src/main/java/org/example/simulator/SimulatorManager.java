package org.example.simulator;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import org.example.config.SimulatorConfig;
import org.example.entity.ProductionLine;
import org.example.entity.ProductionLog;
import org.example.entity.Workstation;
import org.example.exception.BusinessException;
import org.example.service.ProductionLineService;
import org.example.service.ProductionLogService;
import org.example.service.WorkstationService;
import org.example.websocket.LineBroadcaster;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

/**
 * 仿真器生命周期管理器 — 负责仿真任务的启动/停止/复位/调度与持久化。
 *
 * 每条"生产中"的产线由独立的定时 Tick 驱动，使用共享线程池调度。
 */
@Component
public class SimulatorManager {

    private static final Logger log = LoggerFactory.getLogger(SimulatorManager.class);

    private final WorkstationService workstationService;
    private final ProductionLineService productionLineService;
    private final ProductionLogService productionLogService;
    private final SimulatorConfig config;
    private final ObjectMapper objectMapper;
    private final LineBroadcaster lineBroadcaster;

    private final ScheduledExecutorService scheduler =
            Executors.newScheduledThreadPool(Runtime.getRuntime().availableProcessors());
    private final ConcurrentHashMap<Long, ScheduledFuture<?>> runningSimulators = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, LineSimulator> simulators = new ConcurrentHashMap<>();
    private final Set<Long> tickingLines = ConcurrentHashMap.newKeySet();

    public SimulatorManager(WorkstationService workstationService,
                            ProductionLineService productionLineService,
                            ProductionLogService productionLogService,
                            SimulatorConfig config,
                            ObjectMapper objectMapper,
                            LineBroadcaster lineBroadcaster) {
        this.workstationService = workstationService;
        this.productionLineService = productionLineService;
        this.productionLogService = productionLogService;
        this.config = config;
        this.objectMapper = objectMapper;
        this.lineBroadcaster = lineBroadcaster;
    }

    /**
     * 启动产线仿真。幂等：已运行的产线再次调用会抛异常。
     */
    public void start(Long lineId, Long workOrderId) {
        if (runningSimulators.containsKey(lineId)) {
            throw new BusinessException(400, "产线 " + lineId + " 已在仿真运行中");
        }

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, lineId)
                .one();
        if (line == null) {
            throw new BusinessException(404, "产线 " + lineId + " 不存在");
        }

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, lineId)
                .list();
        if (stations == null || stations.isEmpty()) {
            throw new BusinessException(422, "产线 " + lineId + " 下没有工作站，无法启动仿真");
        }

        for (Workstation ws : stations) {
            ws.setDeviceStatus("运行中");
        }
        workstationService.updateBatchById(stations);

        line.setStatus("生产中");
        productionLineService.updateById(line);

        LineSimulator simulator = new LineSimulator(lineId, workOrderId, stations,
                Collections.emptyList(), config.getGoodRate());
        simulators.put(lineId, simulator);

        lineBroadcaster.broadcastLineStatus(lineId, "生产中", workOrderId);

        ScheduledFuture<?> future = scheduler.scheduleAtFixedRate(
                () -> tick(lineId), 0, config.getTickInterval(), TimeUnit.MILLISECONDS);

        runningSimulators.put(lineId, future);

        log.info("产线 {} 仿真已启动，工单: {}, Tick 间隔: {}ms", lineId, workOrderId, config.getTickInterval());
    }

    /**
     * 停止产线仿真，产线置为"暂停"。
     */
    public void stop(Long lineId) {
        stop(lineId, "暂停");
    }

    /**
     * 停止产线仿真并指定最终产线状态。
     */
    public void stop(Long lineId, String finalStatus) {
        ScheduledFuture<?> future = runningSimulators.remove(lineId);
        if (future == null) {
            throw new BusinessException(409, "产线 " + lineId + " 未在仿真运行中");
        }
        future.cancel(false);
        simulators.remove(lineId);
        waitForTickCompletion(lineId);

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, lineId)
                .list();
        for (Workstation ws : stations) {
            ws.setDeviceStatus("待机");
        }
        workstationService.updateBatchById(stations);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, lineId)
                .one();
        if (line != null) {
            line.setStatus(finalStatus);
            productionLineService.updateById(line);
        }

        lineBroadcaster.broadcastLineStatus(lineId, finalStatus, null);

        log.info("产线 {} 仿真已停止，最终状态: {}", lineId, finalStatus);
    }

    /**
     * 复位产线：停止仿真、清零计数器、恢复空闲状态。
     * 无论当前是否在仿真运行中均可调用。
     */
    public void reset(Long lineId) {
        ScheduledFuture<?> future = runningSimulators.remove(lineId);
        if (future != null) {
            future.cancel(false);
        }
        simulators.remove(lineId);
        waitForTickCompletion(lineId);

        workstationService.resetCounters(lineId);

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, lineId)
                .list();
        for (Workstation ws : stations) {
            ws.setDeviceStatus("待机");
        }
        workstationService.updateBatchById(stations);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, lineId)
                .one();
        if (line != null) {
            line.setStatus("空闲");
            productionLineService.updateById(line);
        }

        lineBroadcaster.broadcastLineStatus(lineId, "空闲", null);

        log.info("产线 {} 已复位", lineId);
    }

    public boolean isRunning(Long lineId) {
        return runningSimulators.containsKey(lineId);
    }

    public Optional<LineSimulator> getSimulator(Long lineId) {
        return Optional.ofNullable(simulators.get(lineId));
    }

    public Set<Long> getRunningLineIds() {
        return new HashSet<>(runningSimulators.keySet());
    }

    /**
     * 自旋等待当前正在执行的 Tick 完成，防止 stop/reset 与 tick 的 DB 写入竞争。
     */
    private void waitForTickCompletion(Long lineId) {
        while (tickingLines.contains(lineId)) {
            Thread.yield();
        }
    }

    private void tick(Long lineId) {
        LineSimulator simulator = simulators.get(lineId);
        if (simulator == null) {
            return;
        }

        tickingLines.add(lineId);
        try {
            List<StationState> states = simulator.tick();

            workstationService.updateBatchById(simulator.getStations());

            ProductionLog logEntry = new ProductionLog()
                    .setLineId(lineId)
                    .setWorkOrderId(simulator.getWorkOrderId())
                    .setEventType("加工")
                    .setEventTime(LocalDateTime.now())
                    .setPayload(objectMapper.writeValueAsString(states));
            productionLogService.save(logEntry);

            lineBroadcaster.broadcastStationUpdate(lineId, states);
        } catch (Exception e) {
            log.error("产线 {} Tick 异常", lineId, e);
        } finally {
            tickingLines.remove(lineId);
        }
    }

    @PreDestroy
    public void shutdown() {
        log.info("正在关闭仿真器管理器，共 {} 条产线运行中", runningSimulators.size());
        runningSimulators.forEach((lineId, future) -> {
            future.cancel(false);
            log.info("已取消产线 {} 的仿真任务", lineId);
        });
        runningSimulators.clear();
        simulators.clear();

        scheduler.shutdown();
        try {
            if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
