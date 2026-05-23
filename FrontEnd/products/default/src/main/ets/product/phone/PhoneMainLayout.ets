import { LeaderHomePage, OperatorHomePage, InspectorHomePage, AdminHomePage } from '@ohos/home';
import { ProfilePage } from '@ohos/user';

@ComponentV2
export struct PhoneMainLayout {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local currentIndex: number = 0;

  @Builder
  buildHomePage() {
    if (this.currentRole === 'leader') {
      LeaderHomePage();
    } else if (this.currentRole === 'operator') {
      OperatorHomePage();
    } else if (this.currentRole === 'inspector') {
      InspectorHomePage();
    } else {
      AdminHomePage();
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.buildHomePage();
      }
      .tabBar(this.buildTabBar('工作台'));

      TabContent() {
        LineListPage();
      }
      .tabBar(this.buildTabBar('数据'));

      TabContent() {
        WorkOrderListPage({ role: this.currentRole });
      }
      .tabBar(this.buildTabBar('工单'));

      TabContent() {
        ProfilePage();
      }
      .tabBar(this.buildTabBar('我的'));
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    });
  }

  @Builder
  buildTabBar(title: string) {
    Column() {
      Text(title)
        .fontSize(12);
    };
  }
}
