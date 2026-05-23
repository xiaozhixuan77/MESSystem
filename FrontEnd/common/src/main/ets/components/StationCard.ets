@ComponentV2
export struct StationCard {
  @Param opCode: string = '';
  @Param name: string = '';
  @Param deviceStatus: string = '空闲';
  @Param rawCount: number = 0;
  @Param finishedCount: number = 0;
  @Param ngCount: number = 0;
  @Param isActive: boolean = false;
  @Event onCardClick: () => void = () => {};

  private getBorderColor(): ResourceColor {
    if (this.deviceStatus === '运行中') return '#52c41a';
    if (this.deviceStatus === '故障') return '#f5222d';
    return '#999';
  }

  build() {
    Column() {
      Text(this.opCode)
        .fontSize(14)
        .fontWeight(FontWeight.Bold);
      Text(this.name)
        .fontSize(12)
        .fontColor('#666');

      Row() {
        Circle({ width: 8, height: 8 })
          .fill(this.getBorderColor());
        Text(this.deviceStatus)
          .fontSize(12);
      };

      Row() {
        Text(`raw: ${this.rawCount}  `)
          .fontSize(12);
        Text(`good: ${this.finishedCount}  `)
          .fontSize(12);
        Text(`ng: ${this.ngCount}`)
          .fontSize(12);
      };
    }
    .padding(12)
    .backgroundColor(this.isActive ? '#e6f7ff' : '#fff')
    .borderRadius(8)
    .border({ width: { left: 3 }, color: this.getBorderColor() })
    .width('100%')
    .onClick(() => this.onCardClick());
  }
}
