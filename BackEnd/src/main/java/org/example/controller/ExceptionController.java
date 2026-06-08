package org.example.controller;

import org.example.dto.request.ExceptionHandleRequest;
import org.example.dto.request.ExceptionReportRequest;
import org.example.dto.response.R;
import org.example.entity.ProductionException;
import org.example.entity.ProductionLine;
import org.example.entity.User;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.security.RequiresPermission;
import org.example.service.ProductionExceptionService;
import org.example.service.ProductionLineService;
import org.example.service.UserService;
import org.example.service.WorkOrderService;
import org.example.service.WorkstationService;
import org.example.util.ControllerUtils;
import org.example.vo.ProductionExceptionVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
public class ExceptionController {

    private final ProductionExceptionService productionExceptionService;
    private final WorkOrderService workOrderService;
    private final ProductionLineService productionLineService;
    private final WorkstationService workstationService;
    private final UserService userService;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public ExceptionController(ProductionExceptionService productionExceptionService,
                               WorkOrderService workOrderService,
                               ProductionLineService productionLineService,
                               WorkstationService workstationService,
                               UserService userService) {
        this.productionExceptionService = productionExceptionService;
        this.workOrderService = workOrderService;
        this.productionLineService = productionLineService;
        this.workstationService = workstationService;
        this.userService = userService;
    }

    @PostMapping("/exceptions")
    @RequiresPermission("exception.report")
    public R<ProductionExceptionVO> report(@Valid @RequestBody ExceptionReportRequest request) {
        WorkOrder wo = workOrderService.lambdaQuery()
                .eq(WorkOrder::getId, request.getWorkOrderId())
                .eq(WorkOrder::getIsDeleted, 0)
                .one();
        if (wo == null) {
            return R.error(400, "工单不存在");
        }
        if (!"生产中".equals(wo.getStatus())) {
            return R.error(400, "只有\"生产中\"状态的工单才能上报异常，当前状态: " + wo.getStatus());
        }

        ProductionLine line = productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, request.getLineId())
                .eq(ProductionLine::getIsDeleted, 0)
                .one();
        if (line == null) {
            return R.error(400, "产线不存在");
        }

        Long reporterId = ControllerUtils.getCurrentUserId();
        ProductionException ex = productionExceptionService.reportException(
                request.getWorkOrderId(), request.getLineId(), request.getStationId(),
                request.getDescription(), reporterId);

