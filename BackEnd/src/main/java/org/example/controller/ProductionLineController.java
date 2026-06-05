package org.example.controller;

import org.example.dto.request.LineStartRequest;
import org.example.dto.response.R;
import org.example.entity.Process;
import org.example.entity.Product;
import org.example.entity.ProductionLine;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.entity.Workshop;
import org.example.exception.BusinessException;
import org.example.security.RequiresPermission;
import org.example.service.ProcessService;
import org.example.service.ProductService;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderService;
import org.example.service.WorkshopService;
import org.example.service.WorkstationService;
import org.example.simulator.LineSimulator;
import org.example.simulator.SimulatorManager;
import org.example.vo.LineDetailVO;
import org.example.vo.ProductionLineVO;
import org.example.vo.StationVO;
import org.example.websocket.LineBroadcaster;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
public class ProductionLineController {

    private final ProductionLineService productionLineService;
    private final SimulatorManager simulatorManager;
    private final WorkOrderService workOrderService;
    private final LineBroadcaster lineBroadcaster;
    private final WorkshopService workshopService;
    private final WorkstationService workstationService;
    private final ProductService productService;
    private final ProcessService processService;

    public ProductionLineController(ProductionLineService productionLineService,
                                     SimulatorManager simulatorManager,
                                     WorkOrderService workOrderService,
                                     LineBroadcaster lineBroadcaster,
                                     WorkshopService workshopService,
                                     WorkstationService workstationService,
                                     ProductService productService,
                                     ProcessService processService) {
        this.productionLineService = productionLineService;
        this.simulatorManager = simulatorManager;
        this.workOrderService = workOrderService;
        this.lineBroadcaster = lineBroadcaster;
        this.workshopService = workshopService;
        this.workstationService = workstationService;
        this.productService = productService;
        this.processService = processService;
    }

