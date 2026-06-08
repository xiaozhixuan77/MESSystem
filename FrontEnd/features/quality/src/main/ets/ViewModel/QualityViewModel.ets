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

  private onInspectionUpdate: Function = () => {
    console.log('[test:VM] WebSocket inspection update received, reloading list');
    this.loadInspections();
  };

  async loadInspections(filters?: object): Promise<void> {
    console.log('[test:VM] loadInspections called, filters:', JSON.stringify(filters));
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const raw = await QualityApi.getInspections(filters);
      console.log('[test:VM] API raw response type:', typeof raw, 'isArray:', Array.isArray(raw));
      if (Array.isArray(raw)) {
        console.log('[test:VM] API returned', raw.length, 'items');
        if (raw.length > 0) {
          console.log('[test:VM] First item keys:', Object.keys(raw[0]));
          console.log('[test:VM] First item:', JSON.stringify(raw[0]));
        }
      }
      this.inspectionList = raw as InspectionModel[];
      console.log('[test:VM] inspectionList assigned, length:', this.inspectionList.length);
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
      console.log('[test:VM] loadInspections error:', this.errorMessage);
    } finally {
      this.isLoading = false;
      console.log('[test:VM] isLoading set to false');
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
    WebSocketService.addListener(INSPECTION_TOPIC, this.onInspectionUpdate);
  }

  unsubscribeInspections(): void {
    WebSocketService.removeListener(INSPECTION_TOPIC, this.onInspectionUpdate);
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
