package org.example.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.example.entity.WorkOrder;
import org.example.entity.Workstation;
import org.example.service.DashboardService;
import org.example.service.WorkOrderService;
import org.example.service.WorkstationService;
import org.example.vo.DashboardVO;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class DashboardServiceImpl implements DashboardService {

    private final WorkOrderService workOrderService;
    private final WorkstationService workstationService;

    public DashboardServiceImpl(WorkOrderService workOrderService,
                                 WorkstationService workstationService) {
        this.workOrderService = workOrderService;
        this.workstationService = workstationService;
    }

    @Override
    public DashboardVO getDashboard(String scope) {
        LocalDate today = LocalDate.now();
        DashboardVO vo = new DashboardVO();

        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.plusDays(1).atStartOfDay();

        // 今日工单聚合 — SQL 端完成 SUM/COUNT
        QueryWrapper<WorkOrder> todayWrapper = new QueryWrapper<WorkOrder>()
                .select("COALESCE(SUM(plan_qty), 0) as totalInput",
                        "COALESCE(SUM(reported_qty_good), 0) as totalOutput",
                        "COALESCE(SUM(reported_qty_ng), 0) as totalNg",
                        "COUNT(*) as totalCount",
                        "SUM(CASE WHEN status IN ('生产完成','已报工','完工') THEN 1 ELSE 0 END) as finishedCount")
                .ge("actual_start_time", todayStart)
                .lt("actual_start_time", todayEnd)
                .eq("is_deleted", 0);
        Map<String, Object> todayStats = workOrderService.getBaseMapper().selectMaps(todayWrapper).get(0);

        int totalInput = ((Number) todayStats.get("totalInput")).intValue();
        int totalOutput = ((Number) todayStats.get("totalOutput")).intValue();
        int totalNg = ((Number) todayStats.get("totalNg")).intValue();
        int totalCount = ((Number) todayStats.get("totalCount")).intValue();
        int finishedCount = ((Number) todayStats.get("finishedCount")).intValue();

        vo.setTotalInput(totalInput);
        vo.setTotalOutput(totalOutput);
        vo.setTotalNg(totalNg);
        vo.setTodayPlanRate(totalInput > 0 ? (double) totalOutput / totalInput : 0.0);
        vo.setProductCompletionRate(totalCount > 0 ? (double) finishedCount / totalCount : 0.0);

        // 工作站完工率 — SQL 端完成 SUM
        QueryWrapper<Workstation> wsWrapper = new QueryWrapper<Workstation>()
                .select("COALESCE(SUM(finished_count), 0) as finishedTotal",
                        "COALESCE(SUM(finished_count), 0) + COALESCE(SUM(ng_count), 0) as totalCount")
                .eq("is_deleted", 0);
        Map<String, Object> wsStats = workstationService.getBaseMapper().selectMaps(wsWrapper).get(0);
        int stationFinished = ((Number) wsStats.get("finishedTotal")).intValue();
        int stationTotal = ((Number) wsStats.get("totalCount")).intValue();
        vo.setStationCompletionRate(stationTotal > 0 ? (double) stationFinished / stationTotal : 0.0);

        // 月度趋势 — 内存按日分组 (兼容 H2/MySQL)
        if ("month".equals(scope)) {
            YearMonth ym = YearMonth.from(today);
            LocalDate monthStart = ym.atDay(1);
            LocalDate monthEnd = ym.atEndOfMonth();

            List<WorkOrder> monthOrders = workOrderService.lambdaQuery()
                    .ge(WorkOrder::getActualStartTime, monthStart.atStartOfDay())
                    .lt(WorkOrder::getActualStartTime, monthEnd.plusDays(1).atStartOfDay())
                    .eq(WorkOrder::getIsDeleted, 0)
                    .list();

            Map<Integer, List<WorkOrder>> byDay = monthOrders.stream()
                    .filter(wo -> wo.getActualStartTime() != null)
                    .collect(Collectors.groupingBy(
                            wo -> wo.getActualStartTime().toLocalDate().getDayOfMonth()));

            int maxDay = Math.min(today.getDayOfMonth(), monthEnd.getDayOfMonth());
            List<DashboardVO.DailyRate> rates = new ArrayList<>();
            for (int d = 1; d <= maxDay; d++) {
                DashboardVO.DailyRate dr = new DashboardVO.DailyRate();
                dr.setDay(d);
                List<WorkOrder> dayOrders = byDay.getOrDefault(d, List.of());
                int dayInput = 0;
                int dayOutput = 0;
                for (WorkOrder wo : dayOrders) {
                    dayInput += wo.getPlanQty() != null ? wo.getPlanQty() : 0;
                    dayOutput += wo.getReportedQtyGood() != null ? wo.getReportedQtyGood() : 0;
                }
                dr.setRate(dayInput > 0 ? (double) dayOutput / dayInput : 0.0);
                rates.add(dr);
            }
            vo.setMonthlyRates(rates);
        }

        return vo;
    }
}
