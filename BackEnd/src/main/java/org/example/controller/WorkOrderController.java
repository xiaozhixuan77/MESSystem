package org.example.controller;

import org.example.dto.request.DispatchRequest;
import org.example.dto.request.WorkOrderCreateRequest;
import org.example.dto.request.WorkOrderUpdateRequest;
import org.example.dto.request.WorkOrderPauseRequest;
import org.example.dto.request.WorkOrderReportRequest;
import org.example.dto.request.WorkOrderScrapRequest;
import org.example.dto.response.R;
import org.example.entity.Process;
import org.example.entity.Product;
import org.example.entity.ProductionLine;
import org.example.entity.User;
import org.example.entity.WorkOrder;
import org.example.entity.Workshop;
import org.example.entity.WorkOrderRouteStep;
import org.example.entity.Workstation;
import org.example.security.RequiresPermission;
import org.example.service.WorkshopService;
import org.example.service.ProductionLineService;
import org.example.service.ProcessService;
import org.example.service.ProductService;
import org.example.service.UserService;
import org.example.service.WorkOrderRouteStepService;
import org.example.service.WorkOrderService;
import org.example.service.WorkstationService;
import org.example.simulator.SimulatorManager;
import org.example.vo.WorkOrderDetailVO;
import org.example.vo.WorkOrderRouteStepVO;
import org.example.vo.WorkOrderVO;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
public class WorkOrderController {

    private final WorkOrderService workOrderService;
    private final UserService userService;
    private final ProductService productService;
    private final ProcessService processService;
    private final WorkOrderRouteStepService workOrderRouteStepService;
    private final WorkshopService workshopService;
    private final ProductionLineService productionLineService;
    private final SimulatorManager simulatorManager;
    private final WorkstationService workstationService;

    public WorkOrderController(WorkOrderService workOrderService,
                               UserService userService,
                               ProductService productService,
                               ProcessService processService,
                               WorkOrderRouteStepService workOrderRouteStepService,
                               WorkshopService workshopService,
                               ProductionLineService productionLineService,
                               SimulatorManager simulatorManager,
                               WorkstationService workstationService) {
        this.workOrderService = workOrderService;
        this.userService = userService;
        this.productService = productService;
        this.processService = processService;
        this.workOrderRouteStepService = workOrderRouteStepService;
        this.workshopService = workshopService;
        this.productionLineService = productionLineService;
        this.simulatorManager = simulatorManager;
        this.workstationService = workstationService;
    }

    @GetMapping("/workorders")
    public R<List<WorkOrderVO>> list(@RequestParam(required = false) String status,
                                     @RequestParam(required = false) String type,
                                     @RequestParam(required = false) Long lineId) {
        User currentUser = getCurrentUser();
        if (currentUser == null) {
            return R.error(401, "未登录");
        }

        List<WorkOrder> orders = workOrderService.listWorkOrders(
                currentUser.getRole(), currentUser.getId(), currentUser.getWorkshopId(),
                status, type, lineId);

        return R.ok(buildWorkOrderVOs(orders));
    }

    @GetMapping("/workorders/all")
    @RequiresPermission("workorder.view_team")
    public R<List<WorkOrderVO>> listAll(@RequestParam(required = false) String status,
                                         @RequestParam(required = false) String type,
                                         @RequestParam(required = false) Long lineId,
                                         @RequestParam(required = false) String keyword) {
        List<WorkOrder> orders = workOrderService.listAllWorkOrders(status, type, lineId, keyword);
        return R.ok(buildWorkOrderVOs(orders));
    }

    @PostMapping("/workorders")
    @RequiresPermission("workorder.create")
    public R<WorkOrderDetailVO> create(@Valid @RequestBody WorkOrderCreateRequest request) {
        User currentUser = getCurrentUser();
        WorkOrder wo = workOrderService.createWorkOrder(request, currentUser.getId());
        return R.ok(toWorkOrderDetailVO(wo));
    }

    @PostMapping(value = "/workorders", params = "copyFrom")
    @RequiresPermission("workorder.create")
    public R<WorkOrderDetailVO> copy(@RequestParam Long copyFrom,
                                     @RequestBody(required = false) WorkOrderCreateRequest request) {
        User currentUser = getCurrentUser();
        WorkOrder wo = workOrderService.copyWorkOrder(copyFrom, request, currentUser.getId());
        return R.ok(toWorkOrderDetailVO(wo));
    }

