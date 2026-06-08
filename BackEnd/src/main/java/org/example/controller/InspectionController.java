package org.example.controller;

import org.example.dto.request.InspectionCreateRequest;
import org.example.dto.response.R;
import org.example.entity.InspectionRecord;
import org.example.entity.Process;
import org.example.entity.Product;
import org.example.entity.WorkOrder;
import org.example.security.RequiresPermission;
import org.example.service.InspectionRecordService;
import org.example.service.ProcessService;
import org.example.service.ProductService;
import org.example.service.WorkOrderService;
import org.example.util.ControllerUtils;
import org.example.vo.InspectionRecordVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
public class InspectionController {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final InspectionRecordService inspectionRecordService;
    private final WorkOrderService workOrderService;
    private final ProductService productService;
    private final ProcessService processService;

    public InspectionController(InspectionRecordService inspectionRecordService,
                                WorkOrderService workOrderService,
                                ProductService productService,
                                ProcessService processService) {
        this.inspectionRecordService = inspectionRecordService;
        this.workOrderService = workOrderService;
        this.productService = productService;
        this.processService = processService;
    }

    @PostMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<InspectionRecordVO> create(@Valid @RequestBody InspectionCreateRequest request) {
        Long inspectorId = ControllerUtils.getCurrentUserId();
        InspectionRecord record = inspectionRecordService.inspect(request, inspectorId);
        return R.ok(enrichVO(record));
    }

    @GetMapping("/inspections")
    @RequiresPermission("inspection.create")
    public R<List<InspectionRecordVO>> list(@RequestParam(required = false) Long workOrderId) {
        var query = inspectionRecordService.lambdaQuery()
                .eq(InspectionRecord::getIsDeleted, 0);
        if (workOrderId != null) {
            query.eq(InspectionRecord::getWorkOrderId, workOrderId);
        }
        List<InspectionRecord> records = query.orderByDesc(InspectionRecord::getInspectTime)
                .orderByDesc(InspectionRecord::getId)
                .list();

        if (records.isEmpty()) {
            return R.ok(Collections.emptyList());
        }

        // 批量查工单
        List<Long> woIds = records.stream().map(InspectionRecord::getWorkOrderId).distinct().toList();
        Map<Long, WorkOrder> woMap = workOrderService.lambdaQuery()
                .in(WorkOrder::getId, woIds).list().stream()
                .collect(Collectors.toMap(WorkOrder::getId, w -> w));

        // 批量查产品
        List<Long> productIds = woMap.values().stream().map(WorkOrder::getProductId)
                .filter(id -> id != null).distinct().collect(Collectors.toList());
        Map<Long, String> productNames = productIds.isEmpty() ? Collections.emptyMap() :
                productService.lambdaQuery().in(Product::getId, productIds).list().stream()
                        .collect(Collectors.toMap(Product::getId, p -> p.getName() != null ? p.getName() : ""));

        // 批量查工序
        List<Long> processIds = woMap.values().stream().map(WorkOrder::getProcessId)
                .filter(id -> id != null).distinct().collect(Collectors.toList());
        Map<Long, String> processNames = processIds.isEmpty() ? Collections.emptyMap() :
                processService.lambdaQuery().in(Process::getId, processIds).list().stream()
                        .collect(Collectors.toMap(Process::getId, p -> p.getName() != null ? p.getName() : ""));

        List<InspectionRecordVO> vos = records.stream()
                .map(r -> enrichVO(r, woMap, productNames, processNames))
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
        return R.ok(enrichVO(record));
    }

    @PutMapping("/inspections/{id}")
    @RequiresPermission("inspection.create")
    public R<InspectionRecordVO> submit(@PathVariable Long id,
                                         @Valid @RequestBody InspectionCreateRequest request) {
        Long inspectorId = ControllerUtils.getCurrentUserId();
        InspectionRecord record = inspectionRecordService.submitInspection(id, request, inspectorId);
        return R.ok(enrichVO(record));
    }

    private InspectionRecordVO enrichVO(InspectionRecord r) {
        WorkOrder wo = workOrderService.getById(r.getWorkOrderId());
        Map<Long, WorkOrder> woMap = wo != null
                ? Map.of(wo.getId(), wo)
                : Collections.emptyMap();
        Map<Long, String> productNames = Collections.emptyMap();
        Map<Long, String> processNames = Collections.emptyMap();
        if (wo != null) {
            if (wo.getProductId() != null) {
                Product product = productService.getById(wo.getProductId());
                if (product != null) productNames = Map.of(product.getId(), product.getName() != null ? product.getName() : "");
            }
            if (wo.getProcessId() != null) {
                Process process = processService.getById(wo.getProcessId());
                if (process != null) processNames = Map.of(process.getId(), process.getName() != null ? process.getName() : "");
            }
        }
        return enrichVO(r, woMap, productNames, processNames);
    }

    private InspectionRecordVO enrichVO(InspectionRecord r, Map<Long, WorkOrder> woMap,
                                         Map<Long, String> productNames, Map<Long, String> processNames) {
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
        vo.setStatus(r.getStatus());

        WorkOrder wo = woMap.get(r.getWorkOrderId());
        if (wo != null) {
            vo.setWorkOrderCode(wo.getCode());
            vo.setReportedQtyGood(wo.getReportedQtyGood());
            vo.setReportedQtyNg(wo.getReportedQtyNg());
            vo.setPlanQty(wo.getPlanQty());
            if (wo.getProductId() != null) {
                vo.setProductName(productNames.getOrDefault(wo.getProductId(), ""));
            }
            if (wo.getProcessId() != null) {
                vo.setProcessName(processNames.getOrDefault(wo.getProcessId(), ""));
            }
        }
        return vo;
    }
}
