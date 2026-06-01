import { httpClient } from './HttpClient';

export class AuthApi {
  static async login(username: string, password: string): Promise<Object> {
    return httpClient.post('/auth/login', { username, password });
  }
  static async getCurrentUser(): Promise<Object> {
    return httpClient.get('/me');
  }
  static async logout(): Promise<void> {
    await httpClient.post<void>('/auth/logout');
  }
}
