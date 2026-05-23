import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface WebSocketMessage {
  topic: string;
  version: number;
  eventId: string;
  payload: object;
}

@ObservedV2
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private reconnectTimer: number = -1;
  private heartbeatTimer: number = -1;
  @Trace isConnected: boolean = false;
  private static listeners: Map<string, Function> = new Map();
  private currentUrl: string = '';

  static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  connect(url: string): void {
    if (this.ws) {
      this.ws.off('open');
      this.ws.off('message');
      this.ws.off('close');
      this.ws.off('error');
      this.ws.close();
    }
    this.currentUrl = url;
    this.ws = webSocket.createWebSocket();

    this.ws.on('open', (_err: BusinessError, _value: Object): void => {
      this.isConnected = true;
      this.startHeartbeat();
    });

    this.ws.on('message', (_err: BusinessError, value: string | ArrayBuffer): void => {
      const data: string = typeof value === 'string' ? value : '';
      if (data.length > 0) {
        this.handleMessage(data);
      }
    });

    this.ws.on('close', (_err: BusinessError, _value: Object): void => {
      this.isConnected = false;
      this.stopHeartbeat();
      this.scheduleReconnect();
    });

    this.ws.on('error', (_err: BusinessError): void => {
      this.isConnected = false;
      this.stopHeartbeat();
      this.scheduleReconnect();
    });

    this.ws.connect(url);
  }

  subscribe(topic: string): void {
    const frame: Record<string, string> = { 'action': 'SUBSCRIBE', 'destination': topic };
    this.send(frame);
  }

  unsubscribe(topic: string): void {
    const frame: Record<string, string> = { 'action': 'UNSUBSCRIBE', 'destination': topic };
    this.send(frame);
  }

  disconnect(): void {
    this.currentUrl = '';
    this.stopHeartbeat();
    this.clearReconnect();
    this.ws?.close();
    this.ws = null;
    this.isConnected = false;
  }

  private send(data: Record<string, string>): void {
    if (this.ws && this.isConnected) {
      this.ws.send(JSON.stringify(data));
    }
  }

  private startHeartbeat(): void {
    this.heartbeatTimer = setInterval(() => {
      const ping: Record<string, string> = { 'type': 'ping' };
      this.send(ping);
    }, 30000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer !== -1) {
      return;
    }
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = -1;
      if (this.currentUrl.length > 0) {
        this.connect(this.currentUrl);
      }
    }, 5000);
  }

  private clearReconnect(): void {
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }

  private handleMessage(rawData: string): void {
    try {
      const msg = JSON.parse(rawData) as WebSocketMessage;
      const topic: string = msg.topic || '';
      const listener = WebSocketService.listeners.get(topic);
      if (listener && msg.payload) {
        listener(msg.payload);
      }
    } catch (_e) {
      // 忽略解析失败的消息
    }
  }

  static addListener(topic: string, handler: Function): void {
    WebSocketService.listeners.set(topic, handler);
  }

  static removeListener(topic: string): void {
    WebSocketService.listeners.delete(topic);
  }
}
