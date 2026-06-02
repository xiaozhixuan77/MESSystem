import { httpClient } from './HttpClient';

export class WorkOrderApi {
  static async getWorkOrders(params?: Record<string, string | number>): Promise<Object[]> {
    let path = '/workorders';
    if (params) {
      const qs = Object.keys(params)
        .filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
        .map(k => `${k}=${encodeURIComponent(String(params[k]))}`)
        .join('&');
      if (qs) path += '?' + qs;
    }
    return httpClient.get<Object[]>(path);
  }
  static async getWorkOrderDetail(id: number): Promise<Object> { return httpClient.get(`/workorders/${id}`); }
  static async createWorkOrder(data: object): Promise<Object> { return httpClient.post('/workorders', data); }
  static async updateWorkOrder(id: number, data: object): Promise<Object> { return httpClient.put(`/workorders/${id}`, data); }
  static async dispatchWorkOrder(id: number, operatorId: number): Promise<Object> {
    const params: Record<string, number> = { "operatorId": operatorId };
    return httpClient.post(`/workorders/${id}/dispatch`, params);
  }
  static async startWorkOrder(id: number): Promise<Object> { return httpClient.post(`/workorders/${id}/start`); }
  static async pauseWorkOrder(id: number): Promise<Object> { return httpClient.post(`/workorders/${id}/pause`); }
  static async resumeWorkOrder(id: number): Promise<Object> { return httpClient.post(`/workorders/${id}/resume`); }
  static async reportWorkOrder(id: number, data: object): Promise<Object> { return httpClient.post(`/workorders/${id}/report`, data); }
  static async confirmWorkOrder(id: number): Promise<Object> { return httpClient.post(`/workorders/${id}/confirm`); }
  static async scrapWorkOrder(id: number): Promise<Object> { return httpClient.post(`/workorders/${id}/scrap`); }
  static async copyWorkOrder(sourceId: number, data?: object): Promise<Object> {
    return httpClient.post(`/workorders?copyFrom=${sourceId}`, data);
  }
}
