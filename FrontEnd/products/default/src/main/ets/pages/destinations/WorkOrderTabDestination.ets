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
import { DeepLinkInfo } from '@ohos/utils';

@ComponentV2
export struct WorkOrderTabDestination {
  @Provider('pageStack') workOrderStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;

  @Builder
  PageMap(name: string) {
    NavDestination() {
      if (name === 'WorkOrderList') {
        WorkOrderListView()
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
    .hideTitleBar(true)
  }

  build() {
    NavDestination() {
      Navigation(this.workOrderStack) {
        WorkOrderListView()
      }
      .navDestination(this.PageMap)
      .hideTitleBar(true)
      .onAppear(() => {
        if (this.deepLink && this.deepLink.targetTab === 'WorkOrderTab') {
          this.workOrderStack.pushPathByName(this.deepLink.targetPage, this.deepLink.params);
          this.deepLink = null;
        }
      })
    }
    .hideTitleBar(true)
  }
}
