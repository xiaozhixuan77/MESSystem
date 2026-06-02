import { WorkOrderCard } from '@ohos/uicomponents';
import { RoleConstants, StatusConstants } from '@ohos/utils';
import { WorkOrderModel } from '../Model/WorkOrderModel';
import { WorkOrderViewModel } from '../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct WorkOrderListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Param role: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local searchText: string = '';

  aboutToAppear(): void {
    this.viewModel.loadWorkOrders();
  }

  private getDetailPageName(status: string): string {
    switch (status) {
      case '待派工': return 'PendingDetail';
      case '已派工': return 'AssignedDetail';
      case '生产中': return 'RunningDetail';
      case '暂停中': return 'PausedDetail';
      case '生产完成': return 'CompletedDetail';
      case '已报工': return 'ReportedDetail';
      case '完工': return 'ReportedDetail';
      case '报废': return 'ReportedDetail';
      default: return 'PendingDetail';
    }
  }

  private canCreate(): boolean {
    return this.currentRole === RoleConstants.ADMIN || this.currentRole === RoleConstants.LEADER;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Search({ placeholder: '搜索工单号...', value: this.searchText })
          .onChange((value: string) => {
            this.searchText = value;
            this.viewModel.searchKeyword = value;
          })
          .margin({ left: 16, right: 16, top: 12, bottom: 8 });

        Scroll() {
          Row({ space: 8 }) {
            ForEach(['全部', ...StatusConstants.WORK_ORDER_STATUSES], (label: string) => {
              Text(label)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.viewModel.statusFilter === label ||
                  (label === '全部' && this.viewModel.statusFilter === '')
                  ? '#1565C0' : '#F0F0F0')
                .fontColor(this.viewModel.statusFilter === label ||
                  (label === '全部' && this.viewModel.statusFilter === '')
                  ? '#fff' : '#666')
                .onClick(() => {
                  this.viewModel.statusFilter = label === '全部' ? '' : label;
                  this.viewModel.loadWorkOrders();
                })
            })
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(40)
        .margin({ bottom: 8 });

        Row() {
          Row({ space: 8 }) {
            ForEach(['全部', '试产', '量产', '返工'], (label: string) => {
              Text(label)
                .fontSize(12)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
                .backgroundColor(this.viewModel.typeFilter === label ||
                  (label === '全部' && this.viewModel.typeFilter === '')
                  ? '#E3F2FD' : 'transparent')
                .fontColor(this.viewModel.typeFilter === label ||
                  (label === '全部' && this.viewModel.typeFilter === '')
                  ? '#1565C0' : '#9A9AA8')
                .onClick(() => {
                  this.viewModel.typeFilter = label === '全部' ? '' : label;
                  this.viewModel.loadWorkOrders();
                })
            })
          }

          Blank()

          Text(`共 ${this.viewModel.filteredList.length} 条`)
            .fontSize(12)
            .fontColor('#9A9AA8')
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 8 });

        Refresh({ refreshing: this.viewModel.isLoading }) {
          List() {
            if (this.viewModel.isLoading) {
              ListItem() {
                Row() {
                  LoadingProgress()
                    .width(40).height(40)
                }
                .width('100%').height(200)
                .justifyContent(FlexAlign.Center)
              }
            } else if (this.viewModel.errorMessage) {
              ListItem() {
                Column({ space: 12 }) {
                  Text('加载失败').fontSize(16).fontColor('#666')
                  Text(this.viewModel.errorMessage).fontSize(13).fontColor('#9A9AA8')
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Button('重试')
                    .onClick(() => this.viewModel.loadWorkOrders())
                }
                .width('100%').padding(40)
                .alignItems(HorizontalAlign.Center)
              }
            } else if (this.viewModel.filteredList.length === 0) {
              ListItem() {
                Column({ space: 8 }) {
                  Text('暂无工单').fontSize(16).fontColor('#666')
                  Text('下拉刷新重试').fontSize(13).fontColor('#9A9AA8')
                }
                .width('100%').padding(40)
                .alignItems(HorizontalAlign.Center)
              }
            } else {
              ForEach(this.viewModel.filteredList, (wo: WorkOrderModel) => {
                ListItem() {
                  WorkOrderCard({
                    workOrderCode: wo.code,
                    status: wo.status,
                    productName: wo.productName,
                    planQty: wo.planQty,
                    role: this.role,
                    onCardClick: () => {
                      const pageName = this.getDetailPageName(wo.status);
                      const navParams: Record<string, Object> = { 'workOrderId': wo.id };
                      this.pageStack.pushPathByName(pageName, navParams);
                    },
                    onDispatch: () => {
                      const navParams: Record<string, Object> = { 'workOrderId': wo.id };
                      this.pageStack.pushPathByName('PendingDetail', navParams);
                    }
                  })
                    .margin({ left: 16, right: 16, bottom: 8 })
                }
              }, (wo: WorkOrderModel) => wo.id.toString())
            }
          }
          .width('100%')
          .scrollBar(BarState.Off)
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.viewModel.loadWorkOrders();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')

      if (this.canCreate()) {
        Button('+ 新增工单')
          .fontSize(15)
          .fontColor('#fff')
          .backgroundColor('#1565C0')
          .borderRadius(24)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .shadow({ radius: 8, color: 'rgba(21,101,192,0.3)', offsetY: 4 })
          .margin({ right: 16, bottom: 16 })
          .onClick(() => {
            this.pageStack.pushPathByName('WorkOrderAdd', undefined);
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}
