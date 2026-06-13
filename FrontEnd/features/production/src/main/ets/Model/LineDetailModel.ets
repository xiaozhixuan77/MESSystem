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
    const last = this.stations[this.stations.length - 1];
    return last.finishedCount + last.ngCount;
  }

  get yieldRate(): string {
    const last = this.stations.length > 0 ? this.stations[this.stations.length - 1] : null;
    if (!last) return '0%';
    const total = last.finishedCount + last.ngCount;
    if (total === 0) return '0%';
    return (last.finishedCount / total * 100).toFixed(1) + '%';
  }

  get runtime(): string {
    if (this.stations.length === 0) return '0m';
    const minutes = this.stations[0].processedCount;
    if (minutes <= 0) return '0m';
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    if (h > 0) return `${h}h${m}m`;
    return `${m}m`;
  }

  get ngCount(): number {
    if (this.stations.length === 0) return 0;
    return this.stations[this.stations.length - 1].ngCount;
  }
}
