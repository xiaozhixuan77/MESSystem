package org.example.simulator;

import org.example.entity.ProcessStep;
import org.example.entity.Workstation;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 单产线仿真核心 — 每个"生产中"的产线持有一个独立的 LineSimulator 实例。
 *
 * 7 工作站固定顺序: OP10 上料 → OP20 主板组装 → OP30 后盖组装 → OP40 螺丝锁付 →
 *                     OP50 激光打标 → OP60 成品检测 → OP70 下料
 */
public class LineSimulator {

    private final Long lineId;
    private final Long workOrderId;
    private final List<Workstation> stations;
    private final List<ProcessStep> processSteps;
    private final double goodRate;
    private int currentOpIndex = 0;
    private int productSnCounter = 0;

    public LineSimulator(Long lineId, Long workOrderId, List<Workstation> stations,
                         List<ProcessStep> processSteps, double goodRate) {
        this.lineId = lineId;
        this.workOrderId = workOrderId;
        this.stations = stations;
        this.processSteps = processSteps;
        this.goodRate = goodRate;
    }

    /**
     * 每次 Tick 推进各工作站计数器，按良品率随机决定良品/NG。
     *
     * @return 本次 Tick 后所有工作站的状态快照
     */
    public List<StationState> tick() {
        List<StationState> states = new ArrayList<>(stations.size());

        for (Workstation ws : stations) {
            if (!"运行中".equals(ws.getDeviceStatus())) {
                states.add(new StationState()
                        .setStationId(ws.getId())
                        .setOpCode(ws.getCode())
                        .setName(ws.getName())
                        .setDeviceStatus(ws.getDeviceStatus())
                        .setProcessedCount(ws.getProcessedCount() == null ? 0 : ws.getProcessedCount())
                        .setRawCount(ws.getRawCount() == null ? 0 : ws.getRawCount())
                        .setFinishedCount(ws.getFinishedCount() == null ? 0 : ws.getFinishedCount())
                        .setNgCount(ws.getNgCount() == null ? 0 : ws.getNgCount()));
                continue;
            }

            int newProcessed = ws.getProcessedCount() == null ? 1 : ws.getProcessedCount() + 1;
            int newRaw = ws.getRawCount() == null ? 1 : ws.getRawCount() + 1;
            boolean isGood = ThreadLocalRandom.current().nextDouble() <= goodRate;

            ws.setProcessedCount(newProcessed);
            ws.setRawCount(newRaw);
            if (isGood) {
                ws.setFinishedCount(ws.getFinishedCount() == null ? 1 : ws.getFinishedCount() + 1);
            } else {
                ws.setNgCount(ws.getNgCount() == null ? 1 : ws.getNgCount() + 1);
            }

            states.add(new StationState()
                    .setStationId(ws.getId())
                    .setOpCode(ws.getCode())
                    .setName(ws.getName())
                    .setDeviceStatus(ws.getDeviceStatus())
                    .setProcessedCount(newProcessed)
                    .setRawCount(newRaw)
                    .setFinishedCount(ws.getFinishedCount() == null ? 0 : ws.getFinishedCount())
                    .setNgCount(ws.getNgCount() == null ? 0 : ws.getNgCount()));
        }

        return states;
    }

    public Long getLineId() {
        return lineId;
    }

    public Long getWorkOrderId() {
        return workOrderId;
    }

    public List<Workstation> getStations() {
        return Collections.unmodifiableList(stations);
    }

    public void replaceStations(List<Workstation> freshStations) {
        this.stations.clear();
        this.stations.addAll(freshStations);
    }

    public List<ProcessStep> getProcessSteps() {
        return processSteps;
    }

    public double getGoodRate() {
        return goodRate;
    }

    public int getCurrentOpIndex() {
        return currentOpIndex;
    }

    public void setCurrentOpIndex(int currentOpIndex) {
        this.currentOpIndex = currentOpIndex;
    }

    public int getProductSnCounter() {
        return productSnCounter;
    }

    public int incrementProductSn() {
        return ++productSnCounter;
    }
}
