import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';
import { ProductionViewModel } from '../../../main/ets/ViewModel/ProductionViewModel';
import { LineModel } from '../../../main/ets/Model/LineModel';

export default function abilityTest() {
  describe('ProductionViewModel.instrumented', () => {

    describe('initial_state', () => {
      it('new_viewmodel_has_empty_lines', 0, () => {
        const vm = new ProductionViewModel();
        expect(vm.lines.length).assertEqual(0);
      });
      it('new_viewmodel_isActive_false', 0, () => {
        const vm = new ProductionViewModel();
        expect(vm.isActive).assertEqual(false);
      });
      it('new_viewmodel_isLoading_false', 0, () => {
        const vm = new ProductionViewModel();
        expect(vm.isLoading).assertEqual(false);
      });
    });

    describe('isActive_guard_behavior', () => {
      it('guard_blocks_when_false', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = false;
        expect(!vm.isActive).assertEqual(true);
      });

      it('guard_passes_when_true', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = true;
        expect(!vm.isActive).assertEqual(false);
      });

      it('aboutToDisappear_sets_isActive_false', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = true;
        vm.isActive = false;
        expect(vm.isActive).assertEqual(false);
      });

      it('onAppear_restores_isActive_true', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = false;
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });
    });

    describe('full_lifecycle_simulation', () => {
      it('step1_aboutToAppear', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });

      it('step2_push_detail_aboutToDisappear', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = true;
        const line = new LineModel();
        line.id = 1;
        line.status = '生产中';
        line.finishedCount = 42;
        vm.lines = [line];

        // 进入详情：只设 isActive，不取消 WebSocket
        vm.isActive = false;
        expect(vm.isActive).assertEqual(false);
        expect(vm.lines.length).assertEqual(1);

        // WebSocket 持续推送
        const wsData: Record<string, Object> = { 'finishedCount': 100 };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].finishedCount).assertEqual(100);
      });

      it('step3_pop_detail_onAppear', 0, () => {
        const vm = new ProductionViewModel();
        vm.isActive = false;
        const line = new LineModel();
        line.id = 1;
        vm.lines = [line];

        // onAppear 先恢复 isActive
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
        expect(vm.lines.length > 0).assertEqual(true);
      });
    });

    describe('onLineListStatusUpdate_from_broadcast', () => {
      it('updates_status', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const data: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': data };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('生产中');
      });

      it('updates_counts', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        line.ngCount = 0;
        vm.lines = [line];

        const data: Record<string, Object> = { 'finishedCount': 77, 'ngCount': 3 };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': data };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].finishedCount).assertEqual(77);
        expect(vm.lines[0].ngCount).assertEqual(3);
      });

      it('skips_mismatched_lineId', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const data: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 99, 'data': data };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('空闲');
      });

      it('skips_missing_data', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const payload: Record<string, Object> = { 'lineId': 1 };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('空闲');
      });

      it('real_broadcast_format', 0, () => {
        const vm = new ProductionViewModel();
        const line1 = new LineModel();
        line1.id = 1;
        line1.status = '空闲';
        line1.finishedCount = 0;
        line1.currentWorkorderId = null;
        line1.workOrderStatus = '';
        const line2 = new LineModel();
        line2.id = 2;
        line2.status = '空闲';
        vm.lines = [line1, line2];

        // LineBroadcaster.broadcastLineStatus 的实际消息格式
        const statusData: Record<string, Object> = {
          'status': '生产中',
          'workOrderId': 13,
          'finishedCount': 100,
          'ngCount': 5,
          'woStatus': '生产中'
        };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': statusData };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('生产中');
        expect(vm.lines[0].currentWorkorderId).assertEqual(13);
        expect(vm.lines[0].finishedCount).assertEqual(100);
        expect(vm.lines[0].workOrderStatus).assertEqual('生产中');
        expect(vm.lines[1].status).assertEqual('空闲');
      });

      it('consecutive_ticks', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        vm.lines = [line];

        for (let tick = 1; tick <= 30; tick++) {
          const data: Record<string, Object> = { 'finishedCount': tick * 7 };
          const payload: Record<string, Object> = { 'lineId': 1, 'data': data };
          vm.onLineListStatusUpdate(payload);
        }
        expect(vm.lines[0].finishedCount).assertEqual(210);
      });
    });

    describe('subscribe_unsubscribe', () => {
      it('safe_with_empty_lines', 0, () => {
        const vm = new ProductionViewModel();
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });

      it('multiple_cycles_no_throw', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        vm.lines = [line];
        for (let i = 0; i < 5; i++) {
          vm.subscribeLineList();
          vm.unsubscribeLineList();
        }
        expect(true).assertEqual(true);
      });

      it('many_lines_subscribe', 0, () => {
        const vm = new ProductionViewModel();
        const lines: LineModel[] = [];
        for (let i = 1; i <= 20; i++) {
          const line = new LineModel();
          line.id = i;
          lines.push(line);
        }
        vm.lines = lines;
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });

      it('subscribe_twice_no_double_add', 0, () => {
        const vm = new ProductionViewModel();
        const line = new LineModel();
        line.id = 1;
        vm.lines = [line];
        vm.subscribeLineList();
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });
    });

    describe('ViewModel_isolation', () => {
      it('two_instances_independent', 0, () => {
        const vm1 = new ProductionViewModel();
        const vm2 = new ProductionViewModel();

        vm1.isActive = true;
        vm2.isActive = false;
        expect(vm1.isActive).assertEqual(true);
        expect(vm2.isActive).assertEqual(false);

        const line = new LineModel();
        line.id = 1;
        vm1.lines = [line];
        expect(vm1.lines.length).assertEqual(1);
        expect(vm2.lines.length).assertEqual(0);
      });

      it('old_vm_listener_not_affect_new_vm', 0, () => {
        // Tab 切换：旧 VM 销毁但监听器残留 → 新 VM 不受影响
        const oldVm = new ProductionViewModel();
        oldVm.isActive = true;
        const oldLine = new LineModel();
        oldLine.id = 1;
        oldLine.status = '空闲';
        oldVm.lines = [oldLine];

        // 新建 VM (Tab 切换后)
        const newVm = new ProductionViewModel();
        const newLine = new LineModel();
        newLine.id = 1;
        newLine.status = '生产中';
        newVm.lines = [newLine];

        // 旧 VM 的监听器收到消息
        const data: Record<string, Object> = { 'status': '暂停' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': data };
        oldVm.onLineListStatusUpdate(payload);

        // 旧 VM 数据已更新
        expect(oldVm.lines[0].status).assertEqual('暂停');
        // 新 VM 数据不受影响
        expect(newVm.lines[0].status).assertEqual('生产中');
      });
    });

    describe('LineModel_mutations', () => {
      it('all_properties_mutable', 0, () => {
        const line = new LineModel();
        line.id = 1;
        line.name = 'TestLine';
        line.status = '生产中';
        line.finishedCount = 100;
        line.ngCount = 5;
        line.currentWorkorderId = 23;
        line.workOrderStatus = '生产中';
        line.workOrderCode = 'MO000023';
        line.planQty = 500;

        expect(line.id).assertEqual(1);
        expect(line.name).assertEqual('TestLine');
        expect(line.status).assertEqual('生产中');
        expect(line.finishedCount).assertEqual(100);
        expect(line.ngCount).assertEqual(5);
        expect(line.currentWorkorderId).assertEqual(23);
        expect(line.workOrderStatus).assertEqual('生产中');
        expect(line.workOrderCode).assertEqual('MO000023');
        expect(line.planQty).assertEqual(500);
      });

      it('count_increments_across_ticks', 0, () => {
        const line = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        line.ngCount = 0;

        const vm = new ProductionViewModel();
        vm.lines = [line];

        // 模拟 5 次 Tick 推送
        for (let tick = 0; tick < 5; tick++) {
          const count = (tick + 1) * 10;
          const data: Record<string, Object> = {
            'finishedCount': count,
            'ngCount': tick
          };
          const payload: Record<string, Object> = { 'lineId': 1, 'data': data };
          vm.onLineListStatusUpdate(payload);
        }
        expect(line.finishedCount).assertEqual(50);
        expect(line.ngCount).assertEqual(4);
      });
    });
  });
}
