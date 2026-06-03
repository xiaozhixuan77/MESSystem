import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderEditView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
  }

  build() {
    WorkOrderFormView({ mode: 'edit', workOrderId: this.workOrderId })
  }
}
