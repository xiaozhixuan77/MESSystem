import { PermissionUtil } from '@ohos/utils';
import { WorkOrderViewModel } from '../ViewModel/WorkOrderViewModel';
import { ProductModel } from '../Model/ProductModel';
import { WorkshopModel } from '../Model/WorkshopModel';
import { LineModel } from '../Model/LineModel';
import { ProcessStepModel } from '../Model/ProcessStepModel';

@ComponentV2
export struct WorkOrderFormView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Param mode: string = 'add';
  @Param workOrderId: number = 0;
  @Param sourceWorkOrderId: number = 0;
  @Local viewModel: WorkOrderViewModel = new WorkOrderViewModel();
  @Local showProductPicker: boolean = false;
  @Local showLinePicker: boolean = false;
  @Local productSearchText: string = '';
  @Local showDatePickerFor: string = '';
  @Local datePickerValue: Date = new Date();

  aboutToAppear(): void {
    this.viewModel.formMode = this.mode;
    this.viewModel.loadWorkshops();
    this.viewModel.searchProducts('');
    if (this.mode === 'edit') {
      this.viewModel.loadForEdit(this.workOrderId);
    } else if (this.mode === 'copy') {
      this.viewModel.loadForCopy(this.sourceWorkOrderId);
    }
  }

  private formatDateStr(date: Date, existingValue?: string): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    if (existingValue && existingValue.length >= 16) {
      return `${y}-${m}-${d} ${existingValue.substring(11, 16)}`;
    }
    return `${y}-${m}-${d} 00:00`;
  }

  private openDatePickerFor(field: string): void {
    const currentVal = field === 'start'
      ? this.viewModel.formPlanStartTime
      : this.viewModel.formPlanEndTime;
    if (currentVal) {
      const parsed = new Date(currentVal);
      if (!isNaN(parsed.getTime())) {
        this.datePickerValue = parsed;
      } else {
        this.datePickerValue = new Date();
      }
    } else {
      this.datePickerValue = new Date();
    }
    this.showDatePickerFor = field;
  }

  private confirmDatePicker(): void {
    const existing = this.showDatePickerFor === 'start'
      ? this.viewModel.formPlanStartTime
      : this.viewModel.formPlanEndTime;
    const formatted = this.formatDateStr(this.datePickerValue, existing);
    if (this.showDatePickerFor === 'start') {
      this.viewModel.formPlanStartTime = formatted;
    } else {
      this.viewModel.formPlanEndTime = formatted;
    }
    this.showDatePickerFor = '';
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
  DisabledField(value: string) {
    Text(value || '—')
      .fontSize(14)
      .fontColor('#9A9AA8')
      .width('100%')
      .height(44)
      .backgroundColor('#E8EBF0')
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
      .textAlign(TextAlign.Start)
  }

  @Builder
  TypeMenu() {
    Menu() {
      MenuItem({ content: '试产' }).onClick(() => {
        this.viewModel.formType = '试产'
      })
      MenuItem({ content: '量产' }).onClick(() => {
        this.viewModel.formType = '量产'
      })
      MenuItem({ content: '返工' }).onClick(() => {
        this.viewModel.formType = '返工'
      })
    }
  }

  @Builder
  ProductDialog() {
    Column() {
      Text('选择产品')
        .fontSize(18)
        .fontWeight(700)
        .fontColor('#1A1A2E')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 });
      Row() {
        TextInput({ placeholder: '输入产品编码或名称搜索', text: $$this.productSearchText })
          .height(44)
          .fontSize(14)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .border({ width: 1, color: '#E8EBF0' })
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((v: string) => {
            this.viewModel.searchProducts(v);
          });
      }
      .margin({ bottom: 12 });

      if (this.viewModel.products.length === 0) {
        Text('暂无匹配产品，请输入关键词搜索').fontSize(14).fontColor('#9A9AA8').padding(20);
      } else {
        List() {
          ForEach(this.viewModel.products, (p: ProductModel) => {
            ListItem() {
              Row() {
                Text(`${p.code} - ${p.name}`)
                  .fontSize(15).fontColor('#1A1A2E').layoutWeight(1);
                if (this.viewModel.formProductId === p.id) {
                  Image($r('app.media.icon_check_green')).width(20).height(20);
                }
              }
              .width('100%').padding(14)
              .border({ width: { bottom: 1 }, color: '#F5F7FA' })
              .onClick(() => {
                this.viewModel.selectProduct(p);
                this.showProductPicker = false;
                this.productSearchText = '';
              });
            }
          }, (p: ProductModel) => `${p.id}`);
        }
        .layoutWeight(1).scrollBar(BarState.Off);
      }
    }
    .width('90%')
    .height('70%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  @Builder
  LineDialog() {
    Column() {
      Text('选择产线')
        .fontSize(18)
        .fontWeight(700)
        .fontColor('#1A1A2E')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 });

      if (this.viewModel.lines.length === 0) {
        if (this.viewModel.formWorkshopId <= 0) {
          Text('请先选择车间').fontSize(14).fontColor('#9A9AA8').padding(20);
        } else if (this.viewModel.formProcessId <= 0) {
          Text('请先选择产品以加载工艺').fontSize(14).fontColor('#9A9AA8').padding(20);
        } else {
          Text('当前车间下无支持该工艺的产线').fontSize(14).fontColor('#9A9AA8').padding(20);
        }
      } else {
        List() {
          ForEach(this.viewModel.lines, (l: LineModel) => {
            ListItem() {
              Row() {
                Text(l.name)
                  .fontSize(15).fontColor('#1A1A2E').layoutWeight(1);
                if (this.viewModel.formLineId === l.id) {
                  Image($r('app.media.icon_check_green')).width(20).height(20);
                }
              }
              .width('100%').padding(14)
              .border({ width: { bottom: 1 }, color: '#F5F7FA' })
              .onClick(() => {
                this.viewModel.formLineId = l.id;
                this.showLinePicker = false;
              });
            }
          }, (l: LineModel) => `${l.id}`);
        }
        .layoutWeight(1).scrollBar(BarState.Off);
      }
    }
    .width('90%')
    .height('50%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  @Builder
  WorkshopMenu() {
    Menu() {
      ForEach(this.viewModel.workshops, (w: WorkshopModel) => {
        MenuItem({ content: w.name })
          .onClick(() => {
            this.viewModel.onWorkshopChange(w.id)
          })
      })
    }
  }

  @Builder
  DatePickerDialog() {
    Column() {
      Text('选择日期')
        .fontSize(18)
        .fontWeight(700)
        .fontColor('#1A1A2E')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 });

      DatePicker({
        start: new Date('2020-1-1'),
        end: new Date('2030-12-31'),
        selected: this.datePickerValue
      })
        .onChange((value: DatePickerResult) => {
          this.datePickerValue = new Date(value.year ?? 2025, value.month ?? 0, value.day ?? 1);
        });

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontWeight(500)
          .fontColor('#5A5A6E')
          .backgroundColor('#F5F7FA')
          .layoutWeight(1)
          .height(40)
          .borderRadius(10)
          .onClick(() => {
            this.showDatePickerFor = '';
          });
        Button('确定')
          .fontSize(14)
          .fontWeight(600)
          .fontColor('#FFFFFF')
          .backgroundColor('#1565C0')
          .layoutWeight(1)
          .height(40)
          .borderRadius(10)
          .onClick(() => {
            this.confirmDatePicker();
          });
      }
      .width('100%')
      .margin({ top: 16 });
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  build() {
    Stack() {
      Column() {
        // Header
        Row() {
          Button() {
            Image($r('app.media.icon_arrow_left_gray'))
              .width(20).height(20).fillColor('#1A1A2E');
          }
          .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .borderRadius(12)
          .onClick(() => this.pageStack.pop());

          Text(this.getTitle())
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#1A1A2E')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ left: 12 });

          Row({ space: 8 }) {
            Image($r('app.media.icon_save_gray'))
              .width(18).height(18);
          }
          .width(36)
          .height(36)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center);
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 16,
          bottom: 12
        })
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 1 }, color: '#E8EBF0' })

        // Error message
        if (this.viewModel.errorMessage) {
          Text(this.viewModel.errorMessage)
            .fontSize(14)
            .fontColor('#F44336')
            .padding({
              left: 16,
              right: 16,
              top: 8,
              bottom: 4
            })
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
              .margin({ bottom: 4 })
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
              .width('100%')
              .height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
              .bindMenu(this.TypeMenu)
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
              .width('100%')
              .height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.viewModel.searchProducts('');
                this.productSearchText = '';
                this.showProductPicker = true;
              })

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
                    .padding({
                      left: 6,
                      right: 6,
                      top: 2,
                      bottom: 2
                    })
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
                    .margin({ top: 8, bottom: 8 });

                  Column() {
                    Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.viewModel.formProcessSteps, (step: ProcessStepModel, index: number) => {
                      Row({ space: 4 }) {
                        Text(`${step.seqNo}`)
                          .fontSize(10)
                          .fontColor('#FFFFFF')
                          .fontWeight(600)
                          .width(18)
                          .height(18)
                          .borderRadius(9)
                          .backgroundColor('#1565C0')
                          .textAlign(TextAlign.Center)
                        Text(step.name)
                          .fontSize(12)
                          .fontColor('#1A1A2E')
                          .maxLines(1)
                      }
                      .margin({ bottom: 8 })

                      if (index < this.viewModel.formProcessSteps.length - 1) {
                        Text(' → ').fontSize(12).fontColor('#9A9AA8')
                      }
                    }, (step: ProcessStepModel) => `${step.seqNo}`)
                  }
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12);
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
              TextInput({
                text: this.viewModel.formPlanQty > 0 ? this.viewModel.formPlanQty.toString() : '',
                placeholder: '请输入计划数量'
              })
                .type(InputType.Number)
                .fontSize(14)
                .width('100%')
                .height(44)
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
                  Row() {
                    Text(this.viewModel.formPlanStartTime || 'yyyy-MM-dd HH:mm')
                      .fontSize(14)
                      .fontColor(this.viewModel.formPlanStartTime ? '#1A1A2E' : '#9A9AA8')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height(44)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12)
                  .border({ width: 1, color: '#E8EBF0' })
                  .padding({ left: 12, right: 12 })
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    this.openDatePickerFor('start');
                  })
                }
                .layoutWeight(1)

                Column() {
                  this.FormLabel('计划完成', false)
                  Row() {
                    Text(this.viewModel.formPlanEndTime || 'yyyy-MM-dd HH:mm')
                      .fontSize(14)
                      .fontColor(this.viewModel.formPlanEndTime ? '#1A1A2E' : '#9A9AA8')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height(44)
                  .backgroundColor('#F5F7FA')
                  .borderRadius(12)
                  .border({ width: 1, color: '#E8EBF0' })
                  .padding({ left: 12, right: 12 })
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    this.openDatePickerFor('end');
                  })
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
                  ?
                  (this.viewModel.workshops.find((w: WorkshopModel) => w.id === this.viewModel.formWorkshopId)?.name ??
                    '')
                  : '请选择车间')
                  .fontSize(14)
                  .fontColor(this.viewModel.formWorkshopId > 0 ? '#1A1A2E' : '#9A9AA8')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
              .bindMenu(this.WorkshopMenu)

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
              .width('100%')
              .height(44)
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .border({ width: 1, color: '#E8EBF0' })
              .padding({ left: 12, right: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.showLinePicker = true;
              })
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

          if (PermissionUtil.hasPermission('workorder.create', this.currentRole)) {
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
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 28
        })
        .backgroundColor('#FFFFFF')
        .border({ width: { top: 1 }, color: '#E8EBF0' })
      }
      .width('100%')
      .height('100%');

      // 产品选择弹窗
      if (this.showProductPicker) {
        Stack() {
          Column()
            .width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.5)')
            .onClick(() => {
              this.showProductPicker = false;
            });
          Column() {
            this.ProductDialog();
          }
          .onClick(() => {
          }); // 阻止冒泡
        }
        .width('100%').height('100%');
      }

      // 产线选择弹窗
      if (this.showLinePicker) {
        Stack() {
          Column()
            .width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.5)')
            .onClick(() => {
              this.showLinePicker = false;
            });
          Column() {
            this.LineDialog();
          }
          .onClick(() => {
          }); // 阻止冒泡
        }
        .width('100%').height('100%');
      }

      // 日期选择弹窗
      if (this.showDatePickerFor !== '') {
        Stack() {
          Column()
            .width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.5)')
            .onClick(() => {
              this.showDatePickerFor = '';
            });
          Column() {
            this.DatePickerDialog();
          }
          .onClick(() => {
          }); // 阻止冒泡
        }
        .width('100%').height('100%');
      }
    }
  }
}