import { KpiCard } from '@ohos/common';

@ComponentV2
export struct AdminHomePage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();

  build() {
    NavDestination() {
      Column() {
        Text(`${this.currentUser.name} 的工作台`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 16 });

        // KPI 卡片区域
        Grid() {
          GridItem() {
            KpiCard({ title: '产线总数', value: '--', color: '#1890ff' });
          }
          GridItem() {
            KpiCard({ title: '人员总数', value: '--', color: '#52c41a' });
          }
          GridItem() {
            KpiCard({ title: '活跃工单', value: '--', color: '#faad14' });
          }
          GridItem() {
            KpiCard({ title: '待处理异常', value: '--', color: '#f5222d' });
          }
        }
        .columnsTemplate('1fr 1fr')
        .gap(12);
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
