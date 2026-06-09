import { LineListView, LineDetailView, StationDetailView, ProductionViewModel } from '@ohos/production';
import { InspectionListView, InspectionDetailView, DashboardView, ExceptionListView, ExceptionDetailView } from '@ohos/quality';
import { DeepLinkInfo } from '@ohos/utils';

@ComponentV2
export struct DataTabDestination {
  @Provider('pageStack') dataStack: NavPathStack = new NavPathStack();
  @Provider('sharedVm') lineListVm: ProductionViewModel = new ProductionViewModel();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;
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
  SegmentBar() {
    Row() {
      Row() {
        Text('产线监控')
          .fontSize(14).fontWeight(this.currentView === 'LineList' ? 600 : 400)
          .fontColor(this.currentView === 'LineList' ? Color.White : '#5A5A6E')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 });
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'LineList' ? '#1565C0' : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'LineList') {
          this.currentView = 'LineList';
          this.dataStack.replacePathByName('LineList', undefined);
        }
      });

      Row() {
        Text('抽检记录')
          .fontSize(14).fontWeight(this.currentView === 'InspectionList' ? 600 : 400)
          .fontColor(this.currentView === 'InspectionList' ? Color.White : '#5A5A6E')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 });
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'InspectionList' ? '#1565C0' : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'InspectionList') {
          this.currentView = 'InspectionList';
          this.dataStack.replacePathByName('InspectionList', undefined);
        }
      });

      Row() {
        Text('看板')
          .fontSize(14).fontWeight(this.currentView === 'Dashboard' ? 600 : 400)
          .fontColor(this.currentView === 'Dashboard' ? Color.White : '#5A5A6E')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 });
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'Dashboard' ? '#1565C0' : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'Dashboard') {
          this.currentView = 'Dashboard';
          this.dataStack.replacePathByName('Dashboard', undefined);
        }
      });

      Row() {
        Text('异常')
          .fontSize(14).fontWeight(this.currentView === 'ExceptionList' ? 600 : 400)
          .fontColor(this.currentView === 'ExceptionList' ? Color.White : '#5A5A6E')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 });
      }
      .borderRadius(8)
      .backgroundColor(this.currentView === 'ExceptionList' ? '#1565C0' : Color.Transparent)
      .onClick(() => {
        if (this.currentView !== 'ExceptionList') {
          this.currentView = 'ExceptionList';
          this.dataStack.replacePathByName('ExceptionList', undefined);
        }
      });
    }
    .padding(4)
    .backgroundColor('#F5F7FA')
    .borderRadius(10)
    .width('100%');
  }

  build() {
    NavDestination() {
      Column() {
        // 分段切换栏
        Row() {
          this.SegmentBar();
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        // 内容区
        Navigation(this.dataStack) {
          Stack() {}
        }
        .layoutWeight(1)
        .navDestination(this.PageMap)
        .hideTitleBar(true)
        .onAppear(() => {
          if (this.dataStack.size() === 0) {
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
        });
      }
      .width('100%').height('100%');
    }
    .hideTitleBar(true)
  }
}