    @PutMapping("/workorders/{id}")
    @RequiresPermission("workorder.create")
    public R<WorkOrderDetailVO> update(@PathVariable Long id,
                                       @Valid @RequestBody WorkOrderUpdateRequest request) {
        WorkOrder wo = workOrderService.updateWorkOrder(id, request);
        return R.ok(toWorkOrderDetailVO(wo));
    }

    @GetMapping("/workorders/{id}")
    public R<WorkOrderDetailVO> detail(@PathVariable Long id) {
        WorkOrder wo = workOrderService.getWorkOrderDetail(id);
        return R.ok(toWorkOrderDetailVO(wo));
    }

    @PostMapping("/workorders/{id}/dispatch")
    @RequiresPermission("workorder.dispatch")
    public R<Void> dispatch(@PathVariable Long id,
                            @Valid @RequestBody DispatchRequest request) {
        workOrderService.dispatch(id, request.getOperatorId());
        return R.ok();
    }

    @PostMapping("/workorders/{id}/start")
    @RequiresPermission("workorder.start")
    public R<Void> start(@PathVariable Long id) {
        workOrderService.start(id);

        WorkOrder wo = workOrderService.getById(id);
        if (wo != null && wo.getLineId() != null) {
            simulatorManager.start(wo.getLineId(), id);
        }

        return R.ok();
    }

    @PostMapping("/workorders/{id}/complete")
    @RequiresPermission("workorder.complete")
    public R<Void> complete(@PathVariable Long id) {
        workOrderService.complete(id);
        return R.ok();
    }

    @PostMapping("/workorders/{id}/pause")
    @RequiresPermission("workorder.pause")
    public R<Void> pause(@PathVariable Long id,
                         @RequestBody(required = false) WorkOrderPauseRequest request) {
        String reason = request != null ? request.getReason() : null;
        workOrderService.pause(id, reason);
        return R.ok();
    }

    @PostMapping("/workorders/{id}/resume")
    @RequiresPermission("workorder.resume")
    public R<Void> resume(@PathVariable Long id) {
        workOrderService.resume(id);

        WorkOrder wo = workOrderService.getById(id);
        if (wo != null && wo.getLineId() != null) {
            simulatorManager.start(wo.getLineId(), id);
        }

        return R.ok();
    }

    @PostMapping("/workorders/{id}/report")
    @RequiresPermission("workorder.report")
    public R<Void> report(@PathVariable Long id,
                          @Valid @RequestBody WorkOrderReportRequest request) {
        workOrderService.report(id, request);
        return R.ok();
    }

    @PostMapping("/workorders/{id}/confirm")
    @RequiresPermission("workorder.confirm")
    public R<Void> confirm(@PathVariable Long id) {
        workOrderService.confirm(id);
        return R.ok();
    }

    @PostMapping("/workorders/{id}/scrap")
    @RequiresPermission("workorder.scrap")
    public R<Void> scrap(@PathVariable Long id,
                         @RequestBody(required = false) WorkOrderScrapRequest request) {
        String reason = request != null ? request.getReason() : null;
        workOrderService.scrap(id, reason);
        return R.ok();
    }

    @DeleteMapping("/workorders/{id}")
    @RequiresPermission("workorder.delete")
    public R<Void> delete(@PathVariable Long id) {
        workOrderService.deleteWorkOrder(id);
        return R.ok();
    }

    private WorkOrderVO toWorkOrderVO(WorkOrder wo, Map<Long, Product> productMap,
                                       Map<Long, User> userMap,
                                       Map<Long, Workshop> workshopMap,
                                       Map<Long, ProductionLine> lineMap) {
        WorkOrderVO vo = new WorkOrderVO();
        vo.setId(wo.getId());
        vo.setCode(wo.getCode());
        vo.setType(wo.getType());
        vo.setWorkshopId(wo.getWorkshopId());
        vo.setLineId(wo.getLineId());
        vo.setProductId(wo.getProductId());
        vo.setProcessId(wo.getProcessId());
        vo.setPlanQty(wo.getPlanQty());
        vo.setStatus(wo.getStatus());
        vo.setOperatorId(wo.getOperatorId());
        vo.setPlanStartTime(wo.getPlanStartTime());
        vo.setPlanEndTime(wo.getPlanEndTime());
        vo.setCreatedAt(wo.getCreatedAt());
        vo.setVersion(wo.getVersion());

        if (wo.getProductId() != null) {
            Product product = productMap.get(wo.getProductId());
            if (product != null) {
                vo.setProductName(product.getName());
            }
        }
        if (wo.getOperatorId() != null) {
            User operator = userMap.get(wo.getOperatorId());
            if (operator != null) {
                vo.setOperatorName(operator.getName());
            }
        }
        if (wo.getWorkshopId() != null) {
            Workshop workshop = workshopMap.get(wo.getWorkshopId());
            if (workshop != null) {
                vo.setWorkshopName(workshop.getName());
            }
        }
        if (wo.getLineId() != null) {
            ProductionLine line = lineMap.get(wo.getLineId());
            if (line != null) {
                vo.setLineName(line.getName());
            }
        }

        return vo;
    }

