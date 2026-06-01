import { httpClient } from './HttpClient';
export class LineApi {
  static async getLines(params?: object): Promise<Object[]> { return httpClient.get('/lines'); }
  static async getLineDetail(id: number): Promise<Object> { return httpClient.get(`/lines/${id}`); }
  static async startLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/start`); }
  static async stopLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/stop`); }
  static async resetLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/reset`); }
}
