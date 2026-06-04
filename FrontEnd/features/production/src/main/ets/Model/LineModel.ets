@ObservedV2
export class LineModel {
  @Trace id: number = 0;
  @Trace name: string = '';
  @Trace workshopId: number = 0;
  @Trace currentProcessId: number | null = null;
  @Trace currentWorkorderId: number | null = null;
  @Trace status: string = '空闲';
  @Trace workshopName: string = '';
  @Trace createdAt: string = '';
  @Trace stationCount: number = 0;
  @Trace workOrderCode: string = '';
  @Trace planQty: number = 0;
  @Trace finishedCount: number = 0;
  @Trace ngCount: number = 0;
  @Trace workOrderStatus: string = '';
}
