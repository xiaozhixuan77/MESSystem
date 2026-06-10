import { ProfileView, EmployeeListView } from '@ohos/user';
import { DeepLinkInfo } from '@ohos/utils';

@ComponentV2
export struct ProfileTabDestination {
  @Provider('pageStack') profileStack: NavPathStack = new NavPathStack();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;

  @Builder
  PageMap(name: string) {
    NavDestination() {
      if (name === 'Profile') {
        ProfileView()
      } else if (name === 'EmployeeList') {
        EmployeeListView()
      }
    }
    .hideTitleBar(true)
  }

  build() {
    NavDestination() {
      Navigation(this.profileStack) {
        ProfileView()
      }
      .navDestination(this.PageMap)
      .hideTitleBar(true)
      .onAppear(() => {
        if (this.profileStack.size() === 0) {
          if (this.deepLink && this.deepLink.targetTab === 'ProfileTab') {
            this.profileStack.replacePath({ name: 'Profile' });
            this.profileStack.pushPathByName(this.deepLink.targetPage, this.deepLink.params);
            this.deepLink = null;
          } else {
            this.profileStack.replacePath({ name: 'Profile' });
          }
        }
      });
    }
    .hideTitleBar(true)
  }
}
