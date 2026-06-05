import { WorkOrderRouteModel } from './WorkOrderRouteModel';

export class WorkOrderModel {
  id: number = 0;
  code: string = '';
  type: string = '';
  workshopId: number = 0;
  lineId: number = 0;
  productId: number = 0;
  processId: number = 0;
  planQty: number = 0;
  status: string = '待派工';
  operatorId: number | null = null;
  productName: string = '';
  workshopName: string = '';
  lineName: string = '';
  operatorName: string = '';
  planStartTime: string = '';
  planEndTime: string = '';
  createdAt: string = '';
  version: number = 0;
  // 详情扩展字段（WorkOrderDetailVO）
  dispatchTime: string = '';
  actualStartTime: string = '';
  actualEndTime: string = '';
  pauseTime: string = '';
  reportedQtyGood: number = 0;
  reportedQtyNg: number = 0;
  reportedHours: number = 0;
  exceptionNote: string = '';
  source: string = '';
  createdByName: string = '';
  sourceWorkorderId: number = 0;
  routeSteps: WorkOrderRouteModel[] = [];
  processName: string = '';
}
