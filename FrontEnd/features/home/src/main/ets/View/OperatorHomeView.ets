@ComponentV2
export struct OperatorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

  build() {
    NavDestination() {
      Column() {
        Text(`${this.currentUser.name} 的工作台`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        Column() {
          Text('我的任务')
            .fontSize(14)
            .fontColor('#999');
        }
        .padding(16)
        .backgroundColor('#fff')
        .borderRadius(8)
        .width('100%');
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
