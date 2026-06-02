import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderCopyView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local sourceWorkOrderId: number = 0;

  aboutToAppear(): void {
    const raw: Object = this.pageStack.getParamByName('WorkOrderCopy') as Object;
    if (raw) {
      const param = raw as Record<string, Object>;
      this.sourceWorkOrderId = (param['sourceWorkOrderId'] as number) ?? 0;
    }
  }

  build() {
    WorkOrderFormView({ mode: 'copy', sourceWorkOrderId: this.sourceWorkOrderId })
  }
}
