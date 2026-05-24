import { ProfileView, EmployeeListView } from '@ohos/user';

@ComponentV2
export struct ProfileTab {
  @Local profileStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'Profile') {
      ProfileView();
    } else if (name === 'EmployeeList') {
      EmployeeListView();
    }
  }

  build() {
    Navigation(this.profileStack) {
      Stack() {}
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .onAppear(() => {
      this.profileStack.replacePath({ name: 'Profile' });
    })
  }
}
