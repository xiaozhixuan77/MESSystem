import { PermissionUtil } from '@ohos/utils';
import { WorkOrderViewModel } from '../../ViewModel/WorkOrderViewModel';

@ComponentV2
export struct PausedDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local workOrderId: number = 0;
  private hasAppeared: boolean = false;

  private get hasBottomActions(): boolean {
    return PermissionUtil.hasPermission('workorder.scrap', this.currentRole) ||
      PermissionUtil.hasPermission('workorder.resume', this.currentRole);
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
        if (this.viewModel.errorMessage) {
          Text(this.viewModel.errorMessage)
            .fontSize(13).fontColor('#B71C1C')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .width('100%').backgroundColor('#FFEBEE');
        }
        this.StatusCard();
        Scroll() {
          Column() {
            if (this.viewModel.currentWorkOrder?.exceptionNote) {
              this.ExceptionSection();
            }
            this.ProgressSection();
            this.InfoSection();
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
    .width('100%').height('100%')
    .onAppear(() => {
      if (this.hasAppeared) {
        this.viewModel.loadDetail(this.workOrderId);
      }
      this.hasAppeared = true;
    });
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
        Text('暂停中')
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

      if (this.viewModel.currentWorkOrder?.exceptionNote) {
        Column() {
          Text('暂停原因')
            .fontSize(11).fontColor('rgba(255,255,255,0.9)')
            .margin({ bottom: 6 });
          Text(this.viewModel.currentWorkOrder?.exceptionNote || '')
            .fontSize(14).fontWeight(600).fontColor(Color.White);
          Text('暂停时间：' + (this.viewModel.currentWorkOrder?.pauseTime || '—'))
            .fontSize(12).fontColor('rgba(255,255,255,0.8)')
            .margin({ top: 4 });
        }
        .width('100%').padding(14)
        .backgroundColor('rgba(255,255,255,0.15)').borderRadius(12)
        .margin({ top: 14 });
      }
    }
    .padding(20).backgroundColor('#E65100').borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 16 }).width('calc(100% - 32px)');
  }

  @Builder ExceptionSection() {
    Column() {
      this.SectionTitle('异常信息');
      Row() {
        Column() {
          Text('!')
            .fontSize(18).fontWeight(700).fontColor('#F44336');
        }
        .width(36).height(36).backgroundColor('#FFEBEE').borderRadius(18)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);

        Column() {
          Text('生产异常')
            .fontSize(14).fontWeight(600).fontColor('#F44336').margin({ bottom: 4 });
          Text(this.viewModel.currentWorkOrder?.exceptionNote || '')
            .fontSize(12).fontColor('#5A5A6E')
            .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1);
      }
      .width('100%').padding(14)
      .backgroundColor('#FFEBEE').borderRadius(12)
      .border({ width: 1, color: '#FFCDD2' });
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder ProgressSection() {
    Column() {
      this.SectionTitle('当前进度');
      Row({ space: 10 }) {
        this.ProgressItem('计划数量', `${this.viewModel.currentWorkOrder?.planQty || 0}`, '#1A1A2E');
        this.ProgressItem('已完成', `${this.viewModel.currentWorkOrder?.reportedQtyGood || 0}`, '#4CAF50');
        this.ProgressItem('剩余',
          `${(this.viewModel.currentWorkOrder?.planQty || 0) - (this.viewModel.currentWorkOrder?.reportedQtyGood || 0)}`,
          '#F44336');
      }
      .width('100%');
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%').margin({ bottom: 12 });
  }

  @Builder ProgressItem(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(value).fontSize(20).fontWeight(700).fontColor(color);
      Text(label).fontSize(10).fontColor('#5A5A6E').margin({ bottom: 4 });
    }
    .layoutWeight(1).padding({ top: 14, bottom: 14, left: 8, right: 8 })
    .backgroundColor('#F5F7FA').borderRadius(12)
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

  @Builder TimelineSection() {
    Column() {
      this.SectionTitle('状态流转记录');
      Column() {
        this.LeftTimelineItem('工单创建', this.viewModel.currentWorkOrder?.createdAt || '—', true);
        this.LeftTimelineItem('开始生产', this.viewModel.currentWorkOrder?.actualStartTime || '—', true);
        this.LeftTimelineItem('工单暂停', this.viewModel.currentWorkOrder?.pauseTime || '—', true);
        this.LeftTimelineItem('等待恢复', '等待故障修复后恢复生产', false);
      }
      .width('100%')
      .border({ width: { left: 2 }, color: '#E8EBF0' })
      .padding({ left: 12 });
    }
    .padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .width('100%');
  }

  @Builder LeftTimelineItem(title: string, time: string, done: boolean) {
    Row() {
      Circle()
        .width(10).height(10)
        .fill(done ? '#4CAF50' : '#FF9800')
        .border({ width: 2, color: Color.White })
        .margin({ left: -18 });
      Column() {
        Text(title).fontSize(13).fontColor(done ? '#1A1A2E' : '#9A9AA8').margin({ bottom: 2 });
        Text(time).fontSize(11).fontColor('#9A9AA8');
      }
      .alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1);
    }
    .width('100%').padding({ top: 10, bottom: 10 }).alignItems(VerticalAlign.Top);
  }

  @Builder BottomActions() {
    Row({ space: 12 }) {
      if (PermissionUtil.hasPermission('workorder.scrap', this.currentRole)) {
        Button('报废')
          .layoutWeight(1).height(46)
          .fontSize(15).fontWeight(600)
          .fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#EF9A9A' : '#F44336').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.scrapWorkOrder(this.workOrderId);
            if (ok) { this.pageStack.pop(); }
          });
      }

      if (PermissionUtil.hasPermission('workorder.resume', this.currentRole)) {
        Button('恢复生产')
          .layoutWeight(2).height(46)
          .fontSize(15).fontWeight(600).fontColor(Color.White)
          .backgroundColor(this.viewModel.isSubmitting ? '#81C784' : '#4CAF50').borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            const ok = await this.viewModel.resumeWorkOrder(this.workOrderId);
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