    private List<WorkOrderVO> buildWorkOrderVOs(List<WorkOrder> orders) {
        Set<Long> productIds = new HashSet<>();
        Set<Long> operatorIds = new HashSet<>();
        Set<Long> workshopIds = new HashSet<>();
        Set<Long> lineIds = new HashSet<>();

        for (WorkOrder wo : orders) {
            if (wo.getProductId() != null) productIds.add(wo.getProductId());
            if (wo.getOperatorId() != null) operatorIds.add(wo.getOperatorId());
            if (wo.getWorkshopId() != null) workshopIds.add(wo.getWorkshopId());
            if (wo.getLineId() != null) lineIds.add(wo.getLineId());
        }

        Map<Long, Product> productMap = productIds.isEmpty() ? Map.of()
                : productService.listByIds(productIds).stream()
                        .collect(Collectors.toMap(Product::getId, p -> p));
        Map<Long, User> userMap = operatorIds.isEmpty() ? Map.of()
                : userService.listByIds(operatorIds).stream()
                        .collect(Collectors.toMap(User::getId, u -> u));
        Map<Long, Workshop> workshopMap = workshopIds.isEmpty() ? Map.of()
                : workshopService.listByIds(workshopIds).stream()
                        .collect(Collectors.toMap(Workshop::getId, w -> w));
        Map<Long, ProductionLine> lineMap = lineIds.isEmpty() ? Map.of()
                : productionLineService.listByIds(lineIds).stream()
                        .collect(Collectors.toMap(ProductionLine::getId, l -> l));

        return orders.stream()
                .map(wo -> toWorkOrderVO(wo, productMap, userMap, workshopMap, lineMap))
                .collect(Collectors.toList());
    }

