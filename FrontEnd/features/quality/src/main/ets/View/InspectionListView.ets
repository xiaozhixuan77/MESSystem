import { InspectionModel } from '../Model/InspectionModel';
import { QualityViewModel } from '../ViewModel/QualityViewModel';

@ComponentV2
export struct InspectionListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: QualityViewModel = new QualityViewModel();
  private hasAppeared: boolean = false;

  aboutToAppear(): void {
    this.viewModel.subscribeInspections();
  }

  @Builder
  StatusBadge(status: string) {
    Text(status || '已抽检')
      .fontSize(10).fontWeight(600)
      .fontColor(status === '待抽检' ? '#FF9800' : '#4CAF50')
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor(status === '待抽检' ? '#FFF3E0' : '#E8F5E9')
      .borderRadius(8);
  }

  @Builder
  ConclusionBadge(conclusion: string) {
    Text(conclusion || '—')
      .fontSize(11).fontWeight(600)
      .fontColor(conclusion === '合格' ? '#4CAF50' : (conclusion === '不合格' ? '#F44336' : '#9A9AA8'))
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor(conclusion === '合格' ? '#E8F5E9' : (conclusion === '不合格' ? '#FFEBEE' : '#F5F7FA'))
      .borderRadius(8);
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(13).fontWeight(600).fontColor('#1A1A2E')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 2 });
      Text(label)
        .fontSize(10).fontColor('#5A5A6E');
    }
    .layoutWeight(1);
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('抽检记录')
          .fontSize(18).fontWeight(700).fontColor('#1A1A2E');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // 列表
      Refresh({ refreshing: this.viewModel.isLoading }) {
        List() {
          if (this.viewModel.isLoading) {
            ListItem() {
              Row() {
                LoadingProgress().width(40).height(40);
              }
              .width('100%').height(200).justifyContent(FlexAlign.Center);
            }
          } else if (this.viewModel.errorMessage) {
            ListItem() {
              Column({ space: 12 }) {
                Text('加载失败').fontSize(16).fontColor('#5A5A6E');
                Text(this.viewModel.errorMessage).fontSize(13).fontColor('#9A9AA8')
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
                Button('重试')
                  .fontSize(14).fontColor(Color.White)
                  .backgroundColor('#1565C0').borderRadius(8)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .onClick(() => this.viewModel.loadInspections());
              }
              .width('100%').padding(40).alignItems(HorizontalAlign.Center);
            }
          } else if (this.viewModel.inspectionList.length === 0) {
            ListItem() {
              Column({ space: 8 }) {
                Text('暂无抽检记录').fontSize(16).fontColor('#5A5A6E');
                Text('工单报工后将自动生成待抽检任务').fontSize(13).fontColor('#9A9AA8');
              }
              .width('100%').padding(40).alignItems(HorizontalAlign.Center);
            }
          } else {
            ForEach(this.viewModel.inspectionList, (item: InspectionModel) => {
              ListItem() {
                Column() {
                  // 头部：工单号 + status + conclusion
                  Row() {
                    Text(item.workOrderCode || `工单 #${item.workOrderId}`)
                      .fontSize(14).fontWeight(700).fontColor('#1A1A2E')
                      .layoutWeight(1)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
                    Row({ space: 6 }) {
                      this.StatusBadge(item.status);
                      if (item.conclusion) {
                        this.ConclusionBadge(item.conclusion);
                      }
                    }
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: 10 });

                  // 产品/工序信息
                  if (item.productName) {
                    Text(`${item.productName}${item.processName ? ' · ' + item.processName : ''}`)
                      .fontSize(12).fontColor('#5A5A6E')
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ bottom: 8 });
                  }

                  // 统计行
                  Row({ space: 8 }) {
                    this.StatItem('抽检数量', `${item.sampleQty} 件`);
                    this.StatItem('良品', `${item.sampleGood} 件`);
                    this.StatItem('不良', `${item.sampleNg} 件`);
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12)
                  .margin({ bottom: 10 });

                  // 底部：时间 + 缺陷
                  Row() {
                    Text(item.inspectTime || '')
                      .fontSize(11).fontColor('#9A9AA8')
                      .maxLines(1);
                    if (item.defectTypes) {
                      Text(item.defectTypes)
                        .fontSize(11).fontColor('#FF9800')
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1).textAlign(TextAlign.End);
                    }
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween);
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
                .border({ width: 1, color: '#E8EBF0' });
              }
              .margin({ left: 16, right: 16, bottom: 10 })
              .onClick(() => {
                const p: Record<string, Object> = { 'inspectionId': item.id };
                this.pageStack.pushPathByName('InspectionDetail', p);
              });
            }, (item: InspectionModel) => `${item.id}-${item.status}`);
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None);
      }
      .layoutWeight(1)
      .onRefreshing(() => { this.viewModel.loadInspections(); });
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA')
    .onAppear(() => {
      this.viewModel.loadInspections();
      this.hasAppeared = true;
    });
  }
}
