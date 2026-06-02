import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct PausedDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    if (this.workOrderId > 0) {
      this.viewModel.loadDetail(this.workOrderId);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.StatusCard();
          Column() {
            if (this.viewModel.currentWorkOrder?.exceptionNote) {
              this.ExceptionSection();
            }
            this.ProgressSection();
            this.InfoSection();
            this.TimelineSection();
          }
          .padding(16)
          .width('100%');
        }
        .width('100%');
      }
      .width('100%').height('100%')
      .backgroundColor('#F5F7FA')
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
      .padding({ bottom: 80 });

      this.BottomActions();
    }
    .width('100%').height('100%');
  }

  @Builder
  StatusCard() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24).fillColor(Color.White)
          .onClick(() => this.pageStack.pop());
        Text('工单详情')
          .fontSize(18).fontWeight(700).fontColor(Color.White)
          .layoutWeight(1).textAlign(TextAlign.Center);
        Row().width(24).height(24);
      }
      .width('100%').margin({ bottom: 16 });

      Row() {
        Text('暂停中')
          .fontSize(12).fontWeight(500).fontColor(Color.White)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('rgba(255,255,255,0.2)').borderRadius(20);
      }
      .margin({ bottom: 10 });

      Text(this.viewModel.currentWorkOrder?.code || '—')
        .fontSize(15).fontColor('rgba(255,255,255,0.85)').margin({ bottom: 4 });
      Text(this.viewModel.currentWorkOrder?.productName || '加载中...')
        .fontSize(20).fontWeight(700).fontColor(Color.White).margin({ bottom: 4 });
      Text((this.viewModel.currentWorkOrder?.processName || '') + ' · ' + (this.viewModel.currentWorkOrder?.productName || ''))
        .fontSize(13).fontColor('rgba(255,255,255,0.8)')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });

      if (this.viewModel.currentWorkOrder?.exceptionNote) {
        Column() {
          Text('暂停原因：' + this.viewModel.currentWorkOrder.exceptionNote)
            .fontSize(14).fontWeight(600).fontColor(Color.White);
        }
        .width('100%')
        .padding(12)
        .backgroundColor('rgba(255,255,255,0.15)')
        .borderRadius(12)
        .margin({ top: 12 });
      }
    }
    .padding({ left: 16, right: 16, top: 48, bottom: 20 })
    .backgroundColor('#E65100').width('100%');
  }

  @Builder
  ExceptionSection() {
    Column() {
      Text('异常信息')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row() {
        Column() {
          Text('!')
            .fontSize(18).fontWeight(700).fontColor('#F44336');
        }
        .width(36).height(36)
        .backgroundColor('#FFEBEE')
        .borderRadius(18)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        Column() {
          Text('生产异常')
            .fontSize(14).fontWeight(600).fontColor('#F44336').margin({ bottom: 2 });
          Text(this.viewModel.currentWorkOrder?.exceptionNote || '')
            .fontSize(12).fontColor('#5A5A6E');
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);
      }
      .width('100%').padding(14)
      .backgroundColor('#FFEBEE').borderRadius(12)
      .border({ width: 1, color: '#FFCDD2' });
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  ProgressSection() {
    Column() {
      Text('当前进度')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row({ space: 12 }) {
        this.StatCard('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0}`, '#1A1A2E');
        this.StatCard('已完成', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0}`, '#4CAF50');
        this.StatCard('剩余', `${(this.viewModel.currentWorkOrder?.planQty || 0) - (this.viewModel.currentWorkOrder?.reportedQtyGood || 0)}`, '#F44336');
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  StatCard(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(value)
        .fontSize(22).fontWeight(700).fontColor(color);
      Text(label)
        .fontSize(11).fontColor('#5A5A6E').margin({ top: 2 });
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#F5F7FA').borderRadius(12)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  InfoSection() {
    Column() {
      Text('工单信息')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Grid() {
        GridItem() { this.FieldItem('操作员', this.viewModel.currentWorkOrder?.operatorName || '—'); }
        GridItem() { this.FieldItem('实际开始', this.viewModel.currentWorkOrder?.actualStartTime || '—'); }
        GridItem() { this.FieldItem('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0} 件`); }
        GridItem() { this.FieldItem('工单类型', this.viewModel.currentWorkOrder?.type || '—'); }
      }
      .columnsTemplate('1fr 1fr').rowsGap(10).columnsGap(12).width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  FieldItem(label: string, value: string) {
    Column() {
      Text(label).fontSize(11).fontColor('#5A5A6E').margin({ bottom: 3 });
      Text(value).fontSize(13).fontWeight(600).fontColor('#1A1A2E');
    }
    .alignItems(HorizontalAlign.Start).width('100%');
  }

  @Builder
  TimelineSection() {
    Column() {
      Text('状态流转记录')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Column() {
        this.LeftTimelineItem('工单创建', this.viewModel.currentWorkOrder?.createdAt || '—', true, false);
        this.LeftTimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true, false);
        this.LeftTimelineItem('工单暂停', this.viewModel.currentWorkOrder?.dispatchTime || '—', true, false);
        this.LeftTimelineItem('等待恢复', '等待故障修复后恢复生产', false, true);
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%');
  }

  @Builder
  LeftTimelineItem(title: string, time: string, done: boolean, last: boolean) {
    Row() {
      Column() {
        Circle()
          .width(10).height(10)
          .fill(done ? '#4CAF50' : '#E8EBF0');

        if (!last) {
          Row().width(2).height(30).backgroundColor('#E8EBF0');
        }
      }
      .alignItems(HorizontalAlign.Center);

      Column() {
        Text(title)
          .fontSize(13).fontWeight(500).fontColor(done ? '#1A1A2E' : '#9A9AA8')
          .margin({ bottom: 2 });
        Text(time)
          .fontSize(11).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder
  BottomActions() {
    Row({ space: 12 }) {
      Button('报废')
        .layoutWeight(1).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#EF9A9A' : '#F44336').borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.scrapWorkOrder(this.workOrderId);
          if (ok) {
            this.pageStack.pop();
          }
        });

      Button('恢复生产')
        .layoutWeight(2).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.resumeWorkOrder(this.workOrderId);
          if (ok) {
            this.pageStack.pop();
          }
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 28 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#E8EBF0' });
  }
}
