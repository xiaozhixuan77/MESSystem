import { httpClient } from './HttpClient';

export class DashboardApi {
  static async getDashboard(scope: string = 'today'): Promise<Object> {
    return httpClient.get(`/dashboard?scope=${scope}`);
  }
}
