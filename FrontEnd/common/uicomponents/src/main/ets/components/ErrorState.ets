@ComponentV2
export struct ErrorState {
  @Param message: string = '加载失败';
  @Param showRetry: boolean = false;
  @Event onRetry: () => void = () => {};

  build() {
    Column({ space: 8 }) {
      Text('加载失败')
        .fontSize(16)
        .fontColor('#F44336')
        .fontWeight(FontWeight.Medium);
      if (this.message) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#9A9AA8')
          .maxLines(3)
          .textAlign(TextAlign.Center);
      }
      if (this.showRetry) {
        Button('重试')
          .fontSize(14)
          .margin({ top: 12 })
          .backgroundColor('#1565C0')
          .fontColor(Color.White)
          .borderRadius(8)
          .onClick(() => { this.onRetry(); });
      }
    }
    .width('100%')
    .padding(40)
    .alignItems(HorizontalAlign.Center)
  }
}
