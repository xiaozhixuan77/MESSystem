import { emitter } from '@kit.BasicServicesKit';
import { WORKORDER_CHANGED_EVENT } from '@ohos/datastore';
import { WorkOrderApi, WorkshopApi, ProductApi, LineApi, UserApi, QualityApi, WebSocketService } from '@ohos/network';
import { UserModel } from '@ohos/user';
import { WorkOrderModel } from '../Model/WorkOrderModel';
import { WorkshopModel } from '../Model/WorkshopModel';
import { ProductModel } from '../Model/ProductModel';
import { ProcessStepModel } from '../Model/ProcessStepModel';
import { LineModel } from '../Model/LineModel';
import { WorkOrderRouteModel } from '../Model/WorkOrderRouteModel';
import { InspectionRecordModel } from '../Model/InspectionRecordModel';

@ObservedV2
export class WorkOrderViewModel {
  @Trace workOrderList: WorkOrderModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace searchKeyword: string = '';
  @Trace statusFilter: string = '';
  @Trace typeFilter: string = '';
  @Trace currentWorkOrder: WorkOrderModel | null = null;

  // —— 表单状态 ——
  @Trace workshops: WorkshopModel[] = [];
  @Trace lines: LineModel[] = [];
  @Trace products: ProductModel[] = [];
  @Trace formMode: string = 'add';
  @Trace formCode: string = '';
  @Trace formType: string = '量产';
  @Trace formWorkshopId: number = 0;
  @Trace formLineId: number = 0;
  @Trace formProductId: number = 0;
  @Trace formProductName: string = '';
  @Trace formProductCode: string = '';
  @Trace formProcessId: number = 0;
  @Trace formProcessName: string = '';
  @Trace formProcessSteps: ProcessStepModel[] = [];
  @Trace formPlanQty: number = 0;
  @Trace formPlanStartTime: string = '';
  @Trace formPlanEndTime: string = '';
  @Trace formVersion: number = -1;
  @Trace formSourceWorkOrderId: number = 0;
  @Trace formSourceWorkOrderCode: string = '';
  @Trace isSubmitting: boolean = false;

  // —— 详情页状态 ——
  @Trace operators: UserModel[] = [];
  @Trace selectedOperatorId: number = 0;
  @Trace reportFormGood: number = 0;
  @Trace reportFormNg: number = 0;
  @Trace reportFormHours: number = 0;
  @Trace reportFormNote: string = '';

  // 实时生产进度（从工站 WebSocket 聚合）
  @Trace stationTotalOutput: number = 0;
  @Trace stationTotalNg: number = 0;
  @Trace stationProcessedCount: number = 0;
  @Trace elapsedText: string = '--';
  private elapsedTimer: number = -1;
  private subscribedStationLineId: number = 0;

  // WebSocket 订阅管理
  private subscribedLineIds: Set<number> = new Set();

  // 抽检数据
  @Trace inspectionList: InspectionRecordModel[] = [];
  @Trace inspectionLoading: boolean = false;
  @Trace inspectionError: string = '';
  private subscribedInspection: boolean = false;

  subscribeWorkOrderUpdates(lineId: number): void {
    if (this.subscribedLineIds.has(lineId)) return;
    this.subscribedLineIds.add(lineId);
    const topic = `/topic/lines/${lineId}/workorders`;
    const ws = WebSocketService.getInstance();
    ws.subscribe(topic);
    WebSocketService.addListener(topic, this.onWorkOrderUpdate);
  }

  unsubscribeWorkOrderUpdates(lineId: number): void {
    if (!this.subscribedLineIds.has(lineId)) return;
    this.subscribedLineIds.delete(lineId);
    const topic = `/topic/lines/${lineId}/workorders`;
    WebSocketService.removeListener(topic, this.onWorkOrderUpdate);
  }

  subscribeStationUpdates(lineId: number): void {
    if (this.subscribedStationLineId === lineId) return;
    this.unsubscribeStationUpdates();
    this.subscribedStationLineId = lineId;
    const topic = `/topic/lines/${lineId}/stations`;
    const ws = WebSocketService.getInstance();
    ws.subscribe(topic);
    WebSocketService.addListener(topic, this.onStationUpdate);
  }

