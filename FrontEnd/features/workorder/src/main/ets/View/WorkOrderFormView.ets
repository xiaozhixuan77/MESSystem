import { WorkOrderViewModel } from '../ViewModel/WorkOrderViewModel';
import { ProductModel } from '../Model/ProductModel';
import { WorkshopModel } from '../Model/WorkshopModel';
import { LineModel } from '../Model/LineModel';
import { ProcessStepModel } from '../Model/ProcessStepModel';

@ComponentV2
export struct WorkOrderFormView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Param mode: string = 'add';
  @Param workOrderId: number = 0;
  @Param sourceWorkOrderId: number = 0;
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();

  aboutToAppear(): void {
    this.viewModel.formMode = this.mode;
    this.viewModel.loadWorkshops();
    this.viewModel.searchProducts('');
    if (this.mode === 'edit') {
      this.viewModel.loadForEdit(this.workOrderId);
      if (this.viewModel.formWorkshopId > 0) {
        this.viewModel.loadLines(this.viewModel.formWorkshopId);
      }
    } else if (this.mode === 'copy') {
      this.viewModel.loadForCopy(this.sourceWorkOrderId);
    }
  }

  private getTitle(): string {
    if (this.mode === 'edit') {
      return '编辑工单';
    }
    if (this.mode === 'copy') {
      return '复制工单';
    }
    return '新增工单';
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(600)
      .fontColor('#1A1A2E')
      .margin({ bottom: 12 })
      .padding({ bottom: 8 })
      .border({ width: { bottom: 1 }, color: '#E8EBF0' })
      .width('100%')
  }

  @Builder
  FormLabel(label: string, required: boolean) {
    Text(required ? `${label} *` : label)
      .fontSize(12)
      .fontColor('#5A5A6E')
      .margin({ bottom: 6 })
  }

  @Builder
  DisabledField(value: string) {
    Text(value || '—')
      .fontSize(14)
      .fontColor('#9A9AA8')
      .width('100%').height(44)
      .backgroundColor('#E8EBF0')
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
      .textAlign(TextAlign.Start)
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#1565C0')
          .onClick(() => this.pageStack.pop())
          .margin({ right: 8 })

        Text(this.getTitle())
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#1A1A2E')
          .layoutWeight(1)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#E8EBF0' })

      // Error message
      if (this.viewModel.errorMessage) {
        Text(this.viewModel.errorMessage)
          .fontSize(14)
          .fontColor('#F44336')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
          .width('100%')
          .backgroundColor('#FFF0F0')
      }

      // Content
      Scroll() {
        Column({ space: 12 }) {
          // Copy-from banner
          if (this.mode === 'copy' && this.viewModel.formSourceWorkOrderCode) {
            Column() {
              Text(`复制自工单 ${this.viewModel.formSourceWorkOrderCode}`)
                .fontSize(12)
                .fontColor('#1565C0')
                .fontWeight(600)
                .margin({ bottom: 4 })
              Text('已自动填充产品、工艺路线、计划数量等信息')
                .fontSize(13)
                .fontColor('#5A5A6E')
            }
            .padding(12)
            .borderRadius(12)
            .border({ width: 1, color: '#42A5F5', style: BorderStyle.Dashed })
            .backgroundColor('#E3F2FD')
            .width('100%')
          }

          // Section: 基本信息
          Column() {
            this.SectionTitle('基本信息')

            if (this.mode !== 'add') {
              this.FormLabel('工单号', true)
              this.DisabledField(this.viewModel.formCode)
              Blank().height(12)
            }

            this.FormLabel('工单类型', true)
            Row() {
              Text(this.viewModel.formType || '请选择工单类型')
                .fontSize(14)
                .fontColor(this.viewModel.formType ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu([
              MenuItem({ content: '试产' }).onClick(() => { this.viewModel.formType = '试产' }),
              MenuItem({ content: '量产' }).onClick(() => { this.viewModel.formType = '量产' }),
              MenuItem({ content: '返工' }).onClick(() => { this.viewModel.formType = '返工' }),
            ])
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF')

          // Section: 产品信息
          Column() {
            this.SectionTitle('产品信息')

            this.FormLabel('产品选择', true)
            Row() {
              Text(this.viewModel.formProductName || this.viewModel.formProductCode ||
                (this.viewModel.products.length > 0 ? '点击选择产品' : '加载中...'))
                .fontSize(14)
                .fontColor(this.viewModel.formProductName || this.viewModel.formProductCode ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu(
              this.viewModel.products.map((p: ProductModel) =>
                MenuItem({ content: `${p.code} - ${p.name}` })
                  .onClick(() => { this.viewModel.selectProduct(p) })
              )
            )

            if (this.viewModel.formProductName) {
              Blank().height(12)
              this.FormLabel('产品名称', false)
              this.DisabledField(this.viewModel.formProductName)
            }

            if (this.viewModel.formProcessName || this.viewModel.formProcessSteps.length > 0) {
              Blank().height(12)
              Row() {
                Text('工艺路线')
                  .fontSize(12)
                  .fontColor('#5A5A6E')
                Text(' 自动带出')
                  .fontSize(11)
                  .fontColor('#1565C0')
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(4)
                  .backgroundColor('#E3F2FD')
              }
              .margin({ bottom: 6 })

              if (this.viewModel.formProcessName) {
                this.DisabledField(this.viewModel.formProcessName)
              }

              if (this.viewModel.formProcessSteps.length > 0) {
                Text('工艺步骤预览')
                  .fontSize(12)
                  .fontColor('#5A5A6E')
                  .margin({ top: 8, bottom: 6 })

                Row({ space: 6 }) {
                  ForEach(this.viewModel.formProcessSteps, (step: ProcessStepModel, index: number) => {
                    Row({ space: 4 }) {
                      Text(`${index + 1}`)
                        .fontSize(10)
                        .fontColor('#FFFFFF')
                        .fontWeight(600)
                        .width(18).height(18)
                        .borderRadius(9)
                        .backgroundColor('#1565C0')
                        .textAlign(TextAlign.Center)
                      Text(step.name)
                        .fontSize(12)
                        .fontColor('#1A1A2E')
                        .maxLines(1)
                    }

                    if (index < this.viewModel.formProcessSteps.length - 1) {
                      Text('→').fontSize(12).fontColor('#9A9AA8')
                    }
                  }, (step: ProcessStepModel, index: number) => `${index}`)
                }
              }
            }
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF')

          // Section: 生产计划
          Column() {
            this.SectionTitle('生产计划')

            this.FormLabel('计划数量', true)
            TextInput({ text: this.viewModel.formPlanQty > 0 ? this.viewModel.formPlanQty.toString() : '', placeholder: '请输入计划数量' })
              .type(InputType.Number)
              .fontSize(14)
              .width('100%').height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.viewModel.formPlanQty = parseInt(value) || 0;
              })

            Blank().height(12)

            Row({ space: 12 }) {
              Column() {
                this.FormLabel('计划开始', false)
                TextInput({ text: this.viewModel.formPlanStartTime, placeholder: 'yyyy-MM-dd HH:mm' })
                  .fontSize(14)
                  .width('100%').height(44)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12)
                  .border({ width: 1, color: '#E8EBF0' })
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => { this.viewModel.formPlanStartTime = value })
              }
              .layoutWeight(1)

              Column() {
                this.FormLabel('计划完成', false)
                TextInput({ text: this.viewModel.formPlanEndTime, placeholder: 'yyyy-MM-dd HH:mm' })
                  .fontSize(14)
                  .width('100%').height(44)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12)
                  .border({ width: 1, color: '#E8EBF0' })
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => { this.viewModel.formPlanEndTime = value })
              }
              .layoutWeight(1)
            }
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF')

          // Section: 生产资源
          Column() {
            this.SectionTitle('生产资源')

            this.FormLabel('所属车间', true)
            Row() {
              Text(this.viewModel.formWorkshopId > 0
                ? (this.viewModel.workshops.find((w: WorkshopModel) => w.id === this.viewModel.formWorkshopId)?.name ?? '')
                : '请选择车间')
                .fontSize(14)
                .fontColor(this.viewModel.formWorkshopId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu(
              this.viewModel.workshops.map((w: WorkshopModel) =>
                MenuItem({ content: w.name })
                  .onClick(() => { this.viewModel.onWorkshopChange(w.id) })
              )
            )

            Blank().height(12)

            this.FormLabel('所属产线', true)
            Row() {
              Text(this.viewModel.formLineId > 0
                ? (this.viewModel.lines.find((l: LineModel) => l.id === this.viewModel.formLineId)?.name ?? '')
                : '请选择产线')
                .fontSize(14)
                .fontColor(this.viewModel.formLineId > 0 ? '#1A1A2E' : '#9A9AA8')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').height(44)
            .backgroundColor('#F5F7FA')
            .borderRadius(12)
            .border({ width: 1, color: '#E8EBF0' })
            .padding({ left: 12, right: 12 })
            .alignItems(VerticalAlign.Center)
            .bindMenu(
              this.viewModel.lines.map((l: LineModel) =>
                MenuItem({ content: l.name })
                  .onClick(() => { this.viewModel.formLineId = l.id })
              )
            )
          }
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#FFFFFF')

          Blank().height(80)
        }
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F7FA')

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
          .onClick(() => this.pageStack.pop())

        Button('保存工单')
          .fontSize(15)
          .fontWeight(600)
          .fontColor('#FFFFFF')
          .backgroundColor(this.viewModel.isSubmitting ? '#90CAF9' : '#1565C0')
          .layoutWeight(2)
          .height(46)
          .borderRadius(12)
          .enabled(!this.viewModel.isSubmitting)
          .onClick(async () => {
            let success = false;
            if (this.mode === 'edit') {
              success = await this.viewModel.submitUpdate(this.workOrderId);
            } else if (this.mode === 'copy') {
              success = await this.viewModel.submitCopy(this.sourceWorkOrderId);
            } else {
              success = await this.viewModel.submitCreate();
            }
            if (success) {
              this.pageStack.pop();
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 28 })
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#E8EBF0' })
    }
    .width('100%')
    .height('100%')
  }
}
