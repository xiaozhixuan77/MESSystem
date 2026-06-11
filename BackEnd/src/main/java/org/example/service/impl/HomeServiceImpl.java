package org.example.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.example.entity.InspectionRecord;
import org.example.entity.ProductionException;
import org.example.entity.ProductionLine;
import org.example.entity.User;
import org.example.entity.WorkOrder;
import org.example.service.HomeService;
import org.example.service.InspectionRecordService;
import org.example.service.ProductionExceptionService;
import org.example.service.ProductionLineService;
import org.example.service.UserService;
import org.example.service.WorkOrderService;
import org.example.util.ControllerUtils;
import org.example.vo.HomeSummaryVO;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class HomeServiceImpl implements HomeService {

    private static final Set<String> ACTIVE_STATUSES = Set.of("待派工", "已派工", "生产中", "暂停中", "生产完成", "已报工");
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final WorkOrderService workOrderService;
    private final ProductionExceptionService productionExceptionService;
    private final InspectionRecordService inspectionRecordService;
    private final ProductionLineService productionLineService;
    private final UserService userService;

    public HomeServiceImpl(WorkOrderService workOrderService,
                           ProductionExceptionService productionExceptionService,
                           InspectionRecordService inspectionRecordService,
                           ProductionLineService productionLineService,
                           UserService userService) {
        this.workOrderService = workOrderService;
        this.productionExceptionService = productionExceptionService;
        this.inspectionRecordService = inspectionRecordService;
        this.productionLineService = productionLineService;
        this.userService = userService;
    }

    @Override
    public HomeSummaryVO getSummary() {
        HomeSummaryVO vo = new HomeSummaryVO();

        vo.setPendingExceptionCount(productionExceptionService.lambdaQuery()
                .eq(ProductionException::getResolved, 0)
                .eq(ProductionException::getIsDeleted, 0)
                .count());

        vo.setPendingDispatchCount(workOrderService.lambdaQuery()
                .eq(WorkOrder::getStatus, "待派工")
                .eq(WorkOrder::getIsDeleted, 0)
                .count());

        vo.setPendingInspectionCount(inspectionRecordService.lambdaQuery()
                .eq(InspectionRecord::getStatus, "待抽检")
                .eq(InspectionRecord::getIsDeleted, 0)
                .count());

        vo.setActiveWorkOrderCount(workOrderService.lambdaQuery()
                .in(WorkOrder::getStatus, ACTIVE_STATUSES)
                .eq(WorkOrder::getIsDeleted, 0)
                .count());

        vo.setTotalLineCount(productionLineService.lambdaQuery()
                .eq(ProductionLine::getIsDeleted, 0)
                .count());

        vo.setTotalUserCount(userService.lambdaQuery()
                .eq(User::getIsDeleted, 0)
                .count());

        // 最近未处理异常 top 5
        List<ProductionException> exceptions = productionExceptionService.lambdaQuery()
                .eq(ProductionException::getResolved, 0)
                .eq(ProductionException::getIsDeleted, 0)
                .orderByDesc(ProductionException::getReportTime)
                .last("LIMIT 5")
                .list();
        vo.setRecentExceptions(buildExceptionItems(exceptions));

        // 待派工工单 top 5
        List<WorkOrder> pendingDispatch = workOrderService.lambdaQuery()
                .eq(WorkOrder::getStatus, "待派工")
                .eq(WorkOrder::getIsDeleted, 0)
                .orderByAsc(WorkOrder::getCreatedAt)
                .last("LIMIT 5")
                .list();
        vo.setPendingDispatchItems(buildDispatchItems(pendingDispatch));

        // 待抽检记录 top 5
        List<InspectionRecord> pendingInspections = inspectionRecordService.lambdaQuery()
                .eq(InspectionRecord::getStatus, "待抽检")
                .eq(InspectionRecord::getIsDeleted, 0)
                .orderByAsc(InspectionRecord::getCreatedAt)
                .last("LIMIT 5")
                .list();
        vo.setPendingInspectionItems(buildInspectionItems(pendingInspections));

        // 今日质检统计 — SQL 端聚合
        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.plusDays(1).atStartOfDay();

        QueryWrapper<InspectionRecord> inspectionWrapper = new QueryWrapper<InspectionRecord>()
                .select("COUNT(*) as totalCount",
                        "SUM(CASE WHEN status='已抽检' THEN 1 ELSE 0 END) as doneCount",
                        "SUM(CASE WHEN status='已抽检' AND conclusion='合格' THEN 1 ELSE 0 END) as passedCount")
                .eq("is_deleted", 0)
                .ge("created_at", todayStart)
                .lt("created_at", todayEnd);
        Map<String, Object> inspectionStats = inspectionRecordService.getBaseMapper().selectMaps(inspectionWrapper).get(0);
        Number doneCount = (Number) inspectionStats.get("doneCount");
        Number passedCount = (Number) inspectionStats.get("passedCount");
        long todayDone = doneCount != null ? doneCount.longValue() : 0;
        long todayPassed = passedCount != null ? passedCount.longValue() : 0;
        vo.setTodayInspectionDone(todayDone);
        vo.setTodayInspectionPassRate(todayDone > 0 ? (double) todayPassed / todayDone : 0.0);

        // 操作员任务
        buildOperatorTasks(vo);

        return vo;
    }

    private List<HomeSummaryVO.ExceptionItem> buildExceptionItems(List<ProductionException> exceptions) {
        if (exceptions.isEmpty()) return Collections.emptyList();

        List<Long> woIds = exceptions.stream().map(ProductionException::getWorkOrderId).distinct().collect(Collectors.toList());
        List<Long> lineIds = exceptions.stream().map(ProductionException::getLineId).distinct().collect(Collectors.toList());

        Map<Long, String> woCodes = workOrderService.lambdaQuery()
                .in(WorkOrder::getId, woIds)
                .list().stream()
                .collect(Collectors.toMap(WorkOrder::getId, w -> w.getCode() != null ? w.getCode() : ""));
        Map<Long, String> lineNames = productionLineService.lambdaQuery()
                .in(ProductionLine::getId, lineIds)
                .list().stream()
                .collect(Collectors.toMap(ProductionLine::getId, l -> l.getName() != null ? l.getName() : ""));

        List<HomeSummaryVO.ExceptionItem> items = new ArrayList<>();
        for (ProductionException e : exceptions) {
            HomeSummaryVO.ExceptionItem item = new HomeSummaryVO.ExceptionItem();
            item.setId(e.getId());
            item.setWorkOrderId(e.getWorkOrderId());
            item.setWorkOrderCode(woCodes.getOrDefault(e.getWorkOrderId(), ""));
            item.setLineId(e.getLineId());
            item.setLineName(lineNames.getOrDefault(e.getLineId(), ""));
            item.setDescription(e.getDescription());
            item.setReportTime(e.getReportTime() != null ? e.getReportTime().format(FMT) : null);
            items.add(item);
        }
        return items;
    }

    private List<HomeSummaryVO.DispatchItem> buildDispatchItems(List<WorkOrder> orders) {
        List<HomeSummaryVO.DispatchItem> items = new ArrayList<>();
        for (WorkOrder wo : orders) {
            HomeSummaryVO.DispatchItem item = new HomeSummaryVO.DispatchItem();
            item.setId(wo.getId());
            item.setCode(wo.getCode());
            item.setType(wo.getType());
            item.setPlanQty(wo.getPlanQty());
            item.setCreatedAt(wo.getCreatedAt() != null ? wo.getCreatedAt().format(FMT) : null);
            items.add(item);
        }
        return items;
    }

    private List<HomeSummaryVO.InspectionItem> buildInspectionItems(List<InspectionRecord> records) {
        if (records.isEmpty()) return Collections.emptyList();

        List<Long> woIds = records.stream().map(InspectionRecord::getWorkOrderId).distinct().collect(Collectors.toList());
        Map<Long, String> woCodes = workOrderService.lambdaQuery()
                .in(WorkOrder::getId, woIds)
                .list().stream()
                .collect(Collectors.toMap(WorkOrder::getId, w -> w.getCode() != null ? w.getCode() : ""));

        List<HomeSummaryVO.InspectionItem> items = new ArrayList<>();
        for (InspectionRecord r : records) {
            HomeSummaryVO.InspectionItem item = new HomeSummaryVO.InspectionItem();
            item.setId(r.getId());
            item.setWorkOrderId(r.getWorkOrderId());
            item.setWorkOrderCode(woCodes.getOrDefault(r.getWorkOrderId(), ""));
            item.setSampleQty(r.getSampleQty());
            item.setInspectTime(r.getInspectTime() != null ? r.getInspectTime().format(FMT) : null);
            items.add(item);
        }
        return items;
    }

    private void buildOperatorTasks(HomeSummaryVO vo) {
        Long userId = ControllerUtils.getCurrentUserId();
        if (userId == null) return;

        // 当前生产中任务
        WorkOrder active = workOrderService.lambdaQuery()
                .eq(WorkOrder::getOperatorId, userId)
                .eq(WorkOrder::getStatus, "生产中")
                .eq(WorkOrder::getIsDeleted, 0)
                .orderByDesc(WorkOrder::getActualStartTime)
                .last("LIMIT 1")
                .one();
        List<WorkOrder> pendingStart = workOrderService.lambdaQuery()
                .eq(WorkOrder::getOperatorId, userId)
                .eq(WorkOrder::getStatus, "已派工")
                .eq(WorkOrder::getIsDeleted, 0)
                .orderByAsc(WorkOrder::getCreatedAt)
                .last("LIMIT 5")
                .list();
        List<WorkOrder> pendingReport = workOrderService.lambdaQuery()
                .eq(WorkOrder::getOperatorId, userId)
                .eq(WorkOrder::getStatus, "生产完成")
                .eq(WorkOrder::getIsDeleted, 0)
                .orderByAsc(WorkOrder::getCreatedAt)
                .last("LIMIT 5")
                .list();

        // 批量加载产线名称，避免 N+1
        Map<Long, String> lineNameMap = buildLineNameMap(active, pendingStart, pendingReport);

        if (active != null) {
            vo.setOperatorActiveTask(buildTaskItem(active, lineNameMap));
        }
        vo.setOperatorPendingStartTasks(pendingStart.stream()
                .map(wo -> buildTaskItem(wo, lineNameMap))
                .collect(Collectors.toList()));
        vo.setOperatorPendingReportTasks(pendingReport.stream()
                .map(wo -> buildTaskItem(wo, lineNameMap))
                .collect(Collectors.toList()));
    }

    private Map<Long, String> buildLineNameMap(WorkOrder active, List<WorkOrder>... lists) {
        List<Long> lineIds = new ArrayList<>();
        if (active != null && active.getLineId() != null) lineIds.add(active.getLineId());
        for (List<WorkOrder> list : lists) {
            for (WorkOrder wo : list) {
                if (wo.getLineId() != null) lineIds.add(wo.getLineId());
            }
        }
        if (lineIds.isEmpty()) return Map.of();
        return productionLineService.lambdaQuery()
                .in(ProductionLine::getId, lineIds)
                .select(ProductionLine::getId, ProductionLine::getName)
                .list().stream()
                .collect(Collectors.toMap(
                        ProductionLine::getId,
                        l -> l.getName() != null ? l.getName() : "",
                        (a, b) -> a));
    }

    private HomeSummaryVO.TaskItem buildTaskItem(WorkOrder wo, Map<Long, String> lineNameMap) {
        HomeSummaryVO.TaskItem item = new HomeSummaryVO.TaskItem();
        item.setId(wo.getId());
        item.setCode(wo.getCode());
        item.setType(wo.getType());
        item.setStatus(wo.getStatus());
        item.setPlanQty(wo.getPlanQty());
        item.setReportedQtyGood(wo.getReportedQtyGood());
        item.setReportedQtyNg(wo.getReportedQtyNg());
        if (wo.getLineId() != null) {
            item.setLineName(lineNameMap.getOrDefault(wo.getLineId(), ""));
        }
        return item;
    }
}
