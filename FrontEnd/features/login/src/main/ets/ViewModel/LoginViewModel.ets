import { AuthApi } from '@ohos/common';

@ObservedV2
export class LoginViewModel {
  @Trace employeeNo: string = '';
  @Trace password: string = '';
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';

  async login(): Promise<boolean> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const result = await AuthApi.login(this.employeeNo, this.password);
      return true;
    } catch (e) {
      this.errorMessage = (e as Error).message;
      return false;
    } finally {
      this.isLoading = false;
    }
  }
}
