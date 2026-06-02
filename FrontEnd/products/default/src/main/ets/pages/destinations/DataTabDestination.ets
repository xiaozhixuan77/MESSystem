import { LineListView, LineDetailView, StationDetailView } from '@ohos/production';
import { InspectionListView, InspectionDetailView, DashboardView } from '@ohos/quality';

@ComponentV2
export struct DataTabDestination {
  @Provider('pageStack') dataStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    NavDestination() {
      if (name === 'LineList') {
        LineListView()
      } else if (name === 'LineDetail') {
        LineDetailView()
      } else if (name === 'StationDetail') {
        StationDetailView()
      } else if (name === 'InspectionList') {
        InspectionListView()
      } else if (name === 'InspectionDetail') {
        InspectionDetailView()
      } else if (name === 'Dashboard') {
        DashboardView()
      }
    }
    .hideTitleBar(true)
  }

  build() {
    NavDestination() {
      Navigation(this.dataStack) {
        LineListView()
      }
      .navDestination(this.PageMap)
      .hideTitleBar(true)
    }
    .hideTitleBar(true)
  }
}
