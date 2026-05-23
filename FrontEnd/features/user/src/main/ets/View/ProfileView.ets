import { UserModel } from "@ohos/common";

@ComponentV2
export struct ProfileView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

  build() {
    NavDestination() {
      Column() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Text(`工号: ${this.currentUser.employeeNo}`)
          .fontSize(14)
          .fontColor('#666');

        Text(`姓名: ${this.currentUser.name}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 8 });

        Text(`角色: ${this.currentUser.role}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 8 });

        Button('退出登录')
          .width('100%')
          .margin({ top: 32 })
          .onClick(() => {
            // 退出登录逻辑（后续 Phase 实现）
          });
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
