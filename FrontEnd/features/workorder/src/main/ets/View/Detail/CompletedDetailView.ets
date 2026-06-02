import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';
import { WorkOrderRouteModel } from '../../Model/WorkOrderRouteModel';

@ComponentV2
export struct CompletedDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    if (this.workOrderId > 0) {
      this.viewModel.loadDetail(this.workOrderId);
      this.viewModel.reportFormGood = this.viewModel.currentWorkOrder?.planQty || 0;
    }
  }

  get yieldRate(): string {
    const wo = this.viewModel.currentWorkOrder;
    if (!wo || wo.planQty <= 0) {
      return '0%';
    }
    return (wo.reportedQtyGood / wo.planQty * 100).toFixed(1) + '%';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.StatusCard();
          Column() {
            this.ResultSection();
            this.ReportFormSection();
            this.OperatorSection();
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
        Text('待报工')
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
    .backgroundColor('#FF9800').width('100%');
  }

  @Builder
  ResultSection() {
    Column() {
      Text('生产结果')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row({ space: 12 }) {
        this.StatCard('总产出', `${this.viewModel.currentWorkOrder?.planQty || 0}`, '#1565C0');
        this.StatCard('良品', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0}`, '#4CAF50');
        this.StatCard('NG', `${this.viewModel.currentWorkOrder?.reportedQtyNg || 0}`, '#F44336');
      }
      .width('100%').margin({ bottom: 12 });

      Row() {
        Text(this.yieldRate)
          .fontSize(28).fontWeight(700).fontColor(Color.White)
          .margin({ right: 8 });
        Text('良品率')
          .fontSize(12).fontColor('rgba(255,255,255,0.85)');
      }
      .width('100%').height(56)
      .backgroundColor('#4CAF50').borderRadius(12)
      .justifyContent(FlexAlign.Center);
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
  ReportFormSection() {
    Column() {
      Text('报工录入')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      this.FormInput('实际良品', this.viewModel.reportFormGood.toString(), (v: string) => {
        this.viewModel.reportFormGood = parseInt(v) || 0;
      });

      this.FormInput('实际NG', this.viewModel.reportFormNg.toString(), (v: string) => {
        this.viewModel.reportFormNg = parseInt(v) || 0;
      });

      this.FormInput('实际工时（小时）', this.viewModel.reportFormHours.toString(), (v: string) => {
        this.viewModel.reportFormHours = parseFloat(v) || 0;
      });

      Column() {
        Text('异常说明')
          .fontSize(12).fontWeight(500).fontColor('#1A1A2E')
          .margin({ bottom: 6 });
        TextInput({ placeholder: '如有异常请说明...', text: this.viewModel.reportFormNote })
          .height(80)
          .fontSize(14)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .border({ width: 1, color: '#E8EBF0' })
          .padding(12)
          .onChange((value: string) => {
            this.viewModel.reportFormNote = value;
          });
      }
      .width('100%')
      .margin({ bottom: 12 });
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  FormInput(label: string, value: string, onChange: (v: string) => void) {
    Column() {
      Text(label)
        .fontSize(12).fontWeight(500).fontColor('#1A1A2E')
        .margin({ bottom: 6 });
      TextInput({ text: value })
        .type(InputType.Number)
        .height(44)
        .fontSize(14)
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' })
        .padding({ left: 12, right: 12 })
        .onChange(onChange);
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  OperatorSection() {
    Column() {
      Text('操作员')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row() {
        Column() {
          Text((this.viewModel.currentWorkOrder?.operatorName || '?').charAt(0))
            .fontSize(18).fontWeight(600).fontColor(Color.White);
        }
        .width(40).height(40).backgroundColor('#FF9800').borderRadius(20)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        Column() {
          Text(this.viewModel.currentWorkOrder?.operatorName || '—')
            .fontSize(14).fontWeight(500).fontColor('#1A1A2E');
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);
      }
      .width('100%').padding(12)
      .backgroundColor('#FFF3E0').borderRadius(12);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  TimelineSection() {
    Column() {
      Text('状态时间线')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Column() {
        this.TimelineItem('工单创建', this.viewModel.currentWorkOrder?.createdAt || '—', true, false);
        this.TimelineItem('工单派工', this.viewModel.currentWorkOrder?.dispatchTime || '—', true, false);
        this.TimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true, false);
        this.TimelineItem('生产完成', this.viewModel.currentWorkOrder?.actualEndTime || '刚刚', true, true);
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%');
  }

  @Builder
  TimelineItem(title: string, time: string, done: boolean, last: boolean) {
    Row() {
      Column() {
        Column() {
          if (done) {
            Image($r('sys.media.ohos_ic_public_ok')).width(12).height(12).fillColor(Color.White);
          }
        }
        .width(24).height(24)
        .backgroundColor(done ? '#4CAF50' : '#E8EBF0').borderRadius(12)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        if (!last) {
          Row().width(2).height(24).backgroundColor('#E8EBF0');
        }
      }
      .alignItems(HorizontalAlign.Center);

      Column() {
        Text(title)
          .fontSize(14).fontWeight(600).fontColor(done ? '#1A1A2E' : '#9A9AA8')
          .margin({ bottom: 2 });
        Text(time)
          .fontSize(12).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder
  BottomActions() {
    Row({ space: 12 }) {
      Button('修改')
        .layoutWeight(1).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor('#1A1A2E')
        .backgroundColor('#F5F7FA').borderRadius(12)
        .onClick(() => {
          const navParam: Record<string, number> = { 'workOrderId': this.workOrderId };
          this.pageStack.pushPathByName('WorkOrderEdit', navParam);
        });

      Button('提交报工')
        .layoutWeight(2).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#FFB74D' : '#FF9800').borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.reportWorkOrder(this.workOrderId);
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
