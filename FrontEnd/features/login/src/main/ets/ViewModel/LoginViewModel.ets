import { AuthApi } from '@ohos/network';
import { LoginResponseModel } from '../Model/LoginResponseModel';

@ObservedV2
export class LoginViewModel {
  @Trace username: string = '';
  @Trace password: string = '';
  @Trace rememberMe: boolean = false;
  @Trace isLoading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace loginResult: LoginResponseModel | null = null;

  isFormValid(): boolean {
    return this.username.trim().length > 0 && this.password.length > 0;
  }

  async login(): Promise<boolean> {
    if (!this.isFormValid()) {
      this.errorMessage = '请输入工号和密码';
      return false;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.loginResult = null;

    try {
      const result = await AuthApi.login<LoginResponseModel>(this.username.trim(), this.password);
      this.loginResult = result;
      return true;
    } catch (e) {
      const err = e as Error;
      const errMsg = err.message || '';
      if (err instanceof SyntaxError) {
        this.errorMessage = '服务器响应异常，请检查网络';
      } else if (errMsg.includes('用户名或密码错误')) {
        this.errorMessage = '用户名或密码错误';
      } else if (errMsg.includes('Network') || errMsg.includes('connect') || errMsg.includes('timeout')) {
        this.errorMessage = '网络连接失败，请检查网络设置';
      } else {
        this.errorMessage = errMsg || '登录失败，请重试';
      }
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  reset(): void {
    this.username = '';
    this.password = '';
    this.errorMessage = '';
    this.isLoading = false;
    this.loginResult = null;
  }
}