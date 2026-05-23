@ComponentV2
export struct FoldableMainLayout {
  @Consumer('currentRole') currentRole: string = '';

  build() {
    Row() {
      Column() {
        Text('导航栏')
          .fontSize(14);
      }
      .width(260)
      .height('100%')
      .backgroundColor('#f5f5f5');

      Column() {
        Text('内容区（折叠屏布局，后续 Phase 实现）')
          .fontSize(14)
          .fontColor('#999');
      }
      .layoutWeight(1)
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
