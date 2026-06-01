import {
  WorkOrderListView,
  WorkOrderAddView,
  WorkOrderEditView,
  WorkOrderCopyView,
  PendingDetailView,
  AssignedDetailView,
  RunningDetailView,
  CompletedDetailView,
  ReportedDetailView,
  PausedDetailView
} from '@ohos/workorder';

@ComponentV2
export struct WorkOrderTabDestination {
  @Local workOrderStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';

  @Builder
  PageMap(name: string) {
    if (name === 'WorkOrderList') {
      WorkOrderListView({ role: this.currentRole })
    } else if (name === 'PendingDetail') {
      PendingDetailView()
    } else if (name === 'AssignedDetail') {
      AssignedDetailView()
    } else if (name === 'RunningDetail') {
      RunningDetailView()
    } else if (name === 'CompletedDetail') {
      CompletedDetailView()
    } else if (name === 'ReportedDetail') {
      ReportedDetailView()
    } else if (name === 'PausedDetail') {
      PausedDetailView()
    } else if (name === 'WorkOrderAdd') {
      WorkOrderAddView()
    } else if (name === 'WorkOrderEdit') {
      WorkOrderEditView()
    } else if (name === 'WorkOrderCopy') {
      WorkOrderCopyView()
    }
  }

  build() {
    NavDestination() {
      Navigation(this.workOrderStack) {
        Stack() {}
      }
      .navDestination(this.PageMap)
      .hideTitleBar(true)
      .onAppear(() => {
        this.workOrderStack.replacePath({ name: 'WorkOrderList' });
      })
    }
  }
}
