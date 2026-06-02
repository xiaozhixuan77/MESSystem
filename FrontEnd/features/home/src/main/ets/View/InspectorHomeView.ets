import { UserModel } from '@ohos/user';

@ComponentV2
export struct InspectorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

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
          // 用户问候 + 通知按钮
          Row() {
            Column() {
              Text(this.currentUser.name || '李质检员')
                .fontSize(20).fontWeight(700).fontColor(Color.White);
              Text('质检部 · 早班')
                .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
            }

            Stack() {
              Image($r('app.media.icon_bell_white')).width(18).height(18);
              Circle().width(8).height(8).fill('#F44336').position({ x: 14, y: 2 });
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
            this.KpiCard('12', '待抽检');
            this.KpiCard('8', '今日完成');
            this.KpiCard('98.2%', '合格率');
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
        .padding({ left: 20, right: 20, top: 48, bottom: 20 })
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

            // 抽检卡片 1
            Column() {
              Row() {
                Text('待抽检')
                  .fontSize(10).fontWeight(500).fontColor('#FF9800')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(10)
                  .backgroundColor('#FFF3E0');
                Text('报工 10分钟前').fontSize(11).fontColor('#9A9AA8');
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 8 });

              Text('WO-2024-0116 控制器组装')
                .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                .margin({ bottom: 4 });

              Text('申报：良品 136件 · NG 4件 · 建议抽检 14件')
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

            // 抽检卡片 2
            Column() {
              Row() {
                Text('待抽检')
                  .fontSize(10).fontWeight(500).fontColor('#FF9800')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(10)
                  .backgroundColor('#FFF3E0');
                Text('报工 35分钟前').fontSize(11).fontColor('#9A9AA8');
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 8 });

              Text('WO-2024-0115 电源模块')
                .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                .margin({ bottom: 4 });

              Text('申报：良品 96件 · NG 4件 · 建议抽检 10件')
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
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' });
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 产线运行状态
          Column() {
            Row() {
              Text('产线运行状态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看全部').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            // L1
            Column() {
              Row() {
                Text('L1 柔性线')
                  .fontSize(13).fontWeight(600).fontColor('#1A1A2E');
                Row() {
                  Circle().width(8).height(8).fill('#4CAF50');
                  Text('运行中').fontSize(11).fontColor('#4CAF50');
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 10 });

              Row() {
                Column() {
                  Text('WO-0116').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('当前工单').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);

                Column() {
                  Text('68%').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('完成度').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);

                Column() {
                  Text('98.5%').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('良品率').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);
              }
              .width('100%');
            }
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
            .margin({ bottom: 10 });

            // L2
            Column() {
              Row() {
                Text('L2 柔性线')
                  .fontSize(13).fontWeight(600).fontColor('#1A1A2E');
                Row() {
                  Circle().width(8).height(8).fill('#4CAF50');
                  Text('运行中').fontSize(11).fontColor('#4CAF50');
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 10 });

              Row() {
                Column() {
                  Text('WO-0115').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('当前工单').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);

                Column() {
                  Text('45%').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('完成度').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);

                Column() {
                  Text('97.2%').fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
                  Text('良品率').fontSize(10).fontColor('#5A5A6E');
                }
                .padding(8).backgroundColor('#F5F7FA').borderRadius(8)
                .alignItems(HorizontalAlign.Center).layoutWeight(1);
              }
              .width('100%');
            }
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' });
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
