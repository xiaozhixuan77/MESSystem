import { LineApi } from '@ohos/common';
import { LineModel } from '../Model/LineModel';
import { StationModel } from '../Model/StationModel';

@ObservedV2
export class ProductionViewModel {
  @Trace lines: LineModel[] = [];
  @Trace currentLine: LineModel = new LineModel();
  @Trace stations: StationModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';

  async loadLines(): Promise<void> {
    this.isLoading = true;
    try {
      this.lines = await LineApi.getLines() as LineModel[];
    } finally {
      this.isLoading = false;
    }
  }

  async loadLineDetail(id: number): Promise<void> {
    this.isLoading = true;
    try {
      const data = await LineApi.getLineDetail(id) as Record<string, Object>;
      this.currentLine = data['line'] as LineModel;
      this.stations = data['stations'] as StationModel[];
    } finally {
      this.isLoading = false;
    }
  }

  async startLine(id: number): Promise<void> {
    await LineApi.startLine(id);
  }

  async stopLine(id: number): Promise<void> {
    await LineApi.stopLine(id);
  }

  async resetLine(id: number): Promise<void> {
    await LineApi.resetLine(id);
  }
}
