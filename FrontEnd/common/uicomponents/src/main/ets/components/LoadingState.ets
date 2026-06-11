@ComponentV2
export struct LoadingState {
  @Param size: number = 36;
  @Param text: string = '加载中...';
  @Param fullScreen: boolean = true;

  build() {
    Column({ space: 8 }) {
      LoadingProgress()
        .width(this.size)
        .height(this.size)
        .color('#1565C0');
      if (this.text) {
        Text(this.text)
          .fontSize(13)
          .fontColor('#9A9AA8');
      }
    }
    .width('100%')
    .height(this.fullScreen ? '100%' : undefined)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(40)
  }
}
