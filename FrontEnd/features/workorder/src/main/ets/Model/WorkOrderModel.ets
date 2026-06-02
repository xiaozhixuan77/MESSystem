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
  operatorName: string = '';
  planStartTime: string = '';
  planEndTime: string = '';
  createdAt: string = '';
  version: number = 0;
}
