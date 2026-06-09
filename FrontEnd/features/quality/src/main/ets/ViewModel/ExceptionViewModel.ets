import { ExceptionApi } from '@ohos/network';
import { WebSocketService } from '@ohos/network';
import { ExceptionModel } from '../Model/ExceptionModel';

const EXCEPTION_TOPIC = '/topic/exceptions';

@ObservedV2
export class ExceptionViewModel {
  @Trace exceptionList: ExceptionModel[] = [];
  @Trace currentException: ExceptionModel = new ExceptionModel();
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace handleLoading: boolean = false;
  private subscribed: boolean = false;

  private onExceptionUpdate = (): void => {
    console.info('[test:ExceptionVM] WebSocket /topic/exceptions 收到消息，刷新列表');
    this.loadExceptions();
  };

  subscribeExceptions(): void {
    if (this.subscribed) return;
    this.subscribed = true;
    console.info('[test:ExceptionVM] 订阅 /topic/exceptions');
    const ws = WebSocketService.getInstance();
    ws.subscribe(EXCEPTION_TOPIC);
    WebSocketService.addListener(EXCEPTION_TOPIC, this.onExceptionUpdate);
  }

  unsubscribeExceptions(): void {
    if (!this.subscribed) return;
    this.subscribed = false;
    WebSocketService.removeListener(EXCEPTION_TOPIC, this.onExceptionUpdate);
    const ws = WebSocketService.getInstance();
    ws.unsubscribe(EXCEPTION_TOPIC);
  }

  async loadExceptions(resolved?: boolean): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    console.info('[test:ExceptionVM] 加载异常列表', JSON.stringify({ resolved: resolved }));
    try {
      const params: Record<string, string | number> = {};
      if (resolved !== undefined) {
        params['resolved'] = resolved ? 1 : 0;
      }
      const raw = await ExceptionApi.getExceptions(params) as Object[];
      this.exceptionList = raw.map((r: Object) => this.mapException(r as Record<string, Object>));
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async loadExceptionDetail(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const raw = await ExceptionApi.getExceptionDetail(id) as Record<string, Object>;
      this.currentException = this.mapException(raw);
    } catch (e) {
      this.errorMessage = (e as Error).message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async handleException(id: number, action: string): Promise<boolean> {
    this.handleLoading = true;
    console.info('[test:ExceptionVM] 调用 ExceptionApi.handleException', JSON.stringify({ id: id, action: action }));
    try {
      await ExceptionApi.handleException(id, action);
      console.info('[test:ExceptionVM] handleException API 成功');
      await this.loadExceptionDetail(id);
      console.info('[test:ExceptionVM] 详情已刷新');
      return true;
    } catch (e) {
      console.error('[test:ExceptionVM] handleException 失败', JSON.stringify({ error: (e as Error).message }));
      this.errorMessage = (e as Error).message || '处理失败';
      return false;
    } finally {
      this.handleLoading = false;
    }
  }

  private mapException(r: Record<string, Object>): ExceptionModel {
    const m = new ExceptionModel();
    m.id = r['id'] as number ?? 0;
    m.workOrderId = r['workOrderId'] as number ?? 0;
    m.workOrderCode = r['workOrderCode'] as string ?? '';
    m.lineId = r['lineId'] as number ?? 0;
    m.lineName = r['lineName'] as string ?? '';
    m.stationId = r['stationId'] as number ?? null;
    m.stationName = r['stationName'] as string ?? '';
    m.reporterId = r['reporterId'] as number ?? 0;
    m.reporterName = r['reporterName'] as string ?? '';
    m.reportTime = r['reportTime'] as string ?? '';
    m.description = r['description'] as string ?? '';
    m.handledBy = r['handledBy'] as number ?? null;
    m.handlerName = r['handlerName'] as string ?? '';
    m.handleTime = r['handleTime'] as string ?? '';
    m.handleAction = r['handleAction'] as string ?? '';
    m.resolved = r['resolved'] as number ?? 0;
    m.createdAt = r['createdAt'] as string ?? '';
    return m;
  }
}
