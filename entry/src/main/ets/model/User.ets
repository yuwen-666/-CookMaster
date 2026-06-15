/**
 * 用户数据模型
 */
export class User {
  id: number = 0;
  email: string = '';
  password: string = '';
  nickname: string = '';
  avatar: string = '';
  createTime: string = '';
  lastLoginTime: string = '';
}

/**
 * 登录结果
 */
export class LoginResult {
  success: boolean = false;
  message: string = '';
  user: User | null = null;
}
