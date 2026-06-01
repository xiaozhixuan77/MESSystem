import { AdminHomeView, LeaderHomeView, OperatorHomeView, InspectorHomeView } from '@ohos/home';

@ComponentV2
export struct HomeTabDestination {
  @Consumer('currentRole') currentRole: string = '';

  build() {
    NavDestination() {
      if (this.currentRole === 'leader') {
        LeaderHomeView()
      } else if (this.currentRole === 'operator') {
        OperatorHomeView()
      } else if (this.currentRole === 'inspector') {
        InspectorHomeView()
      } else {
        AdminHomeView()
      }
    }
  }
}
