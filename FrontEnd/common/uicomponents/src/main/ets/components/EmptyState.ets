@ComponentV2
export struct EmptyState {
  @Param title: string = '暂无数据';
  @Param description: string = '';
  @Param actionLabel: string = '';
  @Event onAction: (() => void) | undefined = undefined;

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(16)
        .fontColor('#5A5A6E')
        .fontWeight(FontWeight.Medium);
      if (this.description) {
        Text(this.description)
          .fontSize(13)
          .fontColor('#9A9AA8')
          .maxLines(2)
          .textAlign(TextAlign.Center);
      }
      if (this.actionLabel && this.onAction) {
        Button(this.actionLabel)
          .fontSize(14)
          .margin({ top: 12 })
          .backgroundColor('#1565C0')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            if (this.onAction) {
              this.onAction();
            }
          });
      }
    }
    .width('100%')
    .padding(40)
    .alignItems(HorizontalAlign.Center)
  }
}
