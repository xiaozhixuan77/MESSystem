import { preferencesUtil, httpClient, ApiConstants, LOGIN_EXPIRED_EVENT, LOGIN_SUCCESS_EVENT } from '@ohos/common';
import { UserModel } from '@ohos/user';
import { emitter } from '@kit.BasicServicesKit';
import { LoginPage } from '../login/LoginPage';
import { MainPage } from '../main/MainPage';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provider('currentUser') currentUser: UserModel = new UserModel();
  @Provider('currentRole') currentRole: string = '';
  @Local targetPage: string = '';

  @Builder
  PageMap(name: string) {
    if (name === 'LoginPage') {
      LoginPage();
    } else if (name === 'MainPage') {
      MainPage();
    }
  }

  async aboutToAppear(): Promise<void> {
    emitter.on(LOGIN_EXPIRED_EVENT, () => {
      this.pageStack.replacePath({ name: 'LoginPage' });
    });

    emitter.on(LOGIN_SUCCESS_EVENT, (eventData: emitter.EventData) => {
      const payload = eventData?.data as Record<string, Object> | undefined;
      if (payload) {
        const user = payload['user'] as Record<string, Object> | undefined;
        if (user) {
          this.applyCurrentUser(user);
        }
        this.currentRole = (payload['role'] as string) ?? '';
      }
    });

    try {
      await preferencesUtil.init(getContext(this));
      const token = await preferencesUtil.get('token');
      if (token) {
        this.currentRole = await preferencesUtil.get('role') || '';

        const userJson = await preferencesUtil.get('currentUser');
        if (userJson) {
          try {
            const userObj: Record<string, Object> = JSON.parse(userJson as string);
            this.applyCurrentUser(userObj);
          } catch (parseErr) {
            // JSON 解析失败，忽略
          }
        }

        httpClient.configure(ApiConstants.BASE_URL, token as string);
        this.targetPage = 'MainPage';
      } else {
        this.targetPage = 'LoginPage';
      }
    } catch (e) {
      this.targetPage = 'LoginPage';
    }
  }

  private applyCurrentUser(userObj: Record<string, Object>): void {
    this.currentUser.id = (userObj['id'] as number) ?? 0;
    this.currentUser.employeeNo = (userObj['employeeNo'] as string) ?? '';
    this.currentUser.name = (userObj['name'] as string) ?? '';
    this.currentUser.role = (userObj['role'] as string) ?? '';
    this.currentUser.workshopId = (userObj['workshopId'] as number) ?? null;
    this.currentUser.teamId = (userObj['teamId'] as number) ?? null;
    this.currentUser.status = (userObj['status'] as string) ?? '';
    this.currentUser.avatarUrl = (userObj['avatarUrl'] as string) ?? '';
  }

  build() {
    Navigation(this.pageStack) {
      Stack() {}
    }
    .onAppear(() => {
      if (this.targetPage) {
        this.pageStack.replacePath({ name: this.targetPage });
      }
    })
    .hideTitleBar(true)
    .hideNavBar(true)
    .navDestination(this.PageMap);
  }
}