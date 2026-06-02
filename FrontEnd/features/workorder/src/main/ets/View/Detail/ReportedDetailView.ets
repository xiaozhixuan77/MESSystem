import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct ReportedDetailView {
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

  get isEndState(): boolean {
    const s = this.viewModel.currentWorkOrder?.status;
    return s === '完工' || s === '报废';
  }

  get statusColor(): string {
    const s = this.viewModel.currentWorkOrder?.status;
    if (s === '报废') {
      return '#F44336';
    }
    if (s === '完工') {
      return '#4CAF50';
    }
    return '#00897B';
  }

  get statusLabel(): string {
    return this.viewModel.currentWorkOrder?.status || '已报工';
  }

  get yieldRate(): string {
    const wo = this.viewModel.currentWorkOrder;
    if (!wo || wo.planQty <= 0) {
      return '0%';
    }
    const good = wo.reportedQtyGood || 0;
    return (good / wo.planQty * 100).toFixed(1) + '%';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.StatusCard();
          Column() {
            if (!this.isEndState || this.viewModel.currentWorkOrder?.status === '完工') {
              this.ReportResultSection();
            }
            this.ReportDetailSection();
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
      .padding({ bottom: this.isEndState ? 16 : 80 });

      if (!this.isEndState) {
        this.BottomActions();
      }
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
        Text(this.statusLabel)
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
    }
    .padding({ left: 16, right: 16, top: 48, bottom: 20 })
    .backgroundColor(this.statusColor).width('100%');
  }

  @Builder
  ReportResultSection() {
    Column() {
      Text('报工结果')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Grid() {
        GridItem() { this.FieldItem('良品', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0}`, '#4CAF50'); }
        GridItem() { this.FieldItem('NG', `${this.viewModel.currentWorkOrder?.reportedQtyNg || 0}`, '#F44336'); }
        GridItem() { this.FieldItem('实际工时', `${this.viewModel.currentWorkOrder?.reportedHours || 0}h`); }
        GridItem() { this.FieldItem('良品率', this.yieldRate, '#4CAF50'); }
      }
      .columnsTemplate('1fr 1fr').rowsGap(10).columnsGap(12).width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  FieldItem(label: string, value: string, valueColor?: ResourceColor) {
    Column() {
      Text(label).fontSize(11).fontColor('#5A5A6E').margin({ bottom: 3 });
      Text(value).fontSize(13).fontWeight(600).fontColor(valueColor || '#1A1A2E');
    }
    .alignItems(HorizontalAlign.Start).width('100%');
  }

  @Builder
  ReportDetailSection() {
    Column() {
      Text('报工详情')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Grid() {
        GridItem() { this.FieldItem('申报良品', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0} 件`); }
        GridItem() { this.FieldItem('申报NG', `${this.viewModel.currentWorkOrder?.reportedQtyNg || 0} 件`); }
        GridItem() { this.FieldItem('申报工时', `${this.viewModel.currentWorkOrder?.reportedHours || 0} 小时`); }
        GridItem() { this.FieldItem('操作员', this.viewModel.currentWorkOrder?.operatorName || '—'); }
        GridItem() { this.FieldItem('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0} 件`); }
        GridItem() { this.FieldItem('工单类型', this.viewModel.currentWorkOrder?.type || '—'); }
      }
      .columnsTemplate('1fr 1fr').rowsGap(10).columnsGap(12).width('100%');

      if (this.viewModel.currentWorkOrder?.exceptionNote) {
        Text('异常说明：' + this.viewModel.currentWorkOrder.exceptionNote)
          .fontSize(12).fontColor('#5A5A6E')
          .margin({ top: 12 })
          .width('100%');
      }
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  TimelineSection() {
    Column() {
      Text('状态流转记录')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Column() {
        this.LeftTimelineItem('工单创建', this.viewModel.currentWorkOrder?.createdAt || '—', true, false);
        this.LeftTimelineItem('工单派工', this.viewModel.currentWorkOrder?.dispatchTime || '—', true, false);
        this.LeftTimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true, false);
        this.LeftTimelineItem('生产完成，提交报工', this.viewModel.currentWorkOrder?.actualEndTime || '—', true, false);

        if (this.viewModel.currentWorkOrder?.status === '完工') {
          this.LeftTimelineItem('确认完工', this.viewModel.currentWorkOrder?.actualEndTime || '—', true, true);
        } else if (this.viewModel.currentWorkOrder?.status === '报废') {
          this.LeftTimelineItem('工单报废', this.viewModel.currentWorkOrder?.actualEndTime || '—', true, true);
        } else {
          this.LeftTimelineItem('等待确认', '待班组长确认工时', false, true);
        }
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

      Button('确认工时')
        .layoutWeight(2).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.confirmWorkOrder(this.workOrderId);
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
