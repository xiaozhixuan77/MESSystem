import { httpClient } from './HttpClient';

export class HomeApi {
  static async getSummary(): Promise<Object> {
    return httpClient.get('/home/summary');
  }
}
