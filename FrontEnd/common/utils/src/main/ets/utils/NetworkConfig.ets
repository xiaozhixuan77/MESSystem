import { deviceInfo } from '@kit.BasicServicesKit';

const EMULATOR_HOST = '10.0.2.2';
const LOCALHOST = 'localhost';
const DEFAULT_PORT = '8080';

export class NetworkConfig {
  /**
   * 启发式检测模拟器：检查 serial、marketName 等属性
   */
  static isEmulator(): boolean {
    const serial: string = deviceInfo.serial || '';
    const marketName: string = deviceInfo.marketName || '';
    const manufacture: string = deviceInfo.manufacture || '';
    return serial === '' || serial === 'unknown'
      || marketName === '' || marketName.toLowerCase().includes('emulator')
      || manufacture === '';
  }

  /**
   * 自动检测后端 BASE_URL
   * - 模拟器 → http://10.0.2.2:8080（访问宿主机）
   * - 真机   → http://localhost:8080（需配合端口转发）
   */
  static detectBaseUrl(port: string = DEFAULT_PORT): string {
    if (NetworkConfig.isEmulator()) {
      return `http://${EMULATOR_HOST}:${port}`;
    }
    return `http://${LOCALHOST}:${port}`;
  }
}
