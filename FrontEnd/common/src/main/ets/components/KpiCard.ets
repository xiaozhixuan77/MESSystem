@ComponentV2
export struct KpiCard {
  @Param title: string = '';
  @Param value: string = '';
  @Param color: ResourceColor = '#1890ff';
  @Event onCardClick: () => void = () => {};

  build() {
    Column() {
      Text(this.title)
        .fontSize(12)
        .fontColor('#999');
      Text(this.value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
        .margin({ top: 8 });
    }
    .padding(16)
    .backgroundColor('#fff')
    .borderRadius(8)
    .width('100%')
    .onClick(() => this.onCardClick());
  }
}
