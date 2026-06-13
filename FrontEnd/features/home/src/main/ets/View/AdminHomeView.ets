import { UserModel } from '@ohos/user';
import { HomeViewModel } from '../ViewModel/HomeViewModel';
import { HomeSummaryModel, ExceptionItemModel } from '../Model/HomeSummaryModel';
import { DeepLinkInfo } from '@ohos/utils';
import { LoadingState, ErrorState } from '@ohos/uicomponents';

@ComponentV2
export struct AdminHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;
  @Local summary: HomeSummaryModel | null = null;
  @Local isLoading: boolean = true;
  @Local errorMessage: string = '';
  private vm: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.vm.subscribeHome(() => {
      this.reload(true);
    });
    this.reload(false);
  }

  private reload(silent: boolean): void {
    if (!silent) {
      this.isLoading = true;
      this.errorMessage = '';
    }
    this.vm.loadHomeData().then((data) => {
      if (data) {
        this.summary = data;
      }
      if (!silent) {
        this.isLoading = false;
      }
    }).catch((e: Error) => {
      if (!silent) {
        this.errorMessage = e.message || '加载失败';
        this.isLoading = false;
      }
    });
    this.vm.loadDashboard();
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
  kpiCard(label: string, value: string, valueColor: string) {
    Column() {
      Text(value).fontSize(20).fontWeight(700).fontColor(valueColor).maxLines(1);
      Text(label).fontSize(10).fontColor('#9A9AA8').margin({ top: 4 });
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    .width('100%');
  }

  private formatPercent(rate: number): string {
    return `${Math.round(rate * 100)}%`;
  }

  build() {
    Column() {
      // Header 蓝色区域
      Column() {
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
          Column() {
            Row({ space: 6 }) {
              Column() {
                Image($r('app.media.icon_dashboard_white')).width(14).height(14);
              }
              .width(28).height(28)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('产线总数').fontSize(11).fontColor('rgba(255,255,255,0.85)');
            }
            .margin({ bottom: 8 });
            Text(`${this.summary?.totalLineCount ?? 0}`)
              .fontSize(26).fontWeight(700).fontColor(Color.White);
            Text(`${this.summary?.totalLineCount ?? 0}条产线`)
              .fontSize(10).fontColor('rgba(255,255,255,0.7)').margin({ top: 2 });
          }
          .padding({ top: 16, bottom: 16, left: 12, right: 12 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Column() {
            Row({ space: 6 }) {
              Column() {
                Image($r('app.media.icon_person_white')).width(14).height(14);
              }
              .width(28).height(28)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('人员总数').fontSize(11).fontColor('rgba(255,255,255,0.85)');
            }
            .margin({ bottom: 8 });
            Text(`${this.summary?.totalUserCount ?? 0}`)
              .fontSize(26).fontWeight(700).fontColor(Color.White);
            Text(`${this.summary?.totalUserCount ?? 0}人`)
              .fontSize(10).fontColor('rgba(255,255,255,0.7)').margin({ top: 2 });
          }
          .padding({ top: 16, bottom: 16, left: 12, right: 12 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
        }
        .width('100%')
        .margin({ bottom: 10 });

        Row({ space: 10 }) {
          Column() {
            Row({ space: 6 }) {
              Column() {
                Image($r('app.media.icon_document_white')).width(14).height(14);
              }
              .width(28).height(28)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('活跃工单').fontSize(11).fontColor('rgba(255,255,255,0.85)');
            }
            .margin({ bottom: 8 });
            Text(`${this.summary?.activeWorkOrderCount ?? 0}`)
              .fontSize(26).fontWeight(700).fontColor(Color.White);
            Text(`${this.summary?.pendingDispatchCount ?? 0}待派工`)
              .fontSize(10).fontColor('rgba(255,255,255,0.7)').margin({ top: 2 });
          }
          .padding({ top: 16, bottom: 16, left: 12, right: 12 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Column() {
            Row({ space: 6 }) {
              Column() {
                Image($r('app.media.icon_alert_white')).width(14).height(14);
              }
              .width(28).height(28)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('待处理异常').fontSize(11).fontColor('rgba(255,255,255,0.85)');
            }
            .margin({ bottom: 8 });
            Text(`${this.summary?.pendingExceptionCount ?? 0}`)
              .fontSize(26).fontWeight(700)
              .fontColor((this.summary?.pendingExceptionCount ?? 0) > 0 ? '#FF8A80' : Color.White);
            Text((this.summary?.pendingExceptionCount ?? 0) > 0 ? '需关注' : '无异常')
              .fontSize(10).fontColor('rgba(255,255,255,0.7)').margin({ top: 2 });
          }
          .padding({ top: 16, bottom: 16, left: 12, right: 12 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
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

          Column() {
            Column() {
              Image($r('app.media.tab_profile_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('人员管理')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('ProfileTab', 'EmployeeList', {});
          })

          Column() {
            Column() {
              Image($r('app.media.tab_data_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('产线工艺')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'LineList', {});
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
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'Dashboard', {});
          })
        }
        .width('100%');
      }
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .backgroundColor('#1565C0')
      .width('100%');

      // 内容区域
      if (this.isLoading) {
        LoadingState()
      } else if (this.errorMessage) {
        ErrorState({ showRetry: true, message: this.errorMessage, onRetry: () => { this.reload(false); } })
      } else {
      Column() {
        Scroll() {
          Column() {
            // 异常告警
            Column() {
              Row() {
                Text('异常告警').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
                Text('全部告警').fontSize(12).fontColor('#1565C0').fontWeight(500)
                  .onClick(() => {
                    this.navigateTo('DataTab', 'ExceptionList', {});
                  });
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 12 });

              if (this.summary !== null && this.summary.recentExceptions.length > 0) {
                ForEach(this.summary.recentExceptions, (ex: ExceptionItemModel) => {
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
                      Text(`${ex.lineName}故障`)
                        .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                        .margin({ bottom: 2 });
                      Text(ex.description || '')
                        .fontSize(12).fontColor('#5A5A6E')
                        .margin({ bottom: 8 });
                      Row({ space: 12 }) {
                        Text(`产线：${ex.lineName}`).fontSize(11).fontColor('#9A9AA8');
                        Text(`工单：${ex.workOrderCode}`).fontSize(11).fontColor('#9A9AA8');
                      }
                    }
                    .layoutWeight(1);
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                  .width('100%')
                  .margin({ bottom: 10 })
                  .onClick(() => {
                    this.navigateTo('DataTab', 'ExceptionDetail', { 'exceptionId': ex.id });
                  });
                }, (ex: ExceptionItemModel) => `alert_${ex.id}`);
              } else {
                Text('暂无异常告警')
                  .fontSize(13).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              }
            }
            .width('100%')
            .margin({ bottom: 20 });

            // 今日概览
            Column() {
              Row() {
                Text('今日概览').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
                Text('查看报表').fontSize(12).fontColor('#1565C0').fontWeight(500)
                  .onClick(() => {
                    this.navigateTo('DataTab', 'Dashboard', {});
                  });
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 12 });

              if (this.vm.dashboardLoading) {
                Text('加载中...').fontSize(12).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              } else if (this.vm.dashboard !== null) {
                Grid() {
                  GridItem() { this.kpiCard('计划完成率', this.formatPercent(this.vm.dashboard!.todayPlanRate), '#1565C0'); }
                  GridItem() { this.kpiCard('投入数', `${this.vm.dashboard!.totalInput}`, '#1A1A2E'); }
                  GridItem() { this.kpiCard('产出数', `${this.vm.dashboard!.totalOutput}`, '#1A1A2E'); }
                  GridItem() { this.kpiCard('不良品', `${this.vm.dashboard!.totalNg}`,
                    (this.vm.dashboard!.totalNg ?? 0) > 0 ? '#F44336' : '#1A1A2E'); }
                  GridItem() { this.kpiCard('产品完工率', this.formatPercent(this.vm.dashboard!.productCompletionRate), '#1565C0'); }
                  GridItem() { this.kpiCard('工站完工率', this.formatPercent(this.vm.dashboard!.stationCompletionRate), '#1565C0'); }
                }
                .columnsTemplate('1fr 1fr 1fr')
                .rowsGap(8).columnsGap(8)
                .width('100%');
              } else {
                Text('暂无今日数据').fontSize(12).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              }
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
    }
    .width('100%').height('100%');
  }
}
