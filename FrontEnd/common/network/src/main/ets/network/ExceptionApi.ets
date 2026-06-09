import { httpClient } from './HttpClient';

export class ExceptionApi {
  static async reportException(workOrderId: number, lineId: number,
                                 description: string, stationId?: number): Promise<Object> {
    const body: Record<string, Object> = {};
    body['workOrderId'] = workOrderId;
    body['lineId'] = lineId;
    body['description'] = description;
    if (stationId) {
      body['stationId'] = stationId;
    }
    return httpClient.post('/exceptions', body);
  }

  static async getExceptions(params?: Record<string, string | number>): Promise<Object[]> {
    let path = '/exceptions';
    if (params) {
      const qs = Object.keys(params)
        .filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
        .map(k => `${k}=${encodeURIComponent(String(params[k]))}`)
        .join('&');
      if (qs) path += '?' + qs;
    }
    return httpClient.get(path);
  }

  static async getExceptionDetail(id: number): Promise<Object> {
    return httpClient.get(`/exceptions/${id}`);
  }

  static async handleException(id: number, action: string): Promise<Object> {
    const body: Record<string, string> = { 'action': action };
    return httpClient.post(`/exceptions/${id}/handle`, body);
  }
}
