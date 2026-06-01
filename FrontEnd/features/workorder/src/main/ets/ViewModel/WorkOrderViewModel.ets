import { WorkOrderApi } from '@ohos/network';
import { WorkOrderModel } from '../Model/WorkOrderModel';

@ObservedV2
export class WorkOrderViewModel {
  @Trace workOrderList: WorkOrderModel[] = [];
  @Trace currentWorkOrder: WorkOrderModel | null = null;
  @Trace isLoading: boolean = false;
  @Trace statusFilter: string = '';
  @Trace errorMessage: string = '';

  async loadWorkOrders(role: string, filters?: object): Promise<void> {
    this.isLoading = true;
    try {
      const params: Record<string, Object> = {};
      params['role'] = role;
      if (filters) {
        const filterRecord = filters as Record<string, Object>;
        const filterKeys = Object.keys(filterRecord);
        for (let i = 0; i < filterKeys.length; i++) {
          const key = filterKeys[i];
          params[key] = filterRecord[key];
        }
      }
      this.workOrderList = await WorkOrderApi.getWorkOrders(params) as WorkOrderModel[];
    } catch (e) {
      this.errorMessage = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadDetail(id: number): Promise<void> {
    this.isLoading = true;
    try {
      this.currentWorkOrder = await WorkOrderApi.getWorkOrderDetail(id) as WorkOrderModel;
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
}
