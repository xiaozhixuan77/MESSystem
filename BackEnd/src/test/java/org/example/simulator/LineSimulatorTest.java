package org.example.simulator;

import org.example.entity.Workstation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@DisplayName("LineSimulator 仿真核心")
class LineSimulatorTest {

    private static final Long LINE_ID = 1L;
    private static final Long WORK_ORDER_ID = 100L;

    private List<Workstation> stations;
    private LineSimulator simulator;

    private Workstation createStation(Long id, String code, String name, String deviceStatus) {
        return new Workstation()
                .setId(id)
                .setCode(code)
                .setName(name)
                .setDeviceStatus(deviceStatus);
    }

    @Nested
    @DisplayName("Tick 计数器递增")
    class CounterIncrement {

        @BeforeEach
        void setUp() {
            stations = new ArrayList<>();
            stations.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            stations.add(createStation(2L, "WS-OP20", "主板组装", "运行中"));
            stations.add(createStation(3L, "WS-OP30", "后盖组装", "运行中"));
            simulator = new LineSimulator(LINE_ID, WORK_ORDER_ID, stations,
                    Collections.emptyList(), 1.0);
        }

        @Test
        @DisplayName("null 计数器初始值视为 0 → Tick 后为 1")
        void nullCountersStartAtOne() {
            List<StationState> states = simulator.tick();

            for (StationState s : states) {
                assertEquals(1, s.getProcessedCount(), s.getCode() + " processedCount");
                assertEquals(1, s.getRawCount(), s.getCode() + " rawCount");
                assertEquals(1, s.getFinishedCount(), s.getCode() + " finishedCount");
            }
        }

        @Test
        @DisplayName("连续 Tick 计数器逐次累加")
        void consecutiveTicksAccumulate() {
            simulator.tick(); // first
            List<StationState> states = simulator.tick(); // second

            for (StationState s : states) {
                assertEquals(2, s.getProcessedCount(), s.getCode() + " processedCount");
                assertEquals(2, s.getRawCount(), s.getCode() + " rawCount");
            }
        }

        @Test
        @DisplayName("Tick 返回与 stations 等量的状态快照")
        void returnsAllStations() {
            List<StationState> states = simulator.tick();
            assertEquals(3, stations.size());
            assertEquals(3, states.size());
        }
    }

    @Nested
    @DisplayName("设备状态过滤")
    class DeviceStatusFilter {

        @BeforeEach
        void setUp() {
            stations = new ArrayList<>();
            stations.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            stations.add(createStation(2L, "WS-OP20", "主板组装", "待机"));
            stations.add(createStation(3L, "WS-OP30", "后盖组装", "故障"));
            simulator = new LineSimulator(LINE_ID, WORK_ORDER_ID, stations,
                    Collections.emptyList(), 1.0);
        }

        @Test
        @DisplayName("仅“运行中”的工作站计数递增")
        void onlyRunningStationsAdvance() {
            List<StationState> states = simulator.tick();

            // OP10 运行中 → 计数为 1
            StationState op10 = states.get(0);
            assertEquals(1, op10.getProcessedCount());
            assertEquals(1, op10.getFinishedCount());

            // OP20 待机 → 计数为 0
            StationState op20 = states.get(1);
            assertEquals(0, op20.getProcessedCount());
            assertEquals(0, op20.getFinishedCount());

            // OP30 故障 → 计数为 0
            StationState op30 = states.get(2);
            assertEquals(0, op30.getProcessedCount());
            assertEquals(0, op30.getFinishedCount());
        }

        @Test
        @DisplayName("非运行中工作站保留原有 deviceStatus")
        void nonRunningStationsPreserveStatus() {
            List<StationState> states = simulator.tick();

            assertEquals("待机", states.get(1).getDeviceStatus());
            assertEquals("故障", states.get(2).getDeviceStatus());
        }

        @Test
        @DisplayName("deviceStatus 为 null 时安全跳过（不 NPE）")
        void nullDeviceStatusIsSafe() {
            stations.get(0).setDeviceStatus(null);
            List<StationState> states = simulator.tick();
            assertEquals(0, states.get(0).getProcessedCount());
        }
    }

    @Nested
    @DisplayName("良品率模拟")
    class GoodRate {

        @BeforeEach
        void setUp() {
            stations = new ArrayList<>();
            stations.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            simulator = new LineSimulator(LINE_ID, WORK_ORDER_ID, stations,
                    Collections.emptyList(), 1.0);
        }

        @Test
        @DisplayName("良品率 1.0 → 全部良品，NG 为 0")
        void perfectGoodRateAllGood() {
            LineSimulator perfectSim = new LineSimulator(LINE_ID, WORK_ORDER_ID, stations,
                    Collections.emptyList(), 1.0);
            List<StationState> states = perfectSim.tick();

            for (StationState s : states) {
                assertEquals(1, s.getFinishedCount(), s.getCode() + " finishedCount");
                assertEquals(0, s.getNgCount(), s.getCode() + " ngCount");
            }
        }

