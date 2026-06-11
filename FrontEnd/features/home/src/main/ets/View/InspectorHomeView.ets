import { UserModel } from '@ohos/user';
import { HomeViewModel } from '../ViewModel/HomeViewModel';
import { HomeSummaryModel, InspectionItemModel } from '../Model/HomeSummaryModel';
import { DeepLinkInfo, FormatUtil } from '@ohos/utils';
import { promptAction } from '@kit.ArkUI';
import { LoadingState, ErrorState } from '@ohos/uicomponents';

@ComponentV2
export struct InspectorHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Consumer('deepLink') deepLink: DeepLinkInfo | null = null;
  @Local summary: HomeSummaryModel | null = null;
  @Local isLoading: boolean = true;
  @Local errorMessage: string = '';
  private vm: HomeViewModel = new HomeViewModel();

  aboutToAppear(): void {
    this.vm.subscribeHome(() => {
      this.reload(true);
    });
    this.reload(false);
  }

  private reload(silent: boolean): void {
    if (!silent) {
      this.isLoading = true;
      this.errorMessage = '';
    }
    this.vm.loadHomeData().then((data) => {
      if (data) {
        this.summary = data;
      }
      if (!silent) {
        this.isLoading = false;
      }
    }).catch((e: Error) => {
      if (!silent) {
        this.errorMessage = e.message || '加载失败';
        this.isLoading = false;
      }
    });
  }

  aboutToDisappear(): void {
    this.vm.unsubscribeHome();
  }

  navigateTo(tab: string, page: string, params: Record<string, Object>): void {
    this.deepLink = { targetTab: tab, targetPage: page, params: params };
    this.activeTab = tab;
    this.pageStack.replacePath({ name: tab });
  }

  @Builder
  QuickItem(icon: ResourceStr, label: string) {
    Column() {
      Column() {
        Image(icon).width(16).height(16);
      }
      .width(32).height(32)
      .backgroundColor('rgba(255,255,255,0.95)')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);

      Text(label)
        .fontSize(10)
        .fontColor(Color.White)
        .fontWeight(500)
        .margin({ top: 6 });
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10, left: 4, right: 4 })
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(12)
    .layoutWeight(1)
  }

  build() {
    Column() {
      // Header 蓝色区域
      Column() {
        Row() {
          Column() {
            Text(this.currentUser.name || '李质检员')
              .fontSize(20).fontWeight(700).fontColor(Color.White);
            Text('质检部 · 早班')
              .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
          }

          Stack() {
            Image($r('app.media.icon_bell_white')).width(18).height(18);
            if (this.vm.hasPendingInspections) {
              Circle().width(8).height(8).fill('#F44336').position({ x: 14, y: 2 });
            }
          }
          .width(36).height(36)
          .backgroundColor('rgba(255,255,255,0.15)')
          .borderRadius(12)
          .alignContent(Alignment.Center);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 16 });

        // KPI 指标
        Row({ space: 10 }) {
          Column() {
            Text(`${this.summary?.pendingInspectionCount ?? 0}`)
              .fontSize(22).fontWeight(700).fontColor(Color.White).margin({ bottom: 2 });
            Text('待抽检').fontSize(10).fontColor('rgba(255,255,255,0.8)');
          }
          .padding({ top: 14, bottom: 14, left: 8, right: 8 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1);

          Column() {
            Text(`${this.summary?.todayInspectionDone ?? 0}`)
              .fontSize(22).fontWeight(700).fontColor(Color.White).margin({ bottom: 2 });
            Text('今日完成').fontSize(10).fontColor('rgba(255,255,255,0.8)');
          }
          .padding({ top: 14, bottom: 14, left: 8, right: 8 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1);

          Column() {
            Text(this.summary !== null
              ? FormatUtil.formatPercent(this.summary.todayInspectionPassRate) : '0%')
              .fontSize(22).fontWeight(700).fontColor(Color.White).margin({ bottom: 2 });
            Text('合格率').fontSize(10).fontColor('rgba(255,255,255,0.8)');
          }
          .padding({ top: 14, bottom: 14, left: 8, right: 8 })
          .backgroundColor('rgba(255,255,255,0.12)')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1);
        }
        .width('100%')
        .margin({ bottom: 16 })
        .onAppear(() => {
          console.info('[test:InspectorHomeView] KPI行渲染',
            `pendingInspectionCount=${this.summary?.pendingInspectionCount}`,
            `todayInspectionDone=${this.summary?.todayInspectionDone}`,
            `todayInspectionPassRate=${this.summary?.todayInspectionPassRate}`);
        });

        // 快捷入口
        Row({ space: 8 }) {
          Column() {
            Column() {
              Image($r('app.media.tab_data_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('待检列表')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'InspectionList', {});
          })

          Column() {
            Column() {
              Image($r('app.media.icon_image_blue')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('质检看板')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'Dashboard', {});
          })

          Column() {
            Column() {
              Image($r('app.media.icon_clock_blue')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('质检记录')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('DataTab', 'InspectionList', {});
          })

          Column() {
            Column() {
              Image($r('app.media.tab_workorder_active')).width(16).height(16);
            }
            .width(32).height(32)
            .backgroundColor('rgba(255,255,255,0.95)')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
            Text('质检标准')
              .fontSize(10).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
          }
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10, left: 4, right: 4 })
          .backgroundColor('rgba(255,255,255,0.1)')
          .borderRadius(12)
          .layoutWeight(1)
          .onClick(() => {
            try {
              promptAction.showToast({ message: '功能开发中', duration: 2000 });
            } catch (e) {}
          })
        }
        .width('100%');
      }
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .backgroundColor('#1565C0')
      .width('100%');

      // 内容区域
      if (this.isLoading) {
        LoadingState()
      } else if (this.errorMessage) {
        ErrorState({ showRetry: true, message: this.errorMessage, onRetry: () => { this.reload(false); } })
      } else {
      Column() {
        Scroll() {
          Column() {
            // 待抽检工单
            Column() {
              Row() {
                Text('待抽检工单').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
                Text('全部').fontSize(12).fontColor('#1565C0').fontWeight(500)
                  .onClick(() => {
                    this.navigateTo('DataTab', 'InspectionList', {});
                  });
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 12 });

              if (this.summary !== null) {
                ForEach(this.summary.pendingInspectionItems, (item: InspectionItemModel) => {
                  Column() {
                    Row() {
                      Text('待抽检')
                        .fontSize(10).fontWeight(500).fontColor('#FF9800')
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .borderRadius(10)
                        .backgroundColor('#FFF3E0');
                      Text(item.inspectTime ? `创建 ${item.inspectTime}` : '')
                        .fontSize(11).fontColor('#9A9AA8');
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 8 });

                    Text(item.workOrderCode || '未知工单')
                      .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
                      .margin({ bottom: 4 });

                    Text(`建议抽检 ${item.sampleQty || 0}件`)
                      .fontSize(12).fontColor('#5A5A6E')
                      .margin({ bottom: 12 });

                    Button() {
                      Row({ space: 6 }) {
                        Image($r('app.media.icon_document_white')).width(14).height(14);
                        Text('去抽检').fontSize(13).fontWeight(600).fontColor(Color.White);
                      }
                    }
                    .width('100%').height(36)
                    .backgroundColor('#FF9800')
                    .borderRadius(12)
                    .padding(0)
                    .onClick(() => {
                      this.navigateTo('DataTab', 'InspectionDetail', { 'inspectionId': item.id });
                    });
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .border({ width: { left: 3 }, color: '#FF9800' })
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
                  .margin({ bottom: 10 })
                  .onClick(() => {
                    this.navigateTo('DataTab', 'InspectionDetail', { 'inspectionId': item.id });
                  });
                }, (item: InspectionItemModel) => `insp_${item.id}`);
              }

              if (this.summary !== null &&
                  this.summary.pendingInspectionItems.length === 0) {
                Text('暂无待抽检工单')
                  .fontSize(13).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              }
            }
            .width('100%')
            .margin({ bottom: 20 });

            // 产线运行状态 — 保留占位
            Column() {
              Row() {
                Text('产线运行状态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
                Text('查看全部').fontSize(12).fontColor('#1565C0').fontWeight(500)
                  .onClick(() => {
                    this.navigateTo('DataTab', 'LineList', {});
                  });
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 12 });

              Text('产线运行状态需接入 /lines 接口，暂未实现')
                .fontSize(12).fontColor('#9A9AA8').padding(16).width('100%').textAlign(TextAlign.Center);
            }
            .width('100%');
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          .width('100%');
        }
        .width('100%').height('100%')
        .backgroundColor('#F5F7FA')
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None);
      }
      .layoutWeight(1);
      }
    }
    .width('100%').height('100%');
  }
}
