import { LineListView, LineDetailView, StationDetailView, LineEditView, ProductionViewModel } from '@ohos/production';
import { InspectionListView, InspectionDetailView, DashboardView, ExceptionListView, ExceptionDetailView } from '@ohos/quality';
import { Colors, DeepLinkInfo } from '@ohos/utils';

@ComponentV2
export struct DataTabDestination {
  @Provider('pageStack') dataStack: NavPathStack = new NavPathStack();
  @Provider('sharedVm') lineListVm: ProductionViewModel = new ProductionViewModel();
  @Provider('detailStack') detailStack: NavPathStack = new NavPathStack();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;
  @Consumer('currentBreakpoint') currentBreakpoint: string = 'sm';
  @Local currentView: string = 'LineList';

  aboutToAppear(): void {
    this.lineListVm.loadLines();
  }

  aboutToDisappear(): void {
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
      } else if (name === 'ExceptionList') {
        ExceptionListView()
      } else if (name === 'ExceptionDetail') {
        ExceptionDetailView()
      } else if (name === 'LineEdit') {
        LineEditView()
      }
    }
    .hideTitleBar(true)
    .onShown(() => {
      if (name === 'LineList') {
        if (this.lineListVm.lines.length > 0) {
          this.lineListVm.lines = [];
        }
        this.lineListVm.loadLines();
      }
    })
  }

  @Builder
  DetailPageMap(name: string) {
    NavDestination() {
      if (name === 'LineDetail') {
        LineDetailView()
      } else if (name === 'StationDetail') {
        StationDetailView()
      } else if (name === 'InspectionDetail') {
        InspectionDetailView()
      } else if (name === 'ExceptionDetail') {
        ExceptionDetailView()
      }
    }
    .hideTitleBar(true)
  }

  @Builder
  SegmentBar() {
    Row() {
      Row() {
        Text('产线监控')
          .fontSize(14).fontWeight(this.currentView === 'LineList' ? 600 : 400)
          .fontColor(this.currentView === 'LineList' ? Color.White : Colors.textSecondary)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'LineList' ? Colors.primary : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'LineList') {
          this.currentView = 'LineList';
          this.dataStack.replacePathByName('LineList', undefined);
          this.detailStack.clear();
        }
      })

      Row() {
        Text('抽检记录')
          .fontSize(14).fontWeight(this.currentView === 'InspectionList' ? 600 : 400)
          .fontColor(this.currentView === 'InspectionList' ? Color.White : Colors.textSecondary)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'InspectionList' ? Colors.primary : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'InspectionList') {
          this.currentView = 'InspectionList';
          this.dataStack.replacePathByName('InspectionList', undefined);
          this.detailStack.clear();
        }
      })

      Row() {
        Text('看板')
          .fontSize(14).fontWeight(this.currentView === 'Dashboard' ? 600 : 400)
          .fontColor(this.currentView === 'Dashboard' ? Color.White : Colors.textSecondary)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'Dashboard' ? Colors.primary : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'Dashboard') {
          this.currentView = 'Dashboard';
          this.dataStack.replacePathByName('Dashboard', undefined);
          this.detailStack.clear();
        }
      })

      Row() {
        Text('异常')
          .fontSize(14).fontWeight(this.currentView === 'ExceptionList' ? 600 : 400)
          .fontColor(this.currentView === 'ExceptionList' ? Color.White : Colors.textSecondary)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'ExceptionList' ? Colors.primary : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'ExceptionList') {
          this.currentView = 'ExceptionList';
          this.dataStack.replacePathByName('ExceptionList', undefined);
          this.detailStack.clear();
        }
      })
    }
    .padding(4)
    .backgroundColor(Colors.surfaceVariant)
    .borderRadius(10)
    .width('100%')
  }

  // sm/md: single-pane Navigation
  @Builder
  SinglePaneContent() {
    Navigation(this.dataStack) {
      Stack() {}
    }
    .layoutWeight(1)
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .onAppear(() => {
      if (this.dataStack.size() === 0) {
        this.setupInitialRoute();
      }
    })
  }

  // lg: dual-pane Row
  @Builder
  DualPaneContent() {
    Row() {
      // LEFT: List pane
      Column() {
        if (this.currentView === 'LineList') {
          LineListView()
        } else if (this.currentView === 'InspectionList') {
          InspectionListView()
        } else if (this.currentView === 'ExceptionList') {
          ExceptionListView()
        } else if (this.currentView === 'Dashboard') {
          DashboardView()
        }
      }
      .width('40%')
      .constraintSize({ minWidth: 300 })
      .backgroundColor(Colors.background)
      .border({ width: { right: 1 }, color: Colors.border })

      // RIGHT: Detail pane (hidden for Dashboard)
      if (this.currentView !== 'Dashboard') {
        Navigation(this.detailStack) {
          Stack() {}
        }
        .layoutWeight(1)
        .navDestination(this.DetailPageMap)
        .hideTitleBar(true)
      }
    }
    .layoutWeight(1)
  }

  setupInitialRoute(): void {
    if (this.deepLink && this.deepLink.targetTab === 'DataTab') {
      const page = this.deepLink.targetPage;
      const params = this.deepLink.params;

      let basePage = 'LineList';
      if (page === 'InspectionList' || page === 'InspectionDetail') {
        basePage = 'InspectionList';
        this.currentView = 'InspectionList';
      } else if (page === 'ExceptionList' || page === 'ExceptionDetail') {
        basePage = 'ExceptionList';
        this.currentView = 'ExceptionList';
      } else if (page === 'Dashboard') {
        basePage = 'Dashboard';
        this.currentView = 'Dashboard';
      } else if (page === 'LineList' || page === 'LineDetail' || page === 'StationDetail') {
        basePage = 'LineList';
        this.currentView = 'LineList';
      }

      this.dataStack.replacePath({ name: basePage });
      if (page !== basePage) {
        this.dataStack.pushPathByName(page, params);
      }
      this.deepLink = null;
    } else {
      this.dataStack.replacePath({ name: 'LineList' });
    }
  }

  build() {
    NavDestination() {
      Column() {
        // SegmentBar
        Row() {
          this.SegmentBar()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Colors.surface)
        .border({ width: { bottom: 1 }, color: Colors.border })

        // Content area: single or dual pane
        if (this.currentBreakpoint === 'lg') {
          this.DualPaneContent()
        } else {
          this.SinglePaneContent()
        }
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
  }
}
