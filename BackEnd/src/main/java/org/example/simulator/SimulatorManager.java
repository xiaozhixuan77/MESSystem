package org.example.simulator;

import jakarta.annotation.PreDestroy;
import org.springframework.context.annotation.Lazy;
import org.example.config.SimulatorConfig;
import org.example.entity.ProductionLine;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.exception.BusinessException;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderService;
import org.example.service.WorkstationService;
import org.example.websocket.LineBroadcaster;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

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
import java.util.concurrent.locks.ReentrantLock;

/**
 * 仿真器生命周期管理器 — 负责仿真任务的启动/停止/复位/调度。
 *
 * 每条"生产中"的产线由独立的定时 Tick 驱动，使用共享线程池调度。
 */
@Component
public class SimulatorManager {

    private static final Logger log = LoggerFactory.getLogger(SimulatorManager.class);

    private final WorkstationService workstationService;
    private final ProductionLineService productionLineService;
    private final SimulatorConfig config;
    private final LineBroadcaster lineBroadcaster;
    private final SimulatorTickService tickService;
    private final WorkOrderService workOrderService;

    private final ScheduledExecutorService scheduler =
            Executors.newScheduledThreadPool(Runtime.getRuntime().availableProcessors());
    private final ConcurrentHashMap<Long, ScheduledFuture<?>> runningSimulators = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, LineSimulator> simulators = new ConcurrentHashMap<>();
    private final Set<Long> tickingLines = ConcurrentHashMap.newKeySet();
    private final ConcurrentHashMap<Long, ReentrantLock> startLocks = new ConcurrentHashMap<>();
    private volatile boolean shuttingDown = false;

    public SimulatorManager(WorkstationService workstationService,
                            ProductionLineService productionLineService,
                            SimulatorConfig config,
                            LineBroadcaster lineBroadcaster,
                            SimulatorTickService tickService,
                            @Lazy WorkOrderService workOrderService) {
        this.workstationService = workstationService;
        this.productionLineService = productionLineService;
        this.config = config;
        this.lineBroadcaster = lineBroadcaster;
        this.tickService = tickService;
        this.workOrderService = workOrderService;
    }

    /**
     * 启动产线仿真。幂等：已运行的产线再次调用会抛异常。
     */
    public void start(Long lineId, Long workOrderId) {
        if (shuttingDown) {
            throw new BusinessException(503, "仿真器正在关闭，拒绝新任务");
        }

        ReentrantLock lock = startLocks.computeIfAbsent(lineId, k -> new ReentrantLock());
        lock.lock();
        try {
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
                    .eq(Workstation::getIsDeleted, 0)
                    .list();
            if (stations == null || stations.isEmpty()) {
                throw new BusinessException(422, "产线 " + lineId + " 下没有工作站，无法启动仿真");
            }

            for (Workstation ws : stations) {
                ws.setDeviceStatus("运行中");
            }
            workstationService.updateBatchById(stations);

            LineSimulator simulator = new LineSimulator(lineId, workOrderId, stations,
                    Collections.emptyList(), config.getGoodRate());
            simulators.put(lineId, simulator);

            lineBroadcaster.broadcastLineStatus(lineId, "生产中", workOrderId, 0, 0, "生产中");

            ScheduledFuture<?> future = scheduler.scheduleAtFixedRate(
                    () -> tick(lineId), 0, config.getTickInterval(), TimeUnit.MILLISECONDS);

            runningSimulators.put(lineId, future);

            log.info("产线 {} 仿真已启动，工单: {}, Tick 间隔: {}ms", lineId, workOrderId, config.getTickInterval());
        } finally {
            lock.unlock();
        }
    }

    /**
     * 停止产线仿真，产线置为"暂停"。
     */
    public void stop(Long lineId) {
        stop(lineId, "暂停");
    }

