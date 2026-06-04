import { LineListView, LineDetailView, StationDetailView, ProductionViewModel } from '@ohos/production';
import { InspectionListView, InspectionDetailView, DashboardView } from '@ohos/quality';

@ComponentV2
export struct DataTabDestination {
  @Provider('pageStack') dataStack: NavPathStack = new NavPathStack();
  @Provider('sharedVm') lineListVm: ProductionViewModel = new ProductionViewModel();

  aboutToDisappear(): void {
    console.log('text: [DataTab.aboutToDisappear] Tab即将销毁，清理所有WS订阅');
    this.lineListVm.unsubscribeLineList();
  }

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
    .onShown(() => {
      console.log('text: [DataTab.PageMap.onShown] NavDestination显示', `name=${name}`);
      if (name === 'LineList') {
        if (this.lineListVm.lines.length > 0) {
          this.lineListVm.lines = [];
        }
        this.lineListVm.loadLines();
      }
    })
  }

  build() {
    NavDestination() {
      Navigation(this.dataStack) {
        Stack() {}
      }
      .navDestination(this.PageMap)
      .hideTitleBar(true)
      .onAppear(() => {
        console.log('text: [DataTab.Navigation.onAppear] 内部Navigation出现', `stackSize=${this.dataStack.size()}`);
        if (this.dataStack.size() === 0) {
          console.log('text: [DataTab.Navigation.onAppear] 初始化栈，replacePath LineList');
          this.dataStack.replacePath({ name: 'LineList' });
        }
      })
    }
    .hideTitleBar(true)
  }
}
