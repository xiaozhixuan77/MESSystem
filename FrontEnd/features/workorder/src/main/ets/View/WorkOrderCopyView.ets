@ComponentV2
export struct WorkOrderCopyView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local sourceWorkOrderId: number = 0;

  build() {
    Column() {
      Text('复制工单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 });

      Text('工单复制表单（后续 Phase 实现）')
        .fontSize(14)
        .fontColor('#999');
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}
