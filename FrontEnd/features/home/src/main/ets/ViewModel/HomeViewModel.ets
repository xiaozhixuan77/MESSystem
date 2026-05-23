@ObservedV2
export class HomeViewModel {
  @Trace pendingCount: number = 0;
  @Trace exceptionCount: number = 0;
  @Trace activeWorkOrderCount: number = 0;
  @Trace isLoading: boolean = false;

  async loadHomeData(role: string): Promise<void> {
    this.isLoading = true;
    try {
      // 工作台数据加载（后续 Phase 实现）
    } finally {
      this.isLoading = false;
    }
  }
}
