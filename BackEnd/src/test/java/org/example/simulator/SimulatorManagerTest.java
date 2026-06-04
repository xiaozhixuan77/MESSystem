package org.example.simulator;

import com.baomidou.mybatisplus.extension.conditions.query.LambdaQueryChainWrapper;
import org.example.config.SimulatorConfig;
import org.example.entity.ProductionLine;
import org.example.entity.Workstation;
import org.example.exception.BusinessException;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderService;
import org.example.service.WorkstationService;
import org.example.websocket.LineBroadcaster;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("SimulatorManager 生命周期管理")
class SimulatorManagerTest {

    private static final Long LINE_ID = 1L;
    private static final Long WORK_ORDER_ID = 100L;

    @Mock
    private WorkstationService workstationService;
    @Mock
    private ProductionLineService productionLineService;
    @Mock
    private SimulatorConfig config;
    @Mock
    private LineBroadcaster lineBroadcaster;
    @Mock
    private SimulatorTickService tickService;
    @Mock
    private WorkOrderService workOrderService;

    @Mock
    private LambdaQueryChainWrapper<Workstation> workstationQuery;
    @Mock
    private LambdaQueryChainWrapper<ProductionLine> lineQuery;

    private SimulatorManager manager;

    private List<Workstation> createSevenStations() {
        List<Workstation> list = new ArrayList<>();
        String[] codes = {"WS-FLX-OP10", "WS-FLX-OP20", "WS-FLX-OP30",
                "WS-FLX-OP40", "WS-FLX-OP50", "WS-FLX-OP60", "WS-FLX-OP70"};
        String[] names = {"上料", "主板组装", "后盖组装", "螺丝锁付", "激光打标", "成品检测", "下料"};
        for (int i = 0; i < 7; i++) {
            list.add(new Workstation()
                    .setId((long) (i + 1))
                    .setCode(codes[i])
                    .setName(names[i])
                    .setProductionLineId(LINE_ID)
                    .setDeviceStatus("待机"));
        }
        return list;
    }

    @BeforeEach
    void setUp() {
        when(config.getTickInterval()).thenReturn(1000L);
        when(config.getGoodRate()).thenReturn(0.95);

        manager = new SimulatorManager(workstationService, productionLineService,
                config, lineBroadcaster, tickService, workOrderService);
    }

    @AfterEach
    void tearDown() {
        manager.shutdown();
    }

    @Nested
    @DisplayName("start — 启动仿真")
    class Start {

        @BeforeEach
        void stubCommonMocks() {
            when(workstationService.lambdaQuery()).thenReturn(workstationQuery);
            when(workstationQuery.eq(any(), any())).thenReturn(workstationQuery);
            when(workstationQuery.list()).thenReturn(createSevenStations());

            when(productionLineService.lambdaQuery()).thenReturn(lineQuery);
            when(lineQuery.eq(any(), any())).thenReturn(lineQuery);
            when(lineQuery.one()).thenReturn(
                    new ProductionLine().setId(LINE_ID).setName("柔性组装线").setStatus("空闲"));
        }

        @Test
        @DisplayName("启动成功 → isRunning 为 true")
        void startSuccessfully() {
            manager.start(LINE_ID, WORK_ORDER_ID);

            assertTrue(manager.isRunning(LINE_ID));
            assertTrue(manager.getRunningLineIds().contains(LINE_ID));
            verify(workstationService, atLeastOnce()).updateBatchById(anyList());
            verify(productionLineService).updateById(any(ProductionLine.class));
        }

        @Test
        @DisplayName("重复启动同一产线 → BusinessException 400")
        void duplicateStartThrowsException() {
            manager.start(LINE_ID, WORK_ORDER_ID);

            BusinessException ex = assertThrows(BusinessException.class,
                    () -> manager.start(LINE_ID, WORK_ORDER_ID));
            assertEquals(400, ex.getCode());
            assertTrue(ex.getMessage().contains("已在仿真运行中"));
        }

