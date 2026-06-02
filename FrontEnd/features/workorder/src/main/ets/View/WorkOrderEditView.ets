import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderEditView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const param = this.pageStack.getParamByName('WorkOrderEdit');
    this.workOrderId = ((param as Record<string, Object>)?.['workOrderId'] as number) ?? 0;
  }

  build() {
    WorkOrderFormView({ mode: 'edit', workOrderId: this.workOrderId })
  }
}
