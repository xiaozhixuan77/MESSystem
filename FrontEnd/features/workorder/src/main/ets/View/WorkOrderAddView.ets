import { WorkOrderFormView } from './WorkOrderFormView';

@ComponentV2
export struct WorkOrderAddView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();

  build() {
    WorkOrderFormView({ mode: 'add' })
  }
}