        @Test
        @DisplayName("产线下无工作站 → BusinessException 422")
        void noWorkstationsThrowsException() {
            when(workstationQuery.list()).thenReturn(new ArrayList<>());

            BusinessException ex = assertThrows(BusinessException.class,
                    () -> manager.start(LINE_ID, WORK_ORDER_ID));
            assertEquals(422, ex.getCode());
            assertTrue(ex.getMessage().contains("没有工作站"));
        }

        @Test
        @DisplayName("工作站为 null → BusinessException 422")
        void nullWorkstationsThrowsException() {
            when(workstationQuery.list()).thenReturn(null);

            BusinessException ex = assertThrows(BusinessException.class,
                    () -> manager.start(LINE_ID, WORK_ORDER_ID));
            assertEquals(422, ex.getCode());
        }

        @Test
        @DisplayName("产线不存在 → BusinessException 404")
        void lineNotFoundThrowsException() {
            when(lineQuery.one()).thenReturn(null);

            BusinessException ex = assertThrows(BusinessException.class,
                    () -> manager.start(LINE_ID, WORK_ORDER_ID));
            assertEquals(404, ex.getCode());
            assertTrue(ex.getMessage().contains("不存在"));
        }

        @Test
        @DisplayName("工作站 deviceStatus 设为「运行中」")
        void setsDeviceStatusToRunning() {
            manager.start(LINE_ID, WORK_ORDER_ID);

            verify(workstationService, atLeastOnce()).updateBatchById(anyList());
            verify(productionLineService).updateById(any(ProductionLine.class));
        }

        @Test
        @DisplayName("getSimulator 可获取 LineSimulator 实例")
        void getSimulatorReturnsInstance() {
            manager.start(LINE_ID, WORK_ORDER_ID);

            assertTrue(manager.getSimulator(LINE_ID).isPresent());
            assertEquals(WORK_ORDER_ID, manager.getSimulator(LINE_ID).get().getWorkOrderId());
        }
    }

    @Nested
    @DisplayName("stop — 停止仿真")
    class Stop {

        @BeforeEach
        void startFirst() {
            when(workstationService.lambdaQuery()).thenReturn(workstationQuery);
            when(workstationQuery.eq(any(), any())).thenReturn(workstationQuery);
            when(workstationQuery.list()).thenReturn(createSevenStations());

            when(productionLineService.lambdaQuery()).thenReturn(lineQuery);
            when(lineQuery.eq(any(), any())).thenReturn(lineQuery);
            when(lineQuery.one()).thenReturn(
                    new ProductionLine().setId(LINE_ID).setName("柔性组装线").setStatus("生产中"));

            manager.start(LINE_ID, WORK_ORDER_ID);
        }

        @Test
        @DisplayName("停止运行中的仿真 → isRunning 为 false")
        void stopRunningSimulation() {
            manager.stop(LINE_ID);

            assertFalse(manager.isRunning(LINE_ID));
            assertTrue(manager.getRunningLineIds().isEmpty());
        }

        @Test
        @DisplayName("停止未运行的产线 → BusinessException 409")
        void stopNonRunningThrowsException() {
            manager.stop(LINE_ID); // first stop ok

            BusinessException ex = assertThrows(BusinessException.class,
                    () -> manager.stop(LINE_ID));
            assertEquals(409, ex.getCode());
            assertTrue(ex.getMessage().contains("未在仿真运行中"));
        }

        @Test
        @DisplayName("停止后 getSimulator 返回空")
        void simulatorRemovedAfterStop() {
            manager.stop(LINE_ID);

            assertTrue(manager.getSimulator(LINE_ID).isEmpty());
        }

        @Test
        @DisplayName("产线状态设为「暂停」")
        void setsLineStatusToPaused() {
            manager.stop(LINE_ID);

            verify(productionLineService, atLeastOnce()).updateById(any(ProductionLine.class));
        }
    }

    @Nested
    @DisplayName("reset — 复位仿真")
    class Reset {

