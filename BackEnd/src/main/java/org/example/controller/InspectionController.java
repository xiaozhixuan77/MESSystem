package org.example.controller;

import org.example.dto.response.R;
import org.example.entity.InspectionRecord;
import org.example.entity.WorkOrder;
import org.example.security.RequiresPermission;
import org.example.service.InspectionRecordService;
import org.example.service.WorkOrderService;
import org.example.websocket.LineBroadcaster;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
public class InspectionController {

    private final InspectionRecordService inspectionRecordService;
    private final WorkOrderService workOrderService;
    private final LineBroadcaster lineBroadcaster;

    public InspectionController(InspectionRecordService inspectionRecordService,
                                 WorkOrderService workOrderService,
                                 LineBroadcaster lineBroadcaster) {
        this.inspectionRecordService = inspectionRecordService;
        this.workOrderService = workOrderService;
        this.lineBroadcaster = lineBroadcaster;
    }

    @PostMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<Void> create(@RequestBody Map<String, Object> body) {
        Long workOrderId = toLong(body.get("workOrderId"));
        if (workOrderId == null) {
            return R.error(400, "workOrderId 不能为空");
        }

        WorkOrder wo = workOrderService.getById(workOrderId);
        if (wo == null) {
            return R.error(404, "工单不存在");
        }

        Long inspectorId = getCurrentUserId();

        InspectionRecord record = new InspectionRecord();
        record.setWorkOrderId(workOrderId);
        record.setInspectorId(inspectorId);
        record.setInspectTime(LocalDateTime.now());
        record.setSampleQty(toInt(body.get("sampleQty")));
        record.setSampleGood(toInt(body.get("sampleGood")));
        record.setSampleNg(toInt(body.get("sampleNg")));
        record.setDefectTypes((String) body.get("defectTypes"));
        record.setDefectDescription((String) body.get("defectDescription"));
        record.setConclusion((String) body.get("conclusion"));
        inspectionRecordService.save(record);

        Map<String, Object> extra = Map.of(
                "inspectionId", record.getId(),
                "conclusion", record.getConclusion() != null ? record.getConclusion() : ""
        );
        lineBroadcaster.broadcastWorkOrderUpdate(wo.getLineId(), wo.getId(), wo.getCode(),
                "已报工", extra);

        return R.ok();
    }

    @GetMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<List<InspectionRecord>> list(@RequestParam(required = false) Long workOrderId) {
        var query = inspectionRecordService.lambdaQuery()
                .eq(InspectionRecord::getIsDeleted, 0);
        if (workOrderId != null) {
            query.eq(InspectionRecord::getWorkOrderId, workOrderId);
        }
        return R.ok(query.orderByDesc(InspectionRecord::getInspectTime).list());
    }

    private Long getCurrentUserId() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof UserDetails userDetails) {
            return Long.valueOf(userDetails.getUsername());
        }
        return null;
    }

    private Long toLong(Object value) {
        if (value instanceof Number n) return n.longValue();
        if (value instanceof String s) return Long.parseLong(s);
        return null;
    }

    private Integer toInt(Object value) {
        if (value instanceof Number n) return n.intValue();
        if (value instanceof String s) return Integer.parseInt(s);
        return null;
    }
}
