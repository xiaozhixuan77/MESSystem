import { httpClient } from './HttpClient';

export class WorkshopApi {
  static async getWorkshops(): Promise<Object[]> {
    return httpClient.get('/workshops');
  }
}
