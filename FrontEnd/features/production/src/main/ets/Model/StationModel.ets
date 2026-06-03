@ObservedV2
export class StationModel {
  @Trace id: number = 0;
  @Trace code: string = '';
  @Trace name: string = '';
  @Trace opCode: string = '';
  @Trace productionLineId: number = 0;
  @Trace equipmentCode: string = '';
  @Trace deviceStatus: string = '空闲';
  @Trace workStatus: string = '空闲';
  @Trace conveyorStatus: string = '空闲';
  @Trace processedCount: number = 0;
  @Trace rawCount: number = 0;
  @Trace finishedCount: number = 0;
  @Trace ngCount: number = 0;
}
