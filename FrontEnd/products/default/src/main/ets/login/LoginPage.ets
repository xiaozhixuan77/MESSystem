import { LoginPage as LoginView } from '@ohos/login';

@Builder
export function LoginPageBuilder() {
  LoginPage();
}

@ComponentV2
export struct LoginPage {
  build() {
    LoginView();
  }
}
