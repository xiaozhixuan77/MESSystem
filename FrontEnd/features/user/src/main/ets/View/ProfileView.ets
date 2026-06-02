import { UserModel } from '../Model/UserModel';
import { AuthApi, httpClient } from '@ohos/network';
import { promptAction } from '@kit.ArkUI';

class StatItem {
  value: string = '';
  label: string = '';
}

class MenuItemData {
  iconRes: ResourceStr = '';
  label: string = '';
  iconBgColor: ResourceColor = '#E3F2FD';
  textColor: ResourceColor = '#1A1A2E';
  badge?: string;
  onClick: () => void = () => {};
}

class MenuGroupData {
  items: MenuItemData[] = [];
}

@ComponentV2
export struct ProfileView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Local statData: StatItem[] = [];
  @Local menuGroups: MenuGroupData[] = [];

  aboutToAppear(): void {
    this.initStats();
    this.initMenus();
    this.loadUserProfile();
  }

  initStats(): void {
    const item1 = new StatItem();
    item1.value = '128';
    item1.label = '本月工单';
    const item2 = new StatItem();
    item2.value = '98.5%';
    item2.label = '良品率';
    const item3 = new StatItem();
    item3.value = '360h';
    item3.label = '工作时长';
    const arr: StatItem[] = [item1, item2, item3];
    this.statData = arr;
  }

  initMenus(): void {
    // Group 1
    const m1 = new MenuItemData();
    m1.iconRes = $r('app.media.icon_user_blue');
    m1.label = '个人资料';
    m1.iconBgColor = '#E3F2FD';
    m1.onClick = () => { this.showToast('功能开发中'); };

    const m2 = new MenuItemData();
    m2.iconRes = $r('app.media.icon_lock_purple');
    m2.label = '修改密码';
    m2.iconBgColor = '#F3E5F5';
    m2.onClick = () => { this.showToast('功能开发中'); };

    const g1 = new MenuGroupData();
    const g1Items: MenuItemData[] = [m1, m2];
    g1.items = g1Items;

    // Group 2
    const m3 = new MenuItemData();
    m3.iconRes = $r('app.media.icon_check_green');
    m3.label = '我的工作台';
    m3.iconBgColor = '#E8F5E9';
    m3.onClick = () => { this.showToast('功能开发中'); };

    const m4 = new MenuItemData();
    m4.iconRes = $r('app.media.icon_eye_orange');
    m4.label = '消息通知';
    m4.iconBgColor = '#FFF3E0';
    m4.badge = '3';
    m4.onClick = () => { this.showToast('功能开发中'); };

    const g2 = new MenuGroupData();
    const g2Items: MenuItemData[] = [m3, m4];
    g2.items = g2Items;

    // Group 3
    const m5 = new MenuItemData();
    m5.iconRes = $r('app.media.icon_help_blue');
    m5.label = '帮助中心';
    m5.iconBgColor = '#E3F2FD';
    m5.onClick = () => { this.showToast('功能开发中'); };

    const m6 = new MenuItemData();
    m6.iconRes = $r('app.media.icon_document_blue');
    m6.label = '关于系统';
    m6.iconBgColor = '#E3F2FD';
    m6.onClick = () => { this.showToast('功能开发中'); };

    const g3 = new MenuGroupData();
    const g3Items: MenuItemData[] = [m5, m6];
    g3.items = g3Items;

    // Group 4
    const m7 = new MenuItemData();
    m7.iconRes = $r('app.media.icon_logout_red');
    m7.label = '退出登录';
    m7.iconBgColor = '#FFEBEE';
    m7.textColor = '#F44336';
    m7.onClick = () => { this.handleLogout(); };

    const g4 = new MenuGroupData();
    const g4Items: MenuItemData[] = [m7];
    g4.items = g4Items;

    const groups: MenuGroupData[] = [g1, g2, g3, g4];
    this.menuGroups = groups;
  }

  getRoleName(role: string): string {
    if (role === 'admin') { return '管理员'; }
    if (role === 'leader') { return '班组长'; }
    if (role === 'operator') { return '操作员'; }
    if (role === 'inspector') { return '质检员'; }
    return role;
  }

  showToast(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 2000 });
    } catch (_) {}
  }

  async loadUserProfile(): Promise<void> {
    if (this.currentUser.name) {
      return;
    }
    try {
      const result = await AuthApi.getCurrentUser<Record<string, Object>>();
      if (result) {
        this.currentUser.id = (result['id'] as number) ?? 0;
        this.currentUser.employeeNo = (result['employeeNo'] as string) ?? '';
        this.currentUser.name = (result['name'] as string) ?? '';
        this.currentUser.role = (result['role'] as string) ?? '';
        this.currentUser.teamId = (result['teamId'] as number) ?? null;
        this.currentUser.workshopId = (result['workshopId'] as number) ?? null;
        this.currentUser.status = (result['status'] as string) ?? '';
        this.currentUser.avatarUrl = (result['avatarUrl'] as string) ?? '';
      }
    } catch (_) {}
  }

  handleLogout(): void {
    try {
      promptAction.showDialog({
        title: '确认退出',
        message: '退出登录后需要重新登录，确定退出吗？',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '确定', color: '#F44336' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.confirmLogout();
        }
      }).catch(() => {});
    } catch (_) {}
  }

  async confirmLogout(): Promise<void> {
    try {
      await AuthApi.logout();
    } catch (_) {}
    httpClient.clearAuth();
  }

  build() {
    Scroll() {
      Column() {
        // ===== 用户头部 =====
        Column() {
          Row({ space: 16 }) {
            Text(this.currentUser.name ? this.currentUser.name.charAt(0) : '?')
              .width(64).height(64).borderRadius(32)
              .backgroundColor('rgba(255,255,255,0.2)')
              .border({ width: 3, color: 'rgba(255,255,255,0.3)' })
              .fontSize(24).fontWeight(700).fontColor(Color.White)
              .textAlign(TextAlign.Center);

            Column() {
              Text(this.currentUser.name || '未登录')
                .fontSize(18).fontWeight(700).fontColor(Color.White)
                .margin({ bottom: 4 });
              Text(`${this.getRoleName(this.currentUser.role)} · A班组`)
                .fontSize(13).fontColor(Color.White).opacity(0.9)
                .margin({ bottom: 2 });
              Text(`工号：${this.currentUser.employeeNo || '-'}`)
                .fontSize(11).fontColor(Color.White).opacity(0.7);
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1);
          }
          .width('100%').alignItems(VerticalAlign.Center);
        }
        .width('100%')
        .backgroundColor('#0D47A1')
        .padding({ top: 16, left: 16, right: 16, bottom: 24 });

        // ===== 统计卡片 =====
        Row({ space: 10 }) {
          ForEach(this.statData, (item: StatItem) => {
            Column() {
              Text(item.value).fontSize(22).fontWeight(700).fontColor('#1565C0')
                .margin({ bottom: 2 });
              Text(item.label).fontSize(11).fontColor('#5A5A6E');
            }
            .layoutWeight(1).backgroundColor(Color.White).borderRadius(16).padding(14)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
            .alignItems(HorizontalAlign.Center);
          }, (item: StatItem) => item.label);
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 });

        // ===== 菜单分组 =====
        ForEach(this.menuGroups, (group: MenuGroupData, groupIndex: number) => {
          Column() {
            ForEach(group.items, (item: MenuItemData, index: number) => {
              Row({ space: 12 }) {
                Stack() {
                  Image(item.iconRes).width(18).height(18);
                }
                .width(36).height(36).borderRadius(8)
                .backgroundColor(item.iconBgColor)
                .alignContent(Alignment.Center);

                Text(item.label)
                  .fontSize(14).fontWeight(600)
                  .fontColor(item.textColor).layoutWeight(1);

                if (item.badge) {
                  Text(item.badge)
                    .fontSize(10).fontWeight(600).fontColor(Color.White)
                    .backgroundColor('#F44336').borderRadius(10)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 });
                }

                Image($r('app.media.icon_chevron_gray'))
                  .width(16).height(16);
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .border({
                width: { bottom: index === group.items.length - 1 ? 0 : 1 },
                color: '#E8EBF0'
              })
              .onClick(() => { item.onClick(); });
            }, (item: MenuItemData) => item.label);
          }
          .width('100%').backgroundColor(Color.White).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 12 })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' });
        }, (group: MenuGroupData, index: number) => String(index));

        // ===== 版本信息 =====
        Text('鸿蒙MES系统 v2.1.0\n柔性组装制造执行系统')
          .fontSize(12).fontColor('#9A9AA8').textAlign(TextAlign.Center)
          .width('100%').padding({ top: 20, bottom: 100 });
      }
      .width('100%');
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None);
  }
}
