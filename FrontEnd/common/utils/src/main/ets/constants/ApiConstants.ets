export class ApiConstants {
  static readonly DEFAULT_PORT: string = '8080';
  static readonly BASE_URL: string = 'http://localhost:8080';
  static readonly WS_URL: string = 'ws://localhost:8080/ws';
  static readonly CONNECT_TIMEOUT: number = 10000;
  static readonly READ_TIMEOUT: number = 30000;
  // 运行时由 NetworkConfig.detectBaseUrl() 自动检测填充
  static autoBaseUrl: string = 'http://localhost:8080';
  static autoWsUrl: string = 'ws://localhost:8080/ws';
}