  unsubscribeStationUpdates(): void {
    if (this.subscribedStationLineId <= 0) return;
    const topic = `/topic/lines/${this.subscribedStationLineId}/stations`;
    WebSocketService.removeListener(topic, this.onStationUpdate);
    this.subscribedStationLineId = 0;
  }

  private onWorkOrderUpdate = (payload: Object): void => {
    const envelope = payload as Record<string, Object>;
    if (envelope['type'] !== 'WORKORDER_UPDATE') return;

    const data = envelope['data'] as Record<string, Object>;
    if (!data) return;

    const woId = data['workOrderId'] as number;
    const newStatus = data['status'] as string;

    try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}

    if (this.currentWorkOrder && this.currentWorkOrder.id === woId) {
      this.currentWorkOrder.status = newStatus;
    }
  };

  private onStationUpdate = (payload: Object): void => {
    const msg = payload as Record<string, Object>;
    const lineId = msg['lineId'] as number | undefined;
    const stationData = msg['data'] as Object[];
    if (!lineId || !stationData || stationData.length === 0) return;
    if (!this.currentWorkOrder || this.currentWorkOrder.lineId !== lineId) return;

    const routeStationIds = this.currentWorkOrder.routeSteps
      .map(s => s.stationId)
      .filter((id: number | null) => id !== null) as number[];
    if (routeStationIds.length === 0) return;

    // 最后工序步骤工站：总产出=finished+ng
    const lastStationId = routeStationIds[routeStationIds.length - 1];
    const lastStation = stationData.find(
      (s: Object) => (s as Record<string, Object>)['stationId'] === lastStationId
    ) as Record<string, Object> | undefined;
    if (lastStation) {
      const lastFinished = (lastStation['finishedCount'] as number) ?? 0;
      const lastNg = (lastStation['ngCount'] as number) ?? 0;
      this.stationTotalOutput = lastFinished + lastNg;
      this.stationTotalNg = lastNg;
      this.stationProcessedCount = (lastStation['processedCount'] as number) ?? this.stationProcessedCount;
    }

    // 回填各工序步骤的工站数据
    for (const step of this.currentWorkOrder.routeSteps) {
      if (step.stationId === null) continue;
      const update = stationData.find(
        (s: Object) => (s as Record<string, Object>)['stationId'] === step.stationId
      ) as Record<string, Object> | undefined;
      if (update) {
        step.stationProcessedCount = (update['processedCount'] as number) ?? step.stationProcessedCount;
        step.stationFinishedCount = (update['finishedCount'] as number) ?? step.stationFinishedCount;
        step.stationNgCount = (update['ngCount'] as number) ?? step.stationNgCount;
        step.stationDeviceStatus = (update['deviceStatus'] as string) ?? step.stationDeviceStatus;
      }
    }
  };

  get filteredList(): WorkOrderModel[] {
    if (!this.searchKeyword) {
      return this.workOrderList;
    }
    const kw = this.searchKeyword.toLowerCase();
    return this.workOrderList.filter(wo => wo.code.toLowerCase().includes(kw));
  }

  async loadWorkOrders(silent?: boolean): Promise<void> {
    if (!silent) {
      this.isLoading = true;
    }
    this.errorMessage = '';
    try {
      const params: Record<string, string | number> = {};
      if (this.statusFilter) params['status'] = this.statusFilter;
      if (this.typeFilter) params['type'] = this.typeFilter;
      const raw = await WorkOrderApi.getWorkOrders(params) as WorkOrderModel[];
      raw.sort((a, b) => a.code.localeCompare(b.code));
      this.workOrderList = raw;
    } catch (e) {
      if (!silent) {
        this.errorMessage = (e as Error).message;
      }
    } finally {
      if (!silent) {
        this.isLoading = false;
      }
    }
  }

  async loadDetail(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const raw = await WorkOrderApi.getWorkOrderDetail(id) as Record<string, Object>;
      const wo = new WorkOrderModel();
      wo.id = raw['id'] as number;
      wo.code = raw['code'] as string;
      wo.type = raw['type'] as string;
      wo.workshopId = raw['workshopId'] as number;
      wo.lineId = raw['lineId'] as number;
      wo.productId = raw['productId'] as number;
      wo.processId = raw['processId'] as number;
      wo.planQty = raw['planQty'] as number;
      wo.status = raw['status'] as string;
      wo.operatorId = (raw['operatorId'] as number) ?? null;
      wo.productName = (raw['productName'] as string) ?? '';
      wo.workshopName = (raw['workshopName'] as string) ?? '';
      wo.lineName = (raw['lineName'] as string) ?? '';
      wo.operatorName = (raw['operatorName'] as string) ?? '';
      wo.planStartTime = (raw['planStartTime'] as string) ?? '';
      wo.planEndTime = (raw['planEndTime'] as string) ?? '';
      wo.createdAt = (raw['createdAt'] as string) ?? '';
      wo.version = raw['version'] as number;
      wo.dispatchTime = (raw['dispatchTime'] as string) ?? '';
      wo.actualStartTime = (raw['actualStartTime'] as string) ?? '';
      wo.actualEndTime = (raw['actualEndTime'] as string) ?? '';
      wo.reportedQtyGood = (raw['reportedQtyGood'] as number) ?? 0;
      wo.reportedQtyNg = (raw['reportedQtyNg'] as number) ?? 0;
      wo.reportedHours = (raw['reportedHours'] as number) ?? 0;
      wo.exceptionNote = (raw['exceptionNote'] as string) ?? '';
      wo.source = (raw['source'] as string) ?? '';
      wo.createdByName = (raw['createdByName'] as string) ?? '';
      wo.sourceWorkorderId = (raw['sourceWorkorderId'] as number) ?? 0;
      wo.processName = (raw['processName'] as string) ?? '';
      wo.pauseTime = (raw['pauseTime'] as string) ?? '';
      wo.stationTotalOutput = (raw['stationTotalOutput'] as number) ?? 0;
      wo.stationTotalNg = (raw['stationTotalNg'] as number) ?? 0;
      wo.stationProcessedCount = (raw['stationProcessedCount'] as number) ?? 0;
      wo.elapsedSeconds = (raw['elapsedSeconds'] as number) ?? 0;
      const stepsRaw = raw['routeSteps'] as Object[];
      wo.routeSteps = (stepsRaw || []).map((s: Object) => {
        const step = new WorkOrderRouteModel();
        const r = s as Record<string, Object>;
        step.id = r['id'] as number;
        step.seqNo = r['seqNo'] as number;
        step.opCode = r['opCode'] as string;
        step.name = r['name'] as string;
        step.stationId = (r['stationId'] as number) ?? null;
        step.stationProcessedCount = (r['stationProcessedCount'] as number) ?? 0;
        step.stationFinishedCount = (r['stationFinishedCount'] as number) ?? 0;
        step.stationNgCount = (r['stationNgCount'] as number) ?? 0;
        step.stationDeviceStatus = (r['stationDeviceStatus'] as string) ?? '';
        return step;
      });
      // 详情加载后初始化实时状态
      this.stationTotalOutput = wo.stationTotalOutput;
      this.stationTotalNg = wo.stationTotalNg;
      this.stationProcessedCount = wo.stationProcessedCount;
      this.startElapsedTimer(wo);
      // 报工默认值：总产出=良品+NG，分离良品预填
      const totalOutput = wo.stationTotalOutput;
      if (totalOutput > 0) {
        this.reportFormGood = totalOutput - wo.stationTotalNg;
        this.reportFormNg = wo.stationTotalNg;
      } else {
        this.reportFormGood = wo.planQty;
        this.reportFormNg = 0;
      }
      this.currentWorkOrder = wo;
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  // ========== 详情页动作方法 ==========

  async loadOperators(): Promise<void> {
    try {
      const raw = await UserApi.getUsers('operator', undefined, '在岗') as Record<string, Object>[];
      this.operators = raw.map((r: Record<string, Object>): UserModel => {
        const u = new UserModel();
        u.id = r['id'] as number;
        u.employeeNo = r['employeeNo'] as string;
        u.name = r['name'] as string;
        u.role = r['role'] as string;
        u.workshopId = (r['workshopId'] as number) ?? null;
        u.teamId = (r['teamId'] as number) ?? null;
        u.status = (r['status'] as string) ?? '';
        return u;
      });
      if (this.operators.length > 0 && this.selectedOperatorId === 0) {
        this.selectedOperatorId = this.operators[0].id;
      }
    } catch (e) {
      // 忽略加载失败
    }
  }

  async dispatchWorkOrder(workOrderId: number): Promise<boolean> {
    if (this.selectedOperatorId <= 0) {
      this.errorMessage = '请选择操作员';
      return false;
    }
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.dispatchWorkOrder(workOrderId, this.selectedOperatorId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async startWorkOrder(workOrderId: number): Promise<boolean> {
    if (this.stationTotalOutput > 0 || this.stationProcessedCount > 0) {
      this.errorMessage = '产线未复位，上轮生产数据残留。请先前往产线详情页复位产线';
      return false;
    }
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.startWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async pauseWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.pauseWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async resumeWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.resumeWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async reportWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const data: Record<string, Object> = {
        'good': this.reportFormGood,
        'ng': this.reportFormNg,
        'hours': this.reportFormHours,
        'note': this.reportFormNote
      };
      await WorkOrderApi.reportWorkOrder(workOrderId, data);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async confirmWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.confirmWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async completeWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.completeWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async scrapWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.scrapWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async deleteWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.deleteWorkOrder(workOrderId);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  // ========== 表单方法 ==========

  async loadWorkshops(): Promise<void> {
    try {
      this.workshops = await WorkshopApi.getWorkshops() as WorkshopModel[];
    } catch (e) {
      // 忽略加载失败
    }
  }

  async loadLines(workshopId?: number): Promise<void> {
    try {
      const params: Record<string, string | number> = {};
      if (workshopId) {
        params['workshopId'] = workshopId;
      }
      this.lines = await LineApi.getLines(params) as LineModel[];
    } catch (e) {
      // 忽略加载失败
    }
  }

  async searchProducts(keyword: string): Promise<void> {
    try {
      const kw = keyword?.trim();
      this.products = await ProductApi.getProducts(kw || undefined) as ProductModel[];
    } catch (e) {
      // 忽略加载失败
    }
  }

  async selectProduct(product: ProductModel): Promise<void> {
    this.formProductId = product.id;
    this.formProductCode = product.code;
    this.formProductName = product.name;
    this.products = [];
    if (product.defaultProcessId > 0) {
      try {
        const process = await ProductApi.getProductProcess(product.code) as Record<string, Object>;
        this.formProcessId = process['id'] as number;
        this.formProcessName = process['name'] as string;
        const stepsRaw = process['steps'] as Object[];
        this.formProcessSteps = (stepsRaw || []).map((s: Object) => {
          const step = new ProcessStepModel();
          const r = s as Record<string, Object>;
          step.id = r['id'] as number;
          step.seqNo = r['seqNo'] as number;
          step.opCode = r['opCode'] as string;
          step.name = r['name'] as string;
          return step;
        });
      } catch (e) {
        // 工艺加载失败，清空
        this.formProcessId = 0;
        this.formProcessName = '';
        this.formProcessSteps = [];
      }
    }
  }

  onWorkshopChange(workshopId: number): void {
    this.formWorkshopId = workshopId;
    this.formLineId = 0;
    this.loadLines(workshopId);
  }

  async loadForEdit(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const detail = await WorkOrderApi.getWorkOrderDetail(id) as Record<string, Object>;
      if (detail['status'] as string !== '待派工') {
        this.errorMessage = '仅待派工状态可编辑';
        return;
      }
      this.formCode = detail['code'] as string;
      this.formType = detail['type'] as string;
      this.formWorkshopId = detail['workshopId'] as number;
      this.formLineId = detail['lineId'] as number;
      this.formProductId = detail['productId'] as number;
      this.formProductName = detail['productName'] as string;
      this.formProcessId = detail['processId'] as number;
      this.formProcessName = (detail['processName'] as string) ?? '';
      this.formPlanQty = detail['planQty'] as number;
      this.formPlanStartTime = this.formatDateStr(detail['planStartTime'] as string);
      this.formPlanEndTime = this.formatDateStr(detail['planEndTime'] as string);
      this.formVersion = detail['version'] as number;
      // 加载工序步骤
      const stepsRaw = detail['routeSteps'] as Object[];
      this.formProcessSteps = (stepsRaw || []).map((s: Object) => {
        const step = new ProcessStepModel();
        const r = s as Record<string, Object>;
        step.id = r['id'] as number;
        step.seqNo = r['seqNo'] as number;
        step.opCode = r['opCode'] as string;
        step.name = r['name'] as string;
        return step;
      });
      await this.loadWorkshops();
      if (this.formWorkshopId > 0) {
        await this.loadLines(this.formWorkshopId);
      }
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadForCopy(id: number): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const detail = await WorkOrderApi.getWorkOrderDetail(id) as Record<string, Object>;
      this.formSourceWorkOrderId = id;
      this.formSourceWorkOrderCode = detail['code'] as string;
      this.formCode = detail['code'] as string;
      this.formType = detail['type'] as string;
      this.formWorkshopId = detail['workshopId'] as number;
      this.formLineId = detail['lineId'] as number;
      this.formProductId = detail['productId'] as number;
      this.formProductName = detail['productName'] as string;
      this.formProcessId = detail['processId'] as number;
      this.formProcessName = (detail['processName'] as string) ?? '';
      this.formPlanQty = detail['planQty'] as number;
      this.formPlanStartTime = this.formatDateStr(detail['planStartTime'] as string);
      this.formPlanEndTime = this.formatDateStr(detail['planEndTime'] as string);
      // 加载工序步骤
      const stepsRaw = detail['routeSteps'] as Object[];
      this.formProcessSteps = (stepsRaw || []).map((s: Object) => {
        const step = new ProcessStepModel();
        const r = s as Record<string, Object>;
        step.id = r['id'] as number;
        step.seqNo = r['seqNo'] as number;
        step.opCode = r['opCode'] as string;
        step.name = r['name'] as string;
        return step;
      });
      // 加载车间/产线选项
      await this.loadWorkshops();
      if (this.formWorkshopId > 0) {
        await this.loadLines(this.formWorkshopId);
      }
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  validateForm(): string | null {
    if (!this.formType || !['试产', '量产', '返工'].includes(this.formType)) {
      return '请选择有效的工单类型';
    }
    if (!this.formWorkshopId || this.formWorkshopId <= 0) {
      return '请选择所属车间';
    }
    if (!this.formLineId || this.formLineId <= 0) {
      return '请选择所属产线';
    }
    if (!this.formProductId || this.formProductId <= 0) {
      return '请选择产品';
    }
    if (!this.formPlanQty || this.formPlanQty <= 0) {
      return '计划数量必须大于0';
    }
    if (this.formPlanStartTime && this.formPlanEndTime) {
      if (new Date(this.formPlanStartTime).getTime() >= new Date(this.formPlanEndTime).getTime()) {
        return '计划开始时间必须早于计划完成时间';
      }
    }
    if (this.formMode === 'edit' && this.formVersion < 0) {
      return '缺少版本号，无法更新';
    }
    return null;
  }

  async submitCreate(): Promise<boolean> {
    const err = this.validateForm();
    if (err) {
      this.errorMessage = err;
      return false;
    }
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const body: Record<string, Object> = {
        'type': this.formType,
        'workshopId': this.formWorkshopId,
        'lineId': this.formLineId,
        'productId': this.formProductId,
        'planQty': this.formPlanQty
      };
      if (this.formPlanStartTime) {
        body['planStartTime'] = this.formPlanStartTime.replace(' ', 'T') + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime.replace(' ', 'T') + ':00';
      }
      await WorkOrderApi.createWorkOrder(body);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async submitUpdate(id: number): Promise<boolean> {
    const err = this.validateForm();
    if (err) {
      this.errorMessage = err;
      return false;
    }
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const body: Record<string, Object> = {
        'type': this.formType,
        'workshopId': this.formWorkshopId,
        'lineId': this.formLineId,
        'productId': this.formProductId,
        'planQty': this.formPlanQty,
        'version': this.formVersion
      };
      if (this.formPlanStartTime) {
        body['planStartTime'] = this.formPlanStartTime.replace(' ', 'T') + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime.replace(' ', 'T') + ':00';
      }
      await WorkOrderApi.updateWorkOrder(id, body);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async submitCopy(sourceId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      const body: Record<string, Object> = {};
      if (this.formPlanQty > 0) {
        body['planQty'] = this.formPlanQty;
      }
      if (this.formPlanStartTime) {
        body['planStartTime'] = this.formPlanStartTime.replace(' ', 'T') + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime.replace(' ', 'T') + ':00';
      }
      await WorkOrderApi.copyWorkOrder(sourceId, body);
      try { emitter.emit(WORKORDER_CHANGED_EVENT, { data: {} }); } catch (e) {}
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async submitForm(): Promise<boolean> {
    if (this.formMode === 'edit') {
      return this.submitUpdate(0); // workOrderId 由 View 层管理
    } else if (this.formMode === 'copy') {
      return this.submitCopy(this.formSourceWorkOrderId);
    }
    return this.submitCreate();
  }

  private formatDateStr(raw: string | null): string {
    if (!raw) {
      return '';
    }
    const str = raw.replace('T', ' ');
    return str.length >= 16 ? str.substring(0, 16) : str;
  }

  startElapsedTimer(wo: WorkOrderModel): void {
    this.stopElapsedTimer();
    if (!wo.actualStartTime || wo.actualStartTime.length === 0) {
      this.elapsedText = '--';
      return;
    }
    const startTime = new Date(wo.actualStartTime.replace(' ', 'T')).getTime();
    const update = (): void => {
      let endTime: number;
      if (wo.status === '暂停中' && wo.pauseTime && wo.pauseTime.length > 0) {
        endTime = new Date(wo.pauseTime.replace(' ', 'T')).getTime();
      } else if ((wo.status === '生产完成' || wo.status === '已报工' || wo.status === '完工')
        && wo.actualEndTime && wo.actualEndTime.length > 0) {
        endTime = new Date(wo.actualEndTime.replace(' ', 'T')).getTime();
      } else {
        endTime = Date.now();
      }
      const seconds = Math.max(0, Math.floor((endTime - startTime) / 1000));
      this.elapsedText = this.formatElapsed(seconds);
    };
    update();
    this.elapsedTimer = setInterval(update, 1000);
  }

  stopElapsedTimer(): void {
    if (this.elapsedTimer !== -1) {
      clearInterval(this.elapsedTimer);
      this.elapsedTimer = -1;
    }
  }

  private formatElapsed(totalSeconds: number): string {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;
    const pad = (n: number) => n < 10 ? '0' + n : '' + n;
    return `${pad(h)}:${pad(m)}:${pad(s)}`;
  }

  cleanup(): void {
    this.unsubscribeStationUpdates();
    this.unsubscribeInspectionUpdates();
    this.stopElapsedTimer();
  }

  // ========== 抽检相关 ==========

  async loadInspections(workOrderId: number): Promise<void> {
    this.inspectionLoading = true;
    this.inspectionError = '';
    try {
      const params: Record<string, Object> = { 'workOrderId': workOrderId };
      const raw = await QualityApi.getInspections(params) as Record<string, Object>[];
      this.inspectionList = raw.map((r: Record<string, Object>) => {
        const m = new InspectionRecordModel();
        m.id = r['id'] as number;
        m.workOrderId = r['workOrderId'] as number;
        m.inspectorId = r['inspectorId'] as number;
        m.inspectorName = r['inspectorName'] as string;
        m.inspectTime = r['inspectTime'] as string;
        m.sampleQty = r['sampleQty'] as number;
        m.sampleGood = r['sampleGood'] as number;
        m.sampleNg = r['sampleNg'] as number;
        m.defectTypes = r['defectTypes'] as string;
        m.defectDescription = r['defectDescription'] as string;
        m.conclusion = r['conclusion'] as string;
        m.status = r['status'] as string;
        m.workOrderCode = r['workOrderCode'] as string;
        m.productName = r['productName'] as string;
        m.processName = r['processName'] as string;
        return m;
      });
    } catch (e) {
      this.inspectionError = (e as Error).message || '加载抽检记录失败';
    } finally {
      this.inspectionLoading = false;
    }
  }

  subscribeInspectionUpdates(): void {
    if (this.subscribedInspection) {
      return;
    }
    this.subscribedInspection = true;
    const topic = '/topic/inspections';
    const ws = WebSocketService.getInstance();
    ws.subscribe(topic);
    WebSocketService.addListener(topic, this.onInspectionUpdate);
  }

  unsubscribeInspectionUpdates(): void {
    if (!this.subscribedInspection) {
      return;
    }
    this.subscribedInspection = false;
    const topic = '/topic/inspections';
    WebSocketService.removeListener(topic, this.onInspectionUpdate);
  }

  private onInspectionUpdate = (payload: Object): void => {
    const msg = payload as Record<string, Object>;
    if (msg['type'] !== 'INSPECTION_UPDATE') {
      return;
    }
    const data = msg['data'] as Record<string, Object>;
    if (!data) {
      return;
    }
    const woId = data['workOrderId'] as number;
    if (this.currentWorkOrder && woId === this.currentWorkOrder.id) {
      this.loadInspections(woId);
    }
  };
}