    @GetMapping("/lines")
    public R<List<ProductionLineVO>> list(@RequestParam(required = false) Long workshopId,
                                          @RequestParam(required = false) String status) {
        var query = productionLineService.lambdaQuery()
                .eq(ProductionLine::getIsDeleted, 0);
        if (workshopId != null) {
            query.eq(ProductionLine::getWorkshopId, workshopId);
        }
        if (status != null && !status.isEmpty()) {
            query.eq(ProductionLine::getStatus, status);
        }
        List<ProductionLine> lines = query.list();

        // Workshop names
        Map<Long, String> workshopNames = Collections.emptyMap();
        if (!lines.isEmpty()) {
            List<Long> workshopIds = lines.stream()
                    .map(ProductionLine::getWorkshopId)
                    .filter(id -> id != null && id > 0)
                    .distinct()
                    .collect(Collectors.toList());
            if (!workshopIds.isEmpty()) {
                workshopNames = workshopService.lambdaQuery()
                        .in(Workshop::getId, workshopIds)
                        .list()
                        .stream()
                        .collect(Collectors.toMap(Workshop::getId, Workshop::getName));
            }
        }

        // Station aggregation per line
        List<Long> lineIds = lines.stream().map(ProductionLine::getId).collect(Collectors.toList());
        Map<Long, List<Workstation>> stationsByLine = Collections.emptyMap();
        if (!lineIds.isEmpty()) {
            stationsByLine = workstationService.lambdaQuery()
                    .in(Workstation::getProductionLineId, lineIds)
                    .eq(Workstation::getIsDeleted, 0)
                    .list()
                    .stream()
                    .collect(Collectors.groupingBy(Workstation::getProductionLineId));
        }

        // Active work orders per line — 按 currentWorkorderId 查找，不做状态过滤
        Map<Long, WorkOrder> activeOrders = Collections.emptyMap();
        if (!lineIds.isEmpty()) {
            List<Long> woIds = lines.stream()
                    .map(ProductionLine::getCurrentWorkorderId)
                    .filter(id -> id != null && id > 0)
                    .distinct()
                    .collect(Collectors.toList());
            if (!woIds.isEmpty()) {
                activeOrders = workOrderService.lambdaQuery()
                        .in(WorkOrder::getId, woIds)
                        .list()
                        .stream()
                        .collect(Collectors.toMap(WorkOrder::getLineId, wo -> wo, (a, b) -> a));
            }
        }

        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        Map<Long, String> finalWorkshopNames = workshopNames;
        Map<Long, List<Workstation>> finalStationsByLine = stationsByLine;
        Map<Long, WorkOrder> finalActiveOrders = activeOrders;

        List<ProductionLineVO> vos = lines.stream().map(line -> {
            ProductionLineVO vo = new ProductionLineVO();
            vo.setId(line.getId());
            vo.setName(line.getName());
            vo.setWorkshopId(line.getWorkshopId());
            vo.setStatus(line.getStatus());
            vo.setWorkshopName(finalWorkshopNames.getOrDefault(line.getWorkshopId(), ""));
            if (line.getCreatedAt() != null) {
                vo.setCreatedAt(line.getCreatedAt().format(fmt));
            }

            List<Workstation> lineStations = finalStationsByLine.getOrDefault(line.getId(), Collections.emptyList());
            vo.setStationCount(lineStations.size());
            // 流水线产出 = 最后工位(OP70)的良品/不良数
            Workstation lastStation = lineStations.stream()
                    .max((a, b) -> {
                        String ca = a.getCode() != null ? a.getCode() : "";
                        String cb = b.getCode() != null ? b.getCode() : "";
                        return ca.compareTo(cb);
                    })
                    .orElse(null);
            int finished = lastStation != null && lastStation.getFinishedCount() != null
                    ? lastStation.getFinishedCount() : 0;
            int ng = lastStation != null && lastStation.getNgCount() != null
                    ? lastStation.getNgCount() : 0;
            vo.setFinishedCount(finished);
            vo.setNgCount(ng);

            WorkOrder activeWo = finalActiveOrders.get(line.getId());
            if (activeWo != null) {
                vo.setWorkOrderCode(activeWo.getCode());
                vo.setPlanQty(activeWo.getPlanQty());
            }

            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }

    @GetMapping("/lines/{id}")
    public R<LineDetailVO> detail(@PathVariable Long id) {
        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, id)
                .eq(ProductionLine::getIsDeleted, 0)
                .one();
        if (line == null) {
            return R.error(404, "产线 " + id + " 不存在");
        }

        LineDetailVO vo = new LineDetailVO();
        vo.setId(line.getId());
        vo.setName(line.getName());
        vo.setWorkshopId(line.getWorkshopId());
        vo.setStatus(line.getStatus());
        vo.setCurrentProcessId(line.getCurrentProcessId());
        vo.setCurrentWorkorderId(line.getCurrentWorkorderId());
        if (line.getCreatedAt() != null) {
            vo.setCreatedAt(line.getCreatedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }

        if (line.getWorkshopId() != null) {
            Workshop workshop = workshopService.getById(line.getWorkshopId());
            if (workshop != null) {
                vo.setWorkshopName(workshop.getName());
            }
        }

        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getProductionLineId, id)
                .eq(Workstation::getIsDeleted, 0)
                .list();
        List<StationVO> stationVOs = new ArrayList<>();
        if (stations != null) {
            for (Workstation ws : stations) {
                StationVO sv = new StationVO();
                sv.setId(ws.getId());
                sv.setOpCode(ws.getCode());
                sv.setName(ws.getName());
                sv.setEquipmentCode(ws.getEquipmentCode());
                sv.setDeviceStatus(ws.getDeviceStatus());
                sv.setWorkStatus(ws.getWorkStatus());
                sv.setConveyorStatus(ws.getConveyorStatus());
                sv.setProcessedCount(ws.getProcessedCount() != null ? ws.getProcessedCount() : 0);
                sv.setRawCount(ws.getRawCount() != null ? ws.getRawCount() : 0);
                sv.setFinishedCount(ws.getFinishedCount() != null ? ws.getFinishedCount() : 0);
                sv.setNgCount(ws.getNgCount() != null ? ws.getNgCount() : 0);
                stationVOs.add(sv);
            }
        }
        vo.setStations(stationVOs);

        if (line.getCurrentWorkorderId() != null) {
            WorkOrder wo = workOrderService.getById(line.getCurrentWorkorderId());
            if (wo != null && wo.getIsDeleted() == 0) {
                LineDetailVO.WorkOrderSummary summary = new LineDetailVO.WorkOrderSummary();
                summary.setId(wo.getId());
                summary.setCode(wo.getCode());
                summary.setPlanQty(wo.getPlanQty());
                summary.setStatus(wo.getStatus());

                if (wo.getProductId() != null) {
                    Product product = productService.getById(wo.getProductId());
                    if (product != null) {
                        summary.setProductName(product.getName());
                    }
                }
                if (wo.getProcessId() != null) {
                    Process process = processService.getById(wo.getProcessId());
                    if (process != null) {
                        summary.setProcessName(process.getName());
                    }
                }

                vo.setActiveWorkOrder(summary);
            }
        }

        return R.ok(vo);
    }

    @PostMapping("/lines/{id}/start")
    @RequiresPermission("line.operate")
    public R<Void> start(@PathVariable Long id,
                         @Valid @RequestBody LineStartRequest request) {
        workOrderService.start(request.getWorkOrderId());
        simulatorManager.start(id, request.getWorkOrderId());
        return R.ok();
    }

    @PostMapping("/lines/{id}/stop")
    @RequiresPermission("line.operate")
    public R<Void> stop(@PathVariable Long id) {
        WorkOrder activeWo = workOrderService.lambdaQuery()
                .eq(WorkOrder::getLineId, id)
                .eq(WorkOrder::getStatus, "生产中")
                .one();

        simulatorManager.stop(id);

        if (activeWo != null && "生产中".equals(activeWo.getStatus())) {
            workOrderService.pause(activeWo.getId(), null);
        }

        return R.ok();
    }

    @PostMapping("/lines/{id}/reset")
    @RequiresPermission("line.operate")
    public R<Void> reset(@PathVariable Long id) {
        List<WorkOrder> activeWos = workOrderService.lambdaQuery()
                .eq(WorkOrder::getLineId, id)
                .in(WorkOrder::getStatus, "生产中", "暂停中")
                .list();
        if (!activeWos.isEmpty()) {
            throw new BusinessException(400, "产线有活跃工单，无法复位。请先停止生产或等待工单完成");
        }

        simulatorManager.reset(id);

        return R.ok();
    }

    @PostMapping("/lines/{id}/exception")
    @RequiresPermission("line.operate")
    public R<Void> reportException(@PathVariable Long id,
                                   @RequestBody Map<String, String> body) {
        String description = body != null ? body.get("description") : null;

        WorkOrder activeWo = workOrderService.lambdaQuery()
                .eq(WorkOrder::getLineId, id)
                .eq(WorkOrder::getStatus, "生产中")
                .one();

        simulatorManager.stop(id);

        if (activeWo != null) {
            workOrderService.pause(activeWo.getId(), description);
        }

        return R.ok();
    }
}
