import { LeaderHomeView, OperatorHomeView, InspectorHomeView, AdminHomeView } from '@ohos/home';
import { ProfileView } from '@ohos/user';

@ComponentV2
export struct PhoneMainLayout {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local currentIndex: number = 0;

  @Builder
  buildHomePage() {
    if (this.currentRole === 'leader') {
      LeaderHomeView();
    } else if (this.currentRole === 'operator') {
      OperatorHomeView();
    } else if (this.currentRole === 'inspector') {
      InspectorHomeView();
    } else {
      AdminHomeView();
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.buildHomePage();
      }
      .tabBar(this.buildTabBar('工作台'));

      TabContent() {
        LineListView();
      }
      .tabBar(this.buildTabBar('数据'));

      TabContent() {
        WorkOrderListView({ role: this.currentRole });
      }
      .tabBar(this.buildTabBar('工单'));

      TabContent() {
        ProfileView();
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
