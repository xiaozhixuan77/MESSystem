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
import org.example.entity.User;
import org.example.entity.WorkOrder;
import org.example.entity.WorkOrderRouteStep;
import org.example.security.RequiresPermission;
import org.example.service.ProcessService;
import org.example.service.ProductService;
import org.example.service.UserService;
import org.example.service.WorkOrderRouteStepService;
import org.example.service.WorkOrderService;
import org.example.simulator.SimulatorManager;
import org.example.vo.WorkOrderDetailVO;
import org.example.vo.WorkOrderRouteStepVO;
import org.example.vo.WorkOrderVO;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
public class WorkOrderController {

    private final WorkOrderService workOrderService;
    private final UserService userService;
    private final ProductService productService;
    private final ProcessService processService;
    private final WorkOrderRouteStepService workOrderRouteStepService;
    private final SimulatorManager simulatorManager;

    public WorkOrderController(WorkOrderService workOrderService,
                               UserService userService,
                               ProductService productService,
                               ProcessService processService,
                               WorkOrderRouteStepService workOrderRouteStepService,
                               SimulatorManager simulatorManager) {
        this.workOrderService = workOrderService;
        this.userService = userService;
        this.productService = productService;
        this.processService = processService;
        this.workOrderRouteStepService = workOrderRouteStepService;
        this.simulatorManager = simulatorManager;
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

        Set<Long> productIds = orders.stream()
                .map(WorkOrder::getProductId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());
        Set<Long> operatorIds = orders.stream()
                .map(WorkOrder::getOperatorId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        Map<Long, Product> productMap = productIds.isEmpty() ? Map.of()
                : productService.listByIds(productIds).stream()
                        .collect(Collectors.toMap(Product::getId, p -> p));
        Map<Long, User> userMap = operatorIds.isEmpty() ? Map.of()
                : userService.listByIds(operatorIds).stream()
                        .collect(Collectors.toMap(User::getId, u -> u));

        List<WorkOrderVO> vos = orders.stream()
                .map(wo -> toWorkOrderVO(wo, productMap, userMap))
                .collect(Collectors.toList());
        return R.ok(vos);
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

    private WorkOrderVO toWorkOrderVO(WorkOrder wo, Map<Long, Product> productMap,
                                       Map<Long, User> userMap) {
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

        return vo;
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

        List<WorkOrderRouteStep> steps = workOrderRouteStepService.lambdaQuery()
                .eq(WorkOrderRouteStep::getWorkOrderId, wo.getId())
                .orderByAsc(WorkOrderRouteStep::getSeqNo)
                .list();
        vo.setRouteSteps(steps.stream().map(step -> {
            WorkOrderRouteStepVO stepVO = new WorkOrderRouteStepVO();
            stepVO.setId(step.getId());
            stepVO.setSeqNo(step.getSeqNo());
            stepVO.setOpCode(step.getOpCode());
            stepVO.setName(step.getName());
            stepVO.setStationId(step.getStationId());
            return stepVO;
        }).collect(Collectors.toList()));

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
