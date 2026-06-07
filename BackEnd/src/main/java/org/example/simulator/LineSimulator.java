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
    private final int planQty;
    private int currentOpIndex = 0;
    private int productSnCounter = 0;

    public LineSimulator(Long lineId, Long workOrderId, List<Workstation> stations,
                         List<ProcessStep> processSteps, double goodRate, int planQty) {
        this.lineId = lineId;
        this.workOrderId = workOrderId;
        this.stations = stations;
        this.processSteps = processSteps;
        this.goodRate = goodRate;
        this.planQty = planQty;
    }

    /**
     * 每个 Tick 推进一个新产品进入流水线（OP10 → OP20 → … → OP70）。
     * 工作站 i 的处理量 = max(0, productSnCounter - i)。
     * 良品率独立判定每个工作站每产品。
     *
     * @return 本次 Tick 后所有工作站的状态快照
     */
    public List<StationState> tick() {
        int sn = incrementProductSn();
        List<StationState> states = new ArrayList<>(stations.size());

        for (int i = 0; i < stations.size(); i++) {
            Workstation ws = stations.get(i);
            int processed = ws.getProcessedCount() == null ? 0 : ws.getProcessedCount();
            int raw = ws.getRawCount() == null ? 0 : ws.getRawCount();
            int finished = ws.getFinishedCount() == null ? 0 : ws.getFinishedCount();
            int ng = ws.getNgCount() == null ? 0 : ws.getNgCount();

            if ("运行中".equals(ws.getDeviceStatus()) && sn > i && processed < planQty) {
                processed++;
                raw++;
                boolean isGood = ThreadLocalRandom.current().nextDouble() <= goodRate;
                if (isGood) {
                    finished++;
                } else {
                    ng++;
                }
                ws.setProcessedCount(processed);
                ws.setRawCount(raw);
                ws.setFinishedCount(finished);
                ws.setNgCount(ng);
            }

            states.add(new StationState()
                    .setStationId(ws.getId())
                    .setOpCode(ws.getCode())
                    .setName(ws.getName())
                    .setDeviceStatus(ws.getDeviceStatus())
                    .setProcessedCount(processed)
                    .setRawCount(raw)
                    .setFinishedCount(finished)
                    .setNgCount(ng));
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
