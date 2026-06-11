import { UserViewModel } from '../ViewModel/UserViewModel';
import { UserModel } from '../Model/UserModel';
import { WebSocketService } from '@ohos/network';
import { ErrorState } from '@ohos/uicomponents';

interface RoleBadgeStyle {
  bg: string;
  fg: string;
}

const BADGE_DEFAULT: RoleBadgeStyle = { bg: '#F5F7FA', fg: '#9A9AA8' };
const AVATAR_COLOR_DEFAULT: string = '#9A9AA8';

const ROLE_AVATAR_COLORS: Record<string, string> = {
  'admin': '#EF5350',
  'leader': '#42A5F5',
  'operator': '#66BB6A',
  'inspector': '#FFA726'
};
const ROLE_BADGE_STYLES: Record<string, RoleBadgeStyle> = {
  'admin': { bg: '#FFEBEE', fg: '#F44336' },
  'leader': { bg: '#E3F2FD', fg: '#1565C0' },
  'operator': { bg: '#E8F5E9', fg: '#4CAF50' },
  'inspector': { bg: '#FFF3E0', fg: '#FF9800' }
};
const ROLE_DISPLAY_OPTIONS: string[] = ['班组长', '操作员', '质检员', '管理员'];

@ComponentV2
export struct EmployeeListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local vm: UserViewModel = new UserViewModel();
  private searchTimer: number = 0;
  private readonly USERS_TOPIC: string = '/topic/users';
  private wsSubscribed: boolean = false;

  aboutToAppear(): void {
    this.vm.loadUsers();
    this.subscribeUsers();
  }

  aboutToDisappear(): void {
    this.unsubscribeUsers();
  }

  private onUserStatusChanged = (_msg: Object): void => {
    this.vm.loadUsers();
  };

  private subscribeUsers(): void {
    if (this.wsSubscribed) { return; }
    this.wsSubscribed = true;
    const ws = WebSocketService.getInstance();
    ws.subscribe(this.USERS_TOPIC);
    WebSocketService.addListener(this.USERS_TOPIC, this.onUserStatusChanged);
  }

  private unsubscribeUsers(): void {
    if (!this.wsSubscribed) { return; }
    this.wsSubscribed = false;
    WebSocketService.removeListener(this.USERS_TOPIC, this.onUserStatusChanged);
    WebSocketService.getInstance().unsubscribe(this.USERS_TOPIC);
  }

  getAvatarColor(role: string): string {
    return ROLE_AVATAR_COLORS[role] || AVATAR_COLOR_DEFAULT;
  }

  getBadgeStyle(role: string): RoleBadgeStyle {
    return ROLE_BADGE_STYLES[role] || BADGE_DEFAULT;
  }

  getInitial(name: string): string {
    return name ? name.charAt(0) : '?';
  }

  getSubtitle(user: UserModel): string {
    const parts: string[] = [];
    if (user.employeeNo) {
      parts.push(`工号：${user.employeeNo}`);
    }
    if (user.teamId) {
      parts.push(`班组${user.teamId}`);
    }
    if (user.status) {
      parts.push(user.status);
    }
    return parts.join(' · ') || '—';
  }

  getStatusColor(status: string): string {
    if (status === '在岗' || status === 'active') { return '#4CAF50'; }
    if (status === '离岗' || status === 'disabled' || status === 'offline') { return '#F44336'; }
    return '#9A9AA8';
  }

  @Builder
  RoleTab(label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(500)
      .fontColor(this.vm.activeRoleTab === label ? Color.White : '#5A5A6E')
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(20)
      .backgroundColor(this.vm.activeRoleTab === label ? '#1565C0' : '#F5F7FA')
      .onClick(() => {
        this.vm.onRoleTabChange(label);
      })
  }

  @Builder
  FormDialog() {
    Column() {
      // Title
      Text(this.vm.formMode === 'add' ? '新增人员' : '编辑人员')
        .fontSize(18)
        .fontWeight(700)
        .fontColor('#1A1A2E')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 });

      // Error
      if (this.vm.errorMessage) {
        Text(this.vm.errorMessage)
          .fontSize(13)
          .fontColor('#F44336')
          .padding(10)
          .width('100%')
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
          .margin({ bottom: 12 });
      }

      // Employee No
      Text('工号 *').fontSize(12).fontColor('#5A5A6E').width('100%').margin({ bottom: 6 });
      TextInput({ text: this.vm.formEmployeeNo, placeholder: '请输入工号' })
        .fontSize(14)
        .width('100%')
        .height(44)
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' })
        .padding({ left: 12, right: 12 })
        .enabled(this.vm.formMode === 'add')
        .onChange((v: string) => {
          this.vm.formEmployeeNo = v;
        });
      Blank().height(12);

      // Name
      Text('姓名 *').fontSize(12).fontColor('#5A5A6E').width('100%').margin({ bottom: 6 });
      TextInput({ text: this.vm.formName, placeholder: '请输入姓名' })
        .fontSize(14)
        .width('100%')
        .height(44)
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' })
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => {
          this.vm.formName = v;
        });
      Blank().height(12);

      // Role
      Text('角色 *').fontSize(12).fontColor('#5A5A6E').width('100%').margin({ bottom: 6 });
      Row() {
        Text(this.vm.formRole)
          .fontSize(14)
          .fontColor('#1A1A2E')
          .layoutWeight(1);
        Image($r('app.media.icon_chevron_gray')).width(16).height(16);
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F7FA')
      .borderRadius(12)
      .border({ width: 1, color: '#E8EBF0' })
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .bindMenu(this.RoleMenu);
      Blank().height(12);

      // Password
      Text(this.vm.formMode === 'add' ? '密码 *' : '密码（留空不修改）')
        .fontSize(12).fontColor('#5A5A6E').width('100%').margin({ bottom: 6 });
      TextInput({
        text: this.vm.formPassword,
        placeholder: this.vm.formMode === 'add' ? '请输入密码' : '留空则不修改密码'
      })
        .type(InputType.Password)
        .fontSize(14)
        .width('100%')
        .height(44)
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .border({ width: 1, color: '#E8EBF0' })
        .padding({ left: 12, right: 12 })
        .onChange((v: string) => {
          this.vm.formPassword = v;
        });
      Blank().height(12);

      // Status (edit only)
      if (this.vm.formMode === 'edit') {
        Text('状态').fontSize(12).fontColor('#5A5A6E').width('100%').margin({ bottom: 6 });
        Row({ space: 8 }) {
          Row() {
            Text('在岗')
              .fontSize(13)
              .fontWeight(500)
              .fontColor(this.vm.formStatus === '在岗' ? Color.White : '#5A5A6E')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 });
          }
          .borderRadius(20)
          .backgroundColor(this.vm.formStatus === '在岗' ? '#4CAF50' : '#F5F7FA')
          .onClick(() => {
            this.vm.formStatus = '在岗';
          });

          Row() {
            Text('离岗')
              .fontSize(13)
              .fontWeight(500)
              .fontColor(this.vm.formStatus === '离岗' ? Color.White : '#5A5A6E')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 });
          }
          .borderRadius(20)
          .backgroundColor(this.vm.formStatus === '离岗' ? '#F44336' : '#F5F7FA')
          .onClick(() => {
            this.vm.formStatus = '离岗';
          });
        }
        Blank().height(12);
      }

      // Buttons
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(15)
          .fontWeight(600)
          .fontColor('#1A1A2E')
          .backgroundColor('#F5F7FA')
          .layoutWeight(1)
          .height(46)
          .borderRadius(12)
          .onClick(() => {
            this.vm.closeDialog();
          });

        Button(this.vm.formMode === 'add' ? '添加' : '保存')
          .fontSize(15)
          .fontWeight(600)
          .fontColor(Color.White)
          .backgroundColor(this.vm.isSubmitting ? '#90CAF9' : '#1565C0')
          .layoutWeight(2)
          .height(46)
          .borderRadius(12)
          .enabled(!this.vm.isSubmitting)
          .onClick(async () => {
            if (this.vm.formMode === 'add') {
              await this.vm.createUser();
            } else {
              await this.vm.updateUser();
            }
          });
      }
      .width('100%');

      // Delete button (edit mode only)
      if (this.vm.formMode === 'edit') {
        Blank().height(16);
        Button('删除人员')
          .fontSize(14)
          .fontWeight(500)
          .fontColor('#F44336')
          .backgroundColor(Color.Transparent)
          .width('100%')
          .height(44)
          .borderRadius(12)
          .border({ width: 1, color: '#FFCDD2' })
          .onClick(() => {
            this.vm.closeDialog();
            this.vm.deleteUser(this.vm.editingUserId, this.vm.formName);
          });
      }
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  @Builder
  RoleMenu() {
    Menu() {
      ForEach(ROLE_DISPLAY_OPTIONS, (roleLabel: string) => {
        MenuItem({ content: roleLabel })
          .onClick(() => {
            this.vm.formRole = roleLabel;
          });
      });
    }
  }

  @Builder
  EmployeeCard(user: UserModel) {
    Row({ space: 12 }) {
      // Avatar
      Text(this.getInitial(user.name))
        .fontSize(18)
        .fontWeight(600)
        .fontColor(Color.White)
        .width(48)
        .height(48)
        .borderRadius(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getAvatarColor(user.role));

      // Info
      Column() {
        Row({ space: 6 }) {
          Text(user.name)
            .fontSize(15)
            .fontWeight(600)
            .fontColor('#1A1A2E');
          Circle()
            .width(6).height(6)
            .fill(this.getStatusColor(user.status));
        }
        .margin({ bottom: 2 });
        Text(this.getSubtitle(user))
          .fontSize(12)
          .fontColor('#5A5A6E');
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);

      // Role badge
      Text(this.vm.getRoleLabel(user.role))
        .fontSize(10)
        .fontWeight(600)
        .fontColor(this.getBadgeStyle(user.role).fg)
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(10)
        .backgroundColor(this.getBadgeStyle(user.role).bg);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .margin({ bottom: 10 })
    .onClick(() => {
      this.vm.openEditDialog(user);
    });
  }

  build() {
    Stack() {
      Column() {
        // Header
        Row() {
          Button() {
            Image($r('app.media.icon_arrow_left_gray'))
              .width(20).height(20);
          }
          .width(36).height(36)
          .backgroundColor(Color.Transparent)
          .borderRadius(12)
          .onClick(() => {
            this.pageStack.pop();
          });

          Text('人员管理')
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#1A1A2E')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ left: 12 });

          Button() {
            Image($r('app.media.icon_plus_white'))
              .width(18).height(18);
          }
          .width(36).height(36)
          .backgroundColor('#1565C0')
          .borderRadius(12)
          .onClick(() => {
            this.vm.openAddDialog();
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E8EBF0' });

        // Search bar
        Row() {
          Row() {
            Image($r('app.media.icon_search_gray'))
              .width(18).height(18);
            TextInput({ text: this.vm.keyword, placeholder: '搜索姓名或工号' })
              .fontSize(14)
              .layoutWeight(1)
              .height(40)
              .backgroundColor(Color.Transparent)
              .borderRadius(0)
              .padding({ left: 8 })
              .onChange((v: string) => {
                this.vm.keyword = v;
                clearTimeout(this.searchTimer);
                this.searchTimer = setTimeout(() => {
                  this.vm.loadUsers();
                }, 300);
              });
          }
          .width('100%')
          .height(40)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .border({ width: 1, color: '#E8EBF0' })
          .padding({ left: 12, right: 12 });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 0 });

        // Role tabs
        Row({ space: 8 }) {
          ForEach(this.vm.roleTabs, (tab: string) => {
            this.RoleTab(tab);
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 });

        // Employee list
        if (this.vm.isLoading) {
          Column() {
            LoadingProgress()
              .width(36).height(36).color('#1890ff');
            Text('加载中...').fontSize(13).fontColor('#9A9AA8').margin({ top: 12 });
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else if (this.vm.errorMessage) {
          ErrorState({ showRetry: true, message: this.vm.errorMessage, onRetry: () => { this.vm.loadUsers(); } })
        } else if (this.vm.userList.length === 0) {
          Column() {
            Text('暂无人员数据')
              .fontSize(14).fontColor('#9A9AA8');
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else {
          List() {
            ForEach(this.vm.userList, (user: UserModel) => {
              ListItem() {
                this.EmployeeCard(user);
              }
            }, (user: UserModel) => `${user.id}`);
          }
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 4, bottom: 16 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA');

      // Form dialog overlay
      if (this.vm.showFormDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.5)')
            .onClick(() => {
              this.vm.closeDialog();
            });
          Column() {
            this.FormDialog();
          }
          .onClick(() => {
          });
        }
        .width('100%')
        .height('100%');
      }
    }
    .width('100%')
    .height('100%');
  }
}
