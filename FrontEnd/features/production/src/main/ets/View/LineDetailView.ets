import { StationCard, KpiCard, StatusTag } from '@ohos/uicomponents';
import { PermissionUtil } from '@ohos/utils';
import { preferencesUtil } from '@ohos/datastore';
import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { StationModel } from '../Model/StationModel';
import { promptAction } from '@kit.ArkUI';

@ComponentV2
export struct LineDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local lineId: number = 0;
  @Local viewModel: ProductionViewModel = new ProductionViewModel();

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.lineId = (param?.['lineId'] as number) ?? 0;
    if (this.lineId <= 0) {
      return;
    }
    this.loadData();
  }

  aboutToDisappear(): void {
    this.viewModel.unsubscribeLine();
  }

  private async loadData(): Promise<void> {
    const userStr = await preferencesUtil.get('currentUser');
    if (userStr) {
      try {
        const user = JSON.parse(userStr) as Record<string, string>;
        this.viewModel.currentRole = user['role'] || '';
      } catch (_e) {
        // ignore parse error
      }
    }
    await this.viewModel.loadLineDetail(this.lineId);
    this.viewModel.subscribeLine(this.lineId);
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2000 });
    } catch (_e) {
      // HAR module may not have UIContext
    }
  }

  private canOperate(): boolean {
    return PermissionUtil.hasPermission('line.operate', this.viewModel.currentRole);
  }

  private canReportException(): boolean {
    return PermissionUtil.hasPermission('exception.report', this.viewModel.currentRole);
  }

  private async handleStart(): Promise<void> {
    const woId = this.viewModel.lineDetail.currentWorkorderId;
    if (!woId || woId <= 0) {
      this.showToast('当前无关联工单，无法启动');
      return;
    }
    const ok = await this.viewModel.startLine(this.lineId, woId);
    if (ok) {
      this.showToast('产线已启动');
      await this.viewModel.loadLineDetail(this.lineId);
    } else {
      this.showToast(this.viewModel.errorMessage || '启动失败');
    }
  }

  private async handleStop(): Promise<void> {
    const ok = await this.viewModel.stopLine(this.lineId);
    if (ok) {
      this.showToast('产线已停止');
      await this.viewModel.loadLineDetail(this.lineId);
    } else {
      this.showToast(this.viewModel.errorMessage || '停止失败');
    }
  }

  private async handleReset(): Promise<void> {
    const ok = await this.viewModel.resetLine(this.lineId);
    if (ok) {
      this.showToast('产线已复位');
      await this.viewModel.loadLineDetail(this.lineId);
    } else {
      this.showToast(this.viewModel.errorMessage || '复位失败');
    }
  }

  private handleException(): void {
    this.viewModel.showExceptionDialog = true;
    this.viewModel.exceptionDescription = '';
  }

  private confirmException(): void {
    this.viewModel.showExceptionDialog = false;
    this.showToast('异常已上报');
  }

  private cancelException(): void {
    this.viewModel.showExceptionDialog = false;
    this.viewModel.exceptionDescription = '';
  }

  private getActionButtonColor(action: string): string {
    if (action === 'start') return '#F6FFED';
    if (action === 'stop') return '#FFF7E6';
    if (action === 'reset') return '#E6F7FF';
    return '#FFF1F0';
  }

  private getActionTextColor(action: string): string {
    if (action === 'start') return '#52c41a';
    if (action === 'stop') return '#fa8c16';
    if (action === 'reset') return '#1890ff';
    return '#f5222d';
  }

  private isActionDisabled(action: string): boolean {
    const status = this.viewModel.lineDetail.status;
    if (action === 'start') return status === '生产中' || this.viewModel.isSubmitting;
    if (action === 'stop') return status !== '生产中' || this.viewModel.isSubmitting;
    if (action === 'reset') return this.viewModel.isSubmitting;
    return this.viewModel.isSubmitting;
  }

  @Builder
  ExceptionDialog() {
    Column() {
      Column() {
        Text('异常上报')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .margin({ bottom: 16 });

        TextArea({ placeholder: '请输入异常描述...', text: this.viewModel.exceptionDescription })
          .fontSize(14)
          .height(120)
          .backgroundColor('#F5F7FA')
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.viewModel.exceptionDescription = value;
          });

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .backgroundColor('#F5F7FA')
            .fontColor('#5A5A6E')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => this.cancelException());

          Button('确认上报')
            .fontSize(14)
            .backgroundColor('#f5222d')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => this.confirmException());
        }
        .width('100%')
        .margin({ top: 16 });
      }
      .width('80%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 8 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.45)')
    .zIndex(1000)
    .onClick(() => this.cancelException());
  }

  build() {
    Stack() {
      Column() {
        if (this.viewModel.isLoading) {
          Column() {
            LoadingProgress()
              .width(36).height(36)
              .color('#1565C0');
            Text('加载中...')
              .fontSize(13)
              .fontColor('#999')
              .margin({ top: 8 });
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .width('100%');
        } else if (this.viewModel.errorMessage && !this.viewModel.lineDetail.id) {
          Column() {
            Text('加载失败')
              .fontSize(16)
              .fontColor('#f5222d')
              .margin({ bottom: 8 });
            Text(this.viewModel.errorMessage)
              .fontSize(12)
              .fontColor('#999')
              .margin({ bottom: 16 });
            Button('重试')
              .fontSize(13)
              .backgroundColor('#1565C0')
              .borderRadius(8)
              .onClick(() => this.loadData());
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .width('100%');
        } else {
          Column() {
            // Header with gradient background
            Column() {
              Row() {
                Button() {
                  Image($r('app.media.icon_arrow_left_white'))
                    .width(20).height(20);
                }
                .width(36).height(36)
                .backgroundColor('rgba(255,255,255,0.15)')
                .borderRadius(12)
                .onClick(() => this.pageStack.pop());

                Text(this.viewModel.lineDetail.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .layoutWeight(1)
                  .margin({ left: 12 });

                StatusTag({ status: this.viewModel.lineDetail.status });
              }
              .width('100%');
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 48, bottom: 16 })
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#1565C0', 0], ['#0D47A1', 1]]
            });

            // Stale data warning
            if (this.viewModel.isDataStale && this.viewModel.lineDetail.id > 0) {
              Row() {
                Text('⚠ 数据刷新失败，当前显示可能已过期')
                  .fontSize(12)
                  .fontColor('#fa8c16');
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor('#FFF7E6');
            }

            // Scrollable content
            Scroll() {
            Column() {
              // Active Work Order Card
              if (this.viewModel.lineDetail.activeWorkOrder) {
                Column() {
                  Row() {
                    Text(this.viewModel.lineDetail.activeWorkOrder.code)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1A1A2E');

                    Blank();

                    Text(this.viewModel.lineDetail.activeWorkOrder.status)
                      .fontSize(12)
                      .fontColor('#1565C0')
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor('#E3F2FD')
                      .borderRadius(4);
                  }
                  .width('100%')
                  .margin({ bottom: 6 });

                  Text(this.viewModel.lineDetail.activeWorkOrder.productName +
                    (this.viewModel.lineDetail.activeWorkOrder.processName ?
                    ' - ' + this.viewModel.lineDetail.activeWorkOrder.processName : ''))
                    .fontSize(13)
                    .fontColor('#5A5A6E')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 10 });

                  Progress({
                    value: this.viewModel.todayOutput,
                    total: this.viewModel.lineDetail.activeWorkOrder.planQty,
                    type: ProgressType.Linear
                  })
                    .width('100%')
                    .height(6)
                    .color('#52c41a')
                    .backgroundColor('rgba(0,0,0,0.06)');
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
                .margin({ top: 16, bottom: 4 });
              }

              // Action Buttons
              if (this.canOperate() || this.canReportException()) {
                Row({ space: 10 }) {
                  if (this.canOperate()) {
                    Button() {
                      Column() {
                        Image($r('app.media.icon_play_white'))
                          .width(20).height(20);
                        Text('启动')
                          .fontSize(11)
                          .fontColor(this.getActionTextColor('start'))
                          .margin({ top: 4 });
                      }
                      .alignItems(HorizontalAlign.Center);
                    }
                    .layoutWeight(1)
                    .height(64)
                    .backgroundColor(this.getActionButtonColor('start'))
                    .borderRadius(12)
                    .enabled(!this.isActionDisabled('start'))
                    .opacity(this.isActionDisabled('start') ? 0.4 : 1.0)
                    .onClick(() => this.handleStart());

                    Button() {
                      Column() {
                        Image($r('app.media.icon_stop_white'))
                          .width(20).height(20);
                        Text('停止')
                          .fontSize(11)
                          .fontColor(this.getActionTextColor('stop'))
                          .margin({ top: 4 });
                      }
                      .alignItems(HorizontalAlign.Center);
                    }
                    .layoutWeight(1)
                    .height(64)
                    .backgroundColor(this.getActionButtonColor('stop'))
                    .borderRadius(12)
                    .enabled(!this.isActionDisabled('stop'))
                    .opacity(this.isActionDisabled('stop') ? 0.4 : 1.0)
                    .onClick(() => this.handleStop());

                    Button() {
                      Column() {
                        Image($r('app.media.icon_reset_white'))
                          .width(20).height(20);
                        Text('复位')
                          .fontSize(11)
                          .fontColor(this.getActionTextColor('reset'))
                          .margin({ top: 4 });
                      }
                      .alignItems(HorizontalAlign.Center);
                    }
                    .layoutWeight(1)
                    .height(64)
                    .backgroundColor(this.getActionButtonColor('reset'))
                    .borderRadius(12)
                    .enabled(!this.isActionDisabled('reset'))
                    .opacity(this.isActionDisabled('reset') ? 0.4 : 1.0)
                    .onClick(() => this.handleReset());
                  }

                  if (this.canReportException()) {
                    Button() {
                      Column() {
                        Image($r('app.media.icon_alert_white'))
                          .width(20).height(20);
                        Text('异常')
                          .fontSize(11)
                          .fontColor(this.getActionTextColor('exception'))
                          .margin({ top: 4 });
                      }
                      .alignItems(HorizontalAlign.Center);
                    }
                    .layoutWeight(1)
                    .height(64)
                    .backgroundColor(this.getActionButtonColor('exception'))
                    .borderRadius(12)
                    .enabled(!this.isActionDisabled('exception'))
                    .onClick(() => this.handleException());
                  }
                }
                .width('100%')
                .margin({ top: 14, bottom: 6 });
              }

              // KPI Section
              Text('实时数据')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A2E')
                .width('100%')
                .margin({ top: 16, bottom: 10 });

              Grid() {
                GridItem() {
                  KpiCard({
                    title: '今日产量',
                    value: `${this.viewModel.todayOutput}`,
                    color: '#1890ff'
                  });
                }

                GridItem() {
                  KpiCard({
                    title: '良品率',
                    value: this.viewModel.yieldRate,
                    color: '#52c41a'
                  });
                }

                GridItem() {
                  KpiCard({
                    title: '运行时长',
                    value: this.viewModel.runtime,
                    color: '#fa8c16'
                  });
                }

                GridItem() {
                  KpiCard({
                    title: '异常次数',
                    value: `${this.viewModel.exceptionCount}`,
                    color: '#f5222d'
                  });
                }
              }
              .columnsTemplate('1fr 1fr')
              .rowsGap(10)
              .columnsGap(10)
              .width('100%');

              // Station List
              Text('工作站状态')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A2E')
                .width('100%')
                .margin({ top: 16, bottom: 10 });

              List() {
                ForEach(this.viewModel.lineDetail.stations, (station: StationModel, index: number) => {
                  ListItem() {
                    Row() {
                      // Numbered circle
                      Text(`${index + 1}`)
                        .fontSize(12)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                        .width(28).height(28)
                        .textAlign(TextAlign.Center)
                        .borderRadius(14)
                        .linearGradient({
                          direction: GradientDirection.Bottom,
                          colors: [['#1565C0', 0], ['#0D47A1', 1]]
                        });

                      // Station info
                      Column() {
                        Text(station.name)
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#1A1A2E');
                        Text(station.deviceStatus === '运行中' ? '运行正常' : station.deviceStatus)
                          .fontSize(11)
                          .fontColor(station.deviceStatus === '运行中' ? '#4CAF50' : '#5A5A6E')
                          .margin({ top: 2 });
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({ left: 12 });

                      // Processed count
                      Column() {
                        Text(`${station.processedCount}`)
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#1A1A2E');
                        Text('已处理')
                          .fontSize(10)
                          .fontColor('#5A5A6E');
                      }
                      .alignItems(HorizontalAlign.End);
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center);
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                  .border({ width: { bottom: index < this.viewModel.lineDetail.stations.length - 1 ? 1 : 0 },
                    color: '#E8EBF0' })
                  .onClick(() => {
                    const params: Record<string, number> = { 'stationId': station.id };
                    this.pageStack.pushPathByName('StationDetail', params);
                  });
                }, (station: StationModel) => `${station.id}`);
              }
              .width('100%')
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
              .margin({ bottom: 16 });
            }
            .padding({ left: 16, right: 16 });
            }
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .layoutWeight(1)
            .width('100%');
          }
          .width('100%')
          .height('100%');
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA');

      // Exception Dialog Overlay
      if (this.viewModel.showExceptionDialog) {
        this.ExceptionDialog();
      }
    }
    .width('100%')
    .height('100%');
  }
}
