import { LineApi } from '@ohos/network';
import { WebSocketService } from '@ohos/network';
import { LineModel } from '../Model/LineModel';
import { StationModel } from '../Model/StationModel';
import { LineDetailModel, WorkOrderSummary } from '../Model/LineDetailModel';

@ObservedV2
export class ProductionViewModel {
  @Trace lines: LineModel[] = [];
  @Trace lineDetail: LineDetailModel = new LineDetailModel();
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace currentRole: string = '';
  @Trace isSubmitting: boolean = false;
  @Trace showExceptionDialog: boolean = false;
  @Trace exceptionDescription: string = '';
  @Trace isDataStale: boolean = false;

  private activeLineId: number = 0;

  async loadLines(status?: string): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const params: Record<string, string> = {};
      if (status) {
        params['status'] = status;
      }
      this.lines = await LineApi.getLines(params) as LineModel[];
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadLineDetail(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const data = await LineApi.getLineDetail(id) as Record<string, Object>;
      const detail = new LineDetailModel();
      detail.id = data['id'] as number ?? 0;
      detail.name = data['name'] as string ?? '';
      detail.status = data['status'] as string ?? '空闲';
      detail.workshopName = data['workshopName'] as string ?? '';
      detail.currentWorkorderId = data['currentWorkorderId'] as number ?? null;

      const stationsRaw = data['stations'] as Object[];
      if (stationsRaw) {
        detail.stations = stationsRaw.map((s: Object) => {
          const r = s as Record<string, Object>;
          const sm = new StationModel();
          sm.id = r['id'] as number ?? 0;
          sm.opCode = r['opCode'] as string ?? '';
          sm.name = r['name'] as string ?? '';
          sm.equipmentCode = r['equipmentCode'] as string ?? '';
          sm.deviceStatus = r['deviceStatus'] as string ?? '空闲';
          sm.workStatus = r['workStatus'] as string ?? '空闲';
          sm.conveyorStatus = r['conveyorStatus'] as string ?? '空闲';
          sm.processedCount = r['processedCount'] as number ?? 0;
          sm.rawCount = r['rawCount'] as number ?? 0;
          sm.finishedCount = r['finishedCount'] as number ?? 0;
          sm.ngCount = r['ngCount'] as number ?? 0;
          return sm;
        });
      }

      const woRaw = data['activeWorkOrder'] as Record<string, Object> | null;
      if (woRaw) {
        const wo = new WorkOrderSummary();
        wo.id = woRaw['id'] as number ?? 0;
        wo.code = woRaw['code'] as string ?? '';
        wo.productName = woRaw['productName'] as string ?? '';
        wo.processName = woRaw['processName'] as string ?? '';
        wo.planQty = woRaw['planQty'] as number ?? 0;
        wo.status = woRaw['status'] as string ?? '';
        detail.activeWorkOrder = wo;
      }

      this.lineDetail = detail;
      this.isDataStale = false;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      this.isDataStale = this.lineDetail.id > 0;
    } finally {
      this.isLoading = false;
    }
  }

  async startLine(id: number, workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.startLine(id, workOrderId);
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async stopLine(id: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.stopLine(id);
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async resetLine(id: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.resetLine(id);
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  subscribeLine(lineId: number): void {
    this.activeLineId = lineId;
    const ws = WebSocketService.getInstance();
    ws.subscribe(`/topic/lines/${lineId}`);
    ws.subscribe(`/topic/lines/${lineId}/stations`);
    WebSocketService.addListener(`/topic/lines/${lineId}`, this.onLineStatusUpdate);
    WebSocketService.addListener(`/topic/lines/${lineId}/stations`, this.onStationUpdate);
  }

  unsubscribeLine(): void {
    if (this.activeLineId <= 0) {
      return;
    }
    const ws = WebSocketService.getInstance();
    ws.unsubscribe(`/topic/lines/${this.activeLineId}`);
    ws.unsubscribe(`/topic/lines/${this.activeLineId}/stations`);
    WebSocketService.removeListener(`/topic/lines/${this.activeLineId}`);
    WebSocketService.removeListener(`/topic/lines/${this.activeLineId}/stations`);
    this.activeLineId = 0;
  }

  onLineStatusUpdate = (payload: Object): void => {
    const data = payload as Record<string, Object>;
    if (data['status'] !== undefined) {
      this.lineDetail.status = data['status'] as string;
    }
    if (data['workOrderId'] !== undefined) {
      this.lineDetail.currentWorkorderId = data['workOrderId'] as number ?? null;
    }
  };

  onStationUpdate = (payload: Object): void => {
    const msg = payload as Record<string, Object>;
    const stationData = msg['data'] as Object[];
    if (!stationData) {
      return;
    }
    for (let i = 0; i < this.lineDetail.stations.length; i++) {
      const station = this.lineDetail.stations[i];
      const update = stationData.find((s: Object) =>
        (s as Record<string, Object>)['stationId'] === station.id) as Record<string, Object> | undefined;
      if (update !== undefined) {
        station.processedCount = update['processedCount'] as number ?? station.processedCount;
        station.rawCount = update['rawCount'] as number ?? station.rawCount;
        station.finishedCount = update['finishedCount'] as number ?? station.finishedCount;
        station.ngCount = update['ngCount'] as number ?? station.ngCount;
        station.deviceStatus = update['deviceStatus'] as string ?? station.deviceStatus;
      }
    }
    this.lineDetail.stations = [...this.lineDetail.stations];
  };

  get todayOutput(): number {
    return this.lineDetail.todayOutput;
  }

  get yieldRate(): string {
    return this.lineDetail.yieldRate;
  }

  get runtime(): string {
    return this.lineDetail.runtime;
  }

  get exceptionCount(): number {
    return this.lineDetail.exceptionCount;
  }
}
