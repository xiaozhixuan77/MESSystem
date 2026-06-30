import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { PermissionUtil } from '@ohos/utils';

@ComponentV2
export struct LineEditView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('sharedVm') vm: ProductionViewModel = new ProductionViewModel();
  @Consumer('currentRole') currentRole: string = '';
  @Local mode: string = 'add';
  @Local lineId: number = 0;

  aboutToAppear(): void {
    const navInfo = this.queryNavDestinationInfo();
    const param = navInfo?.param as Record<string, Object>;
    this.mode = (param?.['mode'] as string) ?? 'add';
    this.lineId = (param?.['lineId'] as number) ?? 0;

    this.vm.loadWorkshops();
    this.vm.loadProcesses();
    if (this.mode === 'edit' && this.lineId > 0) {
      const line = this.vm.lines.find(l => l.id === this.lineId);
      if (line) {
        this.vm.openEditForm(line);
      }
    } else {
      this.vm.openAddForm();
    }
  }

  private getSavePermission(): string {
    return this.mode === 'add' ? 'line.create' : 'line.update';
  }

  private getSelectedWorkshopName(): string {
    const w = this.vm.workshops.find(ws => ws.id === this.vm.formWorkshopId);
    return w ? w.name : '请选择车间';
  }

  private getSelectedProcessName(): string {
    const p = this.vm.processes.find(ps => ps.id === this.vm.formCurrentProcessId);
    return p ? `${p.code} ${p.name}` : '请选择工艺';
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(600)
      .fontColor('#1A1A2E')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#E8EBF0' })
      .width('100%')
      .margin({ bottom: 16 })
  }

  @Builder
  FormLabel(label: string, required: boolean) {
    Text(required ? `${label} *` : label)
      .fontSize(12)
      .fontColor('#5A5A6E')
      .margin({ bottom: 6 })
  }

  @Builder
  WorkshopMenu() {
    Menu() {
      ForEach(this.vm.workshops, (item: Object) => {
        MenuItem({ content: (item as Record<string, Object>)['name'] as string })
          .onClick(() => {
            this.vm.formWorkshopId = (item as Record<string, Object>)['id'] as number;
          });
      });
    }
  }

  @Builder
  ProcessMenu() {
    Menu() {
      ForEach(this.vm.processes, (item: Object) => {
        MenuItem({ content: `${(item as Record<string, Object>)['code']} ${(item as Record<string, Object>)['name']}` })
          .onClick(() => {
            this.vm.formCurrentProcessId = (item as Record<string, Object>)['id'] as number;
          });
      });
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Image($r('app.media.icon_arrow_left_gray'))
            .width(20).height(20).fillColor('#1A1A2E');
        }
        .width(36).height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(12)
        .onClick(() => this.pageStack.pop());

        Text(this.mode === 'add' ? '新增产线' : '编辑产线')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#1A1A2E')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ left: 12 });

        Blank().width(36);
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // Error banner
      if (this.vm.formError) {
        Text(this.vm.formError)
          .fontSize(14)
          .fontColor('#F44336')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
          .width('100%')
          .backgroundColor('#FFF0F0');
      }

      // Content
      Scroll() {
        Column({ space: 12 }) {
          // Section: 基本信息
          Column() {
            this.SectionTitle('基本信息');

            this.FormLabel('产线名称', true);
            TextInput({ text: this.vm.formName, placeholder: '请输入产线名称' })
              .fontSize(14)
              .fontColor('#1A1A2E')
              .placeholderColor('#9A9AA8')
              .width('100%')
              .height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => { this.vm.formName = value; });
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF');

          // Section: 关联设置
          Column() {
            this.SectionTitle('关联设置');

            this.FormLabel('所属车间', true);
            Row() {
              Text(this.getSelectedWorkshopName())
                .fontSize(14)
                .fontColor(this.vm.formWorkshopId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('100%')
            .height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu(this.WorkshopMenu);

            Blank().height(12);

            this.FormLabel('指定工艺', true);
            Row() {
              Text(this.getSelectedProcessName())
                .fontSize(14)
                .fontColor(this.vm.formCurrentProcessId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('100%')
            .height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu(this.ProcessMenu);

            if (this.mode === 'add') {
              Blank().height(12);
              Text('创建产线时将根据所选工艺的工序步骤自动创建工作站')
                .fontSize(12)
                .fontColor('#1565C0')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#E3F2FD')
                .width('100%');
            }
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF');

          Blank().height(80);
        }
        .padding(16);
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F7FA');

      // Bottom action bar
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(15)
          .fontWeight(600)
          .fontColor('#1A1A2E')
          .backgroundColor('#F5F7FA')
          .layoutWeight(1)
          .height(46)
          .borderRadius(12)
          .onClick(() => this.pageStack.pop());

        if (PermissionUtil.hasPermission(this.getSavePermission(), this.currentRole)) {
          Button('保存')
            .fontSize(15)
            .fontWeight(600)
            .fontColor('#FFFFFF')
            .backgroundColor(this.vm.isSaving ? '#90CAF9' : '#1565C0')
            .layoutWeight(2)
            .height(46)
            .borderRadius(12)
            .enabled(!this.vm.isSaving)
            .onClick(async () => {
              const success = this.mode === 'add'
                ? await this.vm.createLine()
                : await this.vm.updateLine();
              if (success) {
                this.pageStack.pop();
              }
            });
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 28 })
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#E8EBF0' });
    }
    .width('100%')
    .height('100%');
  }
}
