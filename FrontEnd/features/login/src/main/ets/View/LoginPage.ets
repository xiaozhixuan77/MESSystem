@ComponentV2
export struct LoginPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local employeeNo: string = '';
  @Local password: string = '';
  @Local isLoading: boolean = false;

  aboutToAppear(): void {
    // 登录页初始化
  }

  build() {
    NavDestination() {
      Column() {
        Text('MES 工业管理系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 80, bottom: 40 });

        TextInput({ placeholder: '请输入工号', text: this.employeeNo })
          .onChange((value: string) => {
            this.employeeNo = value;
          })
          .margin({ bottom: 16 });

        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value;
          })
          .margin({ bottom: 32 });

        Button('登录')
          .width('100%')
          .onClick(() => {
            // 登录逻辑在 P1-10 实现
          });

        if (this.isLoading) {
          LoadingProgress()
            .margin({ top: 16 });
        }
      }
      .padding(24)
      .width('100%')
      .height('100%');
    }
  }
}
