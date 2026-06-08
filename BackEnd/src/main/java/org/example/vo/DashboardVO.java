package org.example.vo;

import lombok.Data;

import java.util.List;

@Data
public class DashboardVO {
    private double todayPlanRate;
    private int totalInput;
    private int totalOutput;
    private int totalNg;
    private double productCompletionRate;
    private double stationCompletionRate;
    private List<DailyRate> monthlyRates;

    @Data
    public static class DailyRate {
        private int day;
        private double rate;
    }
}
