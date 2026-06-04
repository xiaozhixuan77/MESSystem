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
  @Trace showStartConfirm: boolean = false;
  @Trace showStopConfirm: boolean = false;
  @Trace showResetConfirm: boolean = false;
  @Trace showErrorDialog: boolean = false;
  @Trace errorDialogMessage: string = '';
  @Trace isDataStale: boolean = false;
  @Trace refreshKey: number = 0;

  private activeLineId: number = 0;
  private subscribedLineIds: Set<number> = new Set();
  isActive: boolean = false;

  async loadLines(status?: string): Promise<void> {
    console.log('text: [VM.loadLines] 开始加载产线列表', status ? `筛选=${status}` : '无筛选');
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const params: Record<string, string> = {};
      if (status) {
        params['status'] = status;
      }
      this.lines = await LineApi.getLines(params) as LineModel[];
      let statusStr = '';
      for (let i = 0; i < this.lines.length; i++) {
        statusStr += `[id=${this.lines[i].id}, status=${this.lines[i].status}, finished=${this.lines[i].finishedCount}] `;
      }
      console.log('text: [VM.loadLines] API返回成功', `产线数=${this.lines.length}`, statusStr);
      this.refreshKey++;
      this.subscribeLineList();
    } catch (e) {
      console.log('text: [VM.loadLines] API返回失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadLineDetail(id: number): Promise<void> {
    console.log('text: [VM.loadLineDetail] 开始加载产线详情', `lineId=${id}`);
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
      console.log('text: [VM.loadLineDetail] 详情加载成功', `status=${detail.status}, stations=${detail.stations.length}, wo=${detail.activeWorkOrder?.code ?? '无'}`);
    } catch (e) {
      console.log('text: [VM.loadLineDetail] 详情加载失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
      this.isDataStale = this.lineDetail.id > 0;
    } finally {
      this.isLoading = false;
    }
  }

  async startLine(id: number, workOrderId: number): Promise<boolean> {
    console.log('text: [VM.startLine] 开始启动产线', `lineId=${id}, woId=${workOrderId}`);
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.startLine(id, workOrderId);
      const line = this.lines.find(l => l.id === id);
      if (line) {
        console.log('text: [VM.startLine] 更新lines列表中的产线状态', `原status=${line.status} → 生产中`);
        line.status = '生产中';
        line.workOrderStatus = '生产中';
        line.currentWorkorderId = workOrderId;
      } else {
        console.log('text: [VM.startLine] 未在lines中找到该产线', `lineId=${id}`);
      }
      if (this.lineDetail.id === id) {
        console.log('text: [VM.startLine] 更新lineDetail状态');
        this.lineDetail.status = '生产中';
        this.lineDetail.currentWorkorderId = workOrderId;
        if (this.lineDetail.activeWorkOrder) {
          this.lineDetail.activeWorkOrder.status = '生产中';
        }
      }
      console.log('text: [VM.startLine] 启动成功');
      return true;
    } catch (e) {
      console.log('text: [VM.startLine] 启动失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async stopLine(id: number): Promise<boolean> {
    console.log('text: [VM.stopLine] 开始停止产线', `lineId=${id}`);
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.stopLine(id);
      const line = this.lines.find(l => l.id === id);
      if (line) {
        console.log('text: [VM.stopLine] 更新lines列表中的产线状态', `原status=${line.status} → 暂停`);
        line.status = '暂停';
        line.workOrderStatus = '暂停中';
      } else {
        console.log('text: [VM.stopLine] 未在lines中找到该产线', `lineId=${id}, lines数量=${this.lines.length}`);
      }
      if (this.lineDetail.id === id) {
        console.log('text: [VM.stopLine] 更新lineDetail状态');
        this.lineDetail.status = '暂停';
        if (this.lineDetail.activeWorkOrder) {
          this.lineDetail.activeWorkOrder.status = '暂停中';
        }
      }
      console.log('text: [VM.stopLine] 停止成功');
      return true;
    } catch (e) {
      console.log('text: [VM.stopLine] 停止失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async resetLine(id: number): Promise<boolean> {
    console.log('text: [VM.resetLine] 开始复位产线', `lineId=${id}`);
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.resetLine(id);
      const line = this.lines.find(l => l.id === id);
      if (line) {
        console.log('text: [VM.resetLine] 更新lines列表中的产线状态', `原status=${line.status} → 空闲`);
        line.status = '空闲';
        line.workOrderStatus = '';
        line.currentWorkorderId = null;
        line.workOrderCode = '';
      } else {
        console.log('text: [VM.resetLine] 未在lines中找到该产线', `lineId=${id}`);
      }
      if (this.lineDetail.id === id) {
        console.log('text: [VM.resetLine] 更新lineDetail状态');
        this.lineDetail.status = '空闲';
        this.lineDetail.currentWorkorderId = null;
        this.lineDetail.activeWorkOrder = null;
      }
      console.log('text: [VM.resetLine] 复位成功');
      return true;
    } catch (e) {
      console.log('text: [VM.resetLine] 复位失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async reportException(lineId: number, description: string): Promise<boolean> {
    console.log('text: [VM.reportException] 开始上报异常', `lineId=${lineId}`);
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await LineApi.reportException(lineId, description);
      const line = this.lines.find(l => l.id === lineId);
      if (line) {
        console.log('text: [VM.reportException] 更新lines列表中的产线状态', `原status=${line.status} → 异常`);
        line.status = '异常';
      }
      if (this.lineDetail.id === lineId) {
        this.lineDetail.status = '异常';
      }
      console.log('text: [VM.reportException] 异常上报成功');
      return true;
    } catch (e) {
      console.log('text: [VM.reportException] 异常上报失败', (e as Error).message);
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  subscribeLine(lineId: number): void {
    console.log('text: [VM.subscribeLine] 订阅产线详情WebSocket', `lineId=${lineId}`);
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
    console.log('text: [VM.unsubscribeLine] 取消订阅产线详情WebSocket', `lineId=${this.activeLineId}`);
    // 不移除 STOMP 订阅 (ws.unsubscribe) — 列表页可能共享同一个 topic
    WebSocketService.removeListener(`/topic/lines/${this.activeLineId}`, this.onLineStatusUpdate);
    WebSocketService.removeListener(`/topic/lines/${this.activeLineId}/stations`, this.onStationUpdate);
    this.activeLineId = 0;
  }

  subscribeLineList(): void {
    console.log('text: [VM.subscribeLineList] 开始订阅列表WebSocket', `当前lines数量=${this.lines.length}, 已订阅=${this.subscribedLineIds.size}`);
    const ws = WebSocketService.getInstance();
    let newCount = 0;
    for (let i = 0; i < this.lines.length; i++) {
      const line = this.lines[i];
      if (this.subscribedLineIds.has(line.id)) {
        continue;
      }
      const topic = `/topic/lines/${line.id}`;
      ws.subscribe(topic);
      WebSocketService.addListener(topic, this.onLineListStatusUpdate);
      this.subscribedLineIds.add(line.id);
      newCount++;
      console.log('text: [VM.subscribeLineList] 新订阅', `lineId=${line.id}, topic=${topic}`);
    }
    console.log('text: [VM.subscribeLineList] 订阅完成', `新增=${newCount}, 总计=${this.subscribedLineIds.size}`);
  }

  unsubscribeLineList(): void {
    console.log('text: [VM.unsubscribeLineList] 开始取消所有列表WebSocket订阅', `订阅数=${this.subscribedLineIds.size}`);
    const ws = WebSocketService.getInstance();
    this.subscribedLineIds.forEach((lineId: number) => {
      const topic = `/topic/lines/${lineId}`;
      console.log('text: [VM.unsubscribeLineList] 取消订阅', `lineId=${lineId}`);
      ws.unsubscribe(topic);
      WebSocketService.removeListener(topic, this.onLineListStatusUpdate);
    });
    this.subscribedLineIds.clear();
    console.log('text: [VM.unsubscribeLineList] 全部取消完成');
  }

  onLineListStatusUpdate = (payload: Object): void => {
    const envelope = payload as Record<string, Object>;
    const lineId = envelope['lineId'] as number | undefined;
    if (!lineId) {
      return;
    }
    const data = envelope['data'] as Record<string, Object> | undefined;
    if (!data) {
      return;
    }
    console.log('text: [VM.onLineListStatusUpdate] 收到WebSocket推送', `lineId=${lineId}, status=${data['status']}, finished=${data['finishedCount']}, ng=${data['ngCount']}, woStatus=${data['woStatus']}`);
    const line = this.lines.find(l => l.id === lineId);
    if (line) {
      if (data['status'] !== undefined) {
        line.status = data['status'] as string;
      }
      if (data['workOrderId'] !== undefined) {
        line.currentWorkorderId = data['workOrderId'] as number ?? null;
      }
      if (data['finishedCount'] !== undefined) {
        line.finishedCount = data['finishedCount'] as number;
      }
      if (data['ngCount'] !== undefined) {
        line.ngCount = data['ngCount'] as number;
      }
      if (data['woStatus'] !== undefined && data['woStatus'] !== null) {
        line.workOrderStatus = data['woStatus'] as string;
      }
      console.log('text: [VM.onLineListStatusUpdate] 已更新lines列表', `lineId=${lineId}, 新status=${line.status}`);
    } else {
      console.log('text: [VM.onLineListStatusUpdate] 未在lines中找到产线', `lineId=${lineId}, 当前lines数量=${this.lines.length}`);
    }
  };

  onLineStatusUpdate = (payload: Object): void => {
    const envelope = payload as Record<string, Object>;
    const data = envelope['data'] as Record<string, Object> | undefined;
    if (data) {
      console.log('text: [VM.onLineStatusUpdate] 收到详情WebSocket推送', `status=${data['status']}, woStatus=${data['woStatus']}`);
      if (data['status'] !== undefined) {
        this.lineDetail.status = data['status'] as string;
      }
      if (data['woStatus'] !== undefined) {
        const ws = data['woStatus'] as string | null;
        if (ws && this.lineDetail.activeWorkOrder) {
          this.lineDetail.activeWorkOrder.status = ws;
          this.lineDetail.currentWorkorderId = this.lineDetail.activeWorkOrder.id;
        } else if (ws === null || ws === undefined) {
          this.lineDetail.currentWorkorderId = null;
          this.lineDetail.activeWorkOrder = null;
        }
      }
    }
  };

  onStationUpdate = (payload: Object): void => {
    const msg = payload as Record<string, Object>;
    const stationData = msg['data'] as Object[];
    if (!stationData) {
      return;
    }
    console.log('text: [VM.onStationUpdate] 收到工位WebSocket推送', `工位数=${stationData.length}`);
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