    /**
     * 停止产线仿真并指定最终产线状态。
     * 即使仿真器未运行，也仍然更新产线和工作站到目标状态（幂等）。
     */
    public void stop(Long lineId, String finalStatus) {
        ScheduledFuture<?> future = runningSimulators.remove(lineId);
        if (future != null) {
            future.cancel(false);
        }
        simulators.remove(lineId);
        if (future != null) {
            waitForTickCompletion(lineId);
        }

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, lineId)
                .eq(Workstation::getIsDeleted, 0)
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
            boolean updated = productionLineService.updateById(line);
            log.info("产线 {} 状态更新为 {}, 结果: {}", lineId, finalStatus, updated);
        } else {
            log.warn("产线 {} 不存在，无法更新状态", lineId);
        }

        int finished = stations.stream().mapToInt(ws -> ws.getFinishedCount() != null ? ws.getFinishedCount() : 0).sum();
        int ng = stations.stream().mapToInt(ws -> ws.getNgCount() != null ? ws.getNgCount() : 0).sum();
        Long woId = line != null ? line.getCurrentWorkorderId() : null;
        lineBroadcaster.broadcastLineStatus(lineId, finalStatus, woId, finished, ng, "暂停中");

        log.info("产线 {} 仿真已停止，最终状态: {}, 已处理: {}, NG: {}", lineId, finalStatus, finished, ng);
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
                .eq(Workstation::getIsDeleted, 0)
                .list();
        for (Workstation ws : stations) {
            ws.setDeviceStatus("待机");
        }
        workstationService.updateBatchById(stations);

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, lineId)
                .one();
        if (line != null) {
            boolean updated = productionLineService.lambdaUpdate()
                    .eq(ProductionLine::getId, lineId)
                    .set(ProductionLine::getStatus, "空闲")
                    .set(ProductionLine::getCurrentWorkorderId, null)
                    .update();
            log.info("产线 {} 复位, currentWorkorderId 清空结果: {}", lineId, updated);
        }

        lineBroadcaster.broadcastLineStatus(lineId, "空闲", null, 0, 0, null);

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
     * 等待当前正在执行的 Tick 完成，防止 stop/reset 与 tick 的 DB 写入竞争。
     */
    private void waitForTickCompletion(Long lineId) {
        while (tickingLines.contains(lineId)) {
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
        }
    }

    private void tick(Long lineId) {
        LineSimulator simulator = simulators.get(lineId);
        if (simulator == null) {
            return;
        }

        tickingLines.add(lineId);
        boolean completed = false;
        try {
            List<Workstation> fresh = workstationService.lambdaQuery()
                    .eq(Workstation::getProductionLineId, lineId)
                    .eq(Workstation::getIsDeleted, 0)
                    .list();
            simulator.replaceStations(fresh);

            List<StationState> states = simulator.tick();

            tickService.persistTick(lineId, simulator, states);

            lineBroadcaster.broadcastStationUpdate(lineId, states);

            completed = checkProductionComplete(lineId, simulator);
        } catch (Exception e) {
            log.error("产线 {} Tick 异常", lineId, e);
        } finally {
            tickingLines.remove(lineId);
        }

        if (completed) {
            markCompleted(lineId, simulator);
        }
    }

    /**
     * 检测产量达标。达标则调用 autoComplete 落库，返回 true。
     * 注意：不在此处清理内存（tick finally 之后由 markCompleted 处理）。
     */
    private boolean checkProductionComplete(Long lineId, LineSimulator simulator) {
        try {
            List<Workstation> stations = simulator.getStations();
            if (stations.isEmpty()) {
                return false;
            }
            Workstation lastStation = stations.get(stations.size() - 1);
            int finished = lastStation.getFinishedCount() != null ? lastStation.getFinishedCount() : 0;
            Long woId = simulator.getWorkOrderId();
            int planQty = workOrderService.lambdaQuery()
                    .eq(WorkOrder::getId, woId)
                    .select(WorkOrder::getPlanQty)
                    .oneOpt()
                    .map(w -> w.getPlanQty() != null ? w.getPlanQty() : Integer.MAX_VALUE)
                    .orElse(Integer.MAX_VALUE);

            if (finished >= planQty) {
                log.info("产线 {} 产量达标 ({}>={})，自动完工", lineId, finished, planQty);
                workOrderService.autoComplete(woId);
                return true;
            }
        } catch (Exception e) {
            log.error("产线 {} 完工检测异常", lineId, e);
        }
        return false;
    }

    /**
     * 完工后清理：取消定时器 + 工作站置待机 + 广播。
     * 在 tick 的 finally 之后调用，避免 waitForTickCompletion 死锁。
     */
    private void markCompleted(Long lineId, LineSimulator simulator) {
        ScheduledFuture<?> future = runningSimulators.remove(lineId);
        if (future != null) {
            future.cancel(false);
        }
        simulators.remove(lineId);

        List<Workstation> stations = simulator.getStations();
        for (Workstation ws : stations) {
            ws.setDeviceStatus("待机");
        }
        workstationService.updateBatchById(stations);

        int finished = stations.get(stations.size() - 1).getFinishedCount() != null
                ? stations.get(stations.size() - 1).getFinishedCount() : 0;
        int ng = stations.get(stations.size() - 1).getNgCount() != null
                ? stations.get(stations.size() - 1).getNgCount() : 0;
        Long woId = simulator.getWorkOrderId();
        lineBroadcaster.broadcastLineStatus(lineId, "空闲", woId, finished, ng, "生产完成");

        log.info("产线 {} 完工清理完成，良品: {}, NG: {}", lineId, finished, ng);
    }

    @PreDestroy
    public void shutdown() {
        shuttingDown = true;
        log.info("正在关闭仿真器管理器，共 {} 条产线运行中", runningSimulators.size());
        runningSimulators.forEach((lineId, future) -> {
            future.cancel(false);
            log.info("已取消产线 {} 的仿真任务", lineId);
        });

        scheduler.shutdown();
        try {
            if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }

        runningSimulators.clear();
        simulators.clear();
    }
}
