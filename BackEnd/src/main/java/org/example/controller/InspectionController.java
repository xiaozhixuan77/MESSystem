package org.example.controller;

import org.example.dto.request.InspectionCreateRequest;
import org.example.dto.response.R;
import org.example.entity.InspectionRecord;
import org.example.security.RequiresPermission;
import org.example.service.InspectionRecordService;
import org.example.util.ControllerUtils;
import org.example.vo.InspectionRecordVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@RestController
public class InspectionController {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final InspectionRecordService inspectionRecordService;

    public InspectionController(InspectionRecordService inspectionRecordService) {
        this.inspectionRecordService = inspectionRecordService;
    }

    @PostMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<InspectionRecordVO> create(@Valid @RequestBody InspectionCreateRequest request) {
        Long inspectorId = ControllerUtils.getCurrentUserId();
        InspectionRecord record = inspectionRecordService.inspect(request, inspectorId);
        return R.ok(toVO(record));
    }

    @GetMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<List<InspectionRecordVO>> list(@RequestParam(required = false) Long workOrderId) {
        var query = inspectionRecordService.lambdaQuery()
                .eq(InspectionRecord::getIsDeleted, 0);
        if (workOrderId != null) {
            query.eq(InspectionRecord::getWorkOrderId, workOrderId);
        }
        List<InspectionRecordVO> vos = query.orderByDesc(InspectionRecord::getInspectTime)
                .list().stream()
                .map(this::toVO)
                .collect(Collectors.toList());
        return R.ok(vos);
    }

    @GetMapping("/inspections/{id}")
    @RequiresPermission("inspection.create")
    public R<InspectionRecordVO> detail(@PathVariable Long id) {
        InspectionRecord record = inspectionRecordService.getById(id);
        if (record == null || record.getIsDeleted() == 1) {
            return R.error(404, "抽检记录不存在");
        }
        return R.ok(toVO(record));
    }

    private InspectionRecordVO toVO(InspectionRecord r) {
        InspectionRecordVO vo = new InspectionRecordVO();
        vo.setId(r.getId());
        vo.setWorkOrderId(r.getWorkOrderId());
        vo.setInspectorId(r.getInspectorId());
        vo.setInspectTime(r.getInspectTime() != null ? r.getInspectTime().format(FMT) : null);
        vo.setSampleQty(r.getSampleQty());
        vo.setSampleGood(r.getSampleGood());
        vo.setSampleNg(r.getSampleNg());
        vo.setDefectTypes(r.getDefectTypes());
        vo.setDefectDescription(r.getDefectDescription());
        vo.setConclusion(r.getConclusion());
        return vo;
    }
}
