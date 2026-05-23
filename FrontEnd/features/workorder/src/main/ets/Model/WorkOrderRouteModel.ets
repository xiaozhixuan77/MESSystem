export class WorkOrderRouteModel {
  id: number = 0;
  workOrderId: number = 0;
  seqNo: number = 0;
  opCode: string = '';
  name: string = '';
  stationId: number | null = null;
  status: string = 'pending';
}
