@ObservedV2
export class ExceptionItemModel {
  @Trace id: number = 0;
  @Trace workOrderId: number = 0;
  @Trace workOrderCode: string = '';
  @Trace lineId: number = 0;
  @Trace lineName: string = '';
  @Trace description: string = '';
  @Trace reportTime: string = '';
}

@ObservedV2
export class DispatchItemModel {
  @Trace id: number = 0;
  @Trace code: string = '';
  @Trace type: string = '';
  @Trace planQty: number = 0;
  @Trace createdAt: string = '';
}

@ObservedV2
export class InspectionItemModel {
  @Trace id: number = 0;
  @Trace workOrderId: number = 0;
  @Trace workOrderCode: string = '';
  @Trace sampleQty: number = 0;
  @Trace inspectTime: string = '';
}

@ObservedV2
export class TaskItemModel {
  @Trace id: number = 0;
  @Trace code: string = '';
  @Trace type: string = '';
  @Trace status: string = '';
  @Trace lineName: string = '';
  @Trace planQty: number = 0;
  @Trace reportedQtyGood: number = 0;
  @Trace reportedQtyNg: number = 0;
}

@ObservedV2
export class HomeSummaryModel {
  @Trace pendingExceptionCount: number = 0;
  @Trace pendingDispatchCount: number = 0;
  @Trace pendingInspectionCount: number = 0;
  @Trace activeWorkOrderCount: number = 0;
  @Trace totalLineCount: number = 0;
  @Trace totalUserCount: number = 0;

  @Trace recentExceptions: ExceptionItemModel[] = [];
  @Trace pendingDispatchItems: DispatchItemModel[] = [];
  @Trace pendingInspectionItems: InspectionItemModel[] = [];
  @Trace todayInspectionDone: number = 0;
  @Trace todayInspectionPassRate: number = 0;

  @Trace operatorActiveTask: TaskItemModel | null = null;
  @Trace operatorPendingStartTasks: TaskItemModel[] = [];
  @Trace operatorPendingReportTasks: TaskItemModel[] = [];
}

@ObservedV2
export class LineItemModel {
  @Trace id: number = 0;
  @Trace name: string = '';
  @Trace status: string = '';
  @Trace workshopName: string = '';
  @Trace stationCount: number = 0;
  @Trace workOrderCode: string = '';
  @Trace planQty: number = 0;
  @Trace finishedCount: number = 0;
  @Trace ngCount: number = 0;
}

@ObservedV2
export class DashboardModel {
  @Trace todayPlanRate: number = 0;
  @Trace totalInput: number = 0;
  @Trace totalOutput: number = 0;
  @Trace totalNg: number = 0;
  @Trace productCompletionRate: number = 0;
  @Trace stationCompletionRate: number = 0;
}
