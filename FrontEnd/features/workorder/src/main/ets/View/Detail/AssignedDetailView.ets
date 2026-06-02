import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';
import { WorkOrderRouteModel } from '../../Model/WorkOrderRouteModel';

@ComponentV2
export struct AssignedDetailView {
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
            this.DispatchSection();
            this.TimelineSection();
            this.InfoSection();
            this.ProcessSection();
            this.ActionTip();
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
        Text('已派工')
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
    .backgroundColor('#4CAF50').width('100%');
  }

  @Builder
  DispatchSection() {
    Column() {
      Text('派工信息')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row() {
        Column() {
          Text((this.viewModel.currentWorkOrder?.operatorName || '?').charAt(0))
            .fontSize(24).fontWeight(700).fontColor(Color.White);
        }
        .width(56).height(56)
        .backgroundColor('#4CAF50').borderRadius(28)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        Column() {
          Text(this.viewModel.currentWorkOrder?.operatorName || '—')
            .fontSize(16).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 3 });
          Text('操作员')
            .fontSize(12).fontColor('#5A5A6E');
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 14 }).layoutWeight(1);
      }
      .width('100%').padding(14)
      .backgroundColor('#E8F5E9').borderRadius(12)
      .border({ width: 1, color: '#A5D6A7' })
      .margin({ bottom: 12 });

      Row() {
        Text('派工时间：')
          .fontSize(13).fontColor('#5A5A6E');
        Text(this.viewModel.currentWorkOrder?.dispatchTime || '—')
          .fontSize(13).fontWeight(500).fontColor('#1A1A2E');
      }
      .width('100%');
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
        this.TimelineItem('开始生产', '等待操作员开始...', false, true);
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
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
  InfoSection() {
    Column() {
      Text('工单信息')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Grid() {
        GridItem() { this.FieldItem('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0} 件`); }
        GridItem() { this.FieldItem('计划开始', this.viewModel.currentWorkOrder?.planStartTime || '—'); }
        GridItem() { this.FieldItem('计划完成', this.viewModel.currentWorkOrder?.planEndTime || '—'); }
        GridItem() { this.FieldItem('工单类型', this.viewModel.currentWorkOrder?.type || '—'); }
        GridItem() { this.FieldItem('创建时间', this.viewModel.currentWorkOrder?.createdAt || '—'); }
        GridItem() { this.FieldItem('创建人', this.viewModel.currentWorkOrder?.createdByName || '—'); }
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
  ProcessSection() {
    Column() {
      Text('工艺流程')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      Row({ space: 0 }) {
        ForEach(this.viewModel.currentWorkOrder?.routeSteps || [], (step: WorkOrderRouteModel, index: number) => {
          Row() {
            Column() {
              Text(`${step.seqNo}`)
                .fontSize(12).fontWeight(600).fontColor(Color.White);
            }
            .width(24).height(24).backgroundColor('#4CAF50').borderRadius(12)
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

            Column() {
              Text(step.name)
                .fontSize(12).fontWeight(500).fontColor('#1A1A2E').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
              Text(step.opCode)
                .fontSize(10).fontColor('#9A9AA8');
            }
            .alignItems(HorizontalAlign.Center).margin({ top: 4 });
          }
          .alignItems(VerticalAlign.Center);

          if (index < (this.viewModel.currentWorkOrder?.routeSteps?.length || 0) - 1) {
            Row().width(20).height(2).backgroundColor('#E8EBF0')
              .margin({ left: 2, right: 2, bottom: 20 });
          }
        }, (step: WorkOrderRouteModel, index: number) => `${step.seqNo}`);
      }
      .width('100%').justifyContent(FlexAlign.Start);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  ActionTip() {
    Row() {
      Text('操作员开始生产后，工单状态将变为"生产中"')
        .fontSize(13).fontColor('#5A5A6E').layoutWeight(1);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F5F7FA')
    .borderRadius(12);
  }

  @Builder
  BottomActions() {
    Row({ space: 12 }) {
      Button('编辑')
        .layoutWeight(1).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor('#1A1A2E')
        .backgroundColor('#F5F7FA').borderRadius(12)
        .onClick(() => {
          const navParam: Record<string, number> = { 'workOrderId': this.workOrderId };
          this.pageStack.pushPathByName('WorkOrderEdit', navParam);
        });

      Button('开始生产')
        .layoutWeight(2).height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.startWorkOrder(this.workOrderId);
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
