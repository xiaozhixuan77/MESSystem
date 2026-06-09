import { UserModel } from '@ohos/user';
import { HomeViewModel } from '../ViewModel/HomeViewModel';
import { InspectionItemModel } from '../Model/HomeSummaryModel';
import { FormatUtil } from '@ohos/utils';

@ComponentV2
export struct InspectorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Local vm: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.vm.loadHomeData();
  }

  get pendingCount(): string {
    return this.vm.summary ? `${this.vm.summary.pendingInspectionCount}` : '0';
  }

  get todayDone(): string {
    return this.vm.summary ? `${this.vm.summary.todayInspectionDone}` : '0';
  }

  get passRate(): string {
    return this.vm.summary ? FormatUtil.formatPercent(this.vm.summary.todayInspectionPassRate) : '0%';
  }

  @Builder
  KpiCard(value: string, label: string) {
    Column() {
      Text(value).fontSize(22).fontWeight(700).fontColor(Color.White).margin({ bottom: 2 });
      Text(label).fontSize(10).fontColor('rgba(255,255,255,0.8)');
    }
    .padding({ top: 14, bottom: 14, left: 8, right: 8 })
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1);
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
        .fontSize(10)
        .fontColor(Color.White)
        .fontWeight(500)
        .margin({ top: 6 });
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10, left: 4, right: 4 })
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(12)
    .layoutWeight(1)
  }

  build() {
    Scroll() {
      Column() {
        // Header 蓝色区域
        Column() {
          Row() {
            Column() {
              Text(this.currentUser.name || '李质检员')
                .fontSize(20).fontWeight(700).fontColor(Color.White);
              Text('质检部 · 早班')
                .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
            }

            Stack() {
              Image($r('app.media.icon_bell_white')).width(18).height(18);
              if (this.vm.hasPendingInspections) {
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
          .margin({ bottom: 16 });

          // KPI 指标
          Row({ space: 10 }) {
            this.KpiCard(this.pendingCount, '待抽检');
            this.KpiCard(this.todayDone, '今日完成');
            this.KpiCard(this.passRate, '合格率');
          }
          .width('100%')
          .margin({ bottom: 16 });

          // 快捷入口
          Row({ space: 8 }) {
            this.QuickItem($r('app.media.tab_data_active'), '待检列表');
            this.QuickItem($r('app.media.icon_image_blue'), '质检看板');
            this.QuickItem($r('app.media.icon_clock_blue'), '质检记录');
            this.QuickItem($r('app.media.tab_workorder_active'), '质检标准');
          }
          .width('100%');
        }
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .backgroundColor('#1565C0');

        // 内容区域
        Column() {
          // 待抽检工单
          Column() {
            Row() {
              Text('待抽检工单').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('全部').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            if (this.vm.summary !== null) {
              ForEach(this.vm.summary.pendingInspectionItems, (item: InspectionItemModel) => {
                Column() {
                  Row() {
                    Text('待抽检')
                      .fontSize(10).fontWeight(500).fontColor('#FF9800')
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .borderRadius(10)
                      .backgroundColor('#FFF3E0');
                    Text(item.inspectTime ? `创建 ${item.inspectTime}` : '')
                      .fontSize(11).fontColor('#9A9AA8');
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: 8 });

                  Text(item.workOrderCode || '未知工单')
                    .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                    .margin({ bottom: 4 });

                  Text(`建议抽检 ${item.sampleQty || 0}件`)
                    .fontSize(12).fontColor('#5A5A6E')
                    .margin({ bottom: 12 });

                  Button() {
                    Row({ space: 6 }) {
                      Image($r('app.media.icon_document_white')).width(14).height(14);
                      Text('去抽检').fontSize(13).fontWeight(600).fontColor(Color.White);
                    }
                  }
                  .width('100%').height(36)
                  .backgroundColor('#FF9800')
                  .borderRadius(12)
                  .padding(0);
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .border({ width: { left: 3 }, color: '#FF9800' })
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                .margin({ bottom: 10 });
              }, (item: InspectionItemModel) => `insp_${item.id}`);
            }

            if (this.vm.summary !== null &&
                this.vm.summary.pendingInspectionItems.length === 0) {
              Text('暂无待抽检工单')
                .fontSize(13).fontColor('#9A9AA8')
                .padding(16).width('100%').textAlign(TextAlign.Center);
            }
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 产线运行状态 — 保留占位
          Column() {
            Row() {
              Text('产线运行状态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看全部').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Text('产线运行状态需接入 /lines 接口，暂未实现')
              .fontSize(12).fontColor('#9A9AA8').padding(16).width('100%').textAlign(TextAlign.Center);
          }
          .width('100%');
        }
        .padding(16)
        .width('100%');
      }
      .width('100%');
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None);
  }
}
