import { ExceptionViewModel } from '../ViewModel/ExceptionViewModel';
import { LineApi } from '@ohos/network';
import { promptAction } from '@kit.ArkUI';

@ComponentV2
export struct ExceptionDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local vm: ExceptionViewModel = new ExceptionViewModel();
  @Local exceptionId: number = 0;
  @Local showHandleConfirm: boolean = false;
  @Local pendingAction: string = '';

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    console.info('[test:ExceptionDetail] 进入异常详情页', JSON.stringify({ param: param }));
    const id = param?.['exceptionId'] as number;
    if (id && id > 0) {
      this.exceptionId = id;
      console.info('[test:ExceptionDetail] 加载异常', JSON.stringify({ exceptionId: id }));
      this.vm.loadExceptionDetail(id);
    }
  }

  get canHandle(): boolean {
    return this.vm.currentException.resolved === 0;
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor('#9A9AA8').layoutWeight(1);
      Text(value || '—').fontSize(13).fontWeight(500).fontColor('#1A1A2E');
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#F5F7FA' });
  }

  @Builder
  HandleConfirmDialog() {
    Column() {
      Column() {
        Text('确认操作')
          .fontSize(16).fontWeight(700).fontColor('#1A1A2E')
          .margin({ bottom: 8 });
        Text(this.pendingAction === '恢复' ?
          '确认恢复产线运行并关闭此异常？' : '确认仅关闭此异常记录（产线保持暂停）？')
          .fontSize(13).fontColor('#5A5A6E')
          .margin({ bottom: 16 });
        Row({ space: 12 }) {
          Button('取消').fontSize(14)
            .backgroundColor('#F5F7FA').fontColor('#5A5A6E')
            .borderRadius(8).layoutWeight(1)
            .onClick(() => { this.showHandleConfirm = false; });
          Button('确认').fontSize(14)
            .backgroundColor(this.pendingAction === '恢复' ? '#4CAF50' : '#FF9800')
            .fontColor(Color.White).borderRadius(8).layoutWeight(1)
            .onClick(() => {
              this.showHandleConfirm = false;
              this.doHandle();
            });
        }
        .width('100%');
      }
      .width('80%').padding(20).backgroundColor(Color.White).borderRadius(16)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 8 });
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.45)')
    .onClick(() => { this.showHandleConfirm = false; });
  }

  private async doHandle(): Promise<void> {
    console.info('[test:ExceptionDetail] 开始处理异常', JSON.stringify({
      exceptionId: this.exceptionId,
      action: this.pendingAction
    }));
    const ok = await this.vm.handleException(this.exceptionId, this.pendingAction);
    console.info('[test:ExceptionDetail] 处理异常结果', JSON.stringify({ ok: ok }));
    if (ok) {
      promptAction.showToast({ message: '处理成功' });
      if (this.pendingAction === '恢复') {
        const lineId = this.vm.currentException.lineId;
        const woId = this.vm.currentException.workOrderId;
        console.info('[test:ExceptionDetail] 启动仿真器', JSON.stringify({ lineId: lineId, workOrderId: woId }));
        try {
          await LineApi.startLine(lineId, woId);
          console.info('[test:ExceptionDetail] 仿真器启动成功');
        } catch (e) {
          console.error('[test:ExceptionDetail] 仿真器启动失败', JSON.stringify({ error: (e as Error).message }));
        }
      }
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Row() {
            Image($r('app.media.icon_arrow_left_gray'))
              .width(20).height(20);
          }
          .width(36).height(36)
          .backgroundColor('rgba(0,0,0,0.08)')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.pageStack.pop(); });

          Text('异常详情')
            .fontSize(18).fontWeight(700).fontColor('#1A1A2E')
            .margin({ left: 12 });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        if (this.vm.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40);
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else if (this.vm.errorMessage) {
          Column({ space: 12 }) {
            Text('加载失败').fontSize(16).fontColor('#5A5A6E');
            Text(this.vm.errorMessage).fontSize(13).fontColor('#9A9AA8');
            Button('重试')
              .fontSize(14).fontColor(Color.White)
              .backgroundColor('#1565C0').borderRadius(8)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .onClick(() => this.vm.loadExceptionDetail(this.exceptionId));
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else {
          Scroll() {
            Column() {
              // 状态横幅
              Column() {
                Row() {
                  Circle()
                    .width(12).height(12)
                    .fill(this.vm.currentException.resolved === 1 ? '#4CAF50' : '#F44336');
                  Text(this.vm.currentException.resolved === 1 ? '已处理' : '未处理')
                    .fontSize(18).fontWeight(700)
                    .fontColor(this.vm.currentException.resolved === 1 ? '#4CAF50' : '#F44336')
                    .margin({ left: 8 });
                }
                .margin({ bottom: 6 });
                Text(this.vm.currentException.resolved === 1 ?
                  `已由 ${this.vm.currentException.handlerName || '—'} 执行「${this.vm.currentException.handleAction || ''}」操作` :
                  '待班组长或管理员处理')
                  .fontSize(12)
                  .fontColor('#5A5A6E');
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.vm.currentException.resolved === 1 ? '#E8F5E9' : '#FFEBEE')
              .borderRadius(16)
              .margin({ bottom: 16 });

              // 基本信息卡片
              Column() {
                Text('基本信息')
                  .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                  .margin({ bottom: 8 });

                this.InfoRow('工单编号', this.vm.currentException.workOrderCode ||
                  `#${this.vm.currentException.workOrderId || ''}`);
                this.InfoRow('产线', this.vm.currentException.lineName || '—');
                if (this.vm.currentException.stationId) {
                  this.InfoRow('工位', this.vm.currentException.stationName || '—');
                }
                this.InfoRow('上报人', this.vm.currentException.reporterName || '—');
                this.InfoRow('上报时间', this.vm.currentException.reportTime || '—');
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .width('100%')
              .margin({ bottom: 12 });

              // 异常描述卡片
              Column() {
                Text('异常描述')
                  .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                  .margin({ bottom: 8 });
                Text(this.vm.currentException.description || '—')
                  .fontSize(14).fontColor('#1A1A2E').lineHeight(22);
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .width('100%')
              .margin({ bottom: 12 });

              // 处理记录（仅已处理时显示）
              if (this.vm.currentException.resolved === 1) {
                Column() {
                  Text('处理记录')
                    .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                    .margin({ bottom: 8 });
                  this.InfoRow('处理人', this.vm.currentException.handlerName || '—');
                  this.InfoRow('处理动作', this.vm.currentException.handleAction || '—');
                  this.InfoRow('处理时间', this.vm.currentException.handleTime || '—');
                }
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .width('100%')
                .margin({ bottom: 12 });
              }
            }
            .padding(16)
            .width('100%');
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None);

          // 底部操作栏（仅未处理且有权限时显示）
          if (this.canHandle) {
            Row({ space: 12 }) {
              Button() {
                Text('关闭')
                  .fontSize(15).fontWeight(600).fontColor('#FF9800');
              }
              .layoutWeight(1).height(44)
              .backgroundColor('#FFF3E0')
              .borderRadius(12)
              .enabled(!this.vm.handleLoading)
              .onClick(() => {
                this.pendingAction = '关闭';
                this.showHandleConfirm = true;
              });

              Button() {
                Text('恢复')
                  .fontSize(15).fontWeight(600).fontColor(Color.White);
              }
              .layoutWeight(1).height(44)
              .backgroundColor('#4CAF50')
              .borderRadius(12)
              .enabled(!this.vm.handleLoading)
              .onClick(() => {
                this.pendingAction = '恢复';
                this.showHandleConfirm = true;
              });
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .border({ width: { top: 1 }, color: '#E8EBF0' });
          }
        }
      }
      .width('100%').height('100%');

      if (this.showHandleConfirm) {
        this.HandleConfirmDialog();
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA');
  }
}
