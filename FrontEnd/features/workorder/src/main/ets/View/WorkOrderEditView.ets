import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderEditView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const raw: Object = this.pageStack.getParamByName('WorkOrderEdit') as Object;
    if (raw) {
      const param = raw as Record<string, Object>;
      this.workOrderId = (param['workOrderId'] as number) ?? 0;
    }
  }

  build() {
    WorkOrderFormView({ mode: 'edit', workOrderId: this.workOrderId })
  }
}
