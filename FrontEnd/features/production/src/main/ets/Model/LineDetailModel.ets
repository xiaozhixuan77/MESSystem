import { StationModel } from './StationModel';

@ObservedV2
export class WorkOrderSummary {
  @Trace id: number = 0;
  @Trace code: string = '';
  @Trace productName: string = '';
  @Trace processName: string = '';
  @Trace planQty: number = 0;
  @Trace status: string = '';
}

@ObservedV2
export class LineDetailModel {
  @Trace id: number = 0;
  @Trace name: string = '';
  @Trace status: string = '空闲';
  @Trace workshopName: string = '';
  @Trace currentWorkorderId: number | null = null;
  @Trace stations: StationModel[] = [];
  @Trace activeWorkOrder: WorkOrderSummary | null = null;

  get todayOutput(): number {
    if (this.stations.length === 0) return 0;
    return this.stations[this.stations.length - 1].finishedCount;
  }

  get yieldRate(): string {
    const finished = this.stations.reduce((sum, s) => sum + s.finishedCount, 0);
    const ng = this.stations.reduce((sum, s) => sum + s.ngCount, 0);
    const total = finished + ng;
    if (total === 0) {
      return '0%';
    }
    const rate = (finished / total) * 100;
    return rate.toFixed(1) + '%';
  }

  get runtime(): string {
    if (this.status === '生产中') {
      return '运行中';
    }
    return '--';
  }

  get exceptionCount(): number {
    return this.stations.filter(s => s.deviceStatus === '异常' || s.deviceStatus === '故障').length;
  }
}
