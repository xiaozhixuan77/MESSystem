export class UserModel {
  id: number = 0;
  employeeNo: string = '';
  name: string = '';
  role: string = '';
  teamId: number | null = null;
  workshopId: number | null = null;
  status: string = 'active';
  avatarUrl: string = '';
  createdAt: string = '';
}
