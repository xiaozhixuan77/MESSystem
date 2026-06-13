import { emitter } from '@kit.BasicServicesKit';
import { WORKORDER_CHANGED_EVENT } from '@ohos/datastore';
import { PermissionUtil } from '@ohos/utils';
import { WorkOrderModel } from '../Model/WorkOrderModel';
import { WorkOrderViewModel } from '../ViewModel/WorkOrderViewModel';

interface StatusColor {
  text: string;
  bg: string;
}

const STATUS_TABS: string[] = ['全部', '待派工', '已派工', '生产中', '已暂停', '待报工', '已报工', '完工', '报废'];

const STATUS_COLORS: Record<string, StatusColor> = {
  '待派工': { text: '#1565C0', bg: '#E3F2FD' } as StatusColor,
  '已派工': { text: '#1890ff', bg: '#E6F7FF' } as StatusColor,
  '生产中': { text: '#4CAF50', bg: '#E8F5E9' } as StatusColor,
  '暂停中': { text: '#FF9800', bg: '#FFF3E0' } as StatusColor,
  '生产完成': { text: '#722ED1', bg: '#F3E5F5' } as StatusColor,
  '待报工': { text: '#722ED1', bg: '#F3E5F5' } as StatusColor,
  '已报工': { text: '#00897B', bg: '#E0F2F1' } as StatusColor,
  '完工': { text: '#4CAF50', bg: '#E8F5E9' } as StatusColor,
  '报废': { text: '#F44336', bg: '#FFEBEE' } as StatusColor,
};

const KNOWN_LINE_IDS = [1, 2];

