import { ProfileView, EmployeeListView } from '@ohos/user';

@ComponentV2
export struct ProfileTab {
  @Provider('pageStack') profileStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'Profile') {
      ProfileView();
    } else if (name === 'EmployeeList') {
      EmployeeListView();
    }
  }

  aboutToAppear(): void {
    this.profileStack.replacePath({ name: 'Profile' });
  }

  build() {
    Navigation(this.profileStack) {
      Stack() {}
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
  }
}
