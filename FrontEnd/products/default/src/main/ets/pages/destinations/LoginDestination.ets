import { LoginView } from '@ohos/login';

@ComponentV2
export struct LoginDestination {
  build() {
    NavDestination() {
      LoginView()
    }
    .hideTitleBar(true)
  }
}
