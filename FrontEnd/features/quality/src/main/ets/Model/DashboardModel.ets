@ObservedV2
export class DailyRateModel {
  @Trace day: number = 0;
  @Trace rate: number = 0;
}

@ObservedV2
export class TopDefectModel {
  @Trace name: string = '';
  @Trace count: number = 0;
}

@ObservedV2
export class DashboardModel {
  @Trace todayPlanRate: number = 0;
  @Trace totalInput: number = 0;
  @Trace totalOutput: number = 0;
  @Trace totalNg: number = 0;
  @Trace productCompletionRate: number = 0;
  @Trace stationCompletionRate: number = 0;
  @Trace monthlyRates: DailyRateModel[] = [];
  @Trace totalInspections: number = 0;
  @Trace passRate: number = 0;
  @Trace pendingCount: number = 0;
  @Trace topDefects: TopDefectModel[] = [];
}
