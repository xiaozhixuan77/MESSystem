import { UserModel } from '@ohos/user';

@ComponentV2
export struct AdminHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

  @Builder
  KpiCard(icon: ResourceStr, label: string, value: string, trend: string, valueColor: ResourceColor) {
    Column() {
      Row({ space: 6 }) {
        Column() {
          Image(icon).width(14).height(14);
        }
        .width(28).height(28)
        .backgroundColor('rgba(255,255,255,0.2)')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Text(label).fontSize(11).fontColor('rgba(255,255,255,0.85)');
      }
      .margin({ bottom: 8 });

      Text(value).fontSize(26).fontWeight(700).fontColor(valueColor);
      Text(trend).fontSize(10).fontColor('rgba(255,255,255,0.7)').margin({ top: 2 });
    }
    .padding({ top: 16, bottom: 16, left: 12, right: 12 })
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
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
          // 用户问候 + 设置按钮
          Row() {
            Column() {
              Text(this.currentUser.name || '刘管理员')
                .fontSize(20).fontWeight(700).fontColor(Color.White);
              Text('系统管理员 · 全权限')
                .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
            }

            Stack() {
              Image($r('app.media.icon_settings_white')).width(18).height(18);
            }
            .width(36).height(36)
            .backgroundColor('rgba(255,255,255,0.15)')
            .borderRadius(12)
            .alignContent(Alignment.Center);
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 16 });

          // 2×2 KPI Grid
          Row({ space: 10 }) {
            this.KpiCard($r('app.media.icon_dashboard_white'), '产线总数', '4', '3运行 1待机', Color.White);
            this.KpiCard($r('app.media.icon_person_white'), '人员总数', '12', '8在岗 4休班', Color.White);
          }
          .width('100%')
          .margin({ bottom: 10 });

          Row({ space: 10 }) {
            this.KpiCard($r('app.media.icon_document_white'), '活跃工单', '5', '2生产中 3待派工', Color.White);
            this.KpiCard($r('app.media.icon_alert_white'), '待处理异常', '1', 'L3产线故障', '#FF8A80');
          }
          .width('100%')
          .margin({ bottom: 16 });

          // 快捷入口
          Row({ space: 8 }) {
            Column() {
              Column() {
                Image($r('app.media.tab_workorder_active')).width(16).height(16);
              }
              .width(32).height(32)
              .backgroundColor('rgba(255,255,255,0.95)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('全部工单')
                .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 10, bottom: 10, left: 4, right: 4 })
            .backgroundColor('rgba(255,255,255,0.1)')
            .borderRadius(12)
            .layoutWeight(1)
            .onClick(() => {
              this.activeTab = 'WorkOrderTab';
              this.pageStack.replacePath({ name: 'WorkOrderTab' });
            })

            this.QuickItem($r('app.media.tab_profile_active'), '人员管理');
            this.QuickItem($r('app.media.tab_data_active'), '产线工艺');
            this.QuickItem($r('app.media.icon_image_blue'), '质检看板');
          }
          .width('100%');
        }
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .backgroundColor('#1565C0');

        // 内容区域
        Column() {
          // 异常告警
          Column() {
            Row() {
              Text('异常告警').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('全部告警').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Row({ space: 12 }) {
              Column() {
                Image($r('app.media.icon_alert_red')).width(20).height(20);
              }
              .width(40).height(40)
              .backgroundColor('#FFEBEE')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);

              Column() {
                Text('产线L3工作站故障')
                  .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                  .margin({ bottom: 2 });
                Text('3号柔性产线第5工作站检测到传送带速度异常')
                  .fontSize(12).fontColor('#5A5A6E')
                  .margin({ bottom: 8 });
                Row({ space: 12 }) {
                  Text('产线：L3柔性线').fontSize(11).fontColor('#9A9AA8');
                  Text('工位：WS-05').fontSize(11).fontColor('#9A9AA8');
                }
              }
              .layoutWeight(1);
            }
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
            .width('100%');
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 今日概览
          Column() {
            Row() {
              Text('今日概览').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看报表').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Row() {
              Column() {
                Text('320').fontSize(20).fontWeight(700).fontColor('#1A1A2E').margin({ bottom: 2 });
                Text('今日产量').fontSize(11).fontColor('#5A5A6E');
              }
              .alignItems(HorizontalAlign.Center).layoutWeight(1);

              Column() {
                Text('97.8%').fontSize(20).fontWeight(700).fontColor('#4CAF50').margin({ bottom: 2 });
                Text('平均良品率').fontSize(11).fontColor('#5A5A6E');
              }
              .alignItems(HorizontalAlign.Center).layoutWeight(1);

              Column() {
                Text('6.5h').fontSize(20).fontWeight(700).fontColor('#1565C0').margin({ bottom: 2 });
                Text('平均工时').fontSize(11).fontColor('#5A5A6E');
              }
              .alignItems(HorizontalAlign.Center).layoutWeight(1);
            }
            .width('100%')
            .padding(16)
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
