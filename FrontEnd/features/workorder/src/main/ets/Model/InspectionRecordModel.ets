export class InspectionRecordModel {
  id: number = 0;
  workOrderId: number = 0;
  inspectorId: number = 0;
  inspectorName: string = '';
  inspectTime: string = '';
  sampleQty: number = 0;
  sampleGood: number = 0;
  sampleNg: number = 0;
  defectTypes: string = '';
  defectDescription: string = '';
  conclusion: string = '';
  status: string = '';
  workOrderCode: string = '';
  productName: string = '';
  processName: string = '';
}