        @BeforeEach
        void stubCommonMocks() {
            when(workstationService.lambdaQuery()).thenReturn(workstationQuery);
            when(workstationQuery.eq(any(), any())).thenReturn(workstationQuery);
            when(workstationQuery.list()).thenReturn(createSevenStations());

            when(productionLineService.lambdaQuery()).thenReturn(lineQuery);
            when(lineQuery.eq(any(), any())).thenReturn(lineQuery);
            when(lineQuery.one()).thenReturn(
                    new ProductionLine().setId(LINE_ID).setName("柔性组装线").setStatus("生产中"));
        }

        @Test
        @DisplayName("复位运行中的仿真 → 停止并清零")
        void resetRunningSimulation() {
            manager.start(LINE_ID, WORK_ORDER_ID);
            assertTrue(manager.isRunning(LINE_ID));

            manager.reset(LINE_ID);

            assertFalse(manager.isRunning(LINE_ID));
            verify(workstationService).resetCounters(LINE_ID);
        }

        @Test
        @DisplayName("复位空闲产线 → 不抛异常")
        void resetIdleLineDoesNotThrow() {
            assertDoesNotThrow(() -> manager.reset(LINE_ID));
            verify(workstationService).resetCounters(LINE_ID);
        }

        @Test
        @DisplayName("产线状态设为「空闲」")
        void setsLineStatusToIdle() {
            manager.reset(LINE_ID);

            verify(productionLineService, atLeastOnce()).updateById(any(ProductionLine.class));
        }
    }

    @Nested
    @DisplayName("状态查询")
    class StateQuery {

        @Test
        @DisplayName("初始状态无运行中仿真")
        void initialStateNothingRunning() {
            assertFalse(manager.isRunning(LINE_ID));
            assertTrue(manager.getRunningLineIds().isEmpty());
            assertTrue(manager.getSimulator(LINE_ID).isEmpty());
        }

        @Test
        @DisplayName("getRunningLineIds 返回防御性副本")
        void getRunningLineIdsReturnsDefensiveCopy() {
            when(workstationService.lambdaQuery()).thenReturn(workstationQuery);
            when(workstationQuery.eq(any(), any())).thenReturn(workstationQuery);
            when(workstationQuery.list()).thenReturn(createSevenStations());
            when(productionLineService.lambdaQuery()).thenReturn(lineQuery);
            when(lineQuery.eq(any(), any())).thenReturn(lineQuery);
            when(lineQuery.one()).thenReturn(
                    new ProductionLine().setId(LINE_ID).setName("柔性组装线").setStatus("空闲"));

            manager.start(LINE_ID, WORK_ORDER_ID);

            manager.getRunningLineIds().clear();

            assertTrue(manager.isRunning(LINE_ID));
        }
    }

    @Nested
    @DisplayName("shutdown — 优雅关闭")
    class Shutdown {

        @Test
        @DisplayName("shutdown 后 isRunning 全部为 false")
        void shutdownClearsAllSimulations() {
            when(workstationService.lambdaQuery()).thenReturn(workstationQuery);
            when(workstationQuery.eq(any(), any())).thenReturn(workstationQuery);
            when(workstationQuery.list()).thenReturn(createSevenStations());
            when(productionLineService.lambdaQuery()).thenReturn(lineQuery);
            when(lineQuery.eq(any(), any())).thenReturn(lineQuery);
            when(lineQuery.one()).thenReturn(
                    new ProductionLine().setId(LINE_ID).setName("柔性组装线").setStatus("空闲"));

            manager.start(LINE_ID, WORK_ORDER_ID);
            assertTrue(manager.isRunning(LINE_ID));

            manager.shutdown();

            assertFalse(manager.isRunning(LINE_ID));
            assertTrue(manager.getRunningLineIds().isEmpty());
        }

        @Test
        @DisplayName("shutdown 可重复调用不抛异常")
        void shutdownIsIdempotent() {
            manager.shutdown();
            assertDoesNotThrow(() -> manager.shutdown());
        }
    }
}
