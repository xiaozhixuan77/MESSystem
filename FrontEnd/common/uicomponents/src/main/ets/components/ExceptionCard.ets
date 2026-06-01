@ComponentV2
export struct ExceptionCard {
  @Param description: string = ''; @Param lineName: string = ''; @Param resolved: boolean = false;
  @Param createdAt: string = ''; @Event onCardClick: () => void = () => {};
  build() {
    Column() {
      Row() {
        Text(this.lineName).fontSize(12).fontColor('#999');
        Text(this.resolved ? '已处理' : '待处理').fontSize(12).fontColor(this.resolved ? '#52c41a' : '#f5222d');
      }.width('100%').justifyContent(FlexAlign.SpaceBetween);
      Text(this.description).fontSize(14).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 8 });
      Text(this.createdAt).fontSize(12).fontColor('#999').margin({ top: 4 });
    }
    .padding(12).backgroundColor('#fff').borderRadius(8).width('100%').onClick(() => this.onCardClick());
  }
}
