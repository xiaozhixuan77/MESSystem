import { ExceptionModel } from '../Model/ExceptionModel';
import { ExceptionViewModel } from '../ViewModel/ExceptionViewModel';
import { PermissionUtil } from '@ohos/utils';

@ComponentV2
export struct ExceptionListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local vm: ExceptionViewModel = new ExceptionViewModel();
  @Local filterIndex: number = 0;

  aboutToAppear(): void {
    this.loadByFilter();
    this.vm.subscribeExceptions();
  }

  aboutToDisappear(): void {
    this.vm.unsubscribeExceptions();
  }

  loadByFilter(): void {
    if (this.filterIndex === 0) {
      this.vm.loadExceptions();
    } else if (this.filterIndex === 1) {
      this.vm.loadExceptions(false);
    } else {
      this.vm.loadExceptions(true);
    }
  }

  @Builder
  FilterTab(label: string, index: number) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontWeight(this.filterIndex === index ? 600 : 400)
        .fontColor(this.filterIndex === index ? Color.White : '#5A5A6E')
        .padding({ left: 14, right: 14, top: 6, bottom: 6 });
    }
    .borderRadius(8)
    .backgroundColor(this.filterIndex === index ? '#1565C0' : Color.Transparent)
    .onClick(() => {
      if (this.filterIndex !== index) {
        this.filterIndex = index;
        this.loadByFilter();
      }
    });
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('异常处理')
          .fontSize(18).fontWeight(700).fontColor('#1A1A2E');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // 筛选 Tab
      Row({ space: 8 }) {
        this.FilterTab('全部', 0);
        this.FilterTab('未处理', 1);
        this.FilterTab('已处理', 2);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // 列表
      Refresh({ refreshing: this.vm.isLoading }) {
        List() {
          if (this.vm.isLoading) {
            ListItem() {
              Row() {
                LoadingProgress().width(40).height(40);
              }
              .width('100%').height(200).justifyContent(FlexAlign.Center);
            }
          } else if (this.vm.errorMessage) {
            ListItem() {
              Column({ space: 12 }) {
                Text('加载失败').fontSize(16).fontColor('#5A5A6E');
                Text(this.vm.errorMessage).fontSize(13).fontColor('#9A9AA8')
                  .maxLines(2);
                Button('重试')
                  .fontSize(14).fontColor(Color.White)
                  .backgroundColor('#1565C0').borderRadius(8)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .onClick(() => this.loadByFilter());
              }
              .width('100%').padding(40).alignItems(HorizontalAlign.Center);
            }
          } else if (this.vm.exceptionList.length === 0) {
            ListItem() {
              Column({ space: 8 }) {
                Text(this.filterIndex === 0 ? '暂无异常记录' :
                  (this.filterIndex === 1 ? '暂无未处理异常' : '暂无已处理异常'))
                  .fontSize(16).fontColor('#5A5A6E');
              }
              .width('100%').padding(40).alignItems(HorizontalAlign.Center);
            }
          } else {
            ForEach(this.vm.exceptionList, (item: ExceptionModel) => {
              ListItem() {
                Column() {
                  // 第一行：产线 + 状态标签
                  Row() {
                    Text(item.lineName || '—')
                      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                      .layoutWeight(1);
                    Text(item.resolved === 1 ? '已处理' : '未处理')
                      .fontSize(10).fontWeight(600)
                      .fontColor(item.resolved === 1 ? '#4CAF50' : '#F44336')
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor(item.resolved === 1 ? '#E8F5E9' : '#FFEBEE')
                      .borderRadius(8);
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: 6 });

                  // 第二行：工单号
                  Row() {
                    Text('工单：')
                      .fontSize(11).fontColor('#9A9AA8');
                    Text(item.workOrderCode || `#${item.workOrderId}`)
                      .fontSize(11).fontColor('#1565C0');
                  }
                  .margin({ bottom: 6 });

                  // 第三行：描述
                  Text(item.description || '—')
                    .fontSize(13).fontColor('#5A5A6E')
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 8 });

                  // 底行：上报人 + 时间
                  Row() {
                    Text(item.reporterName || '')
                      .fontSize(11).fontColor('#9A9AA8');
                    Text(item.reportTime || '')
                      .fontSize(11).fontColor('#9A9AA8');
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween);
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .border({ width: 1, color: '#E8EBF0' })
                .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
              }
              .margin({ left: 16, right: 16, bottom: 10 })
              .onClick(() => {
                const p: Record<string, Object> = { 'exceptionId': item.id };
                this.pageStack.pushPathByName('ExceptionDetail', p);
              });
            }, (item: ExceptionModel) => `${item.id}`);
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None);
      }
      .layoutWeight(1)
      .onRefreshing(() => this.loadByFilter());
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA');
  }
}
