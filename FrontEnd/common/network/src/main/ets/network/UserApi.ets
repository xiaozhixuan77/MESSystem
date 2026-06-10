import { httpClient } from './HttpClient';
export class UserApi {
  static async getUsers(role?: string, keyword?: string, status?: string): Promise<Object[]> {
    const params: Record<string, string> = {};
    if (role) { params['role'] = role; }
    if (keyword) { params['keyword'] = keyword; }
    if (status) { params['status'] = status; }
    const qs = Object.keys(params)
      .filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
      .map(k => `${k}=${encodeURIComponent(params[k])}`)
      .join('&');
    const path = qs ? `/users?${qs}` : '/users';
    return httpClient.get<Object[]>(path);
  }
  static async getUserDetail(id: number): Promise<Object> { return httpClient.get(`/users/${id}`); }
  static async createUser(data: object): Promise<Object> { return httpClient.post('/users', data); }
  static async updateUser(id: number, data: object): Promise<Object> { return httpClient.put(`/users/${id}`, data); }
  static async deleteUser(id: number): Promise<void> { return httpClient.delete<void>(`/users/${id}`); }
}
