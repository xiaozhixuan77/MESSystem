import { ProfileView, EmployeeListView } from '@ohos/user';

@ComponentV2
export struct ProfileTabDestination {
  @Local profileStack: NavPathStack = new NavPathStack();

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
    }
    .hideTitleBar(true)
  }
}