        @Test
        @DisplayName("良品率 0.0 → 全部 NG，finished 为 0")
        void zeroGoodRateAllNg() {
            // 重新创建独立 station 避免前一个测试的状态污染
            List<Workstation> fresh = new ArrayList<>();
            fresh.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            LineSimulator zeroSim = new LineSimulator(LINE_ID, WORK_ORDER_ID, fresh,
                    Collections.emptyList(), 0.0);
            List<StationState> states = zeroSim.tick();

            for (StationState s : states) {
                assertEquals(0, s.getFinishedCount(), s.getCode() + " finishedCount");
                assertEquals(1, s.getNgCount(), s.getCode() + " ngCount");
            }
        }

        @Test
        @DisplayName("良品率 0.5 大量采样近似 50% 良品")
        void approximateHalfGoodRate() {
            List<Workstation> fresh = new ArrayList<>();
            fresh.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            LineSimulator halfSim = new LineSimulator(LINE_ID, WORK_ORDER_ID, fresh,
                    Collections.emptyList(), 0.5);

            int totalFinished = 0;
            int totalNg = 0;
            int iterations = 10000;

            for (int i = 0; i < iterations; i++) {
                halfSim.tick();
                // 使用 Workstation 上的累计值减去上一次
            }

            // 检查最终累计值
            List<Workstation> result = halfSim.getStations();
            totalFinished = result.get(0).getFinishedCount();
            totalNg = result.get(0).getNgCount();

            assertEquals(iterations, totalFinished + totalNg);
            // 95% 置信区间: 0.5 ± 0.05 for 10000 samples
            double ratio = (double) totalFinished / iterations;
            assertTrue(ratio > 0.40, "良品率应 > 40%, 实际: " + ratio);
            assertTrue(ratio < 0.60, "良品率应 < 60%, 实际: " + ratio);
        }
    }

    @Nested
    @DisplayName("状态查询方法")
    class Getters {

        @BeforeEach
        void setUp() {
            stations = new ArrayList<>();
            stations.add(createStation(1L, "WS-OP10", "上料", "运行中"));
            simulator = new LineSimulator(LINE_ID, WORK_ORDER_ID, stations,
                    Collections.emptyList(), 0.95);
        }

        @Test
        @DisplayName("getLineId / getWorkOrderId / getGoodRate 返回构造参数")
        void basicGetters() {
            assertEquals(LINE_ID, simulator.getLineId());
            assertEquals(WORK_ORDER_ID, simulator.getWorkOrderId());
            assertEquals(0.95, simulator.getGoodRate());
        }

        @Test
        @DisplayName("getStations 返回注入的工作站列表")
        void getStationsReturnsInjectedList() {
            assertEquals(stations, simulator.getStations());
            assertEquals(1, simulator.getStations().size());
        }

        @Test
        @DisplayName("currentOpIndex 默认 0，可 set/get")
        void currentOpIndexDefaultZero() {
            assertEquals(0, simulator.getCurrentOpIndex());
            simulator.setCurrentOpIndex(3);
            assertEquals(3, simulator.getCurrentOpIndex());
        }

        @Test
        @DisplayName("productSnCounter 默认 0，incrementProductSn 递增")
        void productSnCounterIncrement() {
            assertEquals(0, simulator.getProductSnCounter());
            assertEquals(1, simulator.incrementProductSn());
            assertEquals(1, simulator.getProductSnCounter());
            assertEquals(2, simulator.incrementProductSn());
        }
    }

    @Nested
    @DisplayName("边界情况")
    class EdgeCases {

        @Test
        @DisplayName("空工作站列表 — Tick 返回空列表")
        void emptyStations() {
            LineSimulator sim = new LineSimulator(LINE_ID, WORK_ORDER_ID,
                    Collections.emptyList(), Collections.emptyList(), 0.95);
            List<StationState> states = sim.tick();
            assertNotNull(states);
            assertTrue(states.isEmpty());
        }

        @Test
        @DisplayName("StationState 链式 setter 正常工作")
        void stationStateChainSetters() {
            StationState state = new StationState()
                    .setStationId(1L)
                    .setCode("WS-OP10")
                    .setName("上料")
                    .setDeviceStatus("运行中")
                    .setProcessedCount(5)
                    .setRawCount(5)
                    .setFinishedCount(4)
                    .setNgCount(1);

            assertEquals(1L, state.getStationId());
            assertEquals("WS-OP10", state.getCode());
            assertEquals("上料", state.getName());
            assertEquals("运行中", state.getDeviceStatus());
            assertEquals(5, state.getProcessedCount());
            assertEquals(5, state.getRawCount());
            assertEquals(4, state.getFinishedCount());
            assertEquals(1, state.getNgCount());
        }
    }
}
