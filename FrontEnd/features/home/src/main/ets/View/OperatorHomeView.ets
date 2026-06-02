import { UserModel } from '@ohos/user';

class OperatorTaskItem {
  tag: string = '';
  tagLabel: string = '';
  time: string = '';
  name: string = '';
  info: string = '';
  buttonLabel: string = '';
  buttonColor: string = '';
  buttonIcon: ResourceStr = '';
}

@ComponentV2
export struct OperatorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Local currentTaskTitle: string = '控制器主板组装 - SMT贴片工序';
  @Local currentTaskCode: string = 'WO-2024-0116';
  @Local currentTaskProgress: number = 68;
  @Local tasks: OperatorTaskItem[] = [];

  aboutToAppear(): void {
    this.tasks = [
      {
        tag: 'pending',
        tagLabel: '待执行',
        time: '14:00 开始',
        name: 'WO-0118 传感器模组后焊',
        info: '预计工时 2h · 数量 50件',
        buttonLabel: '扫码开工',
        buttonColor: '#1565C0',
        buttonIcon: $r('app.media.icon_check_white')
      },
      {
        tag: 'report',
        tagLabel: '待报工',
        time: '已完成加工',
        name: 'WO-0115 电源模块测试',
        info: '良品 96件 · NG 4件 · 工时 3.5h',
        buttonLabel: '提交报工',
        buttonColor: '#4CAF50',
        buttonIcon: $r('app.media.icon_document_white')
      }
    ];
  }

  @Builder
  ActionButton(icon: ResourceStr, label: string) {
    Column() {
      Column() {
        Image(icon).width(14).height(14);
      }
      .width(28).height(28)
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
    .padding({ top: 14, bottom: 14, left: 8, right: 8 })
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(12)
    .layoutWeight(1)
  }

  build() {
    Scroll() {
      Column() {
        // Header 蓝色区域
        Column() {
          // 用户问候 + 扫码按钮
          Row() {
            Column() {
              Text(this.currentUser.name || '王操作员')
                .fontSize(20).fontWeight(700).fontColor(Color.White);
              Text('A班组 · 早班 · 工位WS-03')
                .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
            }

            Stack() {
              Image($r('app.media.icon_scan_white')).width(20).height(20);
            }
            .width(40).height(40)
            .backgroundColor('rgba(255,255,255,0.15)')
            .borderRadius(12)
            .alignContent(Alignment.Center);
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 16 });

          // 当前任务卡片
          Column() {
            Row() {
              Row() {
                Circle().width(8).height(8).fill('#81C784');
                Text('进行中')
                  .fontSize(11).fontWeight(500).fontColor('#81C784');
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('rgba(76,175,80,0.2)')
              .borderRadius(12);

              Text(this.currentTaskCode)
                .fontSize(12).fontColor('rgba(255,255,255,0.7)');
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Text(this.currentTaskTitle)
              .fontSize(15).fontWeight(600).fontColor(Color.White)
              .margin({ bottom: 12 });

            Row({ space: 10 }) {
              Row() {
                Row()
                  .width(this.currentTaskProgress + '%')
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('#4CAF50');
              }
              .width('100%')
              .height(6)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(3)
              .layoutWeight(1);

              Text(this.currentTaskProgress + '%')
                .fontSize(13).fontWeight(600).fontColor(Color.White);
            }
            .width('100%');
          }
          .padding(16)
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(16)
          .border({ width: 1, color: 'rgba(255,255,255,0.15)' })
          .width('100%');

          // 快捷操作
          Row({ space: 10 }) {
            this.ActionButton($r('app.media.icon_activity_blue'), '报工');
            this.ActionButton($r('app.media.icon_alert_blue'), '异常上报');
            this.ActionButton($r('app.media.icon_stop_blue'), 'SOP查看');
          }
          .width('100%')
          .margin({ top: 16 });
        }
        .padding({ left: 20, right: 20, top: 48, bottom: 20 })
        .backgroundColor('#1565C0');

        // 内容区域
        Column() {
          // 我的任务
          Column() {
            Row() {
              Text('我的任务').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('全部任务').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            ForEach(this.tasks, (task: OperatorTaskItem) => {
              Column() {
                Row() {
                  Text(task.tagLabel)
                    .fontSize(10).fontWeight(500)
                    .fontColor(task.tag === 'pending' ? '#FF9800' : '#1565C0')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor(task.tag === 'pending' ? '#FFF3E0' : '#E3F2FD');

                  Text(task.time).fontSize(11).fontColor('#9A9AA8');
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .margin({ bottom: 10 });

                Text(task.name)
                  .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                  .margin({ bottom: 4 });

                Text(task.info)
                  .fontSize(12).fontColor('#5A5A6E')
                  .margin({ bottom: 12 });

                Button() {
                  Row({ space: 6 }) {
                    Image(task.buttonIcon).width(14).height(14);
                    Text(task.buttonLabel).fontSize(13).fontWeight(600).fontColor(Color.White);
                  }
                }
                .width('100%').height(36)
                .backgroundColor(task.buttonColor)
                .borderRadius(12)
                .padding(0);
              }
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
              .margin({ bottom: 10 });
            }, (task: OperatorTaskItem) => task.name);
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 产线动态
          Column() {
            Row() {
              Text('产线动态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看详情').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

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
              .margin({ bottom: 12 });

              Row() {
                Column() {
                  Text('当前工单').fontSize(11).fontColor('#5A5A6E').margin({ bottom: 2 });
                  Text('WO-0116').fontSize(13).fontWeight(600).fontColor('#1A1A2E');
                }
                .alignItems(HorizontalAlign.Center)
                .layoutWeight(1);

                Column() {
                  Text('本班产量').fontSize(11).fontColor('#5A5A6E').margin({ bottom: 2 });
                  Text('136件').fontSize(13).fontWeight(600).fontColor('#1A1A2E');
                }
                .alignItems(HorizontalAlign.Center)
                .layoutWeight(1);

                Column() {
                  Text('良品率').fontSize(11).fontColor('#5A5A6E').margin({ bottom: 2 });
                  Text('98.5%').fontSize(13).fontWeight(600).fontColor('#4CAF50');
                }
                .alignItems(HorizontalAlign.Center)
                .layoutWeight(1);
              }
              .width('100%');
            }
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
            .width('100%');
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
