import { UserApi } from '@ohos/common';

@ObservedV2
export class UserViewModel {
  @Trace userList: UserModel[] = [];
  @Trace isLoading: boolean = false;
  @Trace roleFilter: string = '';

  async loadUsers(role?: string): Promise<void> {
    this.isLoading = true;
    try {
      this.userList = await UserApi.getUsers({ role }) as UserModel[];
    } finally {
      this.isLoading = false;
    }
  }
}
