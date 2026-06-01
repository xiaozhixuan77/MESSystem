import { http } from '@kit.NetworkKit';
import { preferencesUtil } from '@ohos/datastore';
import { LOGIN_EXPIRED_EVENT } from '@ohos/datastore';
import { emitter } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

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

  private showToast(message: string): void {
    try { promptAction.showToast({ message: message, duration: 2000 }); } catch (e) {}
  }

  private async request<T>(method: http.RequestMethod, path: string, data?: object): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    let result: Record<string, Object>;
    try {
      const response = await this.client.request(url, {
        method,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token ? `Bearer ${this.token}` : ''
        },
        extraData: data ? JSON.stringify(data) : '',
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 30000
      });
      const rawResult = response.result;
      if (typeof rawResult === 'string') {
        result = JSON.parse(rawResult) as Record<string, Object>;
      } else {
        result = rawResult as Record<string, Object>;
      }
      const code = result['code'] as number;
      if (code !== 200) {
        const message = (result['message'] as string) || '请求失败';
        if (code === 401) { this.clearAuth(); this.showToast('登录已过期，请重新登录'); }
        else if (code === 403) { this.showToast('无权限执行此操作'); }
        else { this.showToast(message); }
        throw new Error(message);
      }
      return result['data'] as T;
    } catch (error) {
      const err = error as Error;
      if (err instanceof SyntaxError) { this.showToast('服务器响应异常'); throw err; }
      const errMsg = err.message || '';
      if (errMsg.includes('Network') || errMsg.includes('connect') || errMsg.includes('timeout')) {
        this.showToast('网络连接失败，请检查网络');
      }
      if (errMsg) { throw err; }
      throw new Error(String(error));
    }
  }

  async get<T>(path: string): Promise<T> { return this.request<T>(http.RequestMethod.GET, path); }
  async post<T>(path: string, data?: object): Promise<T> { return this.request<T>(http.RequestMethod.POST, path, data); }
  async put<T>(path: string, data?: object): Promise<T> { return this.request<T>(http.RequestMethod.PUT, path, data); }
  async delete<T>(path: string): Promise<T> { return this.request<T>(http.RequestMethod.DELETE, path); }
}

export const httpClient = new HttpClient();
export { HttpClient };
