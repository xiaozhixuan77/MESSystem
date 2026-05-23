import { LineListView, LineDetailView, StationDetailView } from '@ohos/production';
import { InspectionListView, InspectionDetailView, DashboardView } from '@ohos/quality';

@ComponentV2
export struct DataTab {
  @Provider('pageStack') dataStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'LineList') {
      LineListView();
    } else if (name === 'LineDetail') {
      LineDetailView();
    } else if (name === 'StationDetail') {
      StationDetailView();
    } else if (name === 'InspectionList') {
      InspectionListView();
    } else if (name === 'InspectionDetail') {
      InspectionDetailView();
    } else if (name === 'Dashboard') {
      DashboardView();
    }
  }

  aboutToAppear(): void {
    this.dataStack.replacePath({ name: 'LineList' });
  }

  build() {
    Navigation(this.dataStack) {
      Stack() {}
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
  }
}
