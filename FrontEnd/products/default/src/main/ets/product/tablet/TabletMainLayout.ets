@ComponentV2
export struct TabletMainLayout {
  @Consumer('currentRole') currentRole: string = '';

  build() {
    Row() {
      Column() {
        Text('导航栏')
          .fontSize(14);
      }
      .width(200)
      .height('100%')
      .backgroundColor('#f5f5f5');

      Column() {
        Text('内容区（平板布局，后续 Phase 实现）')
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
