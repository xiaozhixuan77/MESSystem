import { HomeTab } from './HomeTab';
import { DataTab } from './DataTab';
import { WorkOrderTab } from './WorkOrderTab';
import { ProfileTab } from './ProfileTab';

@ComponentV2
export struct PhoneMainLayout {
  @Local currentIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomeTab();
      }
      .tabBar(this.buildTabBar('工作台'));

      TabContent() {
        DataTab();
      }
      .tabBar(this.buildTabBar('数据'));

      TabContent() {
        WorkOrderTab();
      }
      .tabBar(this.buildTabBar('工单'));

      TabContent() {
        ProfileTab();
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
