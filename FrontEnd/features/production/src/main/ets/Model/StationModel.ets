export class StationModel {
  id: number = 0;
  code: string = '';
  name: string = '';
  opCode: string = '';
  productionLineId: number = 0;
  equipmentCode: string = '';
  deviceStatus: string = '空闲';
  workStatus: string = '空闲';
  conveyorStatus: string = '空闲';
  processedCount: number = 0;
  rawCount: number = 0;
  finishedCount: number = 0;
  ngCount: number = 0;
}
