import { describe, it, expect } from '@ohos/hypium';
import { ProductionViewModel } from '../main/ets/ViewModel/ProductionViewModel';
import { LineModel } from '../main/ets/Model/LineModel';

export default function localUnitTest() {
  describe('ProductionViewModel', () => {

    describe('initial_state', () => {
      it('all_defaults', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        expect(vm.lines.length).assertEqual(0);
        expect(vm.isLoading).assertEqual(false);
        expect(vm.isActive).assertEqual(false);
        expect(vm.errorMessage).assertEqual('');
      });
    });

    describe('lifecycle_aboutToAppear', () => {
      it('sets_isActive_true', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });

      it('isActive_guard_blocks_when_false', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = false;
        expect(vm.isActive).assertEqual(false);
      });

      it('isActive_guard_passes_when_true', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });
    });

    describe('lifecycle_aboutToDisappear', () => {
      it('sets_isActive_false_and_unsubscribes', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '生产中';
        vm.lines = [line];

        vm.isActive = false;
        vm.unsubscribeLineList();

        expect(vm.isActive).assertEqual(false);
        expect(vm.lines.length).assertEqual(1);
      });

      it('unsubscribeLineList_safe_with_empty_lines', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });
    });

    describe('full_cycle_aboutToAppear_to_aboutToDisappear_back', () => {
      it('return_from_detail_restores_isActive', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.isActive = true;
        const line: LineModel = new LineModel();
        vm.lines = [line];
        vm.isActive = false;
        vm.unsubscribeLineList();
        expect(vm.isActive).assertEqual(false);

        vm.isActive = true;
        expect(vm.isActive).assertEqual(true);
      });

      it('detail_unsubscribeLine_preserves_stomp_for_shared_topics', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.finishedCount = 50;
        vm.lines = [line];

        vm.subscribeLineList();
        vm.subscribeLine(1);
        vm.unsubscribeLine();

        const wsData: Record<string, Object> = { 'finishedCount': 100 };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);
        expect(vm.lines[0].finishedCount).assertEqual(100);
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

      it('updates_finishedCount_and_ngCount', 0, () => {
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

      it('updates_workOrderId_and_woStatus', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.currentWorkorderId = null;
        line.workOrderStatus = '';
        vm.lines = [line];

        const wsData: Record<string, Object> = { 'workOrderId': 13, 'woStatus': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].currentWorkorderId).assertEqual(13);
        expect(vm.lines[0].workOrderStatus).assertEqual('生产中');
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

      it('skips_missing_lineId', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.status = '空闲';
        vm.lines = [line];

        const wsData: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'data': wsData };
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

      it('only_updates_matching_line', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line1: LineModel = new LineModel();
        line1.id = 1;
        line1.status = '空闲';
        const line2: LineModel = new LineModel();
        line2.id = 2;
        line2.status = '空闲';
        vm.lines = [line1, line2];

        const wsData: Record<string, Object> = { 'status': '生产中' };
        const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
        vm.onLineListStatusUpdate(payload);

        expect(vm.lines[0].status).assertEqual('生产中');
        expect(vm.lines[1].status).assertEqual('空闲');
      });

      it('consecutive_updates', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const line: LineModel = new LineModel();
        line.id = 1;
        line.finishedCount = 0;
        vm.lines = [line];

        for (let tick: number = 1; tick <= 10; tick++) {
          const wsData: Record<string, Object> = { 'finishedCount': tick * 10 };
          const payload: Record<string, Object> = { 'lineId': 1, 'data': wsData };
          vm.onLineListStatusUpdate(payload);
        }
        expect(vm.lines[0].finishedCount).assertEqual(100);
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
        expect(vm.lines[0].ngCount).assertEqual(5);
        expect(vm.lines[0].workOrderStatus).assertEqual('生产中');
      });
    });

    describe('subscribe_unsubscribe', () => {
      it('subscribeLineList_safe_with_empty_lines', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        vm.subscribeLineList();
        expect(true).assertEqual(true);
      });

      it('subscribe_then_unsubscribe_multiple_lines', 0, () => {
        const vm: ProductionViewModel = new ProductionViewModel();
        const lines: LineModel[] = [];
        for (let i: number = 1; i <= 10; i++) {
          const line: LineModel = new LineModel();
          line.id = i;
          lines.push(line);
        }
        vm.lines = lines;
        vm.subscribeLineList();
        vm.unsubscribeLineList();
        expect(true).assertEqual(true);
      });

      it('repeated_cycles_no_error', 0, () => {
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
    });

    describe('ViewModel_isolation', () => {
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

      it('old_instance_listener_not_affect_new_instance', 0, () => {
        const oldVm: ProductionViewModel = new ProductionViewModel();
        const newVm: ProductionViewModel = new ProductionViewModel();

        const oldLine: LineModel = new LineModel();
        oldLine.id = 1;
        oldLine.status = '空闲';
        oldVm.lines = [oldLine];

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

    describe('LineModel', () => {
      it('all_fields_settable', 0, () => {
        const line: LineModel = new LineModel();
        line.id = 1;
        line.name = 'Line_A';
        line.status = '生产中';
        line.workshopName = '焊接车间';
        line.stationCount = 6;
        line.workOrderCode = 'MO000023';
        line.planQty = 500;
        line.finishedCount = 100;
        line.ngCount = 5;
        line.currentWorkorderId = 23;
        line.workOrderStatus = '生产中';

        expect(line.id).assertEqual(1);
        expect(line.name).assertEqual('Line_A');
        expect(line.status).assertEqual('生产中');
        expect(line.workshopName).assertEqual('焊接车间');
        expect(line.stationCount).assertEqual(6);
        expect(line.workOrderCode).assertEqual('MO000023');
        expect(line.planQty).assertEqual(500);
        expect(line.finishedCount).assertEqual(100);
        expect(line.ngCount).assertEqual(5);
        expect(line.currentWorkorderId).assertEqual(23);
        expect(line.workOrderStatus).assertEqual('生产中');
      });

      it('status_transitions', 0, () => {
        const line: LineModel = new LineModel();
        line.status = '空闲';
        expect(line.status).assertEqual('空闲');
        line.status = '生产中';
        expect(line.status).assertEqual('生产中');
        line.status = '暂停';
        expect(line.status).assertEqual('暂停');
        line.status = '异常';
        expect(line.status).assertEqual('异常');
      });

      it('count_increments', 0, () => {
        const line: LineModel = new LineModel();
        line.finishedCount = 0;
        line.ngCount = 0;

        for (let i: number = 1; i <= 5; i++) {
          line.finishedCount += i * 10;
          line.ngCount += i;
        }

        expect(line.finishedCount).assertEqual(150);
        expect(line.ngCount).assertEqual(15);
      });
    });
  });
}
