import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { LineModel } from '../Model/LineModel';

@ComponentV2
export struct LineListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: ProductionViewModel = new ProductionViewModel();
  @Local activeTab: string = '全部';

  aboutToAppear(): void {
    this.viewModel.loadLines();
  }

  aboutToDisappear(): void {
    this.viewModel.unsubscribeLineList();
  }

  private getIconBgColor(status: string): [string, string] {
    if (status === '生产中') return ['#42A5F5', '#1565C0'];
    if (status === '异常' || status === '故障' || status === '停机') return ['#FF8A80', '#F44336'];
    return ['#BDBDBD', '#9E9E9E'];
  }

  private getStatusBadgeColor(status: string): [string, string] {
    if (status === '生产中') return ['#E8F5E9', '#4CAF50'];
    if (status === '异常' || status === '故障' || status === '停机') return ['#FFEBEE', '#F44336'];
    if (status === '暂停') return ['#FFF8E1', '#FF9800'];
    return ['#F5F5F5', '#9A9AA8'];
  }

  private getYieldRate(finished: number, ng: number): string {
    const total = finished + ng;
    if (total === 0) return '—';
    return ((finished / total) * 100).toFixed(1) + '%';
  }

  private getProgress(woCode: string | undefined, finished: number, planQty: number): string {
    if (!woCode) return '—';
    if (planQty <= 0) return '0%';
    return Math.round((finished / planQty) * 100) + '%';
  }

  private getOutput(finished: number): string {
    return finished > 0 ? `${finished}` : '—';
  }

  private getFooterText(line: LineModel): string {
    if (line.workOrderCode) {
      return `当前工单：${line.workOrderCode}`;
    }
    if (line.status === '异常' || line.status === '故障') {
      return '异常停机中';
    }
    return '空闲中';
  }

  private selectTab(tab: string): void {
    this.activeTab = tab;
    if (tab === '全部') {
      this.viewModel.loadLines();
    } else {
      const statusMap: Record<string, string> = {
        '运行中': '生产中',
        '故障': '异常',
        '待机': '空闲'
      };
      this.viewModel.loadLines(statusMap[tab] || tab);
    }
  }

  @Builder
  StatusTab(label: string, filterKey: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.activeTab === filterKey ? '#FFFFFF' : '#5A5A6E')
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .backgroundColor(this.activeTab === filterKey ? '#1565C0' : '#F5F7FA')
      .borderRadius(20)
      .onClick(() => this.selectTab(filterKey));
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.icon_arrow_left_gray'))
          .width(20).height(20)
          .onClick(() => this.pageStack.pop());

        Text('产线数据')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .layoutWeight(1)
          .margin({ left: 12 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // Status Tabs
      Row({ space: 8 }) {
        this.StatusTab('全部', '全部');
        this.StatusTab('运行中', '运行中');
        this.StatusTab('故障', '故障');
        this.StatusTab('待机', '待机');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#FFFFFF');

      // Content
      if (this.viewModel.isLoading && this.viewModel.lines.length === 0) {
        Column() {
          LoadingProgress().width(32).height(32).color('#1565C0');
          Text('加载中...').fontSize(13).fontColor('#999').margin({ top: 8 });
        }
        .justifyContent(FlexAlign.Center).layoutWeight(1).width('100%');
      } else if (this.viewModel.errorMessage && this.viewModel.lines.length === 0) {
        Column() {
          Text('加载失败').fontSize(15).fontColor('#f5222d').margin({ bottom: 8 });
          Text(this.viewModel.errorMessage).fontSize(12).fontColor('#999').margin({ bottom: 16 });
          Button('重试').fontSize(13).backgroundColor('#1565C0').borderRadius(8)
            .onClick(() => this.selectTab(this.activeTab));
        }
        .justifyContent(FlexAlign.Center).layoutWeight(1).width('100%');
      } else if (this.viewModel.lines.length === 0) {
        Column() {
          Text('暂无产线数据').fontSize(14).fontColor('#999');
        }
        .justifyContent(FlexAlign.Center).layoutWeight(1).width('100%');
      } else {
        Refresh({ refreshing: $$this.viewModel.isLoading }) {
          List() {
            ForEach(this.viewModel.lines, (line: LineModel) => {
              ListItem() {
                Column() {
                  // Card Header
                  Row() {
                    // Line icon
                    Column() {
                      Image($r('app.media.icon_line_white'))
                        .width(22).height(22);
                    }
                    .width(44).height(44)
                    .borderRadius(12)
                    .linearGradient({
                      direction: GradientDirection.Bottom,
                      colors: [
                        [this.getIconBgColor(line.status)[0], 0],
                        [this.getIconBgColor(line.status)[1], 1]
                      ]
                    })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center);

                    // Line name + type
                    Column() {
                      Text(line.name)
                        .fontSize(15)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#1A1A2E');
                      Text(`${line.stationCount || '—'}工作站 · ${line.workshopName || ''}`)
                        .fontSize(11)
                        .fontColor('#5A5A6E')
                        .margin({ top: 2 });
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 10 });

                    // Status badge
                    Row() {
                      Circle({ width: 8, height: 8 })
                        .fill(this.getStatusBadgeColor(line.status)[1]);
                      Text(line.status)
                        .fontSize(11)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.getStatusBadgeColor(line.status)[1])
                        .margin({ left: 4 });
                    }
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(this.getStatusBadgeColor(line.status)[0])
                    .borderRadius(12);
                  }
                  .width('100%')
                  .margin({ bottom: 14 });

                  // Stats Grid
                  if (line.workOrderCode) {
                    Row() {
                      Column() {
                        Text(this.getProgress(line.workOrderCode, line.finishedCount, line.planQty))
                          .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                        Text('完成进度').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                      }
                      .layoutWeight(1);
                      Column() {
                        Text(this.getYieldRate(line.finishedCount, line.ngCount))
                          .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#4CAF50');
                        Text('良品率').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                      }
                      .layoutWeight(1);
                      Column() {
                        Text(this.getOutput(line.finishedCount))
                          .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
                        Text('已产出').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
                      }
                      .layoutWeight(1);
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#F5F7FA')
                    .borderRadius(12)
                    .margin({ bottom: 12 });
                  }

                  // Footer
                  Row() {
                    Text(this.getFooterText(line))
                      .fontSize(12)
                      .fontColor('#5A5A6E')
                      .layoutWeight(1);

                    Text('查看详情')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                      .backgroundColor('#1565C0')
                      .borderRadius(8)
                      .onClick(() => {
                        const p: Record<string, number> = { 'lineId': line.id };
                        this.pageStack.pushPathByName('LineDetail', p);
                      });
                  }
                  .width('100%');
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
              }
              .margin({ left: 16, right: 16, bottom: 12 });
            }, (line: LineModel) => `${line.id}`);
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring);
        }
        .onRefreshing(() => this.selectTab(this.activeTab));
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}
