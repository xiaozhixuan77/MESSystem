import { LoginView } from '@ohos/login';

@Builder
export function LoginPageBuilder() {
  LoginView();
}

@ComponentV2
export struct LoginPage {
  build() {
    LoginView();
  }
}