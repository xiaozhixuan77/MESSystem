import { UserModel } from '@ohos/user';
import { HomeViewModel } from '../ViewModel/HomeViewModel';
import { TaskItemModel } from '../Model/HomeSummaryModel';

@ComponentV2
export struct OperatorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Local vm: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.vm.loadHomeData();
  }

  get activeTaskCode(): string {
    if (this.vm.summary?.operatorActiveTask) {
      return this.vm.summary.operatorActiveTask.code;
    }
    return '—';
  }

  get activeTaskTitle(): string {
    if (this.vm.summary?.operatorActiveTask) {
      const t = this.vm.summary.operatorActiveTask;
      return `${t.type || ''} ${t.code || ''}`;
    }
    return '暂无进行中任务';
  }

  get activeTaskProgress(): number {
    if (this.vm.summary?.operatorActiveTask) {
      const t = this.vm.summary.operatorActiveTask;
      if (t.planQty > 0) {
        const done = (t.reportedQtyGood || 0) + (t.reportedQtyNg || 0);
        return Math.round(done / t.planQty * 100);
      }
    }
    return 0;
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
    Column() {
      // Header 蓝色区域
      Column() {
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
              Circle().width(8).height(8)
                .fill(this.vm.summary?.operatorActiveTask ? '#81C784' : '#9A9AA8');
              Text(this.vm.summary?.operatorActiveTask ? '进行中' : '待机')
                .fontSize(11).fontWeight(500)
                .fontColor(this.vm.summary?.operatorActiveTask ? '#81C784' : '#9A9AA8');
            }
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(this.vm.summary?.operatorActiveTask ?
              'rgba(76,175,80,0.2)' : 'rgba(158,158,158,0.15)')
            .borderRadius(12);

            Text(this.activeTaskCode)
              .fontSize(12).fontColor('rgba(255,255,255,0.7)');
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 12 });

          Text(this.activeTaskTitle)
            .fontSize(15).fontWeight(600).fontColor(Color.White)
            .margin({ bottom: 12 });

          Row({ space: 10 }) {
            Row() {
              Row()
                .width(`${this.activeTaskProgress}%`)
                .height(6)
                .borderRadius(3)
                .backgroundColor('#4CAF50');
            }
            .width('100%')
            .height(6)
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(3)
            .layoutWeight(1);

            Text(`${this.activeTaskProgress}%`)
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
          Column() {
            Column() {
              Image($r('app.media.icon_alert_red')).width(14).height(14);
            }
            .width(28).height(28)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);

            Text('异常上报')
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
          .onClick(() => {
            this.activeTab = 'DataTab';
            this.pageStack.replacePath({ name: 'DataTab' });
          })
          this.ActionButton($r('app.media.icon_stop_blue'), 'SOP查看');
        }
        .width('100%')
        .margin({ top: 16 });
      }
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .backgroundColor('#1565C0')
      .width('100%');

      // 内容区域（可滚动）
      Column() {
        Scroll() {
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

              if (this.vm.summary !== null) {
                ForEach(this.vm.summary.operatorPendingStartTasks, (t: TaskItemModel) => {
                  Column() {
                    Row() {
                      Text('待执行')
                        .fontSize(10).fontWeight(500).fontColor('#FF9800')
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(10)
                        .backgroundColor('#FFF3E0');
                      Text(`${t.planQty}件`).fontSize(11).fontColor('#9A9AA8');
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 10 });

                    Text(`${t.code} ${t.type || ''}`)
                      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                      .margin({ bottom: 4 });

                    Text(`${t.lineName ? '产线: ' + t.lineName + ' · ' : ''}计划 ${t.planQty}件`)
                      .fontSize(12).fontColor('#5A5A6E')
                      .margin({ bottom: 12 });

                    Button() {
                      Row({ space: 6 }) {
                        Image($r('app.media.icon_check_white')).width(14).height(14);
                        Text('扫码开工').fontSize(13).fontWeight(600).fontColor(Color.White);
                      }
                    }
                    .width('100%').height(36)
                    .backgroundColor('#1565C0')
                    .borderRadius(12)
                    .padding(0);
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                  .margin({ bottom: 10 });
                }, (t: TaskItemModel) => `start_${t.id}`);

                ForEach(this.vm.summary.operatorPendingReportTasks, (t: TaskItemModel) => {
                  Column() {
                    Row() {
                      Text('待报工')
                        .fontSize(10).fontWeight(500).fontColor('#1565C0')
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(10)
                        .backgroundColor('#E3F2FD');
                      Text('已完成加工').fontSize(11).fontColor('#9A9AA8');
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 10 });

                    Text(`${t.code} ${t.type || ''}`)
                      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                      .margin({ bottom: 4 });

                    Text(`良品 ${t.reportedQtyGood || 0}件 · NG ${t.reportedQtyNg || 0}件`)
                      .fontSize(12).fontColor('#5A5A6E')
                      .margin({ bottom: 12 });

                    Button() {
                      Row({ space: 6 }) {
                        Image($r('app.media.icon_document_white')).width(14).height(14);
                        Text('提交报工').fontSize(13).fontWeight(600).fontColor(Color.White);
                      }
                    }
                    .width('100%').height(36)
                    .backgroundColor('#4CAF50')
                    .borderRadius(12)
                    .padding(0);
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                  .margin({ bottom: 10 });
                }, (t: TaskItemModel) => `report_${t.id}`);
              }

              if (this.vm.summary !== null &&
                  this.vm.summary.operatorPendingStartTasks.length === 0 &&
                  this.vm.summary.operatorPendingReportTasks.length === 0) {
                Text('暂无待处理任务')
                  .fontSize(13).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              }
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

              Text('产线动态需接入 /lines 接口，暂未实现')
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
