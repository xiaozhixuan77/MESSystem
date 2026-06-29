import { NavigationRail } from '../components/NavigationRail';
import { LoginDestination } from '../destinations/LoginDestination';
import { AdminHomeView, LeaderHomeView, OperatorHomeView, InspectorHomeView } from '@ohos/home';
import { DataTabDestination } from '../destinations/DataTabDestination';
import { WorkOrderTabDestination } from '../destinations/WorkOrderTabDestination';
import { ProfileTabDestination } from '../destinations/ProfileTabDestination';
import { Colors } from '@ohos/utils';

@ComponentV2
export struct TabletLayout {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('showTabBar') showTabBar: boolean = false;
  @Consumer('currentRole') currentRole: string = '';
  @Param targetPage: string = '';
  @Param isReady: boolean = false;
  @Event onTabChange?: (tab: string) => void;
  @Local isRailExpanded: boolean = false;

  @Builder
  PageMap(name: string) {
    if (name === 'LoginPage') {
      LoginDestination()
    } else if (name === 'HomeTab') {
      NavDestination() {
        if (this.currentRole === 'leader') {
          LeaderHomeView()
        } else if (this.currentRole === 'operator') {
          OperatorHomeView()
        } else if (this.currentRole === 'inspector') {
          InspectorHomeView()
        } else {
          AdminHomeView()
        }
      }
      .hideTitleBar(true)
    } else if (name === 'DataTab') {
      DataTabDestination()
    } else if (name === 'WorkOrderTab') {
      WorkOrderTabDestination()
    } else if (name === 'ProfileTab') {
      ProfileTabDestination()
    }
  }

  build() {
    if (!this.isReady) {
      Stack() {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(Colors.primaryLight)
          Text('加载中...')
            .fontSize(14)
            .fontColor(Colors.textMuted)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.background)
    } else {
      Stack() {
        Column() {
          Row() {
            if (this.showTabBar) {
              NavigationRail({
                isExpanded: this.isRailExpanded,
                onToggle: () => { this.isRailExpanded = !this.isRailExpanded },
                onTabSelect: (tab: string) => { this.onTabChange?.(tab) }
              })
            }

            Navigation(this.pageStack) {
              Stack() {}
            }
            .navDestination(this.PageMap)
            .hideTitleBar(true)
            .hideNavBar(true)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .onAppear(() => {
              if (this.targetPage) {
                this.pageStack.replacePath({ name: this.targetPage });
              }
            })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
  }
}
