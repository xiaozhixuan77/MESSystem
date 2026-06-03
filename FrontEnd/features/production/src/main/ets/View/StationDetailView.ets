import { StationModel } from '../Model/StationModel';

@ComponentV2
export struct StationDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local stationId: number = 0;
  @Local station: StationModel = new StationModel();

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.stationId = (param?.['stationId'] as number) ?? 0;
    // 加载工作站详情（后续 Phase 实现）
  }

  build() {
    Column() {
      Text(this.station.name || '工作站详情')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 });

      Text(`设备状态: ${this.station.deviceStatus}`)
        .fontSize(14)
        .fontColor('#666');
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}
