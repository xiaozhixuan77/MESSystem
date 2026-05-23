import { UserModel } from '@ohos/common';
import { preferencesUtil } from '@ohos/common';
import { httpClient } from '@ohos/common';
import { LOGIN_EXPIRED_EVENT, LOGIN_SUCCESS_EVENT } from '@ohos/common';
import { emitter } from '@kit.BasicServicesKit';
import { LoginPage } from '../login/LoginPage';
import { MainPage } from '../main/MainPage';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provider('currentUser') currentUser: UserModel = new UserModel();
  @Provider('currentRole') currentRole: string = '';

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
          this.currentUser.id = (user['id'] as number) || 0;
          this.currentUser.employeeNo = (user['employeeNo'] as string) || '';
          this.currentUser.name = (user['name'] as string) || '';
          this.currentUser.role = (user['role'] as string) || '';
          this.currentUser.workshopId = (user['workshopId'] as number) || null;
          this.currentUser.teamId = (user['teamId'] as number) || null;
          this.currentUser.status = (user['status'] as string) || '';
          this.currentUser.avatarUrl = (user['avatarUrl'] as string) || '';
        }
        this.currentRole = (payload['role'] as string) || '';
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
            this.currentUser.id = (userObj['id'] as number) || 0;
            this.currentUser.employeeNo = (userObj['employeeNo'] as string) || '';
            this.currentUser.name = (userObj['name'] as string) || '';
            this.currentUser.role = (userObj['role'] as string) || '';
            this.currentUser.workshopId = (userObj['workshopId'] as number) || null;
            this.currentUser.teamId = (userObj['teamId'] as number) || null;
            this.currentUser.status = (userObj['status'] as string) || '';
            this.currentUser.avatarUrl = (userObj['avatarUrl'] as string) || '';
          } catch (parseErr) {
            // JSON 解析失败，忽略
          }
        }

        httpClient.configure('http://localhost:8080', token as string);
        this.pageStack.replacePath({ name: 'MainPage' });
      } else {
        this.pageStack.replacePath({ name: 'LoginPage' });
      }
    } catch (e) {
      this.pageStack.replacePath({ name: 'LoginPage' });
    }
  }

  build() {
    Navigation(this.pageStack) {
      Stack() {}
    }
    .hideTitleBar(true)
    .hideNavBar(true)
    .navDestination(this.PageMap);
  }
}