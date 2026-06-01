import { preferencesUtil, LOGIN_EXPIRED_EVENT, LOGIN_SUCCESS_EVENT } from '@ohos/datastore';
import { httpClient } from '@ohos/network';
import { ApiConstants, BreakpointUtil, NetworkConfig } from '@ohos/utils';
import { UserModel } from '@ohos/user';
import { emitter } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { LoginDestination } from './destinations/LoginDestination';
import { HomeTabDestination } from './destinations/HomeTabDestination';
import { DataTabDestination } from './destinations/DataTabDestination';
import { WorkOrderTabDestination } from './destinations/WorkOrderTabDestination';
import { ProfileTabDestination } from './destinations/ProfileTabDestination';

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
  private windowChangeCallback?: (size: window.Size) => void;

  @Builder
  PageMap(name: string) {
    if (name === 'LoginPage') {
      LoginDestination()
    } else if (name === 'HomeTab') {
      HomeTabDestination()
    } else if (name === 'DataTab') {
      DataTabDestination()
    } else if (name === 'WorkOrderTab') {
      WorkOrderTabDestination()
    } else if (name === 'ProfileTab') {
      ProfileTabDestination()
    }
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
      this.showTabBar = false;
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
            .color('#1890ff')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    } else {
      Stack() {
        Column() {
          Row() {
            // md/lg → 侧边导航栏
            if (this.showTabBar && this.currentBreakpoint !== 'sm') {
              this.Sidebar()
            }

            Navigation(this.pageStack) {
              Stack() {}
            }
            .navDestination(this.PageMap)
            .hideTitleBar(true)
            .hideNavBar(true)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .onAppear(() => {
              if (this.targetPage) {
                this.pageStack.replacePath({ name: this.targetPage });
              }
            })
          }
          .layoutWeight(1)

          // sm → 底部导航栏
          if (this.showTabBar && this.currentBreakpoint === 'sm') {
            this.BottomTabBar()
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  Sidebar() {
    Column() {
      Button('工作台')
        .width('100%')
        .height(this.currentBreakpoint === 'md' ? 80 : 90)
        .fontSize(this.currentBreakpoint === 'md' ? 14 : 16)
        .onClick(() => this.pageStack.replacePath({ name: 'HomeTab' }))

      Button('数据')
        .width('100%')
        .height(this.currentBreakpoint === 'md' ? 80 : 90)
        .fontSize(this.currentBreakpoint === 'md' ? 14 : 16)
        .onClick(() => this.pageStack.replacePath({ name: 'DataTab' }))

      Button('工单')
        .width('100%')
        .height(this.currentBreakpoint === 'md' ? 80 : 90)
        .fontSize(this.currentBreakpoint === 'md' ? 14 : 16)
        .onClick(() => this.pageStack.replacePath({ name: 'WorkOrderTab' }))

      Button('我的')
        .width('100%')
        .height(this.currentBreakpoint === 'md' ? 80 : 90)
        .fontSize(this.currentBreakpoint === 'md' ? 14 : 16)
        .onClick(() => this.pageStack.replacePath({ name: 'ProfileTab' }))
    }
    .width(this.currentBreakpoint === 'md' ? 120 : 160)
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.6)')
  }

  @Builder
  BottomTabBar() {
    Row() {
      Button('工作台')
        .layoutWeight(1)
        .height(56)
        .onClick(() => this.pageStack.replacePath({ name: 'HomeTab' }))

      Button('数据')
        .layoutWeight(1)
        .height(56)
        .onClick(() => this.pageStack.replacePath({ name: 'DataTab' }))

      Button('工单')
        .layoutWeight(1)
        .height(56)
        .onClick(() => this.pageStack.replacePath({ name: 'WorkOrderTab' }))

      Button('我的')
        .layoutWeight(1)
        .height(56)
        .onClick(() => this.pageStack.replacePath({ name: 'ProfileTab' }))
    }
    .width('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
  }
}
