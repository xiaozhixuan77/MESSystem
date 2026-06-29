import { preferencesUtil, LOGIN_EXPIRED_EVENT, LOGIN_SUCCESS_EVENT } from '@ohos/datastore';
import { httpClient, WebSocketService } from '@ohos/network';
import { ApiConstants, BreakpointUtil, Colors, DeepLinkInfo, NetworkConfig } from '@ohos/utils';
import { UserModel } from '@ohos/user';
import { emitter } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { PhoneLayout } from './layouts/PhoneLayout';
import { TabletLayout } from './layouts/TabletLayout';
import { DesktopLayout } from './layouts/DesktopLayout';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provider('showTabBar') showTabBar: boolean = false;
  @Provider('currentBreakpoint') currentBreakpoint: string = 'sm';
  @Provider('currentUser') currentUser: UserModel = new UserModel();
  @Provider('currentRole') currentRole: string = '';
  @Local targetPage: string = '';
  @Local isReady: boolean = false;
  @Provider('activeTab') activeTab: string = 'HomeTab';
  @Provider('deepLink') deepLink: DeepLinkInfo | null = null;
  private windowChangeCallback?: (size: window.Size) => void;

  switchTab(tab: string): void {
    this.activeTab = tab;
    this.pageStack.replacePath({ name: tab });
  }

  async aboutToAppear(): Promise<void> {
    // 自动检测后端地址（模拟器→10.0.2.2，真机→网关IP）
    const detectedUrl = NetworkConfig.detectBaseUrl();
    ApiConstants.autoBaseUrl = detectedUrl;
    ApiConstants.autoWsUrl = detectedUrl.replace('http', 'ws') + '/ws';
    httpClient.configure(detectedUrl, '');

    // 窗口断点监听
    try {
      const ctx = getContext(this);
      const win = await window.getLastWindow(ctx);
      const rect = win.getWindowProperties().windowRect;
      this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(rect.width));

      this.windowChangeCallback = (size: window.Size): void => {
        this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(size.width));
      };
      win.on('windowSizeChange', this.windowChangeCallback);
    } catch (e) {
      this.currentBreakpoint = 'sm';
    }

    // 登录过期监听
    emitter.on(LOGIN_EXPIRED_EVENT, () => {
      WebSocketService.getInstance().disconnect();
      this.showTabBar = false;
      this.activeTab = 'HomeTab';
      this.pageStack.replacePath({ name: 'LoginPage' });
    });

    // 登录成功监听
    emitter.on(LOGIN_SUCCESS_EVENT, (eventData: emitter.EventData) => {
      const payload = eventData?.data as Record<string, Object> | undefined;
      if (payload) {
        const user = payload['user'] as Record<string, Object> | undefined;
        if (user) {
          this.currentUser.id = (user['id'] as number) ?? 0;
          this.currentUser.employeeNo = (user['employeeNo'] as string) ?? '';
          this.currentUser.name = (user['name'] as string) ?? '';
          this.currentUser.role = (user['role'] as string) ?? '';
          this.currentUser.workshopId = (user['workshopId'] as number) ?? null;
          this.currentUser.teamId = (user['teamId'] as number) ?? null;
          this.currentUser.status = (user['status'] as string) ?? '';
          this.currentUser.avatarUrl = (user['avatarUrl'] as string) ?? '';
        }
        this.currentRole = (payload['role'] as string) ?? '';

        const loginToken = (payload['token'] as string) ?? '';
        if (loginToken) {
          WebSocketService.getInstance().connect(ApiConstants.autoWsUrl, loginToken);
        }
      }
    });

    // 恢复登录态
    try {
      await preferencesUtil.init(getContext(this));
      const token = await preferencesUtil.get('token');
      if (token) {
        this.currentRole = await preferencesUtil.get('role') || '';

        const userJson = await preferencesUtil.get('currentUser');
        if (userJson) {
          try {
            const userObj: Record<string, Object> = JSON.parse(userJson as string);
            this.currentUser.id = (userObj['id'] as number) ?? 0;
            this.currentUser.employeeNo = (userObj['employeeNo'] as string) ?? '';
            this.currentUser.name = (userObj['name'] as string) ?? '';
            this.currentUser.role = (userObj['role'] as string) ?? '';
            this.currentUser.workshopId = (userObj['workshopId'] as number) ?? null;
            this.currentUser.teamId = (userObj['teamId'] as number) ?? null;
            this.currentUser.status = (userObj['status'] as string) ?? '';
            this.currentUser.avatarUrl = (userObj['avatarUrl'] as string) ?? '';
          } catch (parseErr) {
            // JSON 解析失败，忽略
          }
        }

        httpClient.configure(ApiConstants.autoBaseUrl, token as string);
        WebSocketService.getInstance().connect(ApiConstants.autoWsUrl, token as string);
        this.showTabBar = true;
        this.targetPage = 'HomeTab';
      } else {
        this.targetPage = 'LoginPage';
      }
    } catch (e) {
      this.targetPage = 'LoginPage';
    }
    this.isReady = true;
  }

  aboutToDisappear(): void {
    WebSocketService.getInstance().disconnect();
    if (this.windowChangeCallback) {
      try {
        const ctx = getContext(this);
        window.getLastWindow(ctx).then((win) => {
          win.off('windowSizeChange', this.windowChangeCallback);
        }).catch(() => {});
      } catch (e) {}
    }
  }

  build() {
    if (!this.isReady) {
      Stack() {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(Colors.primaryLight)
          Text('加载中...')
            .fontSize(14)
            .fontColor(Colors.textMuted)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.background)
    } else if (this.currentBreakpoint === 'sm') {
      PhoneLayout({
        targetPage: this.targetPage,
        isReady: this.isReady,
        onTabChange: (tab: string) => { this.switchTab(tab) }
      })
    } else if (this.currentBreakpoint === 'md') {
      TabletLayout({
        targetPage: this.targetPage,
        isReady: this.isReady,
        onTabChange: (tab: string) => { this.switchTab(tab) }
      })
    } else {
      DesktopLayout({
        targetPage: this.targetPage,
        isReady: this.isReady,
        onTabChange: (tab: string) => { this.switchTab(tab) }
      })
    }
  }
}
