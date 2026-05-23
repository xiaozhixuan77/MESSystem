@ObservedV2
export class UserModel {
  @Trace id: number = 0;
  @Trace employeeNo: string = '';
  @Trace name: string = '';
  @Trace role: string = '';
  @Trace teamId: number | null = null;
  @Trace workshopId: number | null = null;
  @Trace status: string = 'active';
  @Trace avatarUrl: string = '';
  createdAt: string = '';
}
