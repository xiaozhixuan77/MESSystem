import { StationCard } from '@ohos/uicomponents';
import { LineModel } from '../Model/LineModel';
import { StationModel } from '../Model/StationModel';

@ComponentV2
export struct LineDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Param lineId: number = 0;
  @Local line: LineModel = new LineModel();
  @Local stations: StationModel[] = [];

  aboutToAppear(): void {
    // 加载产线详情（后续 Phase 实现）
  }

  build() {
    Column() {
      Text(this.line.name || '产线详情')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 });

      Text(`状态: ${this.line.status}`)
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 16 });

      Grid() {
        ForEach(this.stations, (station: StationModel) => {
          GridItem() {
            StationCard({
              opCode: station.opCode,
              name: station.name,
              deviceStatus: station.deviceStatus,
              rawCount: station.rawCount,
              finishedCount: station.finishedCount,
              ngCount: station.ngCount
            });
          }
        });
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12).columnsGap(12);
    }
    .padding(16)
    .width('100%')
    .height('100%');
  }
}
