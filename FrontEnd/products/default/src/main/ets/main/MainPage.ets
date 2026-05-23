import { LeaderHomeView, OperatorHomeView, InspectorHomeView, AdminHomeView } from '@ohos/home';
import { BreakpointUtil } from '@ohos/common';
import { window } from '@kit.ArkUI';
import { PhoneMainLayout } from '../product/phone/PhoneMainLayout';
import { TabletMainLayout } from '../product/tablet/TabletMainLayout';
import { FoldableMainLayout } from '../product/foldable/FoldableMainLayout';

@ComponentV2
export struct MainPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Local currentBreakpoint: string = 'sm';

  async aboutToAppear(): Promise<void> {
    try {
      const win = await window.getLastWindow(getContext(this));
      const rect = win.getWindowProperties().windowRect;
      this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(rect.width));

      win.on('windowSizeChange', (size: window.Size) => {
        this.currentBreakpoint = BreakpointUtil.getBreakpoint(px2vp(size.width));
      });
    } catch (e) {
      this.currentBreakpoint = 'sm';
    }
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.currentBreakpoint === 'sm') {
          PhoneMainLayout();
        } else if (this.currentBreakpoint === 'md') {
          TabletMainLayout();
        } else {
          FoldableMainLayout();
        }
      }
    }
  }
}
