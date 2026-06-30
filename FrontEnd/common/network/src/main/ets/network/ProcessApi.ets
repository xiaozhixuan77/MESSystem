import { httpClient } from './HttpClient';

export class ProcessApi {
  static async getProcesses(): Promise<Object[]> {
    return httpClient.get('/processes');
  }
}
