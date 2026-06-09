import { httpClient } from './HttpClient';
export class QualityApi {
  static async getInspections(params?: object): Promise<Object[]> { return httpClient.get('/inspections'); }
  static async getInspectionDetail(id: number): Promise<Object> { return httpClient.get(`/inspections/${id}`); }
  static async createInspection(data: object): Promise<Object> { return httpClient.post('/inspections', data); }
  static async submitInspection(id: number, data: object): Promise<Object> { return httpClient.put(`/inspections/${id}`, data); }
  static async getDashboard(scope: string = 'today'): Promise<Object> {
    return httpClient.get(`/dashboard?scope=${encodeURIComponent(scope)}`);
  }
}
