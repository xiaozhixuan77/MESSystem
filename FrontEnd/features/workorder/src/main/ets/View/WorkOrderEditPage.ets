@ComponentV2
export struct WorkOrderEditPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  build() {
    NavDestination() {
      Column() {
        Text('编辑工单')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Text('工单编辑表单（后续 Phase 实现）')
          .fontSize(14)
          .fontColor('#999');
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
