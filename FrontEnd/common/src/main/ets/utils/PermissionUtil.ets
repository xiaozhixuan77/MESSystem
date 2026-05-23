export class PermissionUtil {
  static hasPermission(action: string, role: string): boolean {
    const permissions: Record<string, string[]> = {
      'workorder.view_team': ['admin', 'leader'],
      'workorder.view_own': ['admin', 'operator'],
      'workorder.view_inspection': ['admin', 'inspector'],
      'workorder.create': ['admin', 'leader'],
      'workorder.dispatch': ['admin', 'leader'],
      'workorder.start': ['admin', 'operator'],
      'workorder.pause': ['admin', 'operator', 'leader'],
      'workorder.resume': ['admin', 'operator', 'leader'],
      'workorder.report': ['admin', 'operator'],
      'workorder.confirm': ['admin', 'leader'],
      'workorder.scrap': ['admin', 'leader'],
      'line.view': ['admin', 'leader', 'operator', 'inspector'],
      'line.operate': ['admin', 'operator', 'leader'],
      'station.operate': ['admin', 'operator', 'leader'],
      'exception.report': ['admin', 'operator', 'leader'],
      'exception.view': ['admin', 'leader'],
      'exception.handle': ['admin', 'leader'],
      'inspection.create': ['admin', 'inspector'],
      'user.view': ['admin'],
      'user.create': ['admin'],
      'user.update': ['admin'],
      'user.delete': ['admin'],
      'dashboard.view': ['admin', 'leader', 'operator', 'inspector']
    };
    return (permissions[action] || []).includes(role);
  }
}
