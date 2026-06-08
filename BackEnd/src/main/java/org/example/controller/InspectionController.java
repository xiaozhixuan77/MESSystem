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
import org.springframework.web.bind.annotation.PathVariable;
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

        if (!"已报工".equals(wo.getStatus())) {
            return R.error(400, "只能对已报工的工单进行抽检，当前状态: " + wo.getStatus());
        }

        Integer sampleQty = toInt(body.get("sampleQty"));
        if (sampleQty == null) {
            return R.error(400, "抽检数量不能为空");
        }
        Integer sampleGood = toInt(body.get("sampleGood"));
        if (sampleGood == null) sampleGood = 0;
        Integer sampleNg = toInt(body.get("sampleNg"));
        if (sampleNg == null) sampleNg = 0;

        if (sampleGood + sampleNg != sampleQty) {
            return R.error(400, "良品数+不良品数必须等于抽检数量");
        }

        int minQty = Math.max(1, (int) Math.ceil(wo.getPlanQty() * 0.05));
        int maxQty = Math.max(1, (int) Math.floor(wo.getPlanQty() * 0.10));
        if (sampleQty < minQty || sampleQty > maxQty) {
            return R.error(400, "抽检数量必须在批次量的5%-10%之间（" + minQty + "-" + maxQty + "）");
        }

        Long inspectorId = getCurrentUserId();

        InspectionRecord record = new InspectionRecord();
        record.setWorkOrderId(workOrderId);
        record.setInspectorId(inspectorId);
        record.setInspectTime(LocalDateTime.now());
        record.setSampleQty(sampleQty);
        record.setSampleGood(sampleGood);
        record.setSampleNg(sampleNg);
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

    @GetMapping("/inspections/{id}")
    @RequiresPermission("inspection.create")
    public R<InspectionRecord> detail(@PathVariable Long id) {
        InspectionRecord record = inspectionRecordService.getById(id);
        if (record == null || record.getIsDeleted() == 1) {
            return R.error(404, "抽检记录不存在");
        }
        return R.ok(record);
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
