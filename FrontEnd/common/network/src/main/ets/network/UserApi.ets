import { httpClient } from './HttpClient';
export class UserApi {
  static async getUsers(params?: Record<string, string | number>): Promise<Object[]> {
    let path = '/users';
    if (params) {
      const qs = Object.keys(params)
        .filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
        .map(k => `${k}=${encodeURIComponent(String(params[k]))}`)
        .join('&');
      if (qs) {
        path += '?' + qs;
      }
    }
    return httpClient.get<Object[]>(path);
  }
  static async getUserDetail(id: number): Promise<Object> { return httpClient.get(`/users/${id}`); }
  static async createUser(data: object): Promise<Object> { return httpClient.post('/users', data); }
  static async updateUser(id: number, data: object): Promise<Object> { return httpClient.put(`/users/${id}`, data); }
}