        return R.ok(buildVO(ex, Map.of(wo.getId(), wo.getCode()),
                Map.of(line.getId(), line.getName()), Collections.emptyMap(),
                Collections.emptyMap(), Collections.emptyMap()));
    }

    @GetMapping("/exceptions")
    @RequiresPermission("exception.view")
    public R<List<ProductionExceptionVO>> list(@RequestParam(required = false) Boolean resolved) {
        var query = productionExceptionService.lambdaQuery()
                .eq(ProductionException::getIsDeleted, 0);
        if (resolved != null) {
            query.eq(ProductionException::getResolved, resolved ? 1 : 0);
        }
        List<ProductionException> list = query.orderByDesc(ProductionException::getReportTime).list();

        if (list.isEmpty()) {
            return R.ok(Collections.emptyList());
        }

        List<Long> woIds = list.stream().map(ProductionException::getWorkOrderId).distinct().collect(Collectors.toList());
        List<Long> lineIds = list.stream().map(ProductionException::getLineId).distinct().collect(Collectors.toList());
        List<Long> stationIds = list.stream().map(ProductionException::getStationId)
                .filter(id -> id != null).distinct().collect(Collectors.toList());
        List<Long> userIds = list.stream().flatMap(e -> {
            List<Long> ids = new ArrayList<>();
            if (e.getReporterId() != null) ids.add(e.getReporterId());
            if (e.getHandledBy() != null) ids.add(e.getHandledBy());
            return ids.stream();
        }).distinct().collect(Collectors.toList());

        Map<Long, String> woCodes = workOrderService.lambdaQuery()
                .in(WorkOrder::getId, woIds)
                .list().stream()
                .collect(Collectors.toMap(WorkOrder::getId, w -> w.getCode() != null ? w.getCode() : ""));
        Map<Long, String> lineNames = productionLineService.lambdaQuery()
                .in(ProductionLine::getId, lineIds)
                .list().stream()
                .collect(Collectors.toMap(ProductionLine::getId, l -> l.getName() != null ? l.getName() : ""));
        Map<Long, String> stationNames = stationIds.isEmpty() ? Collections.emptyMap() :
                workstationService.lambdaQuery()
                        .in(Workstation::getId, stationIds)
                        .list().stream()
                        .collect(Collectors.toMap(Workstation::getId, w -> w.getName() != null ? w.getName() : ""));
        Map<Long, String> userNames = userIds.isEmpty() ? Collections.emptyMap() :
                userService.lambdaQuery()
                        .in(User::getId, userIds)
                        .list().stream()
                        .collect(Collectors.toMap(User::getId, u -> u.getName() != null ? u.getName() : ""));

        List<ProductionExceptionVO> vos = list.stream()
                .map(e -> buildVO(e, woCodes, lineNames, stationNames, userNames, userNames))
                .collect(Collectors.toList());
        return R.ok(vos);
    }

    @GetMapping("/exceptions/{id}")
    @RequiresPermission("exception.view")
    public R<ProductionExceptionVO> detail(@PathVariable Long id) {
        ProductionException ex = productionExceptionService.lambdaQuery()
                .eq(ProductionException::getId, id)
                .eq(ProductionException::getIsDeleted, 0)
                .one();
        if (ex == null) {
            return R.error(404, "异常记录不存在");
        }

        Map<Long, String> woCodes = fetchWorkOrderCode(ex.getWorkOrderId());
        Map<Long, String> lineNames = fetchLineName(ex.getLineId());
        Map<Long, String> stationNames = ex.getStationId() != null ? fetchStationName(ex.getStationId()) : Collections.emptyMap();
        Map<Long, String> userNames = fetchUserNames(ex.getReporterId(), ex.getHandledBy());

        return R.ok(buildVO(ex, woCodes, lineNames, stationNames, userNames, userNames));
    }

    @PostMapping("/exceptions/{id}/handle")
    @RequiresPermission("exception.handle")
    public R<ProductionExceptionVO> handle(@PathVariable Long id,
                                           @Valid @RequestBody ExceptionHandleRequest request) {
        Long handlerId = ControllerUtils.getCurrentUserId();
        ProductionException ex = productionExceptionService.handleException(id, request.getAction(), handlerId);

        Map<Long, String> woCodes = fetchWorkOrderCode(ex.getWorkOrderId());
        Map<Long, String> lineNames = fetchLineName(ex.getLineId());
        Map<Long, String> stationNames = ex.getStationId() != null ? fetchStationName(ex.getStationId()) : Collections.emptyMap();
        Map<Long, String> userNames = fetchUserNames(ex.getReporterId(), ex.getHandledBy());

        return R.ok(buildVO(ex, woCodes, lineNames, stationNames, userNames, userNames));
    }

    private ProductionExceptionVO buildVO(ProductionException e,
                                           Map<Long, String> woCodes,
                                           Map<Long, String> lineNames,
                                           Map<Long, String> stationNames,
                                           Map<Long, String> reporterNames,
                                           Map<Long, String> handlerNames) {
        ProductionExceptionVO vo = new ProductionExceptionVO();
        vo.setId(e.getId());
        vo.setWorkOrderId(e.getWorkOrderId());
        vo.setWorkOrderCode(woCodes.getOrDefault(e.getWorkOrderId(), ""));
        vo.setLineId(e.getLineId());
        vo.setLineName(lineNames.getOrDefault(e.getLineId(), ""));
        vo.setStationId(e.getStationId());
        vo.setStationName(e.getStationId() != null ? stationNames.getOrDefault(e.getStationId(), "") : null);
        vo.setReporterId(e.getReporterId());
        vo.setReporterName(reporterNames.getOrDefault(e.getReporterId(), ""));
        vo.setReportTime(e.getReportTime() != null ? e.getReportTime().format(FMT) : null);
        vo.setDescription(e.getDescription());
        vo.setHandledBy(e.getHandledBy());
        vo.setHandlerName(e.getHandledBy() != null ? handlerNames.getOrDefault(e.getHandledBy(), "") : null);
        vo.setHandleTime(e.getHandleTime() != null ? e.getHandleTime().format(FMT) : null);
        vo.setHandleAction(e.getHandleAction());
        vo.setResolved(e.getResolved());
        vo.setCreatedAt(e.getCreatedAt() != null ? e.getCreatedAt().format(FMT) : null);
        return vo;
    }

    private Map<Long, String> fetchWorkOrderCode(Long woId) {
        if (woId == null) return Collections.emptyMap();
        return workOrderService.lambdaQuery()
                .eq(WorkOrder::getId, woId)
                .list().stream()
                .collect(Collectors.toMap(WorkOrder::getId, w -> w.getCode() != null ? w.getCode() : ""));
    }

    private Map<Long, String> fetchLineName(Long lineId) {
        if (lineId == null) return Collections.emptyMap();
        return productionLineService.lambdaQuery()
                .eq(ProductionLine::getId, lineId)
                .list().stream()
                .collect(Collectors.toMap(ProductionLine::getId, l -> l.getName() != null ? l.getName() : ""));
    }

    private Map<Long, String> fetchStationName(Long stationId) {
        if (stationId == null) return Collections.emptyMap();
        return workstationService.lambdaQuery()
                .eq(Workstation::getId, stationId)
                .list().stream()
                .collect(Collectors.toMap(Workstation::getId, w -> w.getName() != null ? w.getName() : ""));
    }

    private Map<Long, String> fetchUserNames(Long... userIds) {
        List<Long> ids = new ArrayList<>();
        for (Long id : userIds) {
            if (id != null) ids.add(id);
        }
        if (ids.isEmpty()) return Collections.emptyMap();
        return userService.lambdaQuery()
                .in(User::getId, ids)
                .list().stream()
                .collect(Collectors.toMap(User::getId, u -> u.getName() != null ? u.getName() : ""));
    }
}
