import { Colors } from '@ohos/utils';

@ComponentV2
export struct BottomTabBar {
  @Consumer('activeTab') activeTab: string = 'HomeTab';
  @Event onTabChange?: (tab: string) => void;

  @Builder
  TabItem(iconActive: Resource, iconInactive: Resource, label: string, tabName: string) {
    Column() {
      Image(this.activeTab === tabName ? iconActive : iconInactive)
        .width(22)
        .height(22)
      Text(label)
        .fontSize(10)
        .fontWeight(500)
        .fontColor(this.activeTab === tabName ? Colors.primary : Colors.textMuted)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.onTabChange?.(tabName))
  }

  build() {
    Row() {
      this.TabItem($r('app.media.tab_home_active'), $r('app.media.tab_home_inactive'), '工作台', 'HomeTab')
      this.TabItem($r('app.media.tab_data_active'), $r('app.media.tab_data_inactive'), '数据', 'DataTab')
      this.TabItem($r('app.media.tab_workorder_active'), $r('app.media.tab_workorder_inactive'), '工单', 'WorkOrderTab')
      this.TabItem($r('app.media.tab_profile_active'), $r('app.media.tab_profile_inactive'), '我的', 'ProfileTab')
    }
    .width('100%')
    .backgroundColor(Colors.surface)
    .border({ width: { top: 1 }, color: Colors.border })
    .padding({ top: 8, bottom: 28 })
  }
}
