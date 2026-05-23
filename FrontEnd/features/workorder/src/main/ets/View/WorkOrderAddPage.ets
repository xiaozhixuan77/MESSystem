@ComponentV2
export struct WorkOrderAddPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column() {
        Text('新增工单')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Text('工单新增表单（后续 Phase 实现）')
          .fontSize(14)
          .fontColor('#999');
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
