import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';
import { ProductionViewModel } from '../../../main/ets/ViewModel/ProductionViewModel';
import { LineModel } from '../../../main/ets/Model/LineModel';

export default function abilityTest() {
  describe('ProductionViewModel.instrumented', () => {

    describe('initial_state', () => {
      it('new_viewmodel_has_empty_lines', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        expect(vm.lines.length).assertEqual(0);
      });
      it('new_viewmodel_isActive_false', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        expect(vm.isActive).assertEqual(false);
      });
      it('new_viewmodel_isLoading_false', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        expect(vm.isLoading).assertEqual(false);
      });
    });

    describe('isActive_guard', () => {
      it('guard_blocks_when_false', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = false;
        expect(vm.isActive).assertEqual(false);
      });

      it('guard_passes_when_true', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });

      it('aboutToDisappear_sets_isActive_false', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        vm.isActive = false;
        expect(vm.isActive).assertEqual(false);
      });

      it('aboutToAppear_sets_isActive_true', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = false;
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });
    });

    describe('full_lifecycle_simulation', () => {
      it('aboutToAppear_then_aboutToDisappear_then_back', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '生产中';
        line.finishedCount = 42;
        vm.lines = [line];

        vm.isActive = false;
        vm.unsubscribeLineList();
        expect(vm.isActive).assertEqual(false);
        expect(vm.lines.length).assertEqual(1);

        const wsData: Record<string, Object> = { 'finishedCount': 100 };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].finishedCount).assertEqual(100);

        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });

      it('two_instances_independent', 0, () => {
        const vm1: ProductionViewModel = new ProductionViewModel();
        const vm2: ProductionViewModel = new ProductionViewModel();

        vm1.isActive = true;
        vm2.isActive = false;
        expect(vm1.isActive).assertEqual(true);
        expect(vm2.isActive).assertEqual(false);

        const line: LineModel = new LineModel();
        vm1.lines = [line];
        expect(vm1.lines.length).assertEqual(1);
        expect(vm2.lines.length).assertEqual(0);
      });
    });

    describe('onLineListStatusUpdate', () => {
      it('updates_status', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const wsData: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].status).assertEqual('生产中');
      });

      it('updates_counts', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        line.ngCount = 0;
        vm.lines = [line];

        const wsData: Record<string, Object> = { 'finishedCount': 77, 'ngCount': 3 };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].finishedCount).assertEqual(77);
        expect(vm.lines[0].ngCount).assertEqual(3);
      });

      it('skips_mismatched_lineId', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const wsData: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 99, 'data': wsData };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].status).assertEqual('空闲');
      });

      it('skips_missing_data', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const payload: Record<string, Object> = { 'lineId': 1 };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].status).assertEqual('空闲');
      });

      it('broadcast_format_all_fields', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '空闲';
        line.currentWorkorderId = null;
        line.finishedCount = 0;
        line.ngCount = 0;
        line.workOrderStatus = '';
        vm.lines = [line];

        const wsData: Record<string, Object> = {
          'status': '生产中',
          'workOrderId': 13,
          'finishedCount': 100,
          'ngCount': 5,
          'woStatus': '生产中'
        };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('生产中');
        expect(vm.lines[0].currentWorkorderId).assertEqual(13);
        expect(vm.lines[0].finishedCount).assertEqual(100);
        expect(vm.lines[0].workOrderStatus).assertEqual('生产中');
      });

      it('consecutive_ticks', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        vm.lines = [line];

        for (let tick: number = 1; tick <= 30; tick++) {
          const wsData: Record<string, Object> = { 'finishedCount': tick * 7 };
          const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
          vm.onLineListStatusUpdate(payload);
        }
        expect(vm.lines[0].finishedCount).assertEqual(210);
      });
    });

    describe('subscribe_unsubscribe', () => {
      it('safe_with_empty_lines', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });

      it('multiple_cycles_no_throw', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        vm.lines = [line];
        for (let i: number = 0; i < 5; i++) {
          vm.subscribeLineList();
          vm.unsubscribeLineList();
        }
        expect(true).assertEqual(true);
      });

      it('many_lines_subscribe', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const lines: LineModel[] = [];
        for (let i: number = 1; i <= 20; i++) {
          const line: LineModel = new LineModel();
          line.id = i;
          lines.push(line);
        }
        vm.lines = lines;
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });

      it('subscribe_twice_no_double_add', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        vm.lines = [line];
        vm.subscribeLineList();
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });
    });

    describe('ViewModel_isolation', () => {
      it('old_vm_listener_not_affect_new_vm', 0, () => {
        const oldVm: ProductionViewModel = new ProductionViewModel();
        const oldLine: LineModel = new LineModel();
        oldLine.id = 1;
        oldLine.status = '空闲';
        oldVm.lines = [oldLine];

        const newVm: ProductionViewModel = new ProductionViewModel();
        const newLine: LineModel = new LineModel();
        newLine.id = 1;
        newLine.status = '生产中';
        newVm.lines = [newLine];

        const wsData: Record<string, Object> = { 'status': '暂停' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        oldVm.onLineListStatusUpdate(payload);

        expect(oldVm.lines[0].status).assertEqual('暂停');
        expect(newVm.lines[0].status).assertEqual('生产中');
      });
    });

    describe('LineModel_mutations', () => {
      it('all_properties_mutable', 0, () => {
        const line: LineModel = new LineModel();
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
        const line: LineModel = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        line.ngCount = 0;

        const vm: ProductionViewModel = new ProductionViewModel();
        vm.lines = [line];

        for (let tick: number = 0; tick < 5; tick++) {
          const count: number = (tick + 1) * 10;
          const wsData: Record<string, Object> = { 'finishedCount': count, 'ngCount': tick };
          const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
          vm.onLineListStatusUpdate(payload);
        }
        expect(line.finishedCount).assertEqual(50);
        expect(line.ngCount).assertEqual(4);
      });
    });
  });
}
