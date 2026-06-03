import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { LineModel } from '../Model/LineModel';
import { StatusTag } from '@ohos/uicomponents';

@ComponentV2
export struct LineListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: ProductionViewModel = new ProductionViewModel();

  aboutToAppear(): void {
    this.viewModel.loadLines();
  }

  private getStatusColor(status: string): ResourceColor {
    if (status === '生产中') return '#52c41a';
    if (status === '空闲') return '#1890ff';
    if (status === '暂停') return '#faad14';
    if (status === '异常' || status === '停机') return '#f5222d';
    return '#999';
  }

  build() {
    Column() {
      Text('产线列表')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 16, top: 16, bottom: 12 })
        .width('100%');

      if (this.viewModel.isLoading && this.viewModel.lines.length === 0) {
        Column() {
          LoadingProgress()
            .width(32).height(32)
            .color('#1565C0');
          Text('加载中...')
            .fontSize(13)
            .fontColor('#999')
            .margin({ top: 8 });
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%');
      } else if (this.viewModel.errorMessage && this.viewModel.lines.length === 0) {
        Column() {
          Text('加载失败')
            .fontSize(15)
            .fontColor('#f5222d')
            .margin({ bottom: 12 });
          Text(this.viewModel.errorMessage)
            .fontSize(12)
            .fontColor('#999')
            .margin({ bottom: 16 });
          Button('重试')
            .fontSize(13)
            .backgroundColor('#1565C0')
            .borderRadius(8)
            .onClick(() => this.viewModel.loadLines());
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%');
      } else if (this.viewModel.lines.length === 0) {
        Column() {
          Text('暂无产线数据')
            .fontSize(14)
            .fontColor('#999');
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%');
      } else {
        Refresh({ refreshing: $$this.viewModel.isLoading }) {
          List() {
            ForEach(this.viewModel.lines, (line: LineModel) => {
              ListItem() {
                Row() {
                  Column()
                    .width(4)
                    .height(48)
                    .backgroundColor(this.getStatusColor(line.status))
                    .borderRadius(2)
                    .margin({ right: 12 });

                  Column() {
                    Row() {
                      Text(line.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#1A1A2E')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });
                      Blank();
                      StatusTag({ status: line.status });
                    }
                    .width('100%');

                    Text(line.workshopName || '')
                      .fontSize(12)
                      .fontColor('#9A9AA8')
                      .margin({ top: 4 });
                  }
                  .layoutWeight(1);
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#FFFFFF')
                .borderRadius(12);
              }
              .margin({ left: 16, right: 16, bottom: 10 })
              .onClick(() => {
                const params: Record<string, number> = { 'lineId': line.id };
                this.pageStack.pushPathByName('LineDetail', params);
              });
            }, (line: LineModel) => `${line.id}`);
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring);
        }
        .onRefreshing(() => {
          this.viewModel.loadLines();
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}
