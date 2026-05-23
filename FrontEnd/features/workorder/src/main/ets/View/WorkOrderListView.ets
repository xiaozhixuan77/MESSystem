import { WorkOrderCard } from '@ohos/common';

@ComponentV2
export struct WorkOrderListView {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('currentRole') currentRole: string = '';
  @Param role: string = '';
  @Local workOrderList: WorkOrderModel[] = [];
  @Local isLoading: boolean = false;
  @Local searchKeyword: string = '';

  aboutToAppear(): void {
    // 加载工单列表（后续 Phase 实现）
  }

  build() {
    NavDestination() {
      Column() {
        Search({ placeholder: '搜索工单号...', value: this.searchKeyword })
          .onSubmit((value: string) => {
            this.searchKeyword = value;
          })
          .margin({ bottom: 12 });

        if (this.isLoading) {
          LoadingProgress();
        } else {
          List() {
            ForEach(this.workOrderList, (wo: WorkOrderModel) => {
              ListItem() {
                WorkOrderCard({
                  workOrderCode: wo.code,
                  status: wo.status,
                  productName: wo.productName,
                  planQty: wo.planQty,
                  role: this.role
                });
              }
            });
          };
        }
      }
      .padding(16)
      .width('100%')
      .height('100%');
    }
  }
}
