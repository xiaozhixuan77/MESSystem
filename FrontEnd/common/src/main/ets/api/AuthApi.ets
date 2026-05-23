import { httpClient } from './HttpClient';

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

interface LoginRequest {
  username: string;
  password: string;
}

export class AuthApi {
  static async login(username: string, password: string): Promise<LoginResponseModel> {
    const params: LoginRequest = { username: username, password: password };
    return httpClient.post<LoginResponseModel>('/auth/login', params);
  }

  static async getCurrentUser(): Promise<LoginResponseUserModel> {
    return httpClient.get<LoginResponseUserModel>('/me');
  }

  static async logout(): Promise<void> {
    await httpClient.post<void>('/auth/logout');
  }
}