    private WorkOrderDetailVO toWorkOrderDetailVO(WorkOrder wo) {
        WorkOrderDetailVO vo = new WorkOrderDetailVO();
        vo.setId(wo.getId());
        vo.setCode(wo.getCode());
        vo.setType(wo.getType());
        vo.setWorkshopId(wo.getWorkshopId());
        vo.setLineId(wo.getLineId());
        vo.setProductId(wo.getProductId());
        vo.setProcessId(wo.getProcessId());
        vo.setPlanQty(wo.getPlanQty());
        vo.setStatus(wo.getStatus());
        vo.setOperatorId(wo.getOperatorId());
        vo.setPlanStartTime(wo.getPlanStartTime());
        vo.setPlanEndTime(wo.getPlanEndTime());
        vo.setCreatedAt(wo.getCreatedAt());
        vo.setVersion(wo.getVersion());

        vo.setSource(wo.getSource());
        vo.setDispatchTime(wo.getDispatchTime());
        vo.setActualStartTime(wo.getActualStartTime());
        vo.setActualEndTime(wo.getActualEndTime());
        vo.setPauseTime(wo.getPauseTime());
        vo.setReportedQtyGood(wo.getReportedQtyGood());
        vo.setReportedQtyNg(wo.getReportedQtyNg());
        vo.setReportedHours(wo.getReportedHours());
        vo.setExceptionNote(wo.getExceptionNote());
        vo.setCreatedBy(wo.getCreatedBy());
        vo.setSourceWorkorderId(wo.getSourceWorkorderId());

        if (wo.getProductId() != null) {
            Product product = productService.getById(wo.getProductId());
            if (product != null) {
                vo.setProductName(product.getName());
            }
        }
        if (wo.getProcessId() != null) {
            Process process = processService.getById(wo.getProcessId());
            if (process != null) {
                vo.setProcessName(process.getName());
            }
        }
        if (wo.getOperatorId() != null) {
            User operator = userService.getById(wo.getOperatorId());
            if (operator != null) {
                vo.setOperatorName(operator.getName());
            }
        }
        if (wo.getCreatedBy() != null) {
            User creator = userService.getById(wo.getCreatedBy());
            if (creator != null) {
                vo.setCreatedByName(creator.getName());
            }
        }
        if (wo.getWorkshopId() != null) {
            Workshop workshop = workshopService.getById(wo.getWorkshopId());
            if (workshop != null) {
                vo.setWorkshopName(workshop.getName());
            }
        }
        if (wo.getLineId() != null) {
            ProductionLine line = productionLineService.getById(wo.getLineId());
            if (line != null) {
                vo.setLineName(line.getName());
            }
        }

        List<WorkOrderRouteStep> steps = workOrderRouteStepService.lambdaQuery()
                .eq(WorkOrderRouteStep::getWorkOrderId, wo.getId())
                .orderByAsc(WorkOrderRouteStep::getSeqNo)
                .list();
        List<WorkOrderRouteStepVO> stepVOs = steps.stream().map(step -> {
            WorkOrderRouteStepVO stepVO = new WorkOrderRouteStepVO();
            stepVO.setId(step.getId());
            stepVO.setSeqNo(step.getSeqNo());
            stepVO.setOpCode(step.getOpCode());
            stepVO.setName(step.getName());
            stepVO.setStationId(step.getStationId());
            return stepVO;
        }).collect(Collectors.toList());

        // 聚合工站实时计数器
        if (wo.getLineId() != null) {
            List<Workstation> workstations = workstationService.lambdaQuery()
                    .eq(Workstation::getProductionLineId, wo.getLineId())
                    .eq(Workstation::getIsDeleted, 0)
                    .list();
            Map<Long, Workstation> stationMap = workstations.stream()
                    .collect(Collectors.toMap(Workstation::getId, w -> w));

            // 最后工序步骤对应的工站数据：总产出=良品+NG
            WorkOrderRouteStepVO lastStep = null;
            for (WorkOrderRouteStepVO sv : stepVOs) {
                if (lastStep == null || sv.getSeqNo() > lastStep.getSeqNo()) {
                    lastStep = sv;
                }
            }
            if (lastStep != null && lastStep.getStationId() != null) {
                Workstation lastStation = stationMap.get(lastStep.getStationId());
                if (lastStation != null) {
                    int lastFinished = lastStation.getFinishedCount() != null ? lastStation.getFinishedCount() : 0;
                    int lastNg = lastStation.getNgCount() != null ? lastStation.getNgCount() : 0;
                    vo.setStationTotalOutput(lastFinished + lastNg);
                    vo.setStationProcessedCount(lastStation.getProcessedCount());
                    vo.setStationTotalNg(lastNg);
                }
            }

            // 回填每个工序步骤的工站数据
            for (WorkOrderRouteStepVO sv : stepVOs) {
                if (sv.getStationId() != null) {
                    Workstation ws = stationMap.get(sv.getStationId());
                    if (ws != null) {
                        sv.setStationProcessedCount(ws.getProcessedCount());
                        sv.setStationFinishedCount(ws.getFinishedCount());
                        sv.setStationNgCount(ws.getNgCount());
                        sv.setStationDeviceStatus(ws.getDeviceStatus());
                    }
                }
            }

            // 计算已运行时长
            LocalDateTime startTime = wo.getActualStartTime();
            if (startTime != null) {
                LocalDateTime endTime;
                String status = wo.getStatus();
                if ("生产中".equals(status)) {
                    endTime = LocalDateTime.now();
                } else if ("暂停中".equals(status) && wo.getPauseTime() != null) {
                    endTime = wo.getPauseTime();
                } else if (("生产完成".equals(status) || "已报工".equals(status) || "完工".equals(status))
                        && wo.getActualEndTime() != null) {
                    endTime = wo.getActualEndTime();
                } else {
                    endTime = null;
                }
                if (endTime != null) {
                    vo.setElapsedSeconds(ChronoUnit.SECONDS.between(startTime, endTime));
                }
            }
        }

        vo.setRouteSteps(stepVOs);
        return vo;
    }

    private User getCurrentUser() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (!(principal instanceof UserDetails userDetails)) {
            return null;
        }
        Long userId = Long.valueOf(userDetails.getUsername());
        return userService.getById(userId);
    }
}
