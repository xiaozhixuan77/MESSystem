export class LoginResponseUserModel {
  id: number = 0;
  employeeNo: string = '';
  name: string = '';
  role: string = '';
  workshopId: number | null = null;
  teamId: number | null = null;
  status: string = '';
  avatarUrl: string | null = null;
}

export class LoginResponseModel {
  token: string = '';
  role: string = '';
  user: LoginResponseUserModel | null = null;
}