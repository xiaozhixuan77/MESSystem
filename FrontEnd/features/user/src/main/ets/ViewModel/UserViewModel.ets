import { UserApi } from '@ohos/network';
import { UserModel } from '../Model/UserModel';

@ObservedV2
export class UserViewModel {
  @Trace userList: UserModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace roleFilter: string = '';

  async loadUsers(role?: string): Promise<void> {
    this.isLoading = true;
    try {
      const params: Record<string, string> = {};
      if (role) {
        params['role'] = role;
      }
      this.userList = await UserApi.getUsers(params) as UserModel[];
    } finally {
      this.isLoading = false;
    }
  }
}
