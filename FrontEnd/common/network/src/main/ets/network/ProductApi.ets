import { httpClient } from './HttpClient';

export class ProductApi {
  static async getProducts(keyword?: string): Promise<Object[]> {
    let path = '/products';
    if (keyword) {
      path += `?keyword=${encodeURIComponent(keyword)}`;
    }
    return httpClient.get(path);
  }

  static async getProductProcess(code: string): Promise<Object> {
    return httpClient.get(`/products/${encodeURIComponent(code)}/process`);
  }
}
