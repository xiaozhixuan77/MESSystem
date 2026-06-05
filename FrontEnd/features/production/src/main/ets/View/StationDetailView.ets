import { WebSocketService } from '@ohos/network';
import { LineApi } from '@ohos/network';
import { StationModel } from '../Model/StationModel';
import { promptAction } from '@kit.ArkUI';

@ComponentV2
export struct StationDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local stationId: number = 0;
  @Local lineId: number = 0;
  @Local station: StationModel = new StationModel();
  @Local lineName: string = '';
  @Local isLoading: boolean = true;
  @Local showExceptionDialog: boolean = false;
  @Local exceptionDescription: string = '';

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.stationId = (param?.['stationId'] as number) ?? 0;
    this.lineId = (param?.['lineId'] as number) ?? 0;
    if (this.lineId > 0 && this.stationId > 0) {
      this.loadData();
      this.subscribeStation();
    }
  }

  aboutToDisappear(): void {
    this.unsubscribeStation();
  }

  private async loadData(): Promise<void> {
    try {
      const data = await LineApi.getLineDetail(this.lineId) as Record<string, Object>;
      this.lineName = data['name'] as string ?? '';

      const stationsRaw = data['stations'] as Object[];
      if (stationsRaw) {
        const found = stationsRaw.find((s: Object) =>
          (s as Record<string, Object>)['id'] === this.stationId) as Record<string, Object> | undefined;
        if (found) {
          this.station.id = found['id'] as number ?? 0;
          this.station.opCode = found['opCode'] as string ?? '';
          this.station.name = found['name'] as string ?? '';
          this.station.equipmentCode = found['equipmentCode'] as string ?? '';
          this.station.deviceStatus = found['deviceStatus'] as string ?? '空闲';
          this.station.workStatus = found['workStatus'] as string ?? '空闲';
          this.station.conveyorStatus = found['conveyorStatus'] as string ?? '空闲';
          this.station.processedCount = found['processedCount'] as number ?? 0;
          this.station.rawCount = found['rawCount'] as number ?? 0;
          this.station.finishedCount = found['finishedCount'] as number ?? 0;
          this.station.ngCount = found['ngCount'] as number ?? 0;
        }
      }

    } catch (_e) {
      // 加载失败，显示空数据
    } finally {
      this.isLoading = false;
    }
  }

  private subscribeStation(): void {
    const topic = `/topic/lines/${this.lineId}/stations`;
    const ws = WebSocketService.getInstance();
    ws.subscribe(topic);
    WebSocketService.addListener(topic, this.onStationUpdate);
  }

  private unsubscribeStation(): void {
    const topic = `/topic/lines/${this.lineId}/stations`;
    // 不移除 STOMP 订阅 — LineDetailView (ProductionViewModel) 共享同一个 topic
    WebSocketService.removeListener(topic, this.onStationUpdate);
  }

  private onStationUpdate = (payload: Object): void => {
    const msg = payload as Record<string, Object>;
    const stationData = msg['data'] as Object[];
    if (!stationData) {
      return;
    }
    const update = stationData.find((s: Object) =>
      (s as Record<string, Object>)['stationId'] === this.stationId) as Record<string, Object> | undefined;
    if (update !== undefined) {
      this.station.processedCount = update['processedCount'] as number ?? this.station.processedCount;
      this.station.rawCount = update['rawCount'] as number ?? this.station.rawCount;
      this.station.finishedCount = update['finishedCount'] as number ?? this.station.finishedCount;
      this.station.ngCount = update['ngCount'] as number ?? this.station.ngCount;
      this.station.deviceStatus = update['deviceStatus'] as string ?? this.station.deviceStatus;
    }
  };

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2000 });
    } catch (_e) {
      // HAR module may not have UIContext
    }
  }

  private getYieldRate(): string {
    const total = this.station.finishedCount + this.station.ngCount;
    if (total === 0) return '—';
    return ((this.station.finishedCount / total) * 100).toFixed(1) + '%';
  }

  private getStatusDotColor(status: string): ResourceColor {
    if (status === '运行中') return '#4CAF50';
    if (status === '异常' || status === '故障') return '#F44336';
    if (status === '待机' || status === '暂停') return '#FF9800';
    return '#9A9AA8';
  }

  private getStatusBgColor(status: string): ResourceColor {
    if (status === '运行中') return 'rgba(76,175,80,0.2)';
    if (status === '异常' || status === '故障') return 'rgba(244,67,54,0.2)';
    return 'rgba(158,158,158,0.15)';
  }

  @Builder
  ExceptionDialog() {
    Column() {
      Column() {
        Text('异常上报')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')
          .margin({ bottom: 12 });

        Text('工作站：' + this.station.name)
          .fontSize(13).fontColor('#5A5A6E').margin({ bottom: 8 });

        TextArea({ placeholder: '请输入异常描述...', text: this.exceptionDescription })
          .fontSize(14).height(100)
          .backgroundColor('#F5F7FA').borderRadius(8).padding(12)
          .onChange((value: string) => { this.exceptionDescription = value; });

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14).backgroundColor('#F5F7FA').fontColor('#5A5A6E')
            .borderRadius(8).layoutWeight(1)
            .onClick(() => { this.showExceptionDialog = false; });
          Button('确认上报')
            .fontSize(14).backgroundColor('#F44336').fontColor('#FFFFFF')
            .borderRadius(8).layoutWeight(1)
            .enabled(this.exceptionDescription.trim().length > 0)
            .opacity(this.exceptionDescription.trim().length > 0 ? 1.0 : 0.4)
            .onClick(() => {
              this.showExceptionDialog = false;
              this.showToast('异常已上报');
            });
        }
        .width('100%').margin({ top: 16 });
      }
      .width('80%').padding(20).backgroundColor('#FFFFFF')
      .borderRadius(16).shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 8 });
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center).backgroundColor('rgba(0,0,0,0.45)')
    .zIndex(1000)
    .onClick(() => { this.showExceptionDialog = false; });
  }

  build() {
    Stack() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(36).height(36).color('#1565C0');
          Text('加载中...').fontSize(13).fontColor('#999').margin({ top: 8 });
        }
        .justifyContent(FlexAlign.Center).width('100%').height('100%');
      } else {
        Column() {
          // ── Header with gradient background ──
          Column() {
            // Top row: back + name + status
            Row() {
              Button() {
                Image($r('app.media.icon_arrow_left_white'))
                  .width(20).height(20);
              }
              .width(36).height(36)
              .backgroundColor('rgba(255,255,255,0.15)')
              .borderRadius(12)
              .onClick(() => this.pageStack.pop());

              Text(this.station.name || '工作站详情')
                .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                .layoutWeight(1).margin({ left: 12 });

              Row() {
                Circle({ width: 8, height: 8 })
                  .fill(this.getStatusDotColor(this.station.deviceStatus));
                Text(this.station.deviceStatus)
                  .fontSize(12).fontColor(
                    this.station.deviceStatus === '运行中' ? '#81C784' :
                    this.station.deviceStatus === '异常' ? '#FF8A80' : '#BDBDBD')
                  .fontWeight(FontWeight.Medium).margin({ left: 6 });
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.getStatusBgColor(this.station.deviceStatus))
              .borderRadius(20);
            }
            .width('100%').margin({ bottom: 14 });

            // Meta info row
            if (this.lineName) {
              Row() {
                Text(this.lineName + ' · 工位')
                  .fontSize(13).fontColor('rgba(255,255,255,0.85)');
              }
              .width('100%');
            }

            // 4 action buttons grid
            Row({ space: 8 }) {
              Button() {
                Column() {
                  Column() {
                    Image($r('app.media.icon_play_white')).width(16).height(16);
                  }
                  .width(32).height(32)
                  .backgroundColor('rgba(255,255,255,0.95)').borderRadius(8)
                  .justifyContent(FlexAlign.Center);
                  Text('启动').fontSize(10).fontColor('#FFFFFF').margin({ top: 6 });
                }
                .alignItems(HorizontalAlign.Center);
              }
              .layoutWeight(1).height(62)
              .backgroundColor('rgba(255,255,255,0.1)').borderRadius(12)
              .onClick(() => this.showToast('功能开发中'));

              Button() {
                Column() {
                  Column() {
                    Image($r('app.media.icon_stop_white')).width(16).height(16);
                  }
                  .width(32).height(32)
                  .backgroundColor('rgba(255,255,255,0.95)').borderRadius(8)
                  .justifyContent(FlexAlign.Center);
                  Text('停止').fontSize(10).fontColor('#FFFFFF').margin({ top: 6 });
                }
                .alignItems(HorizontalAlign.Center);
              }
              .layoutWeight(1).height(62)
              .backgroundColor('rgba(255,255,255,0.1)').borderRadius(12)
              .onClick(() => this.showToast('功能开发中'));

              Button() {
                Column() {
                  Column() {
                    Image($r('app.media.icon_reset_white')).width(16).height(16);
                  }
                  .width(32).height(32)
                  .backgroundColor('rgba(255,255,255,0.95)').borderRadius(8)
                  .justifyContent(FlexAlign.Center);
                  Text('复位').fontSize(10).fontColor('#FFFFFF').margin({ top: 6 });
                }
                .alignItems(HorizontalAlign.Center);
              }
              .layoutWeight(1).height(62)
              .backgroundColor('rgba(255,255,255,0.1)').borderRadius(12)
              .onClick(() => this.showToast('功能开发中'));

              Button() {
                Column() {
                  Column() {
                    Image($r('app.media.icon_alert_white')).width(16).height(16);
                  }
                  .width(32).height(32)
                  .backgroundColor('rgba(255,255,255,0.95)').borderRadius(8)
                  .justifyContent(FlexAlign.Center);
                  Text('异常').fontSize(10).fontColor('#FFFFFF').margin({ top: 6 });
                }
                .alignItems(HorizontalAlign.Center);
              }
              .layoutWeight(1).height(62)
              .backgroundColor('rgba(255,255,255,0.1)').borderRadius(12)
              .onClick(() => {
                this.showExceptionDialog = true;
                this.exceptionDescription = '';
              });
            }
            .width('100%').margin({ top: 16 });
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 18 })
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#1565C0', 0], ['#0D47A1', 1]]
          });

          // ── Scrollable content ──
          Scroll() {
            Column() {
              // 设备状态
              Text('设备状态')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')
                .width('100%').margin({ top: 16, bottom: 10 });

              Column() {
                Row() {
                  Text(this.station.equipmentCode || '未绑定设备')
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                  Blank();
                  Row() {
                    Circle({ width: 8, height: 8 })
                      .fill(this.station.deviceStatus === '运行中' ? '#4CAF50' :
                        this.station.deviceStatus === '异常' ? '#F44336' : '#9A9AA8');
                    Text(this.station.deviceStatus === '运行中' ? '运行正常' : this.station.deviceStatus)
                      .fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(this.station.deviceStatus === '运行中' ? '#4CAF50' : '#5A5A6E')
                      .margin({ left: 4 });
                  }
                }
                .width('100%').margin({ bottom: 14 });

                Row({ space: 10 }) {
                  Column() {
                    Text(`${this.station.processedCount}`)
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                    Text('处理数').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                  }
                  .layoutWeight(1).padding(10).backgroundColor('#F5F7FA').borderRadius(12).alignItems(HorizontalAlign.Center);

                  Column() {
                    Text(`${this.station.rawCount}`)
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                    Text('原料数').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                  }
                  .layoutWeight(1).padding(10).backgroundColor('#F5F7FA').borderRadius(12).alignItems(HorizontalAlign.Center);

                  Column() {
                    Text(this.getYieldRate())
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#4CAF50');
                    Text('良品率').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                  }
                  .layoutWeight(1).padding(10).backgroundColor('#F5F7FA').borderRadius(12).alignItems(HorizontalAlign.Center);
                }
                .width('100%');
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              .borderRadius(16).shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
              .margin({ bottom: 16 });

              // 传送带状态
              Text('传送带状态')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')
                .width('100%').margin({ bottom: 10 });

              Column() {
                Row() {
                  Text('主传送带')
                    .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                  Blank();
                  Text(this.station.conveyorStatus)
                    .fontSize(12).fontWeight(FontWeight.Bold)
                    .fontColor(this.station.conveyorStatus === '运行中' ? '#4CAF50' : '#9A9AA8');
                }
                .width('100%').margin({ bottom: 10 });

                // Conveyor visual indicator
                Row() {
                  Row().width('100%').height(4)
                    .backgroundColor(this.station.conveyorStatus === '运行中' ? '#E8EBF0' : '#F0F0F0')
                    .borderRadius(2);
                }
                .width('100%').height(40)
                .backgroundColor('#F5F7FA').borderRadius(12)
                .justifyContent(FlexAlign.Center)
                .margin({ bottom: 8 });

                Row() {
                  Text('速度：0.5m/s')
                    .fontSize(12).fontColor('#5A5A6E');
                  Blank();
                  Text('方向：正向')
                    .fontSize(12).fontColor('#5A5A6E');
                }
                .width('100%');
              }
              .width('100%').padding(16).backgroundColor('#FFFFFF')
              .borderRadius(16).shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
              .margin({ bottom: 16 });

              // 产出统计
              Text('产出统计')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')
                .width('100%').margin({ bottom: 10 });

              Row({ space: 10 }) {
                // 来料数
                Column() {
                  Column() {
                    Image($r('app.media.icon_cube_blue')).width(18).height(18);
                  }
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor('#E3F2FD').justifyContent(FlexAlign.Center)
                  .margin({ bottom: 8 });

                  Text(`${this.station.rawCount}`)
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                  Text('来料数')
                    .fontSize(11).fontColor('#5A5A6E').margin({ top: 4 });
                }
                .layoutWeight(1).padding({ top: 16, bottom: 16 })
                .backgroundColor('#FFFFFF').borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
                .alignItems(HorizontalAlign.Center);

                // 良品数
                Column() {
                  Column() {
                    Image($r('app.media.icon_check_green')).width(18).height(18);
                  }
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor('#E8F5E9').justifyContent(FlexAlign.Center)
                  .margin({ bottom: 8 });

                  Text(`${this.station.finishedCount}`)
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#4CAF50');
                  Text('良品数')
                    .fontSize(11).fontColor('#5A5A6E').margin({ top: 4 });
                }
                .layoutWeight(1).padding({ top: 16, bottom: 16 })
                .backgroundColor('#FFFFFF').borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
                .alignItems(HorizontalAlign.Center);

                // 不良数
                Column() {
                  Column() {
                    Image($r('app.media.icon_close_red')).width(18).height(18);
                  }
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor('#FFEBEE').justifyContent(FlexAlign.Center)
                  .margin({ bottom: 8 });

                  Text(`${this.station.ngCount}`)
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#F44336');
                  Text('不良数')
                    .fontSize(11).fontColor('#5A5A6E').margin({ top: 4 });
                }
                .layoutWeight(1).padding({ top: 16, bottom: 16 })
                .backgroundColor('#FFFFFF').borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
                .alignItems(HorizontalAlign.Center);
              }
              .width('100%').margin({ bottom: 16 });

              // 工作状态
              Row() {
                Text('工作状态：').fontSize(13).fontColor('#5A5A6E');
                Text(this.station.workStatus)
                  .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1A1A2E');
              }
              .width('100%').padding(14).backgroundColor('#FFFFFF')
              .borderRadius(12).margin({ bottom: 16 });
            }
            .padding({ left: 16, right: 16, bottom: 20 });
          }
          .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1).width('100%');
        }
        .width('100%').height('100%').backgroundColor('#F5F7FA');
      }

      // Exception dialog overlay
      if (this.showExceptionDialog) {
        this.ExceptionDialog();
      }
    }
    .width('100%').height('100%');
  }
}
