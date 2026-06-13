export class PermissionUtil {
  static hasPermission(action: string, role: string): boolean {
    // admin 拥有通配符 *，直接放行
    if (role === 'admin') {
      return true;
    }
    const permissions: Record<string, string[]> = {
      'workorder.view_team': ['admin', 'leader'],
      'workorder.view_own': ['admin', 'operator'],
      'workorder.view_inspection': ['admin', 'inspector'],
      'workorder.create': ['admin', 'leader'],
      'workorder.dispatch': ['admin', 'leader'],
      'workorder.start': ['admin', 'operator', 'leader'],
      'workorder.complete': ['admin', 'operator', 'leader'],
      'workorder.pause': ['admin', 'operator', 'leader'],
      'workorder.resume': ['admin', 'leader'],
      'workorder.report': ['admin', 'operator'],
      'workorder.confirm': ['admin', 'leader'],
      'workorder.scrap': ['admin', 'leader'],
      'workorder.delete': ['admin'],
      'line.view': ['admin', 'leader', 'operator', 'inspector'],
      'line.operate': ['admin', 'operator', 'leader'],
      'station.view': ['admin', 'leader', 'operator', 'inspector'],
      'station.operate': ['admin', 'operator', 'leader'],
      'exception.report': ['admin', 'operator', 'leader'],
      'exception.view': ['admin', 'leader', 'inspector'],
      'exception.handle': ['admin', 'leader'],
      'inspection.view': ['admin', 'inspector'],
      'inspection.create': ['admin', 'inspector'],
      'inspection.submit': ['admin', 'inspector'],
      'master.view': ['admin', 'leader', 'operator', 'inspector'],
      'user.view': ['admin'],
      'user.create': ['admin'],
      'user.update': ['admin'],
      'user.delete': ['admin'],
      'dashboard.view': ['admin', 'leader', 'operator', 'inspector']
    };
    return (permissions[action] || []).includes(role);
  }
}
