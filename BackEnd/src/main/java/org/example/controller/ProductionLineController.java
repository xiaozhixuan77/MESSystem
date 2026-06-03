package org.example.controller;

import org.example.dto.request.LineStartRequest;
import org.example.dto.response.R;
import org.example.entity.ProductionLine;
import org.example.entity.WorkOrder;
import org.example.security.RequiresPermission;
import org.example.service.ProductionLineService;
import org.example.service.WorkOrderService;
import org.example.simulator.SimulatorManager;
import org.example.vo.ProductionLineVO;
import org.example.websocket.LineBroadcaster;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
public class ProductionLineController {

    private final ProductionLineService productionLineService;
    private final SimulatorManager simulatorManager;
    private final WorkOrderService workOrderService;
    private final LineBroadcaster lineBroadcaster;

    public ProductionLineController(ProductionLineService productionLineService,
                                     SimulatorManager simulatorManager,
                                     WorkOrderService workOrderService,
                                     LineBroadcaster lineBroadcaster) {
        this.productionLineService = productionLineService;
        this.simulatorManager = simulatorManager;
        this.workOrderService = workOrderService;
        this.lineBroadcaster = lineBroadcaster;
    }

    @GetMapping("/lines")
    public R<List<ProductionLineVO>> list(@RequestParam(required = false) Long workshopId) {
        var query = productionLineService.lambdaQuery()
                .eq(ProductionLine::getIsDeleted, 0);
        if (workshopId != null) {
            query.eq(ProductionLine::getWorkshopId, workshopId);
        }
        List<ProductionLine> lines = query.list();
        List<ProductionLineVO> vos = lines.stream().map(line -> {
            ProductionLineVO vo = new ProductionLineVO();
            vo.setId(line.getId());
            vo.setName(line.getName());
            vo.setWorkshopId(line.getWorkshopId());
            return vo;
        }).collect(Collectors.toList());
        return R.ok(vos);
    }

    @PostMapping("/lines/{id}/start")
    @RequiresPermission("line.operate")
    public R<Void> start(@PathVariable Long id,
                         @Valid @RequestBody LineStartRequest request) {
        simulatorManager.start(id, request.getWorkOrderId());
        return R.ok();
    }

    @PostMapping("/lines/{id}/stop")
    @RequiresPermission("line.operate")
    public R<Void> stop(@PathVariable Long id) {
        WorkOrder activeWo = workOrderService.lambdaQuery()
                .eq(WorkOrder::getLineId, id)
                .in(WorkOrder::getStatus, "生产中", "暂停中")
                .one();

        if (activeWo != null) {
            simulatorManager.stop(id, "空闲");

            activeWo.setStatus("生产完成");
            activeWo.setActualEndTime(LocalDateTime.now());
            workOrderService.updateById(activeWo);

            ProductionLine line = productionLineService.getById(id);
            if (line != null) {
                line.setCurrentWorkorderId(null);
                productionLineService.updateById(line);
            }
        } else {
            simulatorManager.stop(id);
        }

        return R.ok();
    }

    @PostMapping("/lines/{id}/reset")
    @RequiresPermission("line.operate")
    public R<Void> reset(@PathVariable Long id) {
        simulatorManager.reset(id);
        return R.ok();
    }
}
