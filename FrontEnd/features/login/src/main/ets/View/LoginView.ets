import { LoginViewModel } from '../ViewModel/LoginViewModel';
import {
  preferencesUtil,
  httpClient,
  LOGIN_SUCCESS_EVENT,
  LoginResponseModel,
  LoginResponseUserModel
} from '@ohos/common';
import { emitter } from '@kit.BasicServicesKit';

@ComponentV2
export struct LoginView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: LoginViewModel = new LoginViewModel();
  @Local showPassword: boolean = false;

  aboutToAppear(): void {
    this.viewModel.reset();
    this.loadRememberedUsername();
  }

  async loadRememberedUsername(): Promise<void> {
    const saved = await preferencesUtil.get('rememberedUsername');
    if (saved) {
      this.viewModel.username = saved;
      this.viewModel.rememberMe = true;
    }
  }

  async handleLogin(): Promise<void> {
    if (this.viewModel.isLoading) {
      return;
    }

    const success = await this.viewModel.login();
    if (!success || !this.viewModel.loginResult) {
      return;
    }

    const result: LoginResponseModel = this.viewModel.loginResult;
    const userData: LoginResponseUserModel | null = result.user;

    if (this.viewModel.rememberMe) {
      await preferencesUtil.set('rememberedUsername', this.viewModel.username.trim());
    } else {
      await preferencesUtil.delete('rememberedUsername');
    }

    await preferencesUtil.set('token', result.token);
    await preferencesUtil.set('role', result.role);
    if (userData) {
      await preferencesUtil.set('currentUser', JSON.stringify(userData));
    }

    httpClient.configure('http://localhost:8080', result.token);

    if (userData) {
      const eventData: emitter.EventData = {
        data: {
          token: result.token,
          role: result.role,
          user: userData
        }
      };
      emitter.emit(LOGIN_SUCCESS_EVENT, eventData);
    }

    this.pageStack.replacePath({ name: 'MainPage' });
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text('\u{1F3ED}')
            .fontSize(64)

          Text('MES 工业管理系统')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .margin({ top: 16 });

          Text('柔性组装 MES 仿真系统')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8, bottom: 32 });

          Column() {
            Row() {
              Text('工号')
                .fontSize(14)
                .fontColor('#333333');
            }
            .width('100%');

            TextInput({ placeholder: '请输入工号', text: $$this.viewModel.username })
              .type(InputType.Normal)
              .maxLength(32)
              .fontSize(16)
              .margin({ top: 8 })
              .backgroundColor('#f5f5f5')
              .borderRadius(8);
          }
          .width('100%')
          .margin({ bottom: 20 });

          Column() {
            Row() {
              Text('密码')
                .fontSize(14)
                .fontColor('#333333');
            }
            .width('100%');

            Row() {
              TextInput({ placeholder: '请输入密码', text: $$this.viewModel.password })
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .maxLength(32)
                .fontSize(16)
                .layoutWeight(1)
                .backgroundColor(Color.Transparent);

              Text(this.showPassword ? '隐藏' : '显示')
                .fontSize(13)
                .fontColor('#1890ff')
                .onClick(() => {
                  this.showPassword = !this.showPassword;
                });
            }
            .width('100%')
            .margin({ top: 8 })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .padding({ right: 12 });
          }
          .width('100%')
          .margin({ bottom: 16 });

          Row() {
            Checkbox({ name: 'rememberMe', group: 'rememberMeGroup' })
              .select($$this.viewModel.rememberMe)
              .selectedColor('#1890ff')
              .width(20)
              .height(20);

            Text('记住我')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })
              .onClick(() => {
                this.viewModel.rememberMe = !this.viewModel.rememberMe;
              });
          }
          .width('100%')
          .margin({ bottom: 20 });

          if (this.viewModel.errorMessage) {
            Text(this.viewModel.errorMessage)
              .fontSize(13)
              .fontColor('#ff4444')
              .margin({ bottom: 12 })
              .width('100%');
          }

          Button('登录')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(this.viewModel.isLoading ? '#a0c4ff' : '#1890ff')
            .borderRadius(8)
            .enabled(!this.viewModel.isLoading)
            .onClick(() => {
              this.handleLogin();
            });

          if (this.viewModel.isLoading) {
            LoadingProgress()
              .width(36)
              .height(36)
              .margin({ top: 24 })
              .color('#1890ff');
          }
        }
        .padding({ left: 32, right: 32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None);
    }
    .hideTitleBar(true);
  }
}