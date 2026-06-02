import { UserModel } from '@ohos/user';

interface MetaItem {
  label: string;
  value: string;
}

class TodoItem {
  type: string = '';
  typeLabel: string = '';
  time: string = '';
  title: string = '';
  desc: string = '';
  meta: MetaItem[] = [];
}

class LineStatusItem {
  name: string = '';
  status: string = '';
  stats: MetaItem[] = [];
}

@ComponentV2
export struct LeaderHomeView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('activeTab') activeTab: string = '';
  @Consumer('currentUser') currentUser: UserModel = new UserModel();
  @Local todos: TodoItem[] = [];
  @Local lines: LineStatusItem[] = [];

  aboutToAppear(): void {
    const todo1 = new TodoItem();
    todo1.type = 'exception';
    todo1.typeLabel = '异常待处理';
    todo1.time = '10分钟前';
    todo1.title = '产线L3工作站传送带故障';
    todo1.desc = '3号柔性产线第5工作站检测到传送带速度异常';
    const meta1: MetaItem[] = [
      { label: '产线', value: 'L3柔性线' } as MetaItem,
      { label: '工位', value: 'WS-05' } as MetaItem
    ];
    todo1.meta = meta1;

    const todo2 = new TodoItem();
    todo2.type = 'dispatch';
    todo2.typeLabel = '待派工';
    todo2.time = '30分钟前';
    todo2.title = 'WO-2024-0118 控制器组装工单';
    todo2.desc = '新产品试产批次，需指派熟练操作员';
    const meta2: MetaItem[] = [
      { label: '数量', value: '200件' } as MetaItem,
      { label: '计划', value: '今天 14:00' } as MetaItem
    ];
    todo2.meta = meta2;

    this.todos = [todo1, todo2];

    const line1 = new LineStatusItem();
    line1.name = 'L1 柔性线';
    line1.status = 'running';
    const s1: MetaItem[] = [
      { label: '当前工单', value: 'WO-0116' } as MetaItem,
      { label: '完成进度', value: '78%' } as MetaItem,
      { label: '良品率', value: '98.5%' } as MetaItem
    ];
    line1.stats = s1;

    const line2 = new LineStatusItem();
    line2.name = 'L2 柔性线';
    line2.status = 'running';
    const s2: MetaItem[] = [
      { label: '当前工单', value: 'WO-0115' } as MetaItem,
      { label: '完成进度', value: '45%' } as MetaItem,
      { label: '良品率', value: '97.2%' } as MetaItem
    ];
    line2.stats = s2;

    const line3 = new LineStatusItem();
    line3.name = 'L3 柔性线';
    line3.status = 'error';
    const s3: MetaItem[] = [
      { label: '当前工单', value: 'WO-0114' } as MetaItem,
      { label: '状态', value: '故障' } as MetaItem,
      { label: '故障点', value: 'WS-05' } as MetaItem
    ];
    line3.stats = s3;

    const line4 = new LineStatusItem();
    line4.name = 'L4 柔性线';
    line4.status = 'idle';
    const s4: MetaItem[] = [
      { label: '当前工单', value: '—' } as MetaItem,
      { label: '状态', value: '待机' } as MetaItem,
      { label: '上次运行', value: '2h前' } as MetaItem
    ];
    line4.stats = s4;

    this.lines = [line1, line2, line3, line4];
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
        .fontSize(11)
        .fontColor(Color.White)
        .fontWeight(500)
        .margin({ top: 6 });
    }
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 12, bottom: 12, left: 4, right: 4 })
    .backgroundColor('rgba(255,255,255,0.12)')
    .borderRadius(12)
    .layoutWeight(1)
  }

  build() {
    Scroll() {
      Column() {
        // Header 蓝色区域
        Column() {
          Row() {
            Column() {
              Text(this.currentUser.name || '张班长')
                .fontSize(20).fontWeight(700).fontColor(Color.White);
              Text('A班组组长 · 早班')
                .fontSize(12).fontColor('rgba(255,255,255,0.85)').margin({ top: 2 });
            }

            Stack() {
              Image($r('app.media.icon_bell_white')).width(18).height(18);
              Circle().width(8).height(8).fill('#F44336').position({ x: 14, y: 2 });
            }
            .width(36).height(36)
            .backgroundColor('rgba(255,255,255,0.15)')
            .borderRadius(12)
            .alignContent(Alignment.Center);
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 20 });

          // 快捷入口
          Row({ space: 8 }) {
            this.QuickItem($r('app.media.tab_data_active'), '基础数据');

            Column() {
              Column() {
                Image($r('app.media.tab_workorder_active')).width(16).height(16);
              }
              .width(32).height(32)
              .backgroundColor('rgba(255,255,255,0.95)')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              Text('工单')
                .fontSize(11).fontColor(Color.White).fontWeight(500).margin({ top: 6 });
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 12, bottom: 12, left: 4, right: 4 })
            .backgroundColor('rgba(255,255,255,0.12)')
            .borderRadius(12)
            .layoutWeight(1)
            .onClick(() => {
              this.activeTab = 'WorkOrderTab';
              this.pageStack.replacePath({ name: 'WorkOrderTab' });
            })

            this.QuickItem($r('app.media.icon_image_blue'), '质检看板');
            this.QuickItem($r('app.media.icon_clock_blue'), '历史记录');
          }
          .width('100%');
        }
        .padding({ left: 20, right: 20, top: 48, bottom: 20 })
        .backgroundColor('#1565C0');

        // 内容区域
        Column() {
          // 待办事项
          Column() {
            Row() {
              Text('待办事项').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('查看全部').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            ForEach(this.todos, (todo: TodoItem) => {
              Column() {
                Row() {
                  Row() {
                    Image(todo.type === 'exception' ? $r('app.media.icon_alert_red') : $r('app.media.icon_briefcase_blue'))
                      .width(10).height(10);
                    Text(todo.typeLabel)
                      .fontSize(11).fontWeight(500)
                      .fontColor(todo.type === 'exception' ? '#F44336' : '#1565C0');
                  }
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(12)
                  .backgroundColor(todo.type === 'exception' ? '#FFEBEE' : '#E3F2FD');

                  Text(todo.time).fontSize(11).fontColor('#9A9AA8');
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .margin({ bottom: 8 });

                Text(todo.title)
                  .fontSize(14).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 4 });

                Text(todo.desc)
                  .fontSize(12).fontColor('#5A5A6E').lineHeight(20).margin({ bottom: 10 });

                Row({ space: 12 }) {
                  ForEach(todo.meta, (item: MetaItem) => {
                    Text() {
                      Span(item.label + '：').fontSize(11).fontColor('#5A5A6E');
                      Span(item.value).fontSize(11).fontColor('#1A1A2E').fontWeight(600);
                    }
                  }, (item: MetaItem) => item.label)
                }
                .width('100%')
                .padding({ top: 10 })
                .border({ width: { top: 1 }, color: '#E8EBF0' });
              }
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .border({ width: { left: 3 }, color: todo.type === 'exception' ? '#F44336' : '#1565C0' })
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' })
              .margin({ bottom: 10 });
            }, (todo: TodoItem) => todo.title);
          }
          .width('100%')
          .margin({ bottom: 20 });

          // 产线状态
          Column() {
            Row() {
              Text('产线状态').fontSize(15).fontWeight(600).fontColor('#1A1A2E');
              Text('全部产线').fontSize(12).fontColor('#1565C0').fontWeight(500);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 12 });

            Grid() {
              ForEach(this.lines, (line: LineStatusItem) => {
                GridItem() {
                  Column() {
                    Row() {
                      Text(line.name).fontSize(13).fontWeight(600).fontColor('#1A1A2E');
                      Circle().width(8).height(8)
                        .fill(line.status === 'running' ? '#4CAF50' : (line.status === 'error' ? '#F44336' : '#9A9AA8'));
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 10 });

                    Column({ space: 4 }) {
                      ForEach(line.stats, (stat: MetaItem) => {
                        Row() {
                          Text(stat.label).fontSize(11).fontColor('#5A5A6E');
                          Text(stat.value)
                            .fontSize(11)
                            .fontColor(stat.label === '状态' && stat.value === '故障' ? '#F44336' : '#1A1A2E')
                            .fontWeight(500);
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.SpaceBetween);
                      }, (stat: MetaItem) => stat.label)
                    }
                  }
                  .padding(14)
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)' });
                }
              }, (line: LineStatusItem) => line.name)
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(10).columnsGap(10)
            .width('100%');
          }
          .width('100%');
        }
        .padding(16)
        .width('100%');
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
