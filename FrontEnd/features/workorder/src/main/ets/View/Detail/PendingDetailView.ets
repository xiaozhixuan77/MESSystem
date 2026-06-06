import { PermissionUtil } from '@ohos/utils';
import { UserModel } from '@ohos/user';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';
import { WorkOrderRouteModel } from '../../Model/WorkOrderRouteModel';

@ComponentV2
export struct PendingDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;
  private hasAppeared: boolean = false;

  private get hasBottomActions(): boolean {
    return PermissionUtil.hasPermission('workorder.create', this.currentRole) ||
      PermissionUtil.hasPermission('workorder.dispatch', this.currentRole);
  }

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
            this.InfoSection();
            this.ProcessSection();
            this.OperatorSection();
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
    .width('100%').height('100%')
    .onAppear(() => {
      if (this.hasAppeared) {
        this.viewModel.loadDetail(this.workOrderId);
      }
      this.hasAppeared = true;
    });
  }

  @Builder
  PageHeader() {
    Row() {
      Image($r('app.media.icon_arrow_left_gray'))
        .width(20).height(20).fillColor('#1A1A2E')
        .onClick(() => this.pageStack.pop());
      Text('工单详情')
        .fontSize(18).fontWeight(700).fontColor('#1A1A2E')
        .layoutWeight(1).textAlign(TextAlign.Center)
        .margin({ left: 12 });
      Row().width(36).height(36);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#E8EBF0' });
  }

  @Builder
  StatusCard() {
    Column() {
      Row() {
        Text('待派工')
          .fontSize(12).fontWeight(600).fontColor(Color.White)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(20);
      }
      .margin({ bottom: 10 });

      Text(this.viewModel.currentWorkOrder?.code || '—')
        .fontSize(13).fontColor('rgba(255,255,255,0.9)')
        .margin({ bottom: 4 });

      Text(this.viewModel.currentWorkOrder?.productName || '加载中...')
        .fontSize(16).fontWeight(600).fontColor(Color.White)
        .margin({ bottom: 4 });

      Text((this.viewModel.currentWorkOrder?.processName || '') + ' · ' +
        (this.viewModel.currentWorkOrder?.productName || ''))
        .fontSize(13).fontColor('rgba(255,255,255,0.85)')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .padding(20).backgroundColor('#1565C0').borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 }).width('calc(100% - 32px)');
  }

  @Builder
  InfoSection() {
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
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#E8EBF0' })
      .width('100%').margin({ bottom: 14 });
  }

  @Builder
  FieldItem(label: string, value: string) {
    Column() {
      Text(label).fontSize(11).fontColor('#9A9AA8').margin({ bottom: 4 });
      Text(value).fontSize(14).fontWeight(600).fontColor('#1A1A2E');
    }
    .alignItems(HorizontalAlign.Start).width('100%');
  }

  @Builder
  ProcessSection() {
    Column() {
      this.SectionTitle('工艺流程');

      ForEach(this.viewModel.currentWorkOrder?.routeSteps || [],
        (step: WorkOrderRouteModel, index: number) => {
        Row() {
          Column() {
            Text(`${step.seqNo}`)
              .fontSize(11).fontWeight(700).fontColor(Color.White);
          }
          .width(24).height(24).backgroundColor('#1565C0').borderRadius(12)
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

          Column() {
            Text(step.name)
              .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
              .margin({ bottom: 2 });
            Text(step.opCode)
              .fontSize(12).fontColor('#5A5A6E');
          }
          .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);
        }
        .width('100%').padding({ top: 12, bottom: 12 })
        .border({ width: { bottom: index <
          (this.viewModel.currentWorkOrder?.routeSteps?.length || 0) - 1 ? 1 : 0 },
          color: '#E8EBF0' });
      }, (step: WorkOrderRouteModel, index: number) => `${step.seqNo}`);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder
  OperatorSection() {
    Column() {
      this.SectionTitle('选择操作员');

      if (this.viewModel.operators.length === 0) {
        Text('暂无可用操作员')
          .fontSize(13).fontColor('#9A9AA8').padding({ top: 12, bottom: 12 })
          .width('100%').textAlign(TextAlign.Center);
      } else {
        ForEach(this.viewModel.operators, (op: UserModel) => {
          Row() {
            Column() {
              Text(op.name.charAt(0))
                .fontSize(14).fontWeight(600).fontColor(Color.White);
            }
            .width(40).height(40)
            .backgroundColor('#42A5F5').borderRadius(20)
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

            Column() {
              Text(op.name)
                .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                .margin({ bottom: 2 });
              Text(`工号：${op.employeeNo}`)
                .fontSize(12).fontColor('#5A5A6E');
            }
            .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);

            Column() {
              if (this.viewModel.selectedOperatorId === op.id) {
                Image($r('app.media.icon_check_white'))
                  .width(12).height(12).fillColor(Color.White);
              }
            }
            .width(20).height(20)
            .backgroundColor(this.viewModel.selectedOperatorId === op.id ? '#1565C0' : Color.Transparent)
            .border({ width: 2,
              color: this.viewModel.selectedOperatorId === op.id ? '#1565C0' : '#E8EBF0' })
            .borderRadius(10)
            .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
          }
          .width('100%').padding(12)
          .backgroundColor(this.viewModel.selectedOperatorId === op.id ? '#E3F2FD' : '#F5F7FA')
          .borderRadius(12)
          .border({
            width: this.viewModel.selectedOperatorId === op.id ? 2 : 0,
            color: '#1565C0'
          })
          .margin({ bottom: 8 })
          .onClick(() => { this.viewModel.selectedOperatorId = op.id; });
        }, (op: UserModel) => `${op.id}`);
      }
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%');
  }

  @Builder
  BottomActions() {
    Row({ space: 12 }) {
      if (PermissionUtil.hasPermission('workorder.create', this.currentRole)) {
        Button('修改')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600)
          .fontColor('#1A1A2E').backgroundColor('#F5F7FA').borderRadius(12)
          .onClick(() => {
            const p: Record<string, number> = { 'workOrderId': this.workOrderId };
            this.pageStack.pushPathByName('WorkOrderEdit', p);
          });
      }

      if (PermissionUtil.hasPermission('workorder.dispatch', this.currentRole)) {
        Button('确认派工')
          .layoutWeight(2).height(46)
          .fontSize(15).fontWeight(600)
          .fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#90CAF9' : '#1565C0').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.dispatchWorkOrder(this.workOrderId);
            if (ok) { this.pageStack.pop(); }
          });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 28 })
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#E8EBF0' });
  }
}
