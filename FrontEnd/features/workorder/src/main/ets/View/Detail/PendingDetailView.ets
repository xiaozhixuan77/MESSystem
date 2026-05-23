import { StatusTag } from '@ohos/common';

@ComponentV2
export struct PendingDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
  }

  build() {
    Column() {
      Text('待派工详情')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 });

      Text(`工单 ID: ${this.workOrderId}`)
        .fontSize(14)
        .fontColor('#666');

      // 工单详情内容（后续 Phase 实现）
      Text('工单详细信息将在工单主链路阶段实现')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 16 });
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}
