import { httpClient } from './HttpClient';
import { LoginResponseModel, LoginResponseUserModel } from '../models/LoginResponseModel';

export class AuthApi {
  static async login(username: string, password: string): Promise<LoginResponseModel> {
    return httpClient.post<LoginResponseModel>('/auth/login', { username, password });
  }

  static async getCurrentUser(): Promise<LoginResponseUserModel> {
    return httpClient.get<LoginResponseUserModel>('/me');
  }

  static async logout(): Promise<void> {
    await httpClient.post('/auth/logout');
  }
}
