import { httpClient } from './HttpClient';
export class UserApi {
  static async getUsers(params?: object): Promise<Object[]> { return httpClient.get('/users'); }
  static async getUserDetail(id: number): Promise<Object> { return httpClient.get(`/users/${id}`); }
  static async createUser(data: object): Promise<Object> { return httpClient.post('/users', data); }
  static async updateUser(id: number, data: object): Promise<Object> { return httpClient.put(`/users/${id}`, data); }
}
