import { PermissionUtil } from '@ohos/utils';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct CompletedDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;

  private get hasBottomActions(): boolean {
    return PermissionUtil.hasPermission('workorder.report', this.currentRole);
  }

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    if (this.workOrderId > 0) {
      this.viewModel.loadDetail(this.workOrderId);
    }
  }

  get yieldRate(): string {
    const wo = this.viewModel.currentWorkOrder;
    if (!wo || wo.planQty <= 0) { return '0%'; }
    return (wo.reportedQtyGood / wo.planQty * 100).toFixed(1) + '%';
  }

  build() {
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
            this.ResultSection();
            this.InfoSection();
            this.ReportFormSection();
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

      if (this.hasBottomActions) {
        this.BottomActions();
      }
    }
    .width('100%').height('100%');
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
        Text('待报工')
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
    .padding(20).backgroundColor('#FF9800').borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 }).width('calc(100% - 32px)');
  }

  @Builder ResultSection() {
    Column() {
      this.SectionTitle('自动生产结果');

      Row({ space: 12 }) {
        this.StatCard('总产出', `${this.viewModel.currentWorkOrder?.planQty || 0}`, '#1565C0');
        this.StatCard('良品', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0}`, '#4CAF50');
        this.StatCard('NG', `${this.viewModel.currentWorkOrder?.reportedQtyNg || 0}`, '#F44336');
      }
      .width('100%').margin({ bottom: 16 });

      Row() {
        Text(this.yieldRate)
          .fontSize(28).fontWeight(700).fontColor(Color.White).margin({ right: 8 });
        Text('良品率')
          .fontSize(12).fontColor('rgba(255,255,255,0.9)');
      }
      .width('100%').height(48)
      .backgroundColor('#4CAF50').borderRadius(12)
      .justifyContent(FlexAlign.Center);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
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

  @Builder StatCard(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(value).fontSize(24).fontWeight(700).fontColor(color);
      Text(label).fontSize(12).fontColor('#5A5A6E').margin({ bottom: 4 });
    }
    .layoutWeight(1)
    .padding({ top: 16, bottom: 16, left: 8, right: 8 })
    .backgroundColor('#F5F7FA').borderRadius(12)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder ReportFormSection() {
    Column() {
      this.SectionTitle('报工录入');

      Row({ space: 12 }) {
        Column() {
          Text('实际良品').fontSize(12).fontColor('#5A5A6E').margin({ bottom: 6 });
          TextInput({ text: this.viewModel.reportFormGood.toString() })
            .type(InputType.Number).height(44).fontSize(14)
            .backgroundColor('#F5F7FA').borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' }).padding({ left: 12, right: 12 })
            .onChange((v: string) => { this.viewModel.reportFormGood = parseInt(v) || 0; });
        }
        .layoutWeight(1);

        Column() {
          Text('实际NG').fontSize(12).fontColor('#5A5A6E').margin({ bottom: 6 });
          TextInput({ text: this.viewModel.reportFormNg.toString() })
            .type(InputType.Number).height(44).fontSize(14)
            .backgroundColor('#F5F7FA').borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' }).padding({ left: 12, right: 12 })
            .onChange((v: string) => { this.viewModel.reportFormNg = parseInt(v) || 0; });
        }
        .layoutWeight(1);
      }
      .width('100%').margin({ bottom: 16 });

      Text('实际工时（小时）').fontSize(12).fontColor('#5A5A6E').margin({ bottom: 6 });
      TextInput({ text: this.viewModel.reportFormHours.toString() })
        .type(InputType.Number).height(44).fontSize(14)
        .backgroundColor('#F5F7FA').borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' }).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.viewModel.reportFormHours = parseFloat(v) || 0; })
        .margin({ bottom: 16 });

      Text('异常说明').fontSize(12).fontColor('#5A5A6E').margin({ bottom: 6 });
      TextInput({ placeholder: '如有异常请说明...', text: this.viewModel.reportFormNote })
        .height(80).fontSize(14)
        .backgroundColor('#F5F7FA').borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' }).padding(12)
        .onChange((v: string) => { this.viewModel.reportFormNote = v; });
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
        .width(40).height(40).backgroundColor('#FF9800').borderRadius(20)
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
      this.TimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true);
      this.LastTimelineItem('生产完成', this.viewModel.currentWorkOrder?.actualEndTime || '—', true);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%');
  }

  @Builder TimelineItem(title: string, time: string, done: boolean) {
    Row() {
      Column() {
        Column() {
          if (done) { Image($r('app.media.icon_check_white')).width(12).height(12).fillColor(Color.White); }
        }
        .width(24).height(24)
        .backgroundColor(done ? '#4CAF50' : '#E8EBF0').borderRadius(12)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
        Row().width(2).height(24).backgroundColor('#E8EBF0');
      }.alignItems(HorizontalAlign.Center);
      Column() {
        Text(title).fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
        Text(time).fontSize(12).fontColor('#9A9AA8');
      }.alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder LastTimelineItem(title: string, time: string, done: boolean) {
    Row() {
      Column() {
        Column() {
          if (done) { Image($r('app.media.icon_check_white')).width(12).height(12).fillColor(Color.White); }
        }
        .width(24).height(24)
        .backgroundColor(done ? '#4CAF50' : '#E8EBF0').borderRadius(12)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
      }.alignItems(HorizontalAlign.Center);
      Column() {
        Text(title).fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
        Text(time).fontSize(12).fontColor('#9A9AA8');
      }.alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder BottomActions() {
    Row({ space: 12 }) {
      if (PermissionUtil.hasPermission('workorder.report', this.currentRole)) {
        Button('提交报工')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600).fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#FFB74D' : '#FF9800').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.reportWorkOrder(this.workOrderId);
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
