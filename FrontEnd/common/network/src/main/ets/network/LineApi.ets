import { httpClient } from './HttpClient';
export class LineApi {
  static async getLines(params?: Record<string, string | number>): Promise<Object[]> {
    let path = '/lines';
    if (params) {
      const qs = Object.keys(params)
        .filter(k => params[k] !== undefined && params[k] !== null)
        .map(k => `${k}=${encodeURIComponent(String(params[k]))}`)
        .join('&');
      if (qs) path += '?' + qs;
    }
    return httpClient.get(path);
  }
  static async getLineDetail(id: number): Promise<Object> { return httpClient.get(`/lines/${id}`); }
  static async startLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/start`); }
  static async stopLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/stop`); }
  static async resetLine(id: number): Promise<Object> { return httpClient.post(`/lines/${id}/reset`); }
}
