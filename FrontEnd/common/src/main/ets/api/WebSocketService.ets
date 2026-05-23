import { webSocket } from '@kit.NetworkKit';

@ObservedV2
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  @Trace isConnected: boolean = false;
  private static listeners: Map<string, Function> = new Map();

  static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  connect(url: string): void {
    this.ws = webSocket.createWebSocket();
    this.ws.connect(url, (err: Error) => {
      if (!err) {
        this.isConnected = true;
      }
    });
  }

  subscribe(topic: string): void {
    // STOMP 订阅：发送 SUBSCRIBE 帧
  }

  unsubscribe(topic: string): void {
    // STOMP 取消订阅：发送 UNSUBSCRIBE 帧
  }

  disconnect(): void {
    this.ws?.close();
    this.isConnected = false;
  }

  static addListener(topic: string, handler: Function): void {
    WebSocketService.listeners.set(topic, handler);
  }

  static removeListener(topic: string): void {
    WebSocketService.listeners.delete(topic);
  }
}
