import { http } from '@kit.NetworkKit';
import { preferencesUtil } from '../utils/PreferencesUtil';
import { emitter } from '@kit.BasicServicesKit';

const LOGIN_EXPIRED_EVENT: emitter.InnerEvent = { eventId: 10001 };
const LOGIN_SUCCESS_EVENT: emitter.InnerEvent = { eventId: 10002 };

class HttpClient {
  private client = http.createHttp();
  private baseUrl: string = 'http://localhost:8080';
  private token: string = '';

  configure(baseUrl: string, token: string): void {
    this.baseUrl = baseUrl || 'http://localhost:8080';
    this.token = token || '';
  }

  clearAuth(): void {
    this.token = '';
    preferencesUtil.delete('token');
    preferencesUtil.delete('currentUser');
    emitter.emit(LOGIN_EXPIRED_EVENT, { data: {} });
  }

  private async request<T>(method: http.RequestMethod, path: string, data?: object): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    try {
      const response = await this.client.request(url, {
        method,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token ? `Bearer ${this.token}` : ''
        },
        extraData: data ? JSON.stringify(data) : '',
        connectTimeout: 10000,
        readTimeout: 30000
      });

      const result: Record<string, Object> = JSON.parse(response.result as string);
      if ((result['code'] as number) !== 200) {
        throw new Error(result['message'] as string);
      }
      return result['data'] as T;
    } catch (error) {
      throw new Error(String(error));
    }
  }

  async get<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path);
  }

  async post<T>(path: string, data?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path, data);
  }

  async put<T>(path: string, data?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, path, data);
  }

  async delete<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.DELETE, path);
  }
}

export const httpClient = new HttpClient();
export { HttpClient, LOGIN_EXPIRED_EVENT, LOGIN_SUCCESS_EVENT };
