import { LeaderHomeView, OperatorHomeView, InspectorHomeView, AdminHomeView } from '@ohos/home';

@ComponentV2
export struct HomeTab {
  @Provider('pageStack') homeStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';

  @Builder
  PageMap(name: string) {
    if (name === 'Home') {
      if (this.currentRole === 'leader') {
        LeaderHomeView();
      } else if (this.currentRole === 'operator') {
        OperatorHomeView();
      } else if (this.currentRole === 'inspector') {
        InspectorHomeView();
      } else {
        AdminHomeView();
      }
    }
  }

  aboutToAppear(): void {
    this.homeStack.replacePath({ name: 'Home' });
  }

  build() {
    Navigation(this.homeStack) {
      Stack() {}
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
  }
}
