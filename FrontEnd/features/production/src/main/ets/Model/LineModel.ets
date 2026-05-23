export class LineModel {
  id: number = 0;
  name: string = '';
  workshopId: number = 0;
  currentProcessId: number | null = null;
  currentWorkorderId: number | null = null;
  status: string = '空闲';
  workshopName: string = '';
  createdAt: string = '';
}
