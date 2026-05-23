export class RoleConstants {
  static readonly ADMIN: string = 'admin';
  static readonly LEADER: string = 'leader';
  static readonly OPERATOR: string = 'operator';
  static readonly INSPECTOR: string = 'inspector';

  static readonly ROLES: string[] = ['admin', 'leader', 'operator', 'inspector'];

  static readonly ROLE_LABELS: Record<string, string> = {
    'admin': '管理员',
    'leader': '班组长',
    'operator': '操作员',
    'inspector': '质检员'
  };
}
