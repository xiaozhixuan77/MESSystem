import { UserModel } from '@ohos/user';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';
import { WorkOrderRouteModel } from '../../Model/WorkOrderRouteModel';

@ComponentV2
export struct PendingDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
    if (this.workOrderId > 0) {
      this.viewModel.loadDetail(this.workOrderId);
      this.viewModel.loadOperators();
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.StatusCard();
          Column() {
            this.InfoSection();
            this.ProcessSection();
            this.OperatorSection();
          }
          .padding(16)
          .width('100%');
        }
        .width('100%');
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .padding({ bottom: 80 });

      this.BottomActions();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  StatusCard() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24)
          .fillColor(Color.White)
          .onClick(() => this.pageStack.pop());
        Text('工单详情')
          .fontSize(18).fontWeight(700).fontColor(Color.White)
          .layoutWeight(1).textAlign(TextAlign.Center);
        Row().width(24).height(24);
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Text('待派工')
          .fontSize(12).fontWeight(500).fontColor(Color.White)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(20);
      }
      .margin({ bottom: 10 });

      Text(this.viewModel.currentWorkOrder?.code || '—')
        .fontSize(15).fontColor('rgba(255,255,255,0.85)')
        .margin({ bottom: 4 });

      Text(this.viewModel.currentWorkOrder?.productName || '加载中...')
        .fontSize(20).fontWeight(700).fontColor(Color.White)
        .margin({ bottom: 4 });

      Text((this.viewModel.currentWorkOrder?.processName || '') + ' · ' + (this.viewModel.currentWorkOrder?.productName || ''))
        .fontSize(13).fontColor('rgba(255,255,255,0.8)')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .padding({ left: 16, right: 16, top: 48, bottom: 20 })
    .backgroundColor('#1565C0')
    .width('100%');
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
      .columnsTemplate('1fr 1fr')
      .rowsGap(10).columnsGap(12)
      .width('100%');
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  FieldItem(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11).fontColor('#5A5A6E')
        .margin({ bottom: 3 });
      Text(value)
        .fontSize(13).fontWeight(600).fontColor('#1A1A2E');
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
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
            .width(24).height(24)
            .backgroundColor('#1565C0')
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);

            Column() {
              Text(step.name)
                .fontSize(12).fontWeight(500).fontColor('#1A1A2E')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
              Text(step.opCode)
                .fontSize(10).fontColor('#9A9AA8');
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 4 });
          }
          .alignItems(VerticalAlign.Center);

          if (index < (this.viewModel.currentWorkOrder?.routeSteps?.length || 0) - 1) {
            Row()
              .width(20).height(2)
              .backgroundColor('#E8EBF0')
              .margin({ left: 2, right: 2, bottom: 20 });
          }
        }, (step: WorkOrderRouteModel, index: number) => `${step.seqNo}`);
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  OperatorSection() {
    Column() {
      Text('选择操作员')
        .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 }).width('100%');

      if (this.viewModel.operators.length === 0) {
        Text('加载操作员列表...')
          .fontSize(13).fontColor('#9A9AA8')
          .width('100%').textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 });
      } else {
        ForEach(this.viewModel.operators, (op: UserModel) => {
          Row() {
            Column() {
              Text(op.name.charAt(0))
                .fontSize(16).fontWeight(600).fontColor(Color.White);
            }
            .width(40).height(40)
            .backgroundColor('#1565C0')
            .borderRadius(20)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);

            Column() {
              Text(op.name)
                .fontSize(14).fontWeight(500).fontColor('#1A1A2E')
                .margin({ bottom: 2 });
              Text(`工号：${op.employeeNo}`)
                .fontSize(11).fontColor('#5A5A6E');
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1);

            if (this.viewModel.selectedOperatorId === op.id) {
              Column() {
                Image($r('sys.media.ohos_ic_public_ok'))
                  .width(16).height(16)
                  .fillColor('#1565C0');
              }
              .width(24).height(24)
              .backgroundColor('#E3F2FD')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.viewModel.selectedOperatorId === op.id ? '#E3F2FD' : '#F5F7FA')
          .borderRadius(12)
          .border({
            width: this.viewModel.selectedOperatorId === op.id ? 1.5 : 0,
            color: '#1565C0'
          })
          .margin({ bottom: 8 })
          .onClick(() => {
            this.viewModel.selectedOperatorId = op.id;
          });
        }, (op: UserModel) => `${op.id}`);
      }
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
    .width('100%');
  }

  @Builder
  BottomActions() {
    Row({ space: 12 }) {
      Button('修改')
        .layoutWeight(1)
        .height(46)
        .fontSize(15).fontWeight(600)
        .fontColor('#1A1A2E')
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .onClick(() => {
          const navParam: Record<string, number> = { 'workOrderId': this.workOrderId };
          this.pageStack.pushPathByName('WorkOrderEdit', navParam);
        });

      Button('确认派工')
        .layoutWeight(2)
        .height(46)
        .fontSize(15).fontWeight(600)
        .fontColor(Color.White)
        .backgroundColor(this.viewModel.isSubmitting ? '#7BA8D6' : '#1565C0')
        .borderRadius(12)
        .enabled(!this.viewModel.isSubmitting)
        .onClick(async () => {
          const ok = await this.viewModel.dispatchWorkOrder(this.workOrderId);
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
