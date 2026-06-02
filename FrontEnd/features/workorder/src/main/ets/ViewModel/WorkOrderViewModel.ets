import { WorkOrderApi } from '@ohos/network';
import { WorkOrderModel } from '../Model/WorkOrderModel';

@ObservedV2
export class WorkOrderViewModel {
  @Trace workOrderList: WorkOrderModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace searchKeyword: string = '';
  @Trace statusFilter: string = '';
  @Trace typeFilter: string = '';
  @Trace currentWorkOrder: WorkOrderModel | null = null;

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
      this.currentWorkOrder = await WorkOrderApi.getWorkOrderDetail(id) as WorkOrderModel;
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
}
