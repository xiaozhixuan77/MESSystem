import { UserModel } from '@ohos/common';
import { preferencesUtil } from '@ohos/common';
import { LOGIN_EXPIRED_EVENT } from '@ohos/common';
import { emitter } from '@kit.BasicServicesKit';

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

    try {
      await preferencesUtil.init(getContext(this));
      const token = preferencesUtil.get('token');
      if (token) {
        this.currentRole = preferencesUtil.get('role') || '';
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
