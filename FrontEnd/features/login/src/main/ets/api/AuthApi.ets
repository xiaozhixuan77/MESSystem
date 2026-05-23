import { httpClient } from '@ohos/common';
import { LoginResponseModel, LoginResponseUserModel } from '../Model/LoginResponseModel';

interface LoginRequest {
  username: string;
  password: string;
}

export class AuthApi {
  static async login(username: string, password: string): Promise<LoginResponseModel> {
    const params: LoginRequest = { username: username, password: password };
    return httpClient.post<LoginResponseModel>('/auth/login', params);
  }

  static async getCurrentUser(): Promise<LoginResponseUserModel> {
    return httpClient.get<LoginResponseUserModel>('/me');
  }

  static async logout(): Promise<void> {
    await httpClient.post<void>('/auth/logout');
  }
}
