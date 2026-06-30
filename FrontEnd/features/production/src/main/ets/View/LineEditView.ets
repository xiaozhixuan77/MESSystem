import { ProductionViewModel } from '../ViewModel/ProductionViewModel';
import { PermissionUtil } from '@ohos/utils';

@ComponentV2
export struct LineEditView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('sharedVm') vm: ProductionViewModel = new ProductionViewModel();
  @Consumer('currentRole') currentRole: string = '';
  @Param mode: string = 'add';
  @Param lineId: number = 0;

  aboutToAppear(): void {
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

  build() {
    Column() {
      // Header
      Row() {
        Button('< 返回')
          .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1565C0')
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.pageStack.pop());

        Text(this.mode === 'add' ? '新增产线' : '编辑产线')
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')
          .layoutWeight(1).textAlign(TextAlign.Center);

        if (PermissionUtil.hasPermission(this.getSavePermission(), this.currentRole)) {
          Button('保存')
            .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.vm.isSaving ? '#90CAF9' : '#1565C0')
            .borderRadius(8)
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

        Blank().width(36);
      }
      .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF').border({ width: { bottom: 1 }, color: '#E8EBF0' });

      // Error banner
      if (this.vm.formError) {
        Row() {
          Text(this.vm.formError).fontSize(12).fontColor('#D32F2F').layoutWeight(1);
        }
        .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor('#FFEBEE').margin({ bottom: 8 });
      }

      // Form
      Scroll() {
        Column({ space: 16 }) {
          // Name
          Column() {
            Row() {
              Text('产线名称').fontSize(13).fontColor('#5A5A6E');
              Text(' *').fontSize(13).fontColor('#D32F2F');
            }
            .margin({ bottom: 6 });

            TextInput({ text: this.vm.formName, placeholder: '请输入产线名称' })
              .fontSize(14).fontColor('#1A1A2E')
              .placeholderColor('#9A9AA8')
              .backgroundColor('#F5F7FA')
              .borderRadius(10)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .onChange((value: string) => { this.vm.formName = value; });
          }
          .alignItems(HorizontalAlign.Start);

          // Workshop selector
          Column() {
            Row() {
              Text('所属车间').fontSize(13).fontColor('#5A5A6E');
              Text(' *').fontSize(13).fontColor('#D32F2F');
            }
            .margin({ bottom: 6 });

            Row() {
              Text(this.getSelectedWorkshopName())
                .fontSize(14)
                .fontColor(this.vm.formWorkshopId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1);

              Text('▼').fontSize(11).fontColor('#9A9AA8');
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#F5F7FA').borderRadius(10)
            .bindMenu(this.WorkshopMenuBuilder);
          }
          .alignItems(HorizontalAlign.Start);

          // Process selector
          Column() {
            Row() {
              Text('指定工艺').fontSize(13).fontColor('#5A5A6E');
              Text(' *').fontSize(13).fontColor('#D32F2F');
            }
            .margin({ bottom: 6 });

            Row() {
              Text(this.getSelectedProcessName())
                .fontSize(14)
                .fontColor(this.vm.formCurrentProcessId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1);

              Text('▼').fontSize(11).fontColor('#9A9AA8');
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#F5F7FA').borderRadius(10)
            .bindMenu(this.ProcessMenuBuilder);
          }
          .alignItems(HorizontalAlign.Start);

          // Hint
          if (this.mode === 'add') {
            Text('创建产线时将根据所选工艺的工序步骤自动创建工作站')
              .fontSize(11).fontColor('#9A9AA8').width('100%')
              .padding({ top: 4 });
          }
        }
        .width('100%').padding(16);
      }
      .layoutWeight(1).scrollBar(BarState.Off);

      // Bottom buttons
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#5A5A6E')
          .layoutWeight(1).height(44)
          .backgroundColor('#F5F7FA').borderRadius(12)
          .onClick(() => this.pageStack.pop());

        Button('保存')
          .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
          .layoutWeight(1).height(44)
          .backgroundColor('#1565C0').borderRadius(12)
          .enabled(PermissionUtil.hasPermission(this.getSavePermission(), this.currentRole) && !this.vm.isSaving)
          .onClick(async () => {
            const success = this.mode === 'add'
              ? await this.vm.createLine()
              : await this.vm.updateLine();
            if (success) {
              this.pageStack.pop();
            }
          });
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 16 })
      .backgroundColor('#FFFFFF').border({ width: { top: 1 }, color: '#E8EBF0' });
    }
    .width('100%').height('100%').backgroundColor('#F5F7FA');
  }

  @Builder
  WorkshopMenuBuilder() {
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
  ProcessMenuBuilder() {
    Menu() {
      ForEach(this.vm.processes, (item: Object) => {
        MenuItem({ content: `${(item as Record<string, Object>)['code']} ${(item as Record<string, Object>)['name']}` })
          .onClick(() => {
            this.vm.formCurrentProcessId = (item as Record<string, Object>)['id'] as number;
          });
      });
    }
  }
}
