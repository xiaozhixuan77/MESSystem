import { Colors } from '@ohos/utils';
import { UserModel } from '@ohos/user';

@ComponentV2
export struct NavigationRail {
  @Consumer('activeTab') activeTab: string = 'HomeTab';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Param isExpanded: boolean = false;
  @Event onToggle?: () => void;
  @Event onTabSelect?: (tab: string) => void;

  @Builder
  RailItem(iconActive: Resource, iconInactive: Resource, label: string, tabName: string) {
    Row() {
      Image(this.activeTab === tabName ? iconActive : iconInactive)
        .width(24)
        .height(24)
      if (this.isExpanded) {
        Text(label)
          .fontSize(14)
          .fontWeight(this.activeTab === tabName ? 600 : 400)
          .fontColor(this.activeTab === tabName ? Colors.primary : Colors.textSecondary)
          .margin({ left: 12 })
          .opacity(this.isExpanded ? 1 : 0)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: this.isExpanded ? 24 : 0 })
    .justifyContent(this.isExpanded ? FlexAlign.Start : FlexAlign.Center)
    .borderRadius(12)
    .backgroundColor(this.activeTab === tabName ? Colors.primaryBg : Color.Transparent)
    .margin({ left: 8, right: 8, bottom: 4 })
    .onClick(() => this.onTabSelect?.(tabName))
  }

  build() {
    Column() {
      // Toggle button
      Row() {
        Text(this.isExpanded ? '◀' : '☰')
          .fontSize(18)
          .fontColor(Colors.textSecondary)
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onToggle?.())

      Blank().height(8)

      // Navigation items
      this.RailItem($r('app.media.tab_home_active'), $r('app.media.tab_home_inactive'), '工作台', 'HomeTab')
      this.RailItem($r('app.media.tab_data_active'), $r('app.media.tab_data_inactive'), '数据', 'DataTab')
      this.RailItem($r('app.media.tab_workorder_active'), $r('app.media.tab_workorder_inactive'), '工单', 'WorkOrderTab')
      this.RailItem($r('app.media.tab_profile_active'), $r('app.media.tab_profile_inactive'), '我的', 'ProfileTab')

      Blank()

      // User avatar at bottom (only when expanded)
      if (this.isExpanded) {
        Row() {
          Text(this.currentUser.name ? this.currentUser.name.charAt(0) : 'U')
            .fontSize(16)
            .fontWeight(600)
            .fontColor(Colors.textOnPrimary)
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor(Colors.primary)
            .textAlign(TextAlign.Center)
          Text(this.currentUser.name || '用户')
            .fontSize(13)
            .fontColor(Colors.textPrimary)
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ left: 16, right: 8, bottom: 16 })
      }
    }
    .width(this.isExpanded ? 200 : 80)
    .height('100%')
    .backgroundColor(Colors.surface)
    .border({ width: { right: 1 }, color: Colors.border })
    .animation({ duration: 200, curve: Curve.EaseInOut })
    .clip(true)
  }
}
