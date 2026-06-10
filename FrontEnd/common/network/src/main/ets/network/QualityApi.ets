import { httpClient } from './HttpClient';
export class QualityApi {
  static async getInspections(params?: Record<string, Object>): Promise<Object[]> {
    let path = '/inspections';
    if (params) {
      const qs = Object.keys(params)
        .filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
        .map(k => `${k}=${encodeURIComponent(String(params[k]))}`)
        .join('&');
      if (qs) path += '?' + qs;
    }
    return httpClient.get(path);
  }
  static async getInspectionDetail(id: number): Promise<Object> { return httpClient.get(`/inspections/${id}`); }
  static async createInspection(data: object): Promise<Object> { return httpClient.post('/inspections', data); }
  static async submitInspection(id: number, data: object): Promise<Object> { return httpClient.put(`/inspections/${id}`, data); }
  static async getDashboard(scope: string = 'today'): Promise<Object> {
    return httpClient.get(`/dashboard?scope=${encodeURIComponent(scope)}`);
  }
}
