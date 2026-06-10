import { UserApi } from '@ohos/network';
import { UserModel } from '../Model/UserModel';
import { promptAction } from '@kit.ArkUI';

const ROLE_TABS = ['全部', '班组长', '操作员', '质检员', '管理员'];
const ROLE_LABEL_TO_API: Record<string, string> = {
  '班组长': 'leader', '操作员': 'operator', '质检员': 'inspector', '管理员': 'admin'
};
const ROLE_LABELS: Record<string, string> = {
  'leader': '班组长', 'operator': '操作员', 'inspector': '质检员', 'admin': '管理员'
};

interface CreateUserData {
  employeeNo: string;
  name: string;
  role: string;
  password: string;
}

interface UpdateUserData {
  name: string;
  role: string;
  status: string;
  password?: string;
}

@ObservedV2
export class UserViewModel {
  @Trace userList: UserModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace keyword: string = '';
  @Trace activeRoleTab: string = '全部';
  @Trace showFormDialog: boolean = false;
  @Trace formMode: string = 'add';
  @Trace editingUserId: number = 0;
  @Trace formEmployeeNo: string = '';
  @Trace formName: string = '';
  @Trace formRole: string = '操作员';
  @Trace formPassword: string = '';
  @Trace formStatus: string = '在岗';
  @Trace errorMessage: string = '';
  @Trace isSubmitting: boolean = false;
  roleTabs: string[] = ROLE_TABS;

  getRoleLabel(role: string): string {
    return ROLE_LABELS[role] || role;
  }

  getRoleApiValue(roleTab: string): string {
    return ROLE_LABEL_TO_API[roleTab] || '';
  }

  private loadingPromise: Promise<void> | null = null;

  async loadUsers(): Promise<void> {
    if (this.loadingPromise) {
      return this.loadingPromise;
    }
    this.isLoading = true;
    this.loadingPromise = (async (): Promise<void> => {
      try {
        const role = this.activeRoleTab === '全部' ? undefined : this.getRoleApiValue(this.activeRoleTab);
        const kw = this.keyword.trim() || undefined;
        const result = await UserApi.getUsers(role, kw) as Record<string, Object>[];
        this.userList = result.map((item: Record<string, Object>) => {
          const u = new UserModel();
          u.id = (item['id'] as number) ?? 0;
          u.employeeNo = (item['employeeNo'] as string) ?? '';
          u.name = (item['name'] as string) ?? '';
          u.role = (item['role'] as string) ?? '';
          u.workshopId = (item['workshopId'] as number) ?? null;
          u.teamId = (item['teamId'] as number) ?? null;
          u.status = (item['status'] as string) ?? '在岗';
          u.avatarUrl = (item['avatarUrl'] as string) ?? '';
          return u;
        });
      } finally {
        this.isLoading = false;
        this.loadingPromise = null;
      }
    })();
    return this.loadingPromise;
  }

  onRoleTabChange(tab: string): void {
    this.activeRoleTab = tab;
    this.loadUsers();
  }

  openAddDialog(): void {
    this.formMode = 'add';
    this.editingUserId = 0;
    this.formEmployeeNo = '';
    this.formName = '';
    this.formRole = '操作员';
    this.formPassword = '';
    this.formStatus = '在岗';
    this.errorMessage = '';
    this.showFormDialog = true;
  }

  openEditDialog(user: UserModel): void {
    this.formMode = 'edit';
    this.editingUserId = user.id;
    this.formEmployeeNo = user.employeeNo;
    this.formName = user.name;
    this.formRole = this.getRoleLabel(user.role);
    this.formPassword = '';
    this.formStatus = user.status;
    this.errorMessage = '';
    this.showFormDialog = true;
  }

  closeDialog(): void {
    this.showFormDialog = false;
  }

  private applyLocalUpdate(): void {
    const roleApi = this.getRoleApiValue(this.formRole);
    for (let i = 0; i < this.userList.length; i++) {
      if (this.userList[i].id === this.editingUserId) {
        this.userList[i].name = this.formName.trim();
        this.userList[i].role = roleApi;
        this.userList[i].status = this.formStatus;
        return;
      }
    }
  }

  async createUser(): Promise<boolean> {
    if (!this.formEmployeeNo.trim() || !this.formName.trim() || !this.formPassword.trim()) {
      this.errorMessage = '工号、姓名、密码不能为空';
      return false;
    }
    this.errorMessage = '';
    this.isSubmitting = true;
    try {
      const roleApi = this.getRoleApiValue(this.formRole);
      const createData: CreateUserData = {
        employeeNo: this.formEmployeeNo.trim(),
        name: this.formName.trim(),
        role: roleApi,
        password: this.formPassword.trim()
      };
      await UserApi.createUser(createData);
      this.showFormDialog = false;
      this.loadUsers();
      return true;
    } catch (e) {
      const err = e as Error;
      this.errorMessage = err.message || '创建失败';
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async updateUser(): Promise<boolean> {
    if (!this.formName.trim()) {
      this.errorMessage = '姓名不能为空';
      return false;
    }
    this.errorMessage = '';
    this.isSubmitting = true;
    try {
      const roleApi = this.getRoleApiValue(this.formRole);
      const data: UpdateUserData = {
        name: this.formName.trim(),
        role: roleApi,
        status: this.formStatus
      };
      if (this.formPassword.trim()) {
        data.password = this.formPassword.trim();
      }
      await UserApi.updateUser(this.editingUserId, data);
      this.applyLocalUpdate();
      this.showFormDialog = false;
      this.loadUsers();
      return true;
    } catch (e) {
      const err = e as Error;
      this.errorMessage = err.message || '更新失败';
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  async deleteUser(id: number, name: string): Promise<void> {
    try {
      await new Promise<void>((resolve, reject) => {
        promptAction.showDialog({
          title: '确认删除',
          message: `确定要删除人员「${name}」吗？删除后无法恢复。`,
          buttons: [
            { text: '取消', color: '#999999' },
            { text: '删除', color: '#F44336' }
          ]
        }).then((result: promptAction.ShowDialogSuccessResponse) => {
          if (result.index === 1) {
            resolve();
          } else {
            reject(new Error('cancelled'));
          }
        }).catch(() => {
          reject(new Error('cancelled'));
        });
      });
      await UserApi.deleteUser(id);
      this.loadUsers();
    } catch (e) {
      const err = e as Error;
      if (err.message !== 'cancelled') {
        try {
          promptAction.showToast({ message: '删除失败', duration: 2000 });
        } catch (_) {}
      }
    }
  }
}
