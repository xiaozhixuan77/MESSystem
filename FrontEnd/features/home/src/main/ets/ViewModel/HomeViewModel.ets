// 工作台数据模型（各角色共用）

export class TodoItem {
  type: string = '';       // 'exception' | 'dispatch'
  typeLabel: string = '';
  time: string = '';
  title: string = '';
  desc: string = '';
  meta: Record<string, string>[] = [];
}

export class LineStatusItem {
  name: string = '';
  status: string = '';     // 'running' | 'idle' | 'error'
  stats: Record<string, string>[] = [];
}

export class CurrentTask {
  status: string = '';
  code: string = '';
  title: string = '';
  progress: number = 0;
}

export class OperatorTaskItem {
  tag: string = '';        // 'pending' | 'report'
  tagLabel: string = '';
  tagColor: string = '';
  time: string = '';
  name: string = '';
  info: string = '';
  buttonLabel: string = '';
  buttonColor: string = '';
  buttonIcon: string = '';
}

@ObservedV2
export class HomeViewModel {
  @Trace isLoading: boolean = false;
  @Trace userName: string = '';
  @Trace userRole: string = '';
  @Trace userSubtitle: string = '';

  // Leader — 待办事项
  @Trace leaderTodos: TodoItem[] = [];
  @Trace leaderLines: LineStatusItem[] = [];

  // Operator — 当前任务 + 我的任务 + 产线动态
  @Trace operatorCurrentTask: CurrentTask | null = null;
  @Trace operatorTasks: OperatorTaskItem[] = [];
  @Trace operatorLineName: string = '';
  @Trace operatorLineStatus: string = '';
  @Trace operatorLineStats: Record<string, string>[] = [];

  // Inspector — KPI + 待抽检列表 + 产线状态
  @Trace inspectPendingCount: number = 0;
  @Trace inspectTodayDone: number = 0;
  @Trace inspectPassRate: string = '';
  @Trace inspectList: Record<string, string>[] = [];
  @Trace inspectLines: Record<string, string>[] = [];

  // Admin — KPI + 告警 + 今日概览
  @Trace adminKpis: Record<string, string>[] = [];
  @Trace adminAlerts: Record<string, string>[] = [];
  @Trace adminTodayStats: Record<string, string>[] = [];

  async loadHomeData(role: string): Promise<void> {
    this.isLoading = true;
    try {
      // 工作台数据加载（后续 Phase 实现）
    } finally {
      this.isLoading = false;
    }
  }
}
