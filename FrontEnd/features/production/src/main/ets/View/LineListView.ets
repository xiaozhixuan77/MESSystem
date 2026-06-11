import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { LineModel } from '../Model/LineModel';
import { ErrorState } from '@ohos/uicomponents';

@ComponentV2
struct LineCard {
  @Param line: LineModel = new LineModel();
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();

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
    const total = finished;
    if (total === 0) return '—';
    const good = finished - ng;
    return ((good / total) * 100).toFixed(1) + '%';
  }

  private getProgress(woCode: string | undefined, finished: number, planQty: number): string {
    if (!woCode) return '—';
    if (planQty <= 0) return '0%';
    return Math.round((finished / planQty) * 100) + '%';
  }

  private getOutput(finished: number): string {
    return finished > 0 ? `${finished}` : '—';
  }

  private getFooterText(): string {
    if (this.line.workOrderCode) {
      return `当前工单：${this.line.workOrderCode}`;
    }
    if (this.line.status === '异常' || this.line.status === '故障') {
      return '异常停机中';
    }
    return '空闲中';
  }

  build() {
    Column() {
      // Card Header
      Row() {
        Column() {
          Image($r('app.media.icon_line_white'))
            .width(22).height(22);
        }
        .width(44).height(44)
        .borderRadius(12)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.getIconBgColor(this.line.status)[0], 0],
            [this.getIconBgColor(this.line.status)[1], 1]
          ]
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Column() {
          Text(this.line.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E');
          Text(`${this.line.stationCount || '—'}工作站 · ${this.line.workshopName || ''}`)
            .fontSize(11)
            .fontColor('#5A5A6E')
            .margin({ top: 2 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 });

        Row() {
          Circle({ width: 8, height: 8 })
            .fill(this.getStatusBadgeColor(this.line.status)[1]);
          Text(this.line.status)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getStatusBadgeColor(this.line.status)[1])
            .margin({ left: 4 });
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor(this.getStatusBadgeColor(this.line.status)[0])
        .borderRadius(12);
      }
      .width('100%')
      .margin({ bottom: 14 });

      if (this.line.workOrderCode) {
        Row() {
          Column() {
            Text(this.getProgress(this.line.workOrderCode, this.line.finishedCount, this.line.planQty))
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1A1A2E');
            Text('完成进度').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
          }
          .layoutWeight(1);
          Column() {
            Text(this.getYieldRate(this.line.finishedCount, this.line.ngCount))
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#4CAF50');
            Text('良品率').fontSize(10).fontColor('#5A5A6E').margin({ top: 2 });
          }
          .layoutWeight(1);
          Column() {
            Text(this.getOutput(this.line.finishedCount))
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

      Row() {
        Text(this.getFooterText())
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
            const p: Record<string, number> = { 'lineId': this.line.id };
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
}

@ComponentV2
export struct LineListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('sharedVm') viewModel: ProductionViewModel = new ProductionViewModel();
  @Local activeTab: string = '全部';
  @Local isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.viewModel.loadLines();
  }

  aboutToDisappear(): void {
    // 不取消 WebSocket 订阅 — 保持在后台接收实时推送
  }

  private selectTab(tab: string): Promise<void> {
    this.activeTab = tab;
    if (tab === '全部') {
      return this.viewModel.loadLines();
    }
    return this.viewModel.loadLines(tab);
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
      if (this.viewModel.refreshKey >= 0) {
        // Header
      Row() {
        Text('产线数据')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E');
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        // Status Tabs
        Row({ space: 8 }) {
          this.StatusTab('全部', '全部');
          this.StatusTab('生产中', '生产中');
          this.StatusTab('暂停', '暂停');
          this.StatusTab('异常', '异常');
          this.StatusTab('空闲', '空闲');
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
          ErrorState({ message: this.viewModel.errorMessage, onRetry: () => { this.selectTab(this.activeTab); } })
        } else if (this.viewModel.lines.length === 0) {
          Column() {
            Text('暂无产线数据').fontSize(14).fontColor('#999');
          }
          .justifyContent(FlexAlign.Center).layoutWeight(1).width('100%');
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List() {
              ForEach(this.viewModel.lines, (line: LineModel) => {
                ListItem() {
                  LineCard({ line: line })
                }
                .margin({ left: 16, right: 16, bottom: 12 });
              }, (line: LineModel) => `${line.id}_${line.finishedCount}_${line.ngCount}_${line.status}`);
            }
            .scrollBar(BarState.Off)
            .layoutWeight(1)
            .edgeEffect(EdgeEffect.Spring);
          }
          .onRefreshing(() => {
            this.isRefreshing = true;
            this.selectTab(this.activeTab).finally(() => {
              this.isRefreshing = false;
            });
          });
        }
      }
      }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}
