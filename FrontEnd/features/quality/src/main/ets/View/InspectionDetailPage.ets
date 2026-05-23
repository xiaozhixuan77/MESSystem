@ComponentV2
export struct InspectionDetailPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local inspectionId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.inspectionId = (param?.['inspectionId'] as number) ?? 0;
  }

  build() {
    NavDestination() {
      Column() {
        Text('抽检详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Text('抽检录入表单（后续 Phase 实现）')
          .fontSize(14)
          .fontColor('#999');
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
