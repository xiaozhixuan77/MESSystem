import { QualityApi, WebSocketService } from '@ohos/network';
import { InspectionModel } from '../Model/InspectionModel';
import { DashboardModel, DailyRateModel, TopDefectModel } from '../Model/DashboardModel';

const INSPECTION_TOPIC = '/topic/inspections';
const EXCEPTIONS_TOPIC = '/topic/exceptions';

@ObservedV2
export class QualityViewModel {
  @Trace inspectionList: InspectionModel[] = [];
  @Trace currentInspection: InspectionModel = new InspectionModel();
  @Trace dashboardData: DashboardModel | null = null;
  @Trace dashboardLoading: boolean = false;
  @Trace dashboardError: string = '';
  @Trace isLoading: boolean = false;
  @Trace submitLoading: boolean = false;
  @Trace errorMessage: string = '';
  private subscribed: boolean = false;
  private dashboardSubscribed: boolean = false;

  private onInspectionUpdate: Function = () => {
    this.loadInspections();
  };

  private onDashboardUpdate: Function = (_msg: Object) => {
    this.loadDashboard('month');
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

  subscribeDashboard(): void {
    if (this.dashboardSubscribed) {
      return;
    }
    this.dashboardSubscribed = true;
    const ws = WebSocketService.getInstance();
    ws.subscribe(INSPECTION_TOPIC);
    ws.subscribe(EXCEPTIONS_TOPIC);
    WebSocketService.addListener(INSPECTION_TOPIC, this.onDashboardUpdate);
    WebSocketService.addListener(EXCEPTIONS_TOPIC, this.onDashboardUpdate);
  }

  unsubscribeDashboard(): void {
    if (!this.dashboardSubscribed) {
      return;
    }
    this.dashboardSubscribed = false;
    WebSocketService.removeListener(INSPECTION_TOPIC, this.onDashboardUpdate);
    WebSocketService.removeListener(EXCEPTIONS_TOPIC, this.onDashboardUpdate);
  }

  async loadDashboard(scope: string = 'today'): Promise<void> {
    this.dashboardLoading = true;
    this.dashboardError = '';
    try {
      const results = await Promise.all([
        QualityApi.getDashboard(scope) as Promise<Record<string, Object>>,
        QualityApi.getInspections() as Promise<InspectionModel[]>
      ]);
      const raw = results[0] as Record<string, Object>;
      const inspections = results[1] as InspectionModel[];

      const model = new DashboardModel();
      model.todayPlanRate = (raw['todayPlanRate'] as number) ?? 0;
      model.totalInput = (raw['totalInput'] as number) ?? 0;
      model.totalOutput = (raw['totalOutput'] as number) ?? 0;
      model.totalNg = (raw['totalNg'] as number) ?? 0;
      model.productCompletionRate = (raw['productCompletionRate'] as number) ?? 0;
      model.stationCompletionRate = (raw['stationCompletionRate'] as number) ?? 0;
      const rawRates = (raw['monthlyRates'] as Array<Record<string, Object>>) ?? [];
      model.monthlyRates = rawRates.map((r: Record<string, Object>) => {
        const dr = new DailyRateModel();
        dr.day = (r['day'] as number) ?? 0;
        dr.rate = (r['rate'] as number) ?? 0;
        return dr;
      });

      // 从抽检列表计算质检KPI
      model.totalInspections = inspections.length;
      const passed = inspections.filter((i: InspectionModel) => i.conclusion === '合格').length;
      model.passRate = inspections.length > 0 ? passed / inspections.length : 0;
      model.totalNg = inspections.reduce((sum: number, i: InspectionModel) => sum + (i.sampleNg || 0), 0);
      model.pendingCount = inspections.filter((i: InspectionModel) => i.status === '待抽检').length;

      // 聚合不良类型 TOP5
      const agg: TopDefectModel[] = [];
      for (const insp of inspections) {
        if (insp.defectTypes && insp.defectTypes.trim() !== '') {
          const parts = insp.defectTypes.split(',');
          for (const part of parts) {
            const trimmed = part.trim();
            if (trimmed === '') continue;
            const colonIdx = trimmed.lastIndexOf(':');
            let name = trimmed;
            let count = 1;
            if (colonIdx > 0) {
              name = trimmed.substring(0, colonIdx).trim();
              count = parseInt(trimmed.substring(colonIdx + 1).trim()) || 0;
            }
            let found = false;
            for (const item of agg) {
              if (item.name === name) {
                item.count += count;
                found = true;
                break;
              }
            }
            if (!found) {
              const m = new TopDefectModel();
              m.name = name;
              m.count = count;
              agg.push(m);
            }
          }
        }
      }
      agg.sort((a: TopDefectModel, b: TopDefectModel) => b.count - a.count);
      model.topDefects = agg.slice(0, 5);

      this.dashboardData = model;
    } catch (e) {
      this.dashboardError = (e as Error).message || '加载失败';
    } finally {
      this.dashboardLoading = false;
    }
  }
}
