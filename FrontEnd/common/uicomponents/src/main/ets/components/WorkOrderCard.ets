import { StatusTag } from './StatusTag';
@ComponentV2
export struct WorkOrderCard {
  @Param workOrderCode: string = ''; @Param status: string = ''; @Param productName: string = '';
  @Param planQty: number = 0; @Param role: string = '';
  @Event onCardClick: () => void = () => {}; @Event onDispatch: () => void = () => {};
  build() {
    Column() {
      Row() { Text(this.workOrderCode).fontSize(16).fontWeight(FontWeight.Bold); StatusTag({ status: this.status }); }
      .width('100%').justifyContent(FlexAlign.SpaceBetween);
      Text(`产品：${this.productName} | 数量：${this.planQty}`).fontSize(13).fontColor('#666');
      if (this.role === 'leader' && this.status === '待派工') { Button('派工').onClick(() => this.onDispatch()); }
    }
    .padding(16).backgroundColor('#fff').borderRadius(8).width('100%').onClick(() => this.onCardClick());
  }
}
