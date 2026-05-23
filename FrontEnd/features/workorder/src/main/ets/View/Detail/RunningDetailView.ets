@ComponentV2
export struct RunningDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local workOrderId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.workOrderId = (param?.['workOrderId'] as number) ?? 0;
  }

  build() {
    NavDestination() {
      Column() {
        Text('生产中详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Text(`工单 ID: ${this.workOrderId}`)
          .fontSize(14)
          .fontColor('#666');
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
