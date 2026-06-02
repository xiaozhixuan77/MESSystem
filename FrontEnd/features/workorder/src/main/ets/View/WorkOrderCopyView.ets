import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderCopyView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local sourceWorkOrderId: number = 0;

  aboutToAppear(): void {
    const param = this.pageStack.getParamByName('WorkOrderCopy');
    this.sourceWorkOrderId = ((param as Record<string, Object>)?.['sourceWorkOrderId'] as number) ?? 0;
  }

  build() {
    WorkOrderFormView({ mode: 'copy', sourceWorkOrderId: this.sourceWorkOrderId })
  }
}
