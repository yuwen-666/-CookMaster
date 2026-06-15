import preferences from '@ohos.data.preferences';
import { User, LoginResult } from '../model/User';
import { DatabaseService } from './DatabaseService';
import { NetworkService, SendCodeResponse, VerifyCodeResponse } from './NetworkService';
import { Constants } from '../utils/Constants';

/**
 * 认证服务
 */
export class AuthService {
  private static instance: AuthService;
  private dbService: DatabaseService;
  private networkService: NetworkService;
  private preferences: preferences.Preferences | null = null;

  private constructor() {
    this.dbService = DatabaseService.getInstance();
    this.networkService = NetworkService.getInstance();
  }

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  /**
   * 初始化偏好存储
   */
  async init(context: Context): Promise<void> {
    this.preferences = await preferences.getPreferences(context, Constants.AUTH_PREFS_NAME);
  }

  /**
   * 用户注册
   */
  async register(email: string, password: string, nickname: string): Promise<boolean> {
    const existingUser: User | null = await this.dbService.getUserByEmail(email);
    if (existingUser) {
      return false;
    }

    const rowId: number = await this.dbService.insertUser(email, password, nickname);
    return rowId > 0;
  }

  /**
   * 用户注册并自动登录
   */
  async registerAndLogin(email: string, password: string, nickname: string): Promise<LoginResult> {
    const success: boolean = await this.register(email, password, nickname);
    if (!success) {
      const failResult: LoginResult = new LoginResult();
      failResult.success = false;
      failResult.message = '该邮箱已注册';
      return failResult;
    }

    return await this.login(email, password);
  }

  /**
   * 用户登录
   */
  async login(email: string, password: string): Promise<LoginResult> {
    const user: User | null = await this.dbService.verifyUserLogin(email, password);
    if (!user) {
      const failResult: LoginResult = new LoginResult();
      failResult.success = false;
      failResult.message = '邮箱或密码错误';
      return failResult;
    }

    await this.dbService.updateLastLoginTime(user.id);

    if (this.preferences) {
      await this.preferences.put(Constants.AUTH_KEY_LOGGED_IN, true);
      await this.preferences.put(Constants.AUTH_KEY_EMAIL, email);
      await this.preferences.put(Constants.AUTH_KEY_USER_ID, user.id);
      await this.preferences.flush();
    }

    const successResult: LoginResult = new LoginResult();
    successResult.success = true;
    successResult.message = '登录成功';
    successResult.user = user;
    return successResult;
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    if (this.preferences) {
      await this.preferences.put(Constants.AUTH_KEY_LOGGED_IN, false);
      await this.preferences.put(Constants.AUTH_KEY_EMAIL, '');
      await this.preferences.put(Constants.AUTH_KEY_USER_ID, 0);
      await this.preferences.flush();
    }
  }

  /**
   * 检查是否已登录
   */
  async isLoggedIn(): Promise<boolean> {
    if (!this.preferences) {
      console.error('AuthService: preferences not initialized');
      return false;
    }
    try {
      const loggedIn: boolean = await this.preferences.get(Constants.AUTH_KEY_LOGGED_IN, false) as boolean;
      return loggedIn;
    } catch (error) {
      console.error('AuthService: isLoggedIn error:', error);
      return false;
    }
  }

  /**
   * 获取已登录用户的邮箱
   */
  async getLoggedInEmail(): Promise<string> {
    if (!this.preferences) {
      return '';
    }
    return await this.preferences.get(Constants.AUTH_KEY_EMAIL, '') as string;
  }

  /**
   * 获取已登录用户的ID
   */
  async getLoggedInUserId(): Promise<number> {
    if (!this.preferences) {
      return 0;
    }
    return await this.preferences.get(Constants.AUTH_KEY_USER_ID, 0) as number;
  }

  /**
   * 发送邮箱验证码
   */
  async sendVerificationCode(email: string): Promise<string> {
    try {
      const url: string = Constants.EMAIL_API_URL + '/api/send-code';
      const result: SendCodeResponse | null = await this.networkService.postSendCode(url, email);

      if (result && result.success) {
        console.info('验证码已发送到 ' + email);
        return 'sent';
      } else {
        if (result) {
          console.error('发送验证码失败: ' + result.message);
        }
        return '';
      }
    } catch (error) {
      console.error('发送验证码请求失败:', error);
      return '';
    }
  }

  /**
   * 验证邮箱验证码
   */
  async verifyCode(email: string, code: string): Promise<boolean> {
    try {
      const url: string = Constants.EMAIL_API_URL + '/api/verify-code';
      const result: VerifyCodeResponse | null = await this.networkService.postVerifyCode(url, email, code);

      if (result && result.success) {
        console.info('邮箱 ' + email + ' 验证成功');
        return true;
      } else {
        if (result) {
          console.error('验证失败: ' + result.message);
        }
        return false;
      }
    } catch (error) {
      console.error('验证请求失败:', error);
      return false;
    }
  }
}