@ComponentV2
export struct WorkOrderListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local searchText: string = '';
  private hasAppeared: boolean = false;

  aboutToAppear(): void {
    this.viewModel.loadWorkOrders();
    for (const lineId of KNOWN_LINE_IDS) {
      this.viewModel.subscribeWorkOrderUpdates(lineId);
    }
    emitter.on(WORKORDER_CHANGED_EVENT, () => {
      this.viewModel.loadWorkOrders(true);
    });
  }

  aboutToDisappear(): void {
    for (const lineId of KNOWN_LINE_IDS) {
      this.viewModel.unsubscribeWorkOrderUpdates(lineId);
    }
    emitter.off(WORKORDER_CHANGED_EVENT.eventId);
  }

  private statusLabelToFilter(label: string): string {
    switch (label) {
      case '生产中': return '生产中';
      case '已暂停': return '暂停中';
      case '待报工': return '生产完成';
      default: return label === '全部' ? '' : label;
    }
  }

  private statusToDisplay(status: string): string {
    if (status === '生产完成') return '待报工';
    return status;
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

  @Builder
  StatusBadge(status: string) {
    Text(this.statusToDisplay(status))
      .fontSize(10).fontWeight(600).fontColor(STATUS_COLORS[this.statusToDisplay(status)]?.text || '#9A9AA8')
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .backgroundColor(STATUS_COLORS[this.statusToDisplay(status)]?.bg || '#F5F7FA')
      .borderRadius(10);
  }

  @Builder
  WoButtons(wo: WorkOrderModel) {
    if (wo.status === '待派工') {
      Row({ space: 8 }) {
        if (PermissionUtil.hasPermission('workorder.create', this.currentRole)) {
          Button('复制')
            .fontSize(12).fontWeight(600).fontColor('#5A5A6E')
            .backgroundColor('#F5F7FA').borderRadius(8)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              const p: Record<string, number> = { 'sourceWorkOrderId': wo.id };
              this.pageStack.pushPathByName('WorkOrderCopy', p);
            });
        }
        if (PermissionUtil.hasPermission('workorder.dispatch', this.currentRole)) {
          Button('派工')
            .fontSize(12).fontWeight(600).fontColor(Color.White)
            .backgroundColor('#1565C0').borderRadius(8)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .onClick(() => {
              const p: Record<string, number> = { 'workOrderId': wo.id };
              this.pageStack.pushPathByName('PendingDetail', p);
            });
        }
      }
    } else if (wo.status === '生产中') {
      Button('查看')
        .fontSize(12).fontWeight(600).fontColor('#5A5A6E')
        .backgroundColor('#F5F7FA').borderRadius(8)
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .onClick(() => {
          const p: Record<string, number> = { 'workOrderId': wo.id };
          this.pageStack.pushPathByName('RunningDetail', p);
        });
    } else if (wo.status === '暂停中') {
      if (PermissionUtil.hasPermission('workorder.resume', this.currentRole)) {
        Button('恢复')
          .fontSize(12).fontWeight(600).fontColor(Color.White)
          .backgroundColor('#1565C0').borderRadius(8)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .onClick(() => {
            const p: Record<string, number> = { 'workOrderId': wo.id };
            this.pageStack.pushPathByName('PausedDetail', p);
          });
      }
    } else {
      Button('详情')
        .fontSize(12).fontWeight(600).fontColor('#5A5A6E')
        .backgroundColor('#F5F7FA').borderRadius(8)
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .onClick(() => {
          const p: Record<string, number> = { 'workOrderId': wo.id };
          this.pageStack.pushPathByName(this.getDetailPageName(wo.status), p);
        });
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 搜索栏
        Row({ space: 10 }) {
          Stack() {
            TextInput({ placeholder: '搜索工单号、产品名称', text: $$this.searchText })
              .height(40)
              .fontSize(14).fontColor('#1A1A2E')
              .placeholderColor('#9A9AA8')
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1.5, color: '#E8EBF0' })
              .padding({ left: 40, right: 16 })
              .layoutWeight(1)
              .onChange((v: string) => { this.viewModel.searchKeyword = v; });
            Image($r('app.media.icon_search_gray'))
              .width(18).height(18)
              .position({ x: 12, y: 11 });
          }
          .layoutWeight(1);

          if (PermissionUtil.hasPermission('workorder.create', this.currentRole)) {
            Button() {
              Image($r('app.media.icon_plus_white'))
                .width(18).height(18);
            }
            .width(40).height(40)
            .backgroundColor('#1565C0')
            .borderRadius(12)
            .onClick(() => { this.pageStack.pushPathByName('WorkOrderAdd', undefined); });
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        // 状态筛选标签
        Row({ space: 8 }) {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(STATUS_TABS, (label: string) => {
                Text(label)
                  .fontSize(12).fontWeight(500)
                  .fontColor(this.viewModel.statusFilter === this.statusLabelToFilter(label) ? Color.White : '#5A5A6E')
                  .backgroundColor(this.viewModel.statusFilter === this.statusLabelToFilter(label) ? '#1565C0' : '#F5F7FA')
                  .borderRadius(20)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.viewModel.statusFilter = this.statusLabelToFilter(label);
                    this.viewModel.loadWorkOrders();
                  });
              }, (label: string) => label)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off);
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        // 工单列表
        Refresh({ refreshing: this.viewModel.isLoading }) {
          List() {
            if (this.viewModel.isLoading) {
              ListItem() {
                Row() {
                  LoadingProgress().width(40).height(40);
                }
                .width('100%').height(200).justifyContent(FlexAlign.Center);
              }
            } else if (this.viewModel.errorMessage) {
              ListItem() {
                Column({ space: 12 }) {
                  Text('加载失败').fontSize(16).fontColor('#5A5A6E');
                  Text(this.viewModel.errorMessage).fontSize(13).fontColor('#9A9AA8')
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
                  Button('重试').onClick(() => this.viewModel.loadWorkOrders());
                }
                .width('100%').padding(40).alignItems(HorizontalAlign.Center);
              }
            } else if (this.viewModel.filteredList.length === 0) {
              ListItem() {
                Column({ space: 8 }) {
                  Text('暂无工单').fontSize(16).fontColor('#5A5A6E');
                  Text('下拉刷新或点击新增').fontSize(13).fontColor('#9A9AA8');
                }
                .width('100%').padding(40).alignItems(HorizontalAlign.Center);
              }
            } else {
              ForEach(this.viewModel.filteredList, (wo: WorkOrderModel) => {
                ListItem() {
                  Column() {
                    // wo-header: 工单号 + 状态标签
                    Row() {
                      Text(wo.code)
                        .fontSize(14).fontWeight(700).fontColor('#1A1A2E');
                      this.StatusBadge(wo.status);
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 10 });

                    // wo-product: 产品名 + 工序
                    Text(wo.productName + (wo.processName ? ' · ' + wo.processName : ''))
                      .fontSize(13).fontColor('#5A5A6E')
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ bottom: 12 });

                    // wo-stats: 3 列统计
                    Row({ space: 8 }) {
                      this.StatItem('计划数量', `${wo.planQty} 件`);
                      this.StatItem('工单类型', wo.type || '—');
                      this.StatItem('操作员', wo.operatorName || '—');
                    }
                    .width('100%')
                    .padding(10)
                    .backgroundColor('#F5F7FA')
                    .borderRadius(12)
                    .margin({ bottom: 12 });

                    // wo-footer: 时间 + 操作按钮
                    Row() {
                      Text(wo.createdAt || '')
                        .fontSize(11).fontColor('#9A9AA8');
                      this.WoButtons(wo);
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween);
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
                  .border({ width: 1, color: '#E8EBF0' });
                }
                .margin({ left: 16, right: 16, bottom: 10 })
                .onClick(() => {
                  const p: Record<string, Object> = { 'workOrderId': wo.id };
                  this.pageStack.pushPathByName(this.getDetailPageName(wo.status), p);
                });
              }, (wo: WorkOrderModel) => `${wo.id}-${wo.status}-${wo.version}`);
            }
          }
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None);
        }
        .layoutWeight(1)
        .onRefreshing(() => { this.viewModel.loadWorkOrders(); });
      }
      .width('100%').height('100%')
      .backgroundColor('#F5F7FA');

    }
    .onAppear(() => {
      if (this.hasAppeared) {
        this.viewModel.loadWorkOrders(true);
      }
      this.hasAppeared = true;
    })
    .width('100%').height('100%');
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(13).fontWeight(600).fontColor('#1A1A2E')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 2 });
      Text(label)
        .fontSize(10).fontColor('#5A5A6E');
    }
    .layoutWeight(1);
  }
}
