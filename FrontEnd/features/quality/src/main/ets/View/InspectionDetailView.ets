import { promptAction } from '@kit.ArkUI';
import { QualityViewModel } from '../ViewModel/QualityViewModel';

interface DefectTypeState {
  name: string;
  selected: boolean;
  count: number;
}

interface ParsedDefect {
  name: string;
  count: number;
}

const DEFECT_TYPES: string[] = ['外观缺陷', '尺寸偏差', '功能失效', '装配不良'];

@ComponentV2
export struct InspectionDetailView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local viewModel: QualityViewModel = new QualityViewModel();
  @Local inspectionId: number = 0;
  @Local isPending: boolean = true;

  @Local sampleQty: number = 0;
  @Local sampleGood: number = 0;
  @Local sampleNg: number = 0;
  @Local defectStates: DefectTypeState[] = [];
  @Local defectDescription: string = '';

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    if (param) {
      this.inspectionId = (param['inspectionId'] as number) ?? 0;
    }
    if (this.inspectionId > 0) {
      this.viewModel.loadInspectionDetail(this.inspectionId).then(() => {
        const item = this.viewModel.currentInspection;
        this.isPending = item.status === '待抽检';
        if (this.isPending) {
          this.sampleQty = item.sampleQty || Math.max(1, Math.floor((item.planQty || 0) * 0.07));
          this.defectStates = DEFECT_TYPES.map(name => ({ name, selected: false, count: 0 } as DefectTypeState));
        }
      });
    }
  }

  private get selectedDefectTypes(): string {
    const parts: string[] = [];
    for (const d of this.defectStates) {
      if (d.selected && d.count > 0) {
        parts.push(`${d.name}:${d.count}`);
      }
    }
    return parts.join(',');
  }

  private validateForm(): boolean {
    if (this.sampleQty <= 0) {
      promptAction.showToast({ message: '抽检数量必须大于0' });
      return false;
    }
    if (this.sampleGood + this.sampleNg !== this.sampleQty) {
      promptAction.showToast({ message: '良品数+不良品数必须等于抽检数量' });
      return false;
    }
    return true;
  }

  async submit(): Promise<void> {
    if (!this.validateForm()) return;

    const data: Record<string, Object> = {
      'workOrderId': this.viewModel.currentInspection.workOrderId,
      'sampleQty': this.sampleQty,
      'sampleGood': this.sampleGood,
      'sampleNg': this.sampleNg,
      'defectTypes': this.selectedDefectTypes || '',
      'defectDescription': this.defectDescription,
    };

    try {
      await this.viewModel.submitInspection(this.inspectionId, data);
      promptAction.showToast({ message: '抽检提交成功' });
      this.pageStack.pop();
    } catch (e) {
      // 错误已在 HttpClient 中 toast
    }
  }

  private onSampleQtyChange(v: string): void {
    this.sampleQty = parseInt(v) || 0;
  }

  private onSampleGoodChange(v: string): void {
    this.sampleGood = parseInt(v) || 0;
  }

  private onSampleNgChange(v: string): void {
    this.sampleNg = parseInt(v) || 0;
  }

  private parseDefectTypes(raw: string): ParsedDefect[] {
    if (!raw || raw.trim() === '') return [];
    const result: ParsedDefect[] = [];
    const parts = raw.split(',');
    for (const part of parts) {
      const trimmed = part.trim();
      if (trimmed === '') continue;
      const colonIdx = trimmed.lastIndexOf(':');
      if (colonIdx > 0) {
        const name = trimmed.substring(0, colonIdx).trim();
        const count = parseInt(trimmed.substring(colonIdx + 1).trim()) || 0;
        result.push({ name: name, count: count } as ParsedDefect);
      } else {
        result.push({ name: trimmed, count: 0 } as ParsedDefect);
      }
    }
    return result;
  }

  private getPassRate(): number {
    const qty = this.viewModel.currentInspection.sampleQty;
    if (!qty || qty <= 0) return 0;
    return (this.viewModel.currentInspection.sampleGood || 0) / qty;
  }

  private getInspectorLabel(): string {
    const item = this.viewModel.currentInspection;
    if (item.inspectorName) return item.inspectorName;
    if (item.inspectorId > 0) return `质检员 #${item.inspectorId}`;
    return '—';
  }

  @Builder
  BackButton() {
    Row() {
      Image($r('app.media.icon_arrow_left_gray'))
        .width(20).height(20);
    }
    .width(36).height(36)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.pageStack.pop(); });
  }

  @Builder
  WorkOrderInfoCard() {
    Column() {
      Row() {
        Text(this.viewModel.currentInspection.workOrderCode || `工单 #${this.viewModel.currentInspection.workOrderId}`)
          .fontSize(15).fontWeight(700).fontColor('#1A1A2E');
        Text(this.viewModel.currentInspection.status || '已抽检')
          .fontSize(10).fontWeight(600)
          .fontColor(this.isPending ? '#FF9800' : '#4CAF50')
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor(this.isPending ? '#FFF3E0' : '#E8F5E9')
          .borderRadius(10);
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 });

      if (this.viewModel.currentInspection.productName) {
        Text(`${this.viewModel.currentInspection.productName}${this.viewModel.currentInspection.processName ? ' · ' + this.viewModel.currentInspection.processName : ''}`)
          .fontSize(13).fontColor('#5A5A6E')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 12 });
      }

      Row({ space: 8 }) {
        Column() {
          Text(`${this.viewModel.currentInspection.reportedQtyGood || 0}`)
            .fontSize(16).fontWeight(700).fontColor('#1A1A2E')
            .margin({ bottom: 2 });
          Text('申报良品')
            .fontSize(10).fontColor('#5A5A6E');
        }
        .layoutWeight(1);
        Column() {
          Text(`${this.viewModel.currentInspection.reportedQtyNg || 0}`)
            .fontSize(16).fontWeight(700).fontColor('#1A1A2E')
            .margin({ bottom: 2 });
          Text('申报NG')
            .fontSize(10).fontColor('#5A5A6E');
        }
        .layoutWeight(1);
        Column() {
          Text(`${this.viewModel.currentInspection.sampleQty || this.sampleQty}`)
            .fontSize(16).fontWeight(700).fontColor('#1565C0')
            .margin({ bottom: 2 });
          Text('抽检数量')
            .fontSize(10).fontColor('#5A5A6E');
        }
        .layoutWeight(1);
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F7FA')
      .borderRadius(12);
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
  }

  @Builder
  SampleQtyInput() {
    Column() {
      Text('抽检数量')
        .fontSize(13).fontWeight(500).fontColor('#1A1A2E')
        .margin({ bottom: 8 });
      Row() {
        Text('(建议按批量5%~10%)')
          .fontSize(11).fontColor('#9A9AA8').fontWeight(400);
      }
      .margin({ bottom: 8 });

      TextInput({ text: this.sampleQty > 0 ? `${this.sampleQty}` : '', placeholder: '请输入抽检数量' })
        .type(InputType.Number)
        .height(48)
        .fontSize(15).fontColor('#1A1A2E').fontWeight(600)
        .placeholderColor('#9A9AA8')
        .backgroundColor('#F5F7FA')
        .borderRadius(12)
        .border({ width: 1.5, color: '#E8EBF0' })
        .textAlign(TextAlign.Center)
        .onChange((v: string) => { this.onSampleQtyChange(v); });

      Text('件')
        .fontSize(12).fontColor('#5A5A6E')
        .margin({ top: 4 });
    }
    .width('100%').alignItems(HorizontalAlign.Center);
  }

  @Builder
  SampleResultInput() {
    Column() {
      Text('抽检结果')
        .fontSize(13).fontWeight(500).fontColor('#1A1A2E')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start);

      Row({ space: 12 }) {
        Column() {
          TextInput({ text: this.sampleGood > 0 ? `${this.sampleGood}` : '', placeholder: '0' })
            .type(InputType.Number)
            .height(48)
            .fontSize(15).fontColor('#1A1A2E').fontWeight(600)
            .placeholderColor('#9A9AA8')
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1.5, color: '#E8EBF0' })
            .textAlign(TextAlign.Center)
            .onChange((v: string) => { this.onSampleGoodChange(v); });
          Text('良品')
            .fontSize(12).fontColor('#5A5A6E')
            .margin({ top: 4 });
        }
        .layoutWeight(1);

        Column() {
          TextInput({ text: this.sampleNg > 0 ? `${this.sampleNg}` : '', placeholder: '0' })
            .type(InputType.Number)
            .height(48)
            .fontSize(15).fontColor('#F44336').fontWeight(600)
            .placeholderColor('#9A9AA8')
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1.5, color: '#E8EBF0' })
            .textAlign(TextAlign.Center)
            .onChange((v: string) => { this.onSampleNgChange(v); });
          Text('不良')
            .fontSize(12).fontColor('#5A5A6E')
            .margin({ top: 4 });
        }
        .layoutWeight(1);
      }
      .width('100%');
    }
    .width('100%');
  }

  @Builder
  DefectTypeItem(index: number) {
    Row({ space: 10 }) {
      Row() {
        if (this.defectStates[index].selected) {
          Text('✓')
            .fontSize(12).fontColor(Color.White).fontWeight(700);
        }
      }
      .width(20).height(20)
      .borderRadius(4)
      .border({ width: 2, color: this.defectStates[index].selected ? '#1565C0' : '#E8EBF0' })
      .backgroundColor(this.defectStates[index].selected ? '#1565C0' : Color.Transparent)
      .justifyContent(FlexAlign.Center);

      Text(this.defectStates[index].name)
        .fontSize(14).fontColor('#1A1A2E')
        .layoutWeight(1);

      Row({ space: 8 }) {
        Text('−')
          .fontSize(16).fontColor('#1A1A2E')
          .width(28).height(28)
          .borderRadius(8)
          .border({ width: 1.5, color: '#E8EBF0' })
          .backgroundColor(Color.White)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            const current = this.defectStates[index];
            if (current.count > 0) {
              const newStates = [...this.defectStates];
              const newCount = current.count - 1;
              newStates[index] = {
                name: current.name,
                selected: newCount > 0,
                count: newCount
              };
              this.defectStates = newStates;
            }
          });

        Text(`${this.defectStates[index].count}`)
          .fontSize(15).fontWeight(600).fontColor('#1A1A2E')
          .width(32).textAlign(TextAlign.Center);

        Text('+')
          .fontSize(16).fontColor('#1A1A2E')
          .width(28).height(28)
          .borderRadius(8)
          .border({ width: 1.5, color: '#E8EBF0' })
          .backgroundColor(Color.White)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            const current = this.defectStates[index];
            const newStates = [...this.defectStates];
            newStates[index] = {
              name: current.name,
              selected: true,
              count: current.count + 1
            };
            this.defectStates = newStates;
          });
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.defectStates[index].selected ? '#E3F2FD' : '#F5F7FA')
    .borderRadius(12)
    .border({ width: 2, color: this.defectStates[index].selected ? '#1565C0' : 'transparent' });
  }

  @Builder
  DefectTypeList() {
    Column() {
      Text('不良类型')
        .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start);

      Column({ space: 8 }) {
        ForEach(DEFECT_TYPES, (name: string, index: number) => {
          this.DefectTypeItem(index);
        }, (name: string) => name);
      }
      .width('100%');
    }
    .width('100%');
  }

  @Builder
  InspectionForm() {
    Column({ space: 16 }) {
      this.WorkOrderInfoCard();

      // 抽检结果
      Column() {
        this.SampleQtyInput();
        Blank().height(20);
        this.SampleResultInput();
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });

      // 不良类型
      Column() {
        this.DefectTypeList();
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });

      // 备注说明
      Column() {
        Text('备注说明')
          .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
          .margin({ bottom: 12 })
          .alignSelf(ItemAlign.Start);

        TextArea({ placeholder: '请输入不良描述或其他备注信息...', text: this.defectDescription })
          .height(80)
          .fontSize(14).fontColor('#1A1A2E')
          .placeholderColor('#9A9AA8')
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .border({ width: 1.5, color: '#E8EBF0' })
          .padding(12)
          .onChange((v: string) => { this.defectDescription = v; });
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
    }
    .width('100%');
  }

  @Builder
  WorkOrderContextCard() {
    Column() {
      Row() {
        Text(this.viewModel.currentInspection.workOrderCode || `工单 #${this.viewModel.currentInspection.workOrderId}`)
          .fontSize(16).fontWeight(700).fontColor('#1A1A2E');
        this.ConclusionBadge(this.viewModel.currentInspection.conclusion);
      }
      .width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 10 });

      if (this.viewModel.currentInspection.productName) {
        Text(`${this.viewModel.currentInspection.productName}${this.viewModel.currentInspection.processName ? ' · ' + this.viewModel.currentInspection.processName : ''}`)
          .fontSize(13).fontColor('#5A5A6E').margin({ bottom: 14 });
      }

      Row({ space: 0 }) {
        Column() {
          Text(`${this.viewModel.currentInspection.planQty || 0}`)
            .fontSize(18).fontWeight(700).fontColor('#1A1A2E').margin({ bottom: 4 });
          Text('计划产量').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
        Column() {
          Text(`${this.viewModel.currentInspection.reportedQtyGood || 0}`)
            .fontSize(18).fontWeight(700).fontColor('#4CAF50').margin({ bottom: 4 });
          Text('申报良品').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
        Column() {
          Text(`${this.viewModel.currentInspection.reportedQtyNg || 0}`)
            .fontSize(18).fontWeight(700).fontColor('#F44336').margin({ bottom: 4 });
          Text('申报不良').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
      }
      .width('100%').padding({ top: 12, bottom: 12, left: 8, right: 8 })
      .backgroundColor('#F5F7FA').borderRadius(12);
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
  }

  @Builder
  ConclusionBanner() {
    Column() {
      Stack() {
        Progress({ value: this.getPassRate() * 100, total: 100, type: ProgressType.Ring })
          .width(64).height(64)
          .color(this.viewModel.currentInspection.conclusion === '合格' ? '#4CAF50' : '#F44336')
          .backgroundColor(this.viewModel.currentInspection.conclusion === '合格' ? '#C8E6C9' : '#FFCDD2');
        Text(`${(this.getPassRate() * 100).toFixed(1)}%`)
          .fontSize(16).fontWeight(700)
          .fontColor(this.viewModel.currentInspection.conclusion === '合格' ? '#2E7D32' : '#C62828');
      }
      .margin({ bottom: 12 });

      Text(this.viewModel.currentInspection.conclusion === '合格' ? '合格' : '不合格')
        .fontSize(20).fontWeight(700)
        .fontColor(this.viewModel.currentInspection.conclusion === '合格' ? '#2E7D32' : '#C62828')
        .margin({ bottom: 8 });

      Text(`抽检时间：${this.viewModel.currentInspection.inspectTime || '—'}`)
        .fontSize(12).fontColor('#5A5A6E').margin({ bottom: 4 });
      Text(`质检员：${this.getInspectorLabel()}`)
        .fontSize(12).fontColor('#5A5A6E');
    }
    .width('100%').padding(20).alignItems(HorizontalAlign.Center)
    .backgroundColor(this.viewModel.currentInspection.conclusion === '合格' ? '#E8F5E9' : '#FFEBEE')
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
  }

  @Builder
  SampleStatsCard() {
    Column() {
      Text('抽检结果')
        .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 14 }).alignSelf(ItemAlign.Start);

      Row({ space: 0 }) {
        Column() {
          Text(`${this.viewModel.currentInspection.sampleQty || 0}`)
            .fontSize(22).fontWeight(700).fontColor('#1565C0').margin({ bottom: 4 });
          Text('抽检数量').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
        Column() {
          Text(`${this.viewModel.currentInspection.sampleGood || 0}`)
            .fontSize(22).fontWeight(700).fontColor('#4CAF50').margin({ bottom: 4 });
          Text('良品数').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
        Column() {
          Text(`${this.viewModel.currentInspection.sampleNg || 0}`)
            .fontSize(22).fontWeight(700).fontColor('#F44336').margin({ bottom: 4 });
          Text('不良品数').fontSize(11).fontColor('#9A9AA8');
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Center);
      }
      .width('100%');
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
  }

  @Builder
  DefectAnalysisCard() {
    Column() {
      Text('不良分析')
        .fontSize(14).fontWeight(600).fontColor('#1A1A2E')
        .margin({ bottom: 14 }).alignSelf(ItemAlign.Start);

      if (this.viewModel.currentInspection.defectTypes &&
          this.viewModel.currentInspection.defectTypes.trim() !== '') {
        Column({ space: 0 }) {
          ForEach(this.parseDefectTypes(this.viewModel.currentInspection.defectTypes),
            (item: ParsedDefect, index: number) => {
              this.DefectAnalysisItem(index + 1, item.name, item.count, this.viewModel.currentInspection.sampleNg || 1);
            }, (item: ParsedDefect) => item.name);
        }
        .width('100%').padding(12).backgroundColor('#F5F7FA').borderRadius(12);

        if (this.viewModel.currentInspection.defectDescription) {
          Text(this.viewModel.currentInspection.defectDescription)
            .fontSize(13).fontColor('#5A5A6E').padding(12).margin({ top: 8 })
            .width('100%').backgroundColor('#FFF8E1').borderRadius(10);
        }
      } else {
        Row() {
          Text('✓ 无不良品记录')
            .fontSize(13).fontColor('#4CAF50').fontWeight(500);
        }
        .width('100%').padding(16).justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F7FA').borderRadius(12);
      }
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 });
  }

  @Builder
  DefectAnalysisItem(rank: number, name: string, count: number, maxCount: number) {
    Row() {
      Row() {
        Text(`${rank}`)
          .fontSize(11).fontWeight(700)
          .fontColor(rank <= 2 ? Color.White : '#5A5A6E');
      }
      .width(24).height(24)
      .backgroundColor(rank <= 2 ? '#F44336' : '#F5F7FA')
      .borderRadius(12).justifyContent(FlexAlign.Center);

      Column() {
        Text(name).fontSize(13).fontWeight(600).fontColor('#1A1A2E').margin({ bottom: 2 });
        Row() {
          Row() {}.layoutWeight(count).height('100%')
            .backgroundColor('#F44336').borderRadius(3);
          Row() {}.layoutWeight(Math.max(1, maxCount - count)).height('100%');
        }
        .width('100%').height(6).backgroundColor('#F5F7FA').borderRadius(3);
      }
      .layoutWeight(1).margin({ left: 10 });

      Text(`${count}`).fontSize(13).fontWeight(600).fontColor('#5A5A6E');
    }
    .width('100%').padding({ top: 10, bottom: 10 });
  }

  @Builder
  ViewOnlyContent() {
    Column({ space: 16 }) {
      this.WorkOrderContextCard();
      this.ConclusionBanner();
      this.SampleStatsCard();
      this.DefectAnalysisCard();
    }
    .width('100%');
  }

  @Builder
  ConclusionBadge(conclusion: string) {
    Text(conclusion || '—')
      .fontSize(11).fontWeight(600)
      .fontColor(conclusion === '合格' ? '#4CAF50' : (conclusion === '不合格' ? '#F44336' : '#9A9AA8'))
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .backgroundColor(conclusion === '合格' ? '#E8F5E9' : (conclusion === '不合格' ? '#FFEBEE' : '#F5F7FA'))
      .borderRadius(8);
  }

  @Builder
  DetailStatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(14).fontWeight(700).fontColor('#1A1A2E')
        .margin({ bottom: 2 });
      Text(label)
        .fontSize(10).fontColor('#5A5A6E');
    }
    .layoutWeight(1);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row({ space: 12 }) {
        this.BackButton();
        Text('抽检详情')
          .fontSize(18).fontWeight(700).fontColor('#1A1A2E')
          .layoutWeight(1);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // 内容区
      if (this.viewModel.isLoading) {
        Row() {
          LoadingProgress().width(40).height(40);
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
      } else if (this.isPending) {
        Scroll() {
          this.InspectionForm();
        }
        .width('100%').layoutWeight(1)
        .padding(16)
        .scrollBar(BarState.Off)
        .backgroundColor('#F5F7FA');
      } else {
        Scroll() {
          this.ViewOnlyContent();
        }
        .width('100%').layoutWeight(1)
        .padding(16)
        .scrollBar(BarState.Off)
        .backgroundColor('#F5F7FA');
      }

      // 底部提交按钮（仅待抽检模式）
      if (this.isPending && !this.viewModel.isLoading) {
        Row() {
          Button() {
            if (this.viewModel.submitLoading) {
              LoadingProgress().width(20).height(20).color(Color.White);
            } else {
              Row({ space: 6 }) {
                Text('✓')
                  .fontSize(16).fontColor(Color.White).fontWeight(700);
                Text('提交抽检结果')
                  .fontSize(15).fontWeight(600).fontColor(Color.White);
              }
            }
          }
          .width('100%').height(48)
          .backgroundColor('#1565C0')
          .borderRadius(12)
          .enabled(!this.viewModel.submitLoading)
          .onClick(() => { this.submit(); });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 28 })
        .backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#E8EBF0' });
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7FA');
  }
}
