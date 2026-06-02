import { LoginViewModel } from '../ViewModel/LoginViewModel';
import { preferencesUtil, LOGIN_SUCCESS_EVENT } from '@ohos/datastore';
import { httpClient } from '@ohos/network';
import { ApiConstants } from '@ohos/utils';
import { LoginResponseModel, LoginResponseUserModel } from '../Model/LoginResponseModel';
import { emitter } from '@kit.BasicServicesKit';

const ROLE_ACCOUNTS: Record<string, string> = {
  '班组长': 'LEADER001',
  '操作员': 'OPERATOR001',
  '质检员': 'INSPECTOR001',
  '管理员': 'ADMIN001',
};

@ComponentV2
export struct LoginView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('showTabBar') showTabBar: boolean = false;
  @Local viewModel: LoginViewModel = new LoginViewModel();
  @Local showPassword: boolean = false;
  @Local selectedRole: string = '班组长';

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

    httpClient.configure(ApiConstants.BASE_URL, result.token);

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

    this.showTabBar = true;
    this.pageStack.replacePath({ name: 'HomeTab' });
  }

  selectRole(role: string): void {
    this.selectedRole = role;
    const account = ROLE_ACCOUNTS[role];
    if (account) {
      this.viewModel.username = account;
    }
  }

  build() {
    Scroll() {
      Column() {
        // Logo 区域
        Column() {
          Image($r('app.media.icon_logo'))
            .width(72)
            .height(72);

          Text('柔性组装MES')
            .fontSize(22)
            .fontWeight(700)
            .fontColor('#1A1A2E')
            .margin({ top: 16 });

          Text('工业制造执行系统 · 教学仿真版')
            .fontSize(13)
            .fontColor('#5A5A6E')
            .fontWeight(400)
            .margin({ top: 4 });
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 40, bottom: 40 });

        // 登录卡片
        Column() {
          Text('账号登录')
            .fontSize(18)
            .fontWeight(600)
            .fontColor('#1A1A2E')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 24 });

          // 账号输入框
          Column() {
            Text('账号')
              .fontSize(13)
              .fontWeight(500)
              .fontColor('#1A1A2E')
              .margin({ bottom: 6 });

            Row() {
              Image($r('app.media.icon_user'))
                .width(18)
                .height(18)
                .margin({ left: 14 });

              TextInput({ placeholder: '请输入工号或手机号', text: $$this.viewModel.username })
                .type(InputType.Normal)
                .maxLength(32)
                .fontSize(15)
                .fontColor('#1A1A2E')
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .margin({ left: 10, right: 14 })
                .padding(0);
            }
            .width('100%')
            .height(48)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1.5, color: '#E8EBF0' });
          }
          .width('100%')
          .margin({ bottom: 18 });

          // 密码输入框
          Column() {
            Text('密码')
              .fontSize(13)
              .fontWeight(500)
              .fontColor('#1A1A2E')
              .margin({ bottom: 6 });

            Row() {
              Image($r('app.media.icon_lock'))
                .width(18)
                .height(18)
                .margin({ left: 14 });

              TextInput({ placeholder: '请输入密码', text: $$this.viewModel.password })
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .maxLength(32)
                .fontSize(15)
                .fontColor('#1A1A2E')
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .margin({ left: 10 })
                .padding(0);
            }
            .width('100%')
            .height(48)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1.5, color: '#E8EBF0' });
          }
          .width('100%')
          .margin({ bottom: 8 });

          // 登录按钮
          Button('登 录')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(600)
            .fontColor(Color.White)
            .backgroundColor(this.viewModel.isLoading ? '#7BA8D6' : '#1565C0')
            .borderRadius(12)
            .enabled(!this.viewModel.isLoading)
            .shadow({ radius: 12, color: 'rgba(21, 101, 192, 0.35)', offsetY: 4 })
            .margin({ top: 8 })
            .onClick(() => {
              this.handleLogin();
            });

          // 错误提示
          if (this.viewModel.errorMessage) {
            Text(this.viewModel.errorMessage)
              .fontSize(13)
              .fontColor('#F44336')
              .margin({ top: 12 })
              .width('100%')
              .textAlign(TextAlign.Center);
          }

          // 加载指示器
          if (this.viewModel.isLoading) {
            LoadingProgress()
              .width(36)
              .height(36)
              .margin({ top: 16 })
              .color('#1565C0');
          }

          // 安全提示
          Row() {
            Image($r('app.media.icon_shield'))
              .width(12)
              .height(12);

            Text('安全加密传输保护')
              .fontSize(12)
              .fontColor('#9A9AA8');
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .margin({ top: 16 });
        }
        .backgroundColor(Color.White)
        .borderRadius(16)
        .padding({ left: 24, right: 24, top: 28, bottom: 28 })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
        .width('100%');

        // 角色快速切换
        Column() {
          Text('快速切换角色（演示）')
            .fontSize(12)
            .fontColor('#5A5A6E')
            .fontWeight(500)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 20, bottom: 12 });

          Row({ space: 8 }) {
            ForEach(['班组长', '操作员', '质检员', '管理员'], (role: string) => {
              Button(role)
                .layoutWeight(1)
                .height(40)
                .fontSize(12)
                .fontWeight(500)
                .fontColor(this.selectedRole === role ? '#1565C0' : '#5A5A6E')
                .backgroundColor(this.selectedRole === role ? '#E3F2FD' : Color.White)
                .border({
                  width: 1.5,
                  color: this.selectedRole === role ? '#1565C0' : '#E8EBF0'
                })
                .borderRadius(12)
                .padding(0)
                .onClick(() => {
                  this.selectRole(role);
                });
            }, (role: string) => role)
          }
          .width('100%');

          Text('v2.0.1 · HarmonyOS NEXT')
            .fontSize(11)
            .fontColor('#9A9AA8')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 16 });
        };
      }
      .padding({ left: 32, right: 32 })
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None);
  }
}
