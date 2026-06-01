export class StatusConstants {
  static readonly WORK_ORDER_STATUSES: string[] = ['待派工', '已派工', '生产中', '暂停中', '生产完成', '已报工', '完工', '报废'];
  static readonly LINE_STATUSES: Record<string, string> = { 'idle': '空闲', 'running': '生产中', 'paused': '暂停', 'error': '故障' };
  static readonly DEVICE_STATUSES: string[] = ['空闲', '运行中', '故障', '维护中'];
  static readonly INSPECTION_CONCLUSIONS: string[] = ['合格', '不合格', '让步接收'];
}
