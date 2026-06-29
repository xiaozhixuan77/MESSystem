import { Colors } from '@ohos/utils';
import { UserModel } from '@ohos/user';
import { LOGIN_EXPIRED_EVENT } from '@ohos/datastore';
import { emitter } from '@kit.BasicServicesKit';

interface BadgeColors {
  bg: string;
  fg: string;
}

@ComponentV2
export struct EnhancedSidebar {
  @Consumer('activeTab') activeTab: string = 'HomeTab';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Consumer('currentRole') currentRole: string = '';
  @Event onTabSelect?: (tab: string) => void;

  getRoleLabel(role: string): string {
    switch (role) {
      case 'admin': return '管理员';
      case 'leader': return '班组长';
      case 'operator': return '操作员';
      case 'inspector': return '质检员';
      default: return role || '未知';
    }
  }

  getRoleBadgeColors(role: string): BadgeColors {
    const map = Colors.roleBadgeMap as Record<string, BadgeColors>;
    return map[role] ?? { bg: Colors.infoBg, fg: Colors.info };
  }

  handleLogout(): void {
    emitter.emit(LOGIN_EXPIRED_EVENT, { data: {} });
  }

  @Builder
  SidebarNavItem(iconActive: Resource, iconInactive: Resource, label: string, tabName: string) {
    Row() {
      if (this.activeTab === tabName) {
        Rect()
          .width(3)
          .height(32)
          .radius(1.5)
          .fill(Colors.primary)
      } else {
        Rect()
          .width(3)
          .height(0)
          .fill(Color.Transparent)
      }
      Image(this.activeTab === tabName ? iconActive : iconInactive)
        .width(24)
        .height(24)
        .margin({ left: 16 })
      Text(label)
        .fontSize(14)
        .fontWeight(this.activeTab === tabName ? 600 : 400)
        .fontColor(this.activeTab === tabName ? Colors.primary : Colors.textSecondary)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(52)
    .backgroundColor(this.activeTab === tabName ? Colors.primaryBg : Color.Transparent)
    .borderRadius(8)
    .margin({ left: 8, right: 8, bottom: 4 })
    .onClick(() => this.onTabSelect?.(tabName))
  }

  build() {
    Column() {
      // === 1. App header ===
      Row() {
        Text('M')
          .fontSize(18)
          .fontWeight(700)
          .fontColor(Colors.onPrimary)
          .width(36)
          .height(36)
          .borderRadius(8)
          .backgroundColor(Colors.primary)
          .textAlign(TextAlign.Center)
        Text('MES 系统')
          .fontSize(16)
          .fontWeight(600)
          .fontColor(Colors.textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Divider()
        .color(Colors.border)
        .width('100%')

      // === 2. User section ===
      Row() {
        Text(this.currentUser.name ? this.currentUser.name.charAt(0) : 'U')
          .fontSize(18)
          .fontWeight(600)
          .fontColor(Colors.onPrimary)
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor(Colors.roleAvatarMap[this.currentRole] ?? Colors.primary)
          .textAlign(TextAlign.Center)
        Column() {
          Text(this.currentUser.name || '用户')
            .fontSize(14)
            .fontWeight(600)
            .fontColor(Colors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Circle({ width: 8, height: 8 })
              .fill(Colors.success)
            Text(this.getRoleLabel(this.currentRole))
              .fontSize(11)
              .fontColor(Colors.textSecondary)
              .margin({ left: 6 })
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(this.getRoleBadgeColors(this.currentRole).bg)
              .borderRadius(4)
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Divider()
        .color(Colors.border)
        .width('100%')

      // === 3. Navigation items ===
      Blank().height(12)
      this.SidebarNavItem($r('app.media.tab_home_active'), $r('app.media.tab_home_inactive'), '工作台', 'HomeTab')
      this.SidebarNavItem($r('app.media.tab_data_active'), $r('app.media.tab_data_inactive'), '数据', 'DataTab')
      this.SidebarNavItem($r('app.media.tab_workorder_active'), $r('app.media.tab_workorder_inactive'), '工单', 'WorkOrderTab')
      this.SidebarNavItem($r('app.media.tab_profile_active'), $r('app.media.tab_profile_inactive'), '我的', 'ProfileTab')

      Divider()
        .color(Colors.border)
        .width('100%')
        .margin({ top: 8 })

      // === 4. Live summary section ===
      Column() {
        Text('产线概览')
          .fontSize(11)
          .fontWeight(600)
          .fontColor(Colors.textMuted)
          .padding({ left: 20, bottom: 8 })

        Row() {
          Circle({ width: 8, height: 8 }).fill(Colors.success)
          Text('运行中: -- 条')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 20, bottom: 4 })

        Row() {
          Circle({ width: 8, height: 8 }).fill(Colors.error)
          Text('异常: -- 条')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 20, bottom: 4 })

        Row() {
          Circle({ width: 8, height: 8 }).fill(Colors.info)
          Text('今日产出: -- 件')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 20 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)

      Divider()
        .color(Colors.border)
        .width('100%')

      // === 5. Quick actions ===
      Column() {
        Row() {
          Image($r('app.media.tab_workorder_active'))
            .width(18)
            .height(18)
          Text('异常上报')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .borderRadius(8)
        .border({ width: 1, color: Colors.border })
        .justifyContent(FlexAlign.Center)
        .margin({ left: 16, right: 16, bottom: 8 })

        Row() {
          Image($r('app.media.tab_home_active'))
            .width(18)
            .height(18)
          Text('扫码操作')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .borderRadius(8)
        .border({ width: 1, color: Colors.border })
        .justifyContent(FlexAlign.Center)
        .margin({ left: 16, right: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Blank()

      // === 6. Footer ===
      Divider()
        .color(Colors.border)
        .width('100%')

      Row() {
        Image($r('app.media.tab_profile_inactive'))
          .width(20)
          .height(20)
        Text('设置')
          .fontSize(13)
          .fontColor(Colors.textSecondary)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 20 })
      .onClick(() => this.onTabSelect?.('ProfileTab'))

      Row() {
        Image($r('app.media.tab_profile_inactive'))
          .width(20)
          .height(20)
          .fillColor(Colors.error)
        Text('退出登录')
          .fontSize(13)
          .fontColor(Colors.error)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 20, bottom: 8 })
      .onClick(() => this.handleLogout())
    }
    .width(240)
    .height('100%')
    .backgroundColor(Colors.surface)
    .border({ width: { right: 1 }, color: Colors.border })
  }
}
