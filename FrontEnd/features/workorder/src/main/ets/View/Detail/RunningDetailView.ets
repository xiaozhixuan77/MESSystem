import { PermissionUtil } from '@ohos/utils';
import { LoadingState, ErrorState } from '@ohos/uicomponents';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct RunningDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;
  private hasAppeared: boolean = false;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    if (this.workOrderId > 0) {
      this.viewModel.loadDetail(this.workOrderId).then(() => {
        if (this.viewModel.currentWorkOrder && this.viewModel.currentWorkOrder.lineId > 0) {
          this.viewModel.subscribeStationUpdates(this.viewModel.currentWorkOrder.lineId);
        }
      });
    }
  }

  aboutToDisappear(): void {
    this.viewModel.cleanup();
  }

  get progressValue(): number {
    const wo = this.viewModel.currentWorkOrder;
    if (!wo || wo.planQty <= 0) { return 0; }
    const actual = this.viewModel.stationTotalOutput > 0
      ? this.viewModel.stationTotalOutput
      : (wo.reportedQtyGood || 0);
    return Math.round(actual / wo.planQty * 100);
  }

  get goodCount(): string {
    const v = this.viewModel.stationTotalOutput > 0
      ? this.viewModel.stationTotalOutput - this.viewModel.stationTotalNg
      : (this.viewModel.currentWorkOrder?.reportedQtyGood || 0);
    return `${v}`;
  }

  get ngCount(): string {
    const v = this.viewModel.stationTotalNg || this.viewModel.currentWorkOrder?.reportedQtyNg || 0;
    return `${v}`;
  }

  get targetCount(): string {
    return `${this.viewModel.currentWorkOrder?.planQty || 0}`;
  }

  get elapsedDisplay(): string {
    return this.viewModel.elapsedText;
  }

  build() {
    if (this.viewModel.currentWorkOrder === null) {
      if (this.viewModel.errorMessage) {
        ErrorState({ showRetry: true, message: this.viewModel.errorMessage, onRetry: () => { this.viewModel.loadDetail(this.workOrderId); } })
      } else {
        LoadingState()
      }
    } else {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.PageHeader();
        if (this.viewModel.errorMessage) {
          Text(this.viewModel.errorMessage)
            .fontSize(13).fontColor('#B71C1C')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .width('100%').backgroundColor('#FFEBEE');
        }
        this.StatusCard();
        Scroll() {
          Column() {
            this.ProgressSection();
            this.InfoSection();
            this.RealtimeSection();
            this.OperatorSection();
            this.TimelineSection();
            Blank().height(100);
          }
          .padding(16).width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off).edgeEffect(EdgeEffect.None)
        .backgroundColor('#F5F7FA');
      }
      .width('100%').height('100%');

      this.BottomActions();
    }
    .width('100%').height('100%')
    .onAppear(() => {
      if (this.hasAppeared) {
        this.viewModel.loadDetail(this.workOrderId).then(() => {
          if (this.viewModel.currentWorkOrder && this.viewModel.currentWorkOrder.lineId > 0) {
            this.viewModel.subscribeStationUpdates(this.viewModel.currentWorkOrder.lineId);
          }
        });
      }
      this.hasAppeared = true;
    });
    }
  }

  @Builder PageHeader() {
    Row() {
      Image($r('app.media.icon_arrow_left_gray'))
        .width(20).height(20).fillColor('#1A1A2E')
        .onClick(() => this.pageStack.pop());
      Text('工单详情')
        .fontSize(18).fontWeight(700).fontColor('#1A1A2E')
        .layoutWeight(1).textAlign(TextAlign.Center).margin({ left: 12 });
      Row().width(36).height(36);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#E8EBF0' });
  }

  @Builder StatusCard() {
    Column() {
      Row() {
        Text('生产中')
          .fontSize(12).fontWeight(600).fontColor(Color.White)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('rgba(255,255,255,0.2)').borderRadius(20);
      }.margin({ bottom: 10 });
      Text(this.viewModel.currentWorkOrder?.code || '—')
        .fontSize(13).fontColor('rgba(255,255,255,0.9)').margin({ bottom: 4 });
      Text(this.viewModel.currentWorkOrder?.productName || '加载中...')
        .fontSize(16).fontWeight(600).fontColor(Color.White).margin({ bottom: 4 });
      Text((this.viewModel.currentWorkOrder?.processName || '') + ' · ' +
        (this.viewModel.currentWorkOrder?.productName || ''))
        .fontSize(13).fontColor('rgba(255,255,255,0.85)')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .padding(20).backgroundColor('#1565C0').borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 }).width('calc(100% - 32px)');
  }

  @Builder ProgressSection() {
    Column() {
      this.SectionTitle('生产进度');
      Column() {
        Progress({ value: this.progressValue, total: 100, type: ProgressType.Ring })
          .width(120).height(120)
          .color('#1565C0')
          .style({ strokeWidth: 12 });

        Text(`${this.progressValue}%`)
          .fontSize(36).fontWeight(700).fontColor('#1A1A2E')
          .margin({ top: -80 });
        Text('已完成')
          .fontSize(12).fontColor('#5A5A6E').margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Center).width('100%')
      .padding({ top: 20, bottom: 20 });

      Row({ space: 32 }) {
        Column() {
          Text(this.goodCount).fontSize(20).fontWeight(700).fontColor('#4CAF50');
          Text('良品').fontSize(12).fontColor('#5A5A6E').margin({ top: 2 });
        }.alignItems(HorizontalAlign.Center);
        Column() {
          Text(this.ngCount).fontSize(20).fontWeight(700).fontColor('#F44336');
          Text('NG').fontSize(12).fontColor('#5A5A6E').margin({ top: 2 });
        }.alignItems(HorizontalAlign.Center);
        Column() {
          Text(this.targetCount).fontSize(20).fontWeight(700).fontColor('#1A1A2E');
          Text('目标').fontSize(12).fontColor('#5A5A6E').margin({ top: 2 });
        }.alignItems(HorizontalAlign.Center);
      }
      .width('100%').justifyContent(FlexAlign.Center).margin({ top: 20 });
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder StatCard(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(value).fontSize(20).fontWeight(700).fontColor(color);
      Text(label).fontSize(12).fontColor('#5A5A6E').margin({ top: 2 });
    }
    .alignItems(HorizontalAlign.Center);
  }

  @Builder InfoSection() {
    Column() {
      this.SectionTitle('工单信息');
      Flex({ wrap: FlexWrap.Wrap }) {
        Column() {
          Text('工单编号').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.code || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('工单类型').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.type || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('所属车间').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.workshopName || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('所属产线').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.lineName || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('产品名称').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.productName || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('计划数量').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(`${this.viewModel.currentWorkOrder?.planQty || 0} 件`).fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('计划开始').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.planStartTime || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('计划完成').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.planEndTime || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
        Column() {
          Text('操作员').fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.operatorName || '—').fontSize(14).fontWeight(600).fontColor('#1A1A2E');
        }.alignItems(HorizontalAlign.Start).width('50%').margin({ bottom: 12 });
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder RealtimeSection() {
    Column() {
      this.SectionTitle('实时数据');
      Grid() {
        GridItem() { this.FieldItem('实际开始时间', this.viewModel.currentWorkOrder?.actualStartTime || '—'); }
        GridItem() { this.FieldItem('已运行时长', this.elapsedDisplay); }
        GridItem() { this.FieldItem('当前工序', this.viewModel.currentWorkOrder?.processName || '—'); }
        GridItem() { this.FieldItem('预估完成', this.viewModel.currentWorkOrder?.planEndTime || '—'); }
      }
      .columnsTemplate('1fr 1fr').rowsGap(12).columnsGap(12).width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder OperatorSection() {
    Column() {
      this.SectionTitle('操作员');
      Row() {
        Column() {
          Text((this.viewModel.currentWorkOrder?.operatorName || '?').charAt(0))
            .fontSize(14).fontWeight(600).fontColor(Color.White);
        }
        .width(40).height(40).backgroundColor('#1565C0').borderRadius(20)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
        Column() {
          Text(this.viewModel.currentWorkOrder?.operatorName || '—')
            .fontSize(14).fontWeight(600).fontColor('#1A1A2E');
          Text('操作员')
            .fontSize(12).fontColor('#5A5A6E');
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 12 });
      }
      .width('100%').padding(12).backgroundColor('#F5F7FA').borderRadius(12);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder TimelineSection() {
    Column() {
      this.SectionTitle('状态时间线');
      this.TimelineItem('工单创建', this.viewModel.currentWorkOrder?.createdAt || '—', true);
      this.TimelineItem('工单派工', this.viewModel.currentWorkOrder?.dispatchTime || '—', true);
      this.LastTimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%');
  }

  @Builder TimelineItem(title: string, time: string, done: boolean) {
    Row() {
      Column() {
        Column() {
          if (done) {
            Image($r('app.media.icon_check_white')).width(12).height(12).fillColor(Color.White);
          }
        }
        .width(24).height(24)
        .backgroundColor(done ? '#4CAF50' : '#E8EBF0').borderRadius(12)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
        Row().width(2).height(24).backgroundColor('#E8EBF0');
      }
      .alignItems(HorizontalAlign.Center);
      Column() {
        Text(title).fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
        Text(time).fontSize(12).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder LastTimelineItem(title: string, time: string, done: boolean) {
    Row() {
      Column() {
        Column() {
          if (done) {
            Image($r('app.media.icon_check_white')).width(12).height(12).fillColor(Color.White);
          }
        }
        .width(24).height(24)
        .backgroundColor(done ? '#4CAF50' : '#E8EBF0').borderRadius(12)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
      }
      .alignItems(HorizontalAlign.Center);
      Column() {
        Text(title).fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
        Text(time).fontSize(12).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder BottomActions() {
    Row({ space: 12 }) {
      Button('返回列表')
        .layoutWeight(1).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor('#1A1A2E').backgroundColor('#F5F7FA').borderRadius(12)
        .onClick(() => this.pageStack.pop());

      if (PermissionUtil.hasPermission('workorder.pause', this.currentRole)) {
        Button('暂停生产')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600).fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#FFB74D' : '#FF9800').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.pauseWorkOrder(this.workOrderId);
            if (ok) { this.pageStack.pop(); }
          });
      }

      if (PermissionUtil.hasPermission('workorder.complete', this.currentRole)) {
        Button('生产完成')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600).fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.completeWorkOrder(this.workOrderId);
            if (ok) { this.pageStack.pop(); }
          });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 28 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#E8EBF0' });
  }

  @Builder SectionTitle(title: string) {
    Text(title)
      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
      .padding({ bottom: 10 }).border({ width: { bottom: 1 }, color: '#E8EBF0' })
      .width('100%').margin({ bottom: 14 });
  }

  @Builder FieldItem(label: string, value: string) {
    Column() {
      Text(label).fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
      Text(value).fontSize(14).fontWeight(600).fontColor('#1A1A2E');
    }
    .alignItems(HorizontalAlign.Start).width('100%');
  }
}
