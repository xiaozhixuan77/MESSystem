package org.example.service.impl;

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
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class DashboardServiceImpl implements DashboardService {

    private static final Set<String> FINISHED_STATUSES = Set.of("生产完成", "已报工", "完工");

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

        // 今日数据
        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.plusDays(1).atStartOfDay();

        List<WorkOrder> todayOrders = workOrderService.lambdaQuery()
                .ge(WorkOrder::getActualStartTime, todayStart)
                .lt(WorkOrder::getActualStartTime, todayEnd)
                .eq(WorkOrder::getIsDeleted, 0)
                .list();

        int totalInput = 0;
        int totalOutput = 0;
        int totalNg = 0;
        int finishedCount = 0;
        int totalCount = todayOrders.size();

        for (WorkOrder wo : todayOrders) {
            totalInput += wo.getPlanQty() != null ? wo.getPlanQty() : 0;
            totalOutput += wo.getReportedQtyGood() != null ? wo.getReportedQtyGood() : 0;
            totalNg += wo.getReportedQtyNg() != null ? wo.getReportedQtyNg() : 0;
            if (wo.getStatus() != null && FINISHED_STATUSES.contains(wo.getStatus())) {
                finishedCount++;
            }
        }

        vo.setTotalInput(totalInput);
        vo.setTotalOutput(totalOutput);
        vo.setTotalNg(totalNg);
        vo.setTodayPlanRate(totalInput > 0 ? (double) totalOutput / totalInput : 0.0);
        vo.setProductCompletionRate(totalCount > 0 ? (double) finishedCount / totalCount : 0.0);

        // 工作站完工率
        List<Workstation> stations = workstationService.lambdaQuery()
                .eq(Workstation::getIsDeleted, 0)
                .list();
        int stationFinished = 0;
        int stationTotal = 0;
        for (Workstation ws : stations) {
            int f = ws.getFinishedCount() != null ? ws.getFinishedCount() : 0;
            int n = ws.getNgCount() != null ? ws.getNgCount() : 0;
            stationFinished += f;
            stationTotal += f + n;
        }
        vo.setStationCompletionRate(stationTotal > 0 ? (double) stationFinished / stationTotal : 0.0);

        // 月度趋势
        if ("month".equals(scope)) {
            YearMonth ym = YearMonth.from(today);
            LocalDate monthStart = ym.atDay(1);
            LocalDate monthEnd = ym.atEndOfMonth();

            // 当月全部工单，按日分组
            LocalDateTime monthStartDt = monthStart.atStartOfDay();
            LocalDateTime monthEndDt = monthEnd.plusDays(1).atStartOfDay();

            List<WorkOrder> monthOrders = workOrderService.lambdaQuery()
                    .ge(WorkOrder::getActualStartTime, monthStartDt)
                    .lt(WorkOrder::getActualStartTime, monthEndDt)
                    .eq(WorkOrder::getIsDeleted, 0)
                    .list();

            Map<Integer, List<WorkOrder>> byDay = monthOrders.stream()
                    .filter(wo -> wo.getActualStartTime() != null)
                    .collect(Collectors.groupingBy(
                            wo -> wo.getActualStartTime().toLocalDate().getDayOfMonth()));

            List<DashboardVO.DailyRate> rates = new ArrayList<>();
            int maxDay = Math.min(today.getDayOfMonth(), monthEnd.getDayOfMonth());
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
