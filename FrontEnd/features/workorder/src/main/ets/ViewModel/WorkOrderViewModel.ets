import { WorkOrderApi, WorkshopApi, ProductApi, LineApi, UserApi } from '@ohos/network';
import { UserModel } from '@ohos/user';
import { WorkOrderModel } from '../Model/WorkOrderModel';
import { WorkshopModel } from '../Model/WorkshopModel';
import { ProductModel } from '../Model/ProductModel';
import { ProcessStepModel } from '../Model/ProcessStepModel';
import { LineModel } from '../Model/LineModel';
import { WorkOrderRouteModel } from '../Model/WorkOrderRouteModel';

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
  @Trace formVersion: number = 0;
  @Trace formSourceWorkOrderId: number = 0;
  @Trace formSourceWorkOrderCode: string = '';
  @Trace isSubmitting: boolean = false;

  // —— 详情页状态 ——
  @Trace operators: UserModel[] = [];
  @Trace selectedOperatorId: number = 0;
  @Trace pauseReason: string = '';
  @Trace scrapReason: string = '';
  @Trace reportFormGood: number = 0;
  @Trace reportFormNg: number = 0;
  @Trace reportFormHours: number = 0;
  @Trace reportFormNote: string = '';

  get filteredList(): WorkOrderModel[] {
    if (!this.searchKeyword) {
      return this.workOrderList;
    }
    const kw = this.searchKeyword.toLowerCase();
    return this.workOrderList.filter(wo => wo.code.toLowerCase().includes(kw));
  }

  async loadWorkOrders(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const params: Record<string, string | number> = {};
      if (this.statusFilter) params['status'] = this.statusFilter;
      if (this.typeFilter) params['type'] = this.typeFilter;
      this.workOrderList = await WorkOrderApi.getWorkOrders(params) as WorkOrderModel[];
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
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
      const stepsRaw = raw['routeSteps'] as Object[];
      wo.routeSteps = (stepsRaw || []).map((s: Object) => {
        const step = new WorkOrderRouteModel();
        const r = s as Record<string, Object>;
        step.id = r['id'] as number;
        step.seqNo = r['seqNo'] as number;
        step.opCode = r['opCode'] as string;
        step.name = r['name'] as string;
        step.stationId = (r['stationId'] as number) ?? null;
        return step;
      });
      this.currentWorkOrder = wo;
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  get canDispatch(): boolean {
    return this.currentWorkOrder?.status === '待派工';
  }

  get canStart(): boolean {
    return this.currentWorkOrder?.status === '已派工';
  }

  get canPause(): boolean {
    return this.currentWorkOrder?.status === '生产中';
  }

  get canResume(): boolean {
    return this.currentWorkOrder?.status === '暂停中';
  }

  get canReport(): boolean {
    return this.currentWorkOrder?.status === '生产完成';
  }

  get canConfirm(): boolean {
    return this.currentWorkOrder?.status === '已报工';
  }

  // ========== 详情页动作方法 ==========

  async loadOperators(): Promise<void> {
    try {
      const params: Record<string, string> = { 'role': 'operator' };
      const raw = await UserApi.getUsers(params) as Record<string, Object>[];
      this.operators = raw.map((r: Record<string, Object>): UserModel => {
        const u = new UserModel();
        u.id = r['id'] as number;
        u.employeeNo = r['employeeNo'] as string;
        u.name = r['name'] as string;
        u.role = r['role'] as string;
        u.workshopId = (r['workshopId'] as number) ?? null;
        u.teamId = (r['teamId'] as number) ?? null;
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
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async startWorkOrder(workOrderId: number): Promise<boolean> {
    this.isSubmitting = true;
    this.errorMessage = '';
    try {
      await WorkOrderApi.startWorkOrder(workOrderId);
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
    if (!keyword || keyword.trim().length === 0) {
      this.products = [];
      return;
    }
    try {
      this.products = await ProductApi.getProducts(keyword.trim()) as ProductModel[];
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
    if (this.formMode === 'edit' && (!this.formVersion || this.formVersion <= 0)) {
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
        body['planStartTime'] = this.formPlanStartTime + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime + ':00';
      }
      await WorkOrderApi.createWorkOrder(body);
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
        body['planStartTime'] = this.formPlanStartTime + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime + ':00';
      }
      await WorkOrderApi.updateWorkOrder(id, body);
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
        body['planStartTime'] = this.formPlanStartTime + ':00';
      }
      if (this.formPlanEndTime) {
        body['planEndTime'] = this.formPlanEndTime + ':00';
      }
      await WorkOrderApi.copyWorkOrder(sourceId, body);
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
    // Convert ISO "2026-06-02T08:00:00" or "2026-06-02 08:00:00" to "2026-06-02 08:00"
    const str = raw.replace('T', ' ');
    return str.length >= 16 ? str.substring(0, 16) : str;
  }
}
