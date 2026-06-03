import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface StompFrame {
  command: string;
  headers: Record<string, string>;
  body: string;
}

@ObservedV2
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private reconnectTimer: number = -1;
  private heartbeatTimer: number = -1;
  @Trace isConnected: boolean = false;
  private static listeners: Map<string, Function[]> = new Map();
  private currentUrl: string = '';
  private currentToken: string = '';
  private subscriptionCounter: number = 0;
  private pendingSubscriptions: Map<string, string> = new Map();
  private receiveBuffer: string = '';

  static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  connect(url: string, token: string): void {
    this.stopHeartbeat();
    this.clearReconnect();
    this.ws?.close();
    this.ws = null;
    this.isConnected = false;

    this.currentUrl = url;
    this.currentToken = token;
    this.receiveBuffer = '';

    this.ws = webSocket.createWebSocket();
    this.ws.on('open', (_err: BusinessError, _value: Object): void => {
      this.sendStompConnect();
    });
    this.ws.on('message', (_err: BusinessError, value: string | ArrayBuffer): void => {
      const data: string = typeof value === 'string' ? value : '';
      if (data.length > 0) {
        this.onData(data);
      }
    });
    this.ws.on('close', (_err: BusinessError, _value: Object): void => {
      this.onDisconnect();
    });
    this.ws.on('error', (_err: BusinessError): void => {
      this.onDisconnect();
    });
    this.ws.connect(url);
  }

  subscribe(destination: string): void {
    let alreadySubscribed = false;
    this.pendingSubscriptions.forEach((dest: string) => {
      if (dest === destination) {
        alreadySubscribed = true;
      }
    });
    if (alreadySubscribed) {
      return;
    }

    const subId = 'sub-' + this.subscriptionCounter++;
    this.pendingSubscriptions.set(subId, destination);

    if (this.isConnected && this.ws) {
      const subHeaders: Record<string, string> = { "id": subId, "destination": destination };
      this.sendStompFrame('SUBSCRIBE', subHeaders);
    }
  }

  unsubscribe(destination: string): void {
    let targetSubId = '';
    this.pendingSubscriptions.forEach((dest: string, subId: string) => {
      if (dest === destination) {
        targetSubId = subId;
      }
    });
    if (targetSubId.length === 0) {
      return;
    }

    this.pendingSubscriptions.delete(targetSubId);
    if (this.isConnected && this.ws) {
      const unsubHeaders: Record<string, string> = { "id": targetSubId };
      this.sendStompFrame('UNSUBSCRIBE', unsubHeaders);
    }
  }

  disconnect(): void {
    if (this.isConnected && this.ws) {
      try {
        const emptyHeaders: Record<string, string> = {};
        this.sendStompFrame('DISCONNECT', emptyHeaders);
      } catch (_e) {
        // best effort
      }
    }
    this.currentUrl = '';
    this.currentToken = '';
    this.stopHeartbeat();
    this.clearReconnect();
    this.ws?.close();
    this.ws = null;
    this.isConnected = false;
    this.pendingSubscriptions.clear();
    this.receiveBuffer = '';
  }

  static addListener(topic: string, handler: Function): void {
    const list = WebSocketService.listeners.get(topic);
    if (list) {
      list.push(handler);
    } else {
      WebSocketService.listeners.set(topic, [handler]);
    }
  }

  static removeListener(topic: string, handler: Function): void {
    const list = WebSocketService.listeners.get(topic);
    if (!list) {
      return;
    }
    const idx = list.indexOf(handler);
    if (idx !== -1) {
      list.splice(idx, 1);
    }
    if (list.length === 0) {
      WebSocketService.listeners.delete(topic);
    }
  }

  // ─── STOMP frame serialization ───

  private sendStompConnect(): void {
    const headers: Record<string, string> = {
      'accept-version': '1.1,1.2',
      'host': 'localhost'
    };
    if (this.currentToken.length > 0) {
      headers['Authorization'] = 'Bearer ' + this.currentToken;
    }
    this.sendStompFrame('CONNECT', headers);
  }

  private sendStompFrame(command: string, headers: Record<string, string>, body?: string): void {
    if (!this.ws) {
      return;
    }
    let frame = command + '\n';
    const keys = Object.keys(headers);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      frame += k + ':' + headers[k] + '\n';
    }
    if (body !== undefined && body.length > 0) {
      frame += 'content-length:' + this.utf8ByteLength(body) + '\n';
    }
    frame += '\n';
    if (body !== undefined && body.length > 0) {
      frame += body;
    }
    frame += '\0';
    this.ws.send(frame);
  }

  private utf8ByteLength(str: string): number {
    let len = 0;
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      if (code <= 0x7f) {
        len += 1;
      } else if (code <= 0x7ff) {
        len += 2;
      } else if (code <= 0xffff) {
        len += 3;
      } else {
        len += 4;
      }
    }
    return len;
  }

  // ─── STOMP frame deserialization ───

  private onData(data: string): void {
    if (data === '\n') {
      return;
    }
    this.receiveBuffer += data;

    while (true) {
      const nullIndex = this.receiveBuffer.indexOf('\0');
      if (nullIndex === -1) {
        break;
      }
      const frameStr = this.receiveBuffer.substring(0, nullIndex);
      this.receiveBuffer = this.receiveBuffer.substring(nullIndex + 1);

      if (frameStr.length === 0 || frameStr === '\n') {
        continue;
      }

      try {
        const frame = this.parseStompFrame(frameStr);
        this.processFrame(frame);
      } catch (_e) {
        // malformed frame, skip
      }
    }
  }

  private parseStompFrame(frameStr: string): StompFrame {
    const lines = frameStr.split('\n');
    const command = lines[0];
    const headers: Record<string, string> = {};

    let i = 1;
    while (i < lines.length && lines[i].length > 0) {
      const colonIdx = lines[i].indexOf(':');
      if (colonIdx > 0) {
        const key = lines[i].substring(0, colonIdx);
        const value = lines[i].substring(colonIdx + 1);
        headers[key] = value;
      }
      i++;
    }
    i++;

    let body = lines.slice(i).join('\n');

    const contentLength = headers['content-length'];
    if (contentLength) {
      const cl = parseInt(contentLength);
      if (cl > 0 && body.length > cl) {
        body = body.substring(0, cl);
      }
    }

    const frame: StompFrame = { command: command, headers: headers, body: body };
    return frame;
  }

  private processFrame(frame: StompFrame): void {
    switch (frame.command) {
      case 'CONNECTED':
        this.isConnected = true;
        this.startHeartbeat();
        this.pendingSubscriptions.forEach((destination: string, subId: string) => {
          const replayHeaders: Record<string, string> = { "id": subId, "destination": destination };
          this.sendStompFrame('SUBSCRIBE', replayHeaders);
        });
        break;

      case 'MESSAGE': {
        const destination = frame.headers['destination'];
        if (destination && frame.body.length > 0) {
          const list = WebSocketService.listeners.get(destination);
          if (list) {
            const parsed = JSON.parse(frame.body) as Object;
            for (let i = 0; i < list.length; i++) {
              try {
                list[i](parsed);
              } catch (_e) {
                // handler error, skip
              }
            }
          }
        }
        break;
      }

      case 'ERROR':
        break;

      case 'RECEIPT':
        break;

      default:
        break;
    }
  }

  // ─── Heartbeat ───

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval((): void => {
      if (!this.isConnected && this.currentUrl.length > 0) {
        this.stopHeartbeat();
        this.scheduleReconnect();
      }
    }, 30000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== -1) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  // ─── Reconnect ───

  private onDisconnect(): void {
    this.isConnected = false;
    this.receiveBuffer = '';
    this.stopHeartbeat();
    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer !== -1) {
      return;
    }
    this.reconnectTimer = setTimeout((): void => {
      this.reconnectTimer = -1;
      if (this.currentUrl.length > 0 && this.currentToken.length > 0) {
        this.connect(this.currentUrl, this.currentToken);
      }
    }, 5000);
  }

  private clearReconnect(): void {
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
  }
}
