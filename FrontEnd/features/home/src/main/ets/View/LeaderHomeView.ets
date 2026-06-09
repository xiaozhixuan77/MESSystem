import { UserModel } from '@ohos/user';
import { HomeViewModel } from '../ViewModel/HomeViewModel';
import { ExceptionItemModel, DispatchItemModel } from '../Model/HomeSummaryModel';
import { DeepLinkInfo } from '@ohos/utils';

@ComponentV2
export struct LeaderHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;
  @Local vm: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.vm.loadHomeData();
    this.vm.subscribeHome();
  }

  aboutToDisappear(): void {
    this.vm.unsubscribeHome();
  }

  navigateTo(tab: string, page: string, params: Record<string, Object>): void {
    this.deepLink = { targetTab: tab, targetPage: page, params: params };
    this.activeTab = tab;
    this.pageStack.replacePath({ name: tab });
  }

  @Builder
  QuickItem(icon: ResourceStr, label: string) {
    Column() {
      Column() {
        Image(icon).width(16).height(16);
      }
      .width(32).height(32)
      .backgroundColor('rgba(255,255,255,0.95)')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);

      Text(label)
        .fontSize(11)
        .fontColor(Color.White)
        .fontWeight(500)
        .margin({ top: 6 });
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 12, bottom: 12, left: 4, right: 4 })
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(12)
    .layoutWeight(1)
  }

  build() {
    Column() {
      // Header 蓝色区域
      Column() {
        Row() {
          Column() {
            Text(this.currentUser.name || '张班长')
              .fontSize(20).fontWeight(700).fontColor(Color.White);
            Text('A班组组长 · 早班')
              .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
          }

          Stack() {
            Image($r('app.media.icon_bell_white')).width(18).height(18);
            if (this.vm.hasPendingExceptions) {
              Circle().width(8).height(8).fill('#F44336').position({ x: 14, y: 2 });
            }
          }
          .width(36).height(36)
          .backgroundColor('rgba(255,255,255,0.15)')
          .borderRadius(12)
          .alignContent(Alignment.Center);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 20 });

        // 快捷入口
        Row({ space: 8 }) {
          Column() {
            Column() {
              Image($r('app.media.tab_data_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('基础数据')
              .fontSize(11).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'LineList', {});
          })

          Column() {
            Column() {
              Image($r('app.media.tab_workorder_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('工单')
              .fontSize(11).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.activeTab = 'WorkOrderTab';
            this.pageStack.replacePath({ name: 'WorkOrderTab' });
          })

          Column() {
            Column() {
              Image($r('app.media.icon_image_blue')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('质检看板')
              .fontSize(11).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'Dashboard', {});
          })

          Column() {
            Column() {
              Image($r('app.media.icon_clock_blue')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('历史记录')
              .fontSize(11).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'InspectionList', {});
          })
        }
        .width('100%');
      }
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .backgroundColor('#1565C0')
      .width('100%');

      // 内容区域（可滚动）
      Column() {
        Scroll() {
          Column() {
            // 待办事项
          Column() {
            Row() {
              Text('待办事项').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看全部').fontSize(12).fontColor('#1565C0').fontWeight(500)
                .onClick(() => {
                  this.navigateTo('DataTab', 'ExceptionList', {});
                });
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            if (this.vm.summary !== null) {
              ForEach(this.vm.summary.recentExceptions, (ex: ExceptionItemModel) => {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.icon_alert_red')).width(10).height(10);
                      Text('异常待处理')
                        .fontSize(11).fontWeight(500).fontColor('#F44336');
                    }
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(12)
                    .backgroundColor('#FFEBEE');

                    Text(ex.reportTime || '').fontSize(11).fontColor('#9A9AA8');
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: 8 });

                  Text(ex.lineName || '未知产线')
                    .fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 4 });

                  Text(ex.description || '')
                    .fontSize(12).fontColor('#5A5A6E').lineHeight(20).margin({ bottom: 10 });

                  Row({ space: 12 }) {
                    Text() {
                      Span('产线：').fontSize(11).fontColor('#5A5A6E');
                      Span(ex.lineName).fontSize(11).fontColor('#1A1A2E').fontWeight(600);
                    }
                    Text() {
                      Span('工单：').fontSize(11).fontColor('#5A5A6E');
                      Span(ex.workOrderCode).fontSize(11).fontColor('#1A1A2E').fontWeight(600);
                    }
                  }
                  .width('100%')
                  .padding({ top: 10 })
                  .border({ width: { top: 1 }, color: '#E8EBF0' });
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .border({ width: { left: 3 }, color: '#F44336' })
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                .margin({ bottom: 10 })
                .onClick(() => {
                  this.navigateTo('DataTab', 'ExceptionDetail', { 'exceptionId': ex.id });
                });
              }, (ex: ExceptionItemModel) => `ex_${ex.id}`);

              ForEach(this.vm.summary.pendingDispatchItems, (wo: DispatchItemModel) => {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.icon_briefcase_blue')).width(10).height(10);
                      Text('待派工')
                        .fontSize(11).fontWeight(500).fontColor('#1565C0');
                    }
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(12)
                    .backgroundColor('#E3F2FD');

                    Text(wo.createdAt || '').fontSize(11).fontColor('#9A9AA8');
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: 8 });

                  Text(`${wo.code || ''} ${wo.type || ''}`)
                    .fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 4 });

                  Text(`计划数量：${wo.planQty}件`)
                    .fontSize(12).fontColor('#5A5A6E').lineHeight(20).margin({ bottom: 10 });

                  Row({ space: 12 }) {
                    Text() {
                      Span('数量：').fontSize(11).fontColor('#5A5A6E');
                      Span(`${wo.planQty}件`).fontSize(11).fontColor('#1A1A2E').fontWeight(600);
                    }
                  }
                  .width('100%')
                  .padding({ top: 10 })
                  .border({ width: { top: 1 }, color: '#E8EBF0' });
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .border({ width: { left: 3 }, color: '#1565C0' })
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                .margin({ bottom: 10 })
                .onClick(() => {
                  this.navigateTo('WorkOrderTab', 'PendingDetail', { 'workOrderId': wo.id });
                });
              }, (wo: DispatchItemModel) => `dp_${wo.id}`);
            }

            if (this.vm.summary !== null &&
                this.vm.summary.recentExceptions.length === 0 &&
                this.vm.summary.pendingDispatchItems.length === 0) {
              Text('暂无待办事项')
                .fontSize(13).fontColor('#9A9AA8')
                .padding(16).width('100%').textAlign(TextAlign.Center);
            }
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 产线状态 — 保留占位（后续接入 /lines API）
          Column() {
            Row() {
              Text('产线状态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('全部产线').fontSize(12).fontColor('#1565C0').fontWeight(500)
                .onClick(() => {
                  this.navigateTo('DataTab', 'LineList', {});
                });
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Text('产线状态需接入 /lines 接口，暂未实现')
              .fontSize(12).fontColor('#9A9AA8').padding(16).width('100%').textAlign(TextAlign.Center);
          }
          .width('100%');
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
        .width('100%');
      }
      .width('100%').height('100%')
      .backgroundColor('#F5F7FA')
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None);
    }
    .layoutWeight(1);
    }
    .width('100%').height('100%');
  }
}
