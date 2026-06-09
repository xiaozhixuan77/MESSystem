import { QualityViewModel } from '../ViewModel/QualityViewModel';
import { DashboardChart } from './DashboardChart';
import { TopDefectModel } from '../Model/DashboardModel';
import { FormatUtil } from '@ohos/utils';

@ComponentV2
export struct DashboardView {
  @Local vm: QualityViewModel = new QualityViewModel();
  @Local isRefreshing: boolean = false;
  private hasLoaded: boolean = false;

  aboutToAppear(): void {
    if (!this.hasLoaded) {
      this.hasLoaded = true;
      this.vm.loadDashboard('month');
    }
    this.vm.subscribeDashboard();
  }

  aboutToDisappear(): void {
    this.vm.unsubscribeDashboard();
  }

  getMaxDefectCount(): number {
    const d = this.vm.dashboardData;
    if (d !== null && d.topDefects.length > 0) {
      return d.topDefects[0].count;
    }
    return 0;
  }

  getKpiVal(field: string): string {
    const d = this.vm.dashboardData;
    if (!d) return '--';
    if (field === 'totalInspections') return String(d.totalInspections);
    if (field === 'passRate') return FormatUtil.formatPercent(d.passRate);
    if (field === 'totalNg') return String(d.totalNg);
    if (field === 'pendingCount') return String(d.pendingCount);
    return '--';
  }

  @Builder
  KpiCard(label: string, field: string, trend: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.8)')
        .margin({ bottom: 8 });

      Text(this.getKpiVal(field))
        .fontSize(24)
        .fontWeight(700)
        .fontColor(Color.White)
        .margin({ bottom: 6 });

      Text(trend)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.8)');
    }
    .padding(16)
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(16)
    .layoutWeight(1);
  }

  @Builder
  QualityRing(label: string, pct: number, color: ResourceColor) {
    Column() {
      Stack() {
        Progress({ value: pct, total: 100, type: ProgressType.Ring })
          .width(50).height(50)
          .color(color)
          .backgroundColor('#E8EBF0');

        Text(`${pct}%`)
          .fontSize(13)
          .fontWeight(700)
          .fontColor('#1A1A2E');
      }

      Text(label)
        .fontSize(11)
        .fontColor('#5A5A6E')
        .margin({ top: 8 });
    }
    .padding({ top: 14, bottom: 14, left: 8, right: 8 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1);
  }

  @Builder
  DefectItem(rank: number, name: string, count: number, maxCount: number) {
    Row() {
      Row() {
        Text(`${rank}`)
          .fontSize(11)
          .fontWeight(700)
          .fontColor(rank <= 2 ? Color.White : '#5A5A6E');
      }
      .width(24).height(24)
      .backgroundColor(rank <= 2 ? '#F44336' : '#F5F7FA')
      .borderRadius(12)
      .justifyContent(FlexAlign.Center);

      Column() {
        Text(name)
          .fontSize(13)
          .fontWeight(600)
          .fontColor('#1A1A2E')
          .margin({ bottom: 2 });

        Row() {
          Row() {
          }
          .layoutWeight(count)
          .height('100%')
          .backgroundColor('#F44336')
          .borderRadius(3);
          Row() {
          }
          .layoutWeight(Math.max(1, maxCount - count))
          .height('100%');
        }
        .width('100%')
        .height(6)
        .backgroundColor('#F5F7FA')
        .borderRadius(3);
      }
      .layoutWeight(1)
      .margin({ left: 10 });

      Text(`${count}`)
        .fontSize(13)
        .fontWeight(600)
        .fontColor('#5A5A6E');
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 });
  }

  build() {
    Refresh({ refreshing: this.isRefreshing }) {
      Scroll() {
        Column() {
          // ── 蓝色 Header 区域 ──
          Column() {
            // header-top
            Row() {
              Text('质检看板')
                .fontSize(18)
                .fontWeight(700)
                .fontColor(Color.White)
                .layoutWeight(1)
                .margin({ left: 12 });
            }
            .width('100%')
            .margin({ bottom: 16 });

            // header-date
            Text('2024年1月 · 本月数据概览')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.8)')
              .margin({ bottom: 16 });

            // 2×2 KPI
            Column({ space: 10 }) {
              Row({ space: 10 }) {
                this.KpiCard('抽检总数', 'totalInspections', '↑ 12% 较上月');
                this.KpiCard('一次合格率', 'passRate', '↓ 0.3% 较上月');
              }
              Row({ space: 10 }) {
                this.KpiCard('不良品数', 'totalNg', '↓ 2 较上月');
                this.KpiCard('待抽检工单', 'pendingCount', '实时更新');
              }
            }
            .width('100%');
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor('#1565C0');

          // ── 内容区 ──
          Column() {
            // ── Section 1: 本月计划达成率趋势 ──
            Row() {
              Text('本月计划达成率趋势')
                .fontSize(14)
                .fontWeight(600)
                .fontColor('#1A1A2E');
              Text('查看更多')
                .fontSize(12)
                .fontColor('#1565C0')
                .fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Column() {
              Row() {
                Text('日良品率')
                  .fontSize(14)
                  .fontWeight(600)
                  .fontColor('#1A1A2E');
              }
              .width('100%')
              .margin({ bottom: 16 });

              DashboardChart({
                rates: this.vm.dashboardData !== null
                  ? this.vm.dashboardData.monthlyRates : []
              });
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .width('100%')
            .margin({ bottom: 16 });

            // ── Section 2: 工序合格率 ──
            Text('工序合格率')
              .fontSize(14)
              .fontWeight(600)
              .fontColor('#1A1A2E')
              .margin({ bottom: 12 });

            Row({ space: 10 }) {
              this.QualityRing('SMT贴片', 95, '#4CAF50');
              this.QualityRing('回流焊', 97, '#4CAF50');
              this.QualityRing('功能测试', 90, '#1565C0');
            }
            .width('100%')
            .margin({ bottom: 16 });

            // ── Section 3: 常见不良类型 TOP5 ──
            Text('常见不良类型 TOP5')
              .fontSize(14)
              .fontWeight(600)
              .fontColor('#1A1A2E')
              .margin({ bottom: 12 });

            Column() {
              if (this.vm.dashboardData !== null &&
                  this.vm.dashboardData.topDefects.length > 0) {
                ForEach(this.vm.dashboardData.topDefects,
                  (item: TopDefectModel, index: number) => {
                    if (index > 0) {
                      Row().width('100%').height(1).backgroundColor('#E8EBF0');
                    }
                    this.DefectItem(index + 1, item.name, item.count,
                      this.getMaxDefectCount());
                  },
                  (item: TopDefectModel) => item.name);
              } else {
                Text('暂无不良数据')
                  .fontSize(13).fontColor('#9A9AA8')
                  .padding(16).width('100%').textAlign(TextAlign.Center);
              }
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .width('100%')
            .margin({ bottom: 16 });
          }
          .padding(16)
          .width('100%');
        }
        .width('100%');
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None);
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA')
    .onRefreshing(() => {
      this.isRefreshing = true;
      this.vm.loadDashboard('month').then(() => { this.isRefreshing = false; });
    });
  }
}
