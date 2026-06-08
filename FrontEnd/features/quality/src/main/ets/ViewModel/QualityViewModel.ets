import { QualityApi, WebSocketService } from '@ohos/network';
import { InspectionModel } from '../Model/InspectionModel';

const INSPECTION_TOPIC = '/topic/inspections';

@ObservedV2
export class QualityViewModel {
  @Trace inspectionList: InspectionModel[] = [];
  @Trace currentInspection: InspectionModel = new InspectionModel();
  @Trace dashboardData: Record<string, Object> = {};
  @Trace isLoading: boolean = false;
  @Trace submitLoading: boolean = false;
  @Trace errorMessage: string = '';
  private subscribed: boolean = false;

  private onInspectionUpdate: Function = () => {
    this.loadInspections();
  };

  async loadInspections(filters?: object): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.inspectionList = await QualityApi.getInspections(filters) as InspectionModel[];
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async loadInspectionDetail(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.currentInspection = await QualityApi.getInspectionDetail(id) as InspectionModel;
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async submitInspection(id: number, data: object): Promise<Object> {
    this.submitLoading = true;
    try {
      return await QualityApi.submitInspection(id, data);
    } finally {
      this.submitLoading = false;
    }
  }

  subscribeInspections(): void {
    if (this.subscribed) {
      return;
    }
    this.subscribed = true;
    const ws = WebSocketService.getInstance();
    ws.subscribe(INSPECTION_TOPIC);
    WebSocketService.addListener(INSPECTION_TOPIC, this.onInspectionUpdate);
  }

  unsubscribeInspections(): void {
    if (!this.subscribed) {
      return;
    }
    this.subscribed = false;
    WebSocketService.removeListener(INSPECTION_TOPIC, this.onInspectionUpdate);
    const ws = WebSocketService.getInstance();
    ws.unsubscribe(INSPECTION_TOPIC);
  }

  async loadDashboard(params?: object): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.dashboardData = await QualityApi.getDashboard(params) as Record<string, Object>;
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }
}
