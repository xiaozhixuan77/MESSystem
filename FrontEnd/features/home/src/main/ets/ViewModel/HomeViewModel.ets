import { HomeApi, DashboardApi, LineApi, WebSocketService } from '@ohos/network';
import {
  HomeSummaryModel,
  ExceptionItemModel,
  DispatchItemModel,
  InspectionItemModel,
  TaskItemModel,
  LineItemModel,
  DashboardModel
} from '../Model/HomeSummaryModel';

export class HomeViewModel {
  isLoading: boolean = false;
  errorMessage: string = '';
  summary: HomeSummaryModel | null = null;

  lineList: LineItemModel[] = [];
  lineLoading: boolean = false;
  dashboard: DashboardModel | null = null;
  dashboardLoading: boolean = false;

  async loadHomeData(): Promise<HomeSummaryModel | null> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const raw = await HomeApi.getSummary() as Record<string, Object>;
      this.summary = this.parseSummary(raw);
      return this.summary;
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
      return null;
    } finally {
      this.isLoading = false;
    }
  }

  private parseSummary(raw: Record<string, Object>): HomeSummaryModel {
    const m = new HomeSummaryModel();
    m.pendingExceptionCount = (raw['pendingExceptionCount'] as number) ?? 0;
    m.pendingDispatchCount = (raw['pendingDispatchCount'] as number) ?? 0;
    m.pendingInspectionCount = (raw['pendingInspectionCount'] as number) ?? 0;
    m.activeWorkOrderCount = (raw['activeWorkOrderCount'] as number) ?? 0;
    m.totalLineCount = (raw['totalLineCount'] as number) ?? 0;
    m.totalUserCount = (raw['totalUserCount'] as number) ?? 0;
    m.todayInspectionDone = (raw['todayInspectionDone'] as number) ?? 0;
    m.todayInspectionPassRate = (raw['todayInspectionPassRate'] as number) ?? 0;

    const exceptions = raw['recentExceptions'] as Array<Record<string, Object>>;
    if (exceptions) {
      m.recentExceptions = exceptions.map((e: Record<string, Object>) => {
        const item = new ExceptionItemModel();
        item.id = (e['id'] as number) ?? 0;
        item.workOrderId = (e['workOrderId'] as number) ?? 0;
        item.workOrderCode = (e['workOrderCode'] as string) ?? '';
        item.lineId = (e['lineId'] as number) ?? 0;
        item.lineName = (e['lineName'] as string) ?? '';
        item.description = (e['description'] as string) ?? '';
        item.reportTime = (e['reportTime'] as string) ?? '';
        return item;
      });
    }

    const dispatches = raw['pendingDispatchItems'] as Array<Record<string, Object>>;
    if (dispatches) {
      m.pendingDispatchItems = dispatches.map((d: Record<string, Object>) => {
        const item = new DispatchItemModel();
        item.id = (d['id'] as number) ?? 0;
        item.code = (d['code'] as string) ?? '';
        item.type = (d['type'] as string) ?? '';
        item.planQty = (d['planQty'] as number) ?? 0;
        item.createdAt = (d['createdAt'] as string) ?? '';
        return item;
      });
    }

    const inspections = raw['pendingInspectionItems'] as Array<Record<string, Object>>;
    if (inspections) {
      m.pendingInspectionItems = inspections.map((r: Record<string, Object>) => {
        const item = new InspectionItemModel();
        item.id = (r['id'] as number) ?? 0;
        item.workOrderId = (r['workOrderId'] as number) ?? 0;
        item.workOrderCode = (r['workOrderCode'] as string) ?? '';
        item.sampleQty = (r['sampleQty'] as number) ?? 0;
        item.inspectTime = (r['inspectTime'] as string) ?? '';
        return item;
      });
    }

    const activeTask = raw['operatorActiveTask'] as Record<string, Object>;
    if (activeTask) {
      m.operatorActiveTask = this.parseTaskItem(activeTask);
    }

    const startTasks = raw['operatorPendingStartTasks'] as Array<Record<string, Object>>;
    if (startTasks) {
      m.operatorPendingStartTasks = startTasks.map((t: Record<string, Object>) => this.parseTaskItem(t));
    }

    const reportTasks = raw['operatorPendingReportTasks'] as Array<Record<string, Object>>;
    if (reportTasks) {
      m.operatorPendingReportTasks = reportTasks.map((t: Record<string, Object>) => this.parseTaskItem(t));
    }

    return m;
  }

  private parseTaskItem(t: Record<string, Object>): TaskItemModel {
    const item = new TaskItemModel();
    item.id = (t['id'] as number) ?? 0;
    item.code = (t['code'] as string) ?? '';
    item.type = (t['type'] as string) ?? '';
    item.status = (t['status'] as string) ?? '';
    item.lineName = (t['lineName'] as string) ?? '';
    item.planQty = (t['planQty'] as number) ?? 0;
    item.reportedQtyGood = (t['reportedQtyGood'] as number) ?? 0;
    item.reportedQtyNg = (t['reportedQtyNg'] as number) ?? 0;
    return item;
  }

  async loadLines(params?: Record<string, string | number>): Promise<void> {
    this.lineLoading = true;
    try {
      const raw = await LineApi.getLines(params) as Array<Record<string, Object>>;
      if (raw) {
        this.lineList = raw.map((r: Record<string, Object>) => {
          const item = new LineItemModel();
          item.id = (r['id'] as number) ?? 0;
          item.name = (r['name'] as string) ?? '';
          item.status = (r['status'] as string) ?? '';
          item.workshopName = (r['workshopName'] as string) ?? '';
          item.stationCount = (r['stationCount'] as number) ?? 0;
          item.workOrderCode = (r['workOrderCode'] as string) ?? '';
          item.planQty = (r['planQty'] as number) ?? 0;
          item.finishedCount = (r['finishedCount'] as number) ?? 0;
          item.ngCount = (r['ngCount'] as number) ?? 0;
          return item;
        });
      }
    } catch (e) {
      console.error('[HomeVM] loadLines 失败:', (e as Error).message);
    } finally {
      this.lineLoading = false;
    }
  }

  async loadDashboard(): Promise<void> {
    this.dashboardLoading = true;
    try {
      const raw = await DashboardApi.getDashboard('today') as Record<string, Object>;
      if (raw) {
        const d = new DashboardModel();
        d.todayPlanRate = (raw['todayPlanRate'] as number) ?? 0;
        d.totalInput = (raw['totalInput'] as number) ?? 0;
        d.totalOutput = (raw['totalOutput'] as number) ?? 0;
        d.totalNg = (raw['totalNg'] as number) ?? 0;
        d.productCompletionRate = (raw['productCompletionRate'] as number) ?? 0;
        d.stationCompletionRate = (raw['stationCompletionRate'] as number) ?? 0;
        this.dashboard = d;
      }
    } catch (e) {
      console.error('[HomeVM] loadDashboard 失败:', (e as Error).message);
    } finally {
      this.dashboardLoading = false;
    }
  }

  private subscribed: boolean = false;
  private debounceTimer: number = -1;
  private readonly DEBOUNCE_MS: number = 1000;
  private readonly HOME_TOPIC: string = '/topic/home';
  private refreshCallback: (() => void) | null = null;

  subscribeHome(onRefresh: () => void): void {
    if (this.subscribed) {
      return;
    }
    this.subscribed = true;
    this.refreshCallback = onRefresh;
    const ws = WebSocketService.getInstance();
    ws.subscribe(this.HOME_TOPIC);
    WebSocketService.addListener(this.HOME_TOPIC, this.onHomeRefresh);
    console.info('[HomeVM] 已订阅 /topic/home');
  }

  unsubscribeHome(): void {
    if (!this.subscribed) {
      return;
    }
    this.subscribed = false;
    this.refreshCallback = null;
    WebSocketService.removeListener(this.HOME_TOPIC, this.onHomeRefresh);
    WebSocketService.getInstance().unsubscribe(this.HOME_TOPIC);
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
    console.info('[HomeVM] 已取消订阅 /topic/home');
  }

  private onHomeRefresh = (msg: Object): void => {
    console.info('[HomeVM] /topic/home 收到刷新信号');
    this.debouncedReload();
  };

  private debouncedReload(): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(async () => {
      this.debounceTimer = -1;
      await Promise.all([
        this.loadHomeData(),
        this.loadDashboard(),
        this.loadLines()
      ]);
      this.refreshCallback?.();
    }, this.DEBOUNCE_MS);
  }

  get hasPendingExceptions(): boolean {
    return this.summary !== null && this.summary.pendingExceptionCount > 0;
  }

  get hasPendingDispatches(): boolean {
    return this.summary !== null && this.summary.pendingDispatchCount > 0;
  }

  get hasPendingInspections(): boolean {
    return this.summary !== null && this.summary.pendingInspectionCount > 0;
  }

  get hasOperatorTasks(): boolean {
    return this.summary !== null &&
      (this.summary.operatorActiveTask !== null ||
       this.summary.operatorPendingStartTasks.length > 0 ||
       this.summary.operatorPendingReportTasks.length > 0);
  }
}
