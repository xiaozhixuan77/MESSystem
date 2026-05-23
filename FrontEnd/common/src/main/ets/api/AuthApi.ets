import { httpClient } from './HttpClient';

export class AuthApi {
  static async login(employeeNo: string, password: string): Promise<Object> {
    return httpClient.post('/auth/login', { employeeNo, password });
  }

  static async getCurrentUser(): Promise<Object> {
    return httpClient.get('/me');
  }

  static async logout(): Promise<void> {
    await httpClient.post('/auth/logout');
  }
}
