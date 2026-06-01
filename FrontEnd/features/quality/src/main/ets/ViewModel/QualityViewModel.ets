import { QualityApi } from '@ohos/network';
import { InspectionModel } from '../Model/InspectionModel';

@ObservedV2
export class QualityViewModel {
  @Trace inspectionList: InspectionModel[] = [];
  @Trace dashboardData: Record<string, Object> = {};
  @Trace isLoading: boolean = false;

  async loadInspections(filters?: object): Promise<void> {
    this.isLoading = true;
    try {
      this.inspectionList = await QualityApi.getInspections(filters) as InspectionModel[];
    } finally {
      this.isLoading = false;
    }
  }

  async loadDashboard(params?: object): Promise<void> {
    this.isLoading = true;
    try {
      this.dashboardData = await QualityApi.getDashboard(params) as Record<string, Object>;
    } finally {
      this.isLoading = false;
    }
  }
}
