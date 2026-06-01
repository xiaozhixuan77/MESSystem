import { httpClient } from './HttpClient';

interface LoginParams {
  username: string;
  password: string;
}

export class AuthApi {
  static async login<T>(username: string, password: string): Promise<T> {
    const params: LoginParams = { username, password };
    return httpClient.post<T>('/auth/login', params);
  }
  static async getCurrentUser<T>(): Promise<T> {
    return httpClient.get<T>('/me');
  }
  static async logout(): Promise<void> {
    await httpClient.post<void>('/auth/logout');
  }
}
