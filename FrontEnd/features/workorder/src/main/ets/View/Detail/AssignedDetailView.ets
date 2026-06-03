import { PermissionUtil } from '@ohos/utils';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';
import { WorkOrderRouteModel } from '../../Model/WorkOrderRouteModel';

@ComponentV2
export struct AssignedDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;

  private get hasBottomActions(): boolean {
    return PermissionUtil.hasPermission('workorder.create', this.currentRole) ||
      PermissionUtil.hasPermission('workorder.start', this.currentRole);
  }

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
      Column() {
        this.PageHeader();
        this.StatusCard();
        Scroll() {
          Column() {
            this.DispatchSection();
            this.TimelineSection();
            this.InfoSection();
            this.ProcessSection();
            this.ActionTip();
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
        Text('已派工')
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
    .padding(20).backgroundColor('#4CAF50').borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 }).width('calc(100% - 32px)');
  }

  @Builder DispatchSection() {
    Column() {
      this.SectionTitle('派工信息');

      Row() {
        Column() {
          Text((this.viewModel.currentWorkOrder?.operatorName || '?').charAt(0))
            .fontSize(20).fontWeight(700).fontColor(Color.White);
        }
        .width(56).height(56).backgroundColor('#4CAF50').borderRadius(28)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        Column() {
          Text(this.viewModel.currentWorkOrder?.operatorName || '—')
            .fontSize(16).fontWeight(700).fontColor('#1A1A2E').margin({ bottom: 4 });
          Text('操作员')
            .fontSize(13).fontColor('#5A5A6E').margin({ bottom: 4 });
          Text('A班组 · 装配一车间')
            .fontSize(12).fontWeight(600).fontColor('#1565C0');
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 14 }).layoutWeight(1);
      }
      .width('100%').padding(16)
      .backgroundColor('#E3F2FD').borderRadius(12)
      .border({ width: 1, color: '#42A5F5' })
      .margin({ bottom: 12 });

      Row() {
        Text('派工时间：')
          .fontSize(12).fontColor('#5A5A6E');
        Text(this.viewModel.currentWorkOrder?.dispatchTime || '—')
          .fontSize(12).fontColor('#5A5A6E');
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: '#E8EBF0', style: BorderStyle.Dashed });
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
      this.LastTimelineItem('开始生产', '等待操作员开始...', false);
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
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
        Text(title)
          .fontSize(14).fontWeight(600)
          .fontColor(done ? '#1A1A2E' : '#9A9AA8').margin({ bottom: 2 });
        Text(time)
          .fontSize(12).fontColor('#9A9AA8');
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
        Text(title)
          .fontSize(14).fontWeight(600)
          .fontColor(done ? '#1A1A2E' : '#9A9AA8').margin({ bottom: 2 });
        Text(time)
          .fontSize(12).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top);
  }

  @Builder InfoSection() {
    Column() {
      this.SectionTitle('工单信息');
      Grid() {
        GridItem() { this.FieldItem('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0} 件`); }
        GridItem() { this.FieldItem('计划工时', '—'); }
        GridItem() { this.FieldItem('计划开始', this.viewModel.currentWorkOrder?.planStartTime || '—'); }
        GridItem() { this.FieldItem('计划完成', this.viewModel.currentWorkOrder?.planEndTime || '—'); }
        GridItem() { this.FieldItem('产线', this.viewModel.currentWorkOrder?.productName || '—'); }
        GridItem() { this.FieldItem('优先级', '高'); }
      }
      .columnsTemplate('1fr 1fr').rowsGap(12).columnsGap(12).width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder ProcessSection() {
    Column() {
      this.SectionTitle('工艺流程');
      ForEach(this.viewModel.currentWorkOrder?.routeSteps || [],
        (step: WorkOrderRouteModel, index: number) => {
        Row() {
          Column() {
            Text(`${step.seqNo}`)
              .fontSize(11).fontWeight(700).fontColor(Color.White);
          }
          .width(24).height(24).backgroundColor('#4CAF50').borderRadius(12)
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

          Column() {
            Text(step.name).fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
            Text(step.opCode).fontSize(12).fontColor('#5A5A6E');
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

  @Builder ActionTip() {
    Row() {
      Text('操作员开始生产后，工单状态将变为"生产中"')
        .fontSize(13).fontColor('#5A5A6E').layoutWeight(1);
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#F5F7FA').borderRadius(12);
  }

  @Builder BottomActions() {
    Row({ space: 12 }) {
      if (PermissionUtil.hasPermission('workorder.create', this.currentRole)) {
        Button('编辑')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600)
          .fontColor('#1A1A2E').backgroundColor('#F5F7FA').borderRadius(12)
          .onClick(() => {
            const p: Record<string, number> = { 'workOrderId': this.workOrderId };
            this.pageStack.pushPathByName('WorkOrderEdit', p);
          });
      }

      if (PermissionUtil.hasPermission('workorder.start', this.currentRole)) {
        Button('开始生产')
          .layoutWeight(2).height(46)
          .fontSize(15).fontWeight(600).fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.startWorkOrder(this.workOrderId);
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
