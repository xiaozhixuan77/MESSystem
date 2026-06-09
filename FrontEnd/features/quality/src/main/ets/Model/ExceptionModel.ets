@ObservedV2
export class ExceptionModel {
  @Trace id: number = 0;
  @Trace workOrderId: number = 0;
  @Trace workOrderCode: string = '';
  @Trace lineId: number = 0;
  @Trace lineName: string = '';
  @Trace stationId: number | null = null;
  @Trace stationName: string = '';
  @Trace reporterId: number = 0;
  @Trace reporterName: string = '';
  @Trace reportTime: string = '';
  @Trace description: string = '';
  @Trace handledBy: number | null = null;
  @Trace handlerName: string = '';
  @Trace handleTime: string = '';
  @Trace handleAction: string = '';
  @Trace resolved: number = 0;
  @Trace createdAt: string = '';
}
