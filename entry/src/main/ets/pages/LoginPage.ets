import { router } from '@kit.ArkUI';
import { AuthService } from '../service/AuthService';
import { Constants } from '../utils/Constants';
import { LoginResult } from '../model/User';

/**
 * 登录页面
 */
@Entry
@Component
struct LoginPage {
  @State email: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showPassword: boolean = false;
  @State isCheckingLogin: boolean = true;

  private authService: AuthService = AuthService.getInstance();

  async aboutToAppear() {
    // 延迟一下确保 AuthService 初始化完成
    await this.delay(100);
    try {
      // 检查是否已登录
      const loggedIn: boolean = await this.authService.isLoggedIn();
      if (loggedIn) {
        router.replaceUrl({ url: Constants.ROUTES.INDEX });
      }
    } catch (error) {
      console.error('检查登录状态失败:', error);
    }
    this.isCheckingLogin = false;
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  build() {
    Column() {
      if (this.isCheckingLogin) {
        // 加载中
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        // 渐变顶部装饰
        Column() {
          this.HeaderSection()
        }
        .width('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FF6B35', 0.0], ['#FF8A5C', 0.6], ['#FAF8F5', 1.0]]
        })
        .padding({ top: 60, bottom: 40 })

        // 表单区域
        this.FormSection()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Constants.COLORS.background)
  }

  /**
   * 头部区域
   */
  @Builder
  HeaderSection() {
    Column() {
      Text('🍳')
        .fontSize(72)
        .margin({ bottom: 16 })

      Text(Constants.APP_NAME)
        .fontSize(Constants.FONT_SIZE.title)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('邮箱登录')
        .fontSize(Constants.FONT_SIZE.large)
        .fontColor('#FFFFFFCC')
        .margin({ top: 8 })
    }
  }

  /**
   * 表单区域
   */
  @Builder
  FormSection() {
    Column() {
      // 邮箱输入
      this.EmailInput()

      // 密码输入
      this.PasswordInput()

      // 错误提示
      this.ErrorTip()

      // 登录按钮
      this.LoginButton()

      // 注册链接
      this.RegisterLink()
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
  }

  /**
   * 邮箱输入框
   */
  @Builder
  EmailInput() {
    Column() {
      Text('邮箱')
        .fontSize(Constants.FONT_SIZE.small)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })

      TextInput({ placeholder: '请输入邮箱地址', text: this.email })
        .type(InputType.Email)
        .height(50)
        .fontSize(Constants.FONT_SIZE.normal)
        .backgroundColor(Constants.COLORS.warmWhite)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .border({ width: 1, color: Constants.COLORS.divider })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.email = value;
          this.errorMessage = '';
        })
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 密码输入框
   */
  @Builder
  PasswordInput() {
    Column() {
      Text('密码')
        .fontSize(Constants.FONT_SIZE.small)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })

      Row() {
        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .layoutWeight(1)
          .height(50)
          .fontSize(Constants.FONT_SIZE.normal)
          .backgroundColor(Constants.COLORS.warmWhite)
          .borderRadius(Constants.BORDER_RADIUS.medium)
          .border({ width: 1, color: Constants.COLORS.divider })
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.password = value;
            this.errorMessage = '';
          })

        Text(this.showPassword ? '🙈' : '👁')
          .fontSize(20)
          .margin({ left: 12 })
          .onClick(() => {
            this.showPassword = !this.showPassword;
          })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  /**
   * 错误提示
   */
  @Builder
  ErrorTip() {
    if (this.errorMessage) {
      Text(this.errorMessage)
        .fontSize(Constants.FONT_SIZE.small)
        .fontColor(Constants.COLORS.error)
        .width('100%')
        .margin({ bottom: 12 })
    }
  }

  /**
   * 登录按钮
   */
  @Builder
  LoginButton() {
    Button(this.isLoading ? '登录中...' : '登录')
      .type(ButtonType.Capsule)
      .width('100%')
      .height(52)
      .fontSize(Constants.FONT_SIZE.medium)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .backgroundColor(Constants.COLORS.primary)
      .shadow(Constants.SHADOWS.colored)
      .enabled(!this.isLoading && this.email.length > 0 && this.password.length > 0)
      .margin({ top: 24 })
      .stateStyles({
        pressed: {
          .opacity(Constants.OPACITY.pressed)
          .scale({ x: 0.97, y: 0.97 })
        }
      })
      .onClick(() => {
        this.handleLogin();
      })
  }

  /**
   * 注册链接
   */
  @Builder
  RegisterLink() {
    Column() {
      Row() {
        Divider()
          .strokeWidth(1)
          .color(Constants.COLORS.divider)
          .width(60)
          .margin({ right: 12 })

        Text('其他操作')
          .fontSize(12)
          .fontColor(Constants.COLORS.textLight)

        Divider()
          .strokeWidth(1)
          .color(Constants.COLORS.divider)
          .width(60)
          .margin({ left: 12 })
      }
      .width('100%')
      .margin({ top: 24, bottom: 16 })

      Row() {
        Text('没有账号？')
          .fontSize(Constants.FONT_SIZE.normal)
          .fontColor(Constants.COLORS.textSecondary)

        Text('去注册')
          .fontSize(Constants.FONT_SIZE.normal)
          .fontColor(Constants.COLORS.primary)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
      }
      .stateStyles({
        pressed: {
          .opacity(Constants.OPACITY.pressed)
        }
      })
      .onClick(() => {
        console.info('点击去注册，跳转: ' + Constants.ROUTES.REGISTER);
        router.pushUrl({ url: Constants.ROUTES.REGISTER });
      })

      // 测试账号提示
      Column() {
        Text('测试账号')
          .fontSize(12)
          .fontColor(Constants.COLORS.textLight)
          .margin({ top: 20, bottom: 6 })

        Text('邮箱: test@test.com  密码: 123456')
          .fontSize(12)
          .fontColor(Constants.COLORS.textLight)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(Constants.COLORS.warmGray)
          .borderRadius(Constants.BORDER_RADIUS.small)
      }
    }
    .margin({ top: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 处理登录
   */
  private async handleLogin() {
    // 验证邮箱格式
    if (!/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(this.email)) {
      this.errorMessage = '请输入正确的邮箱地址';
      return;
    }

    // 验证密码
    if (this.password.length < 6) {
      this.errorMessage = '密码不能少于6位';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const result: LoginResult = await this.authService.login(this.email, this.password);
      if (result.success) {
        router.replaceUrl({ url: Constants.ROUTES.INDEX });
      } else {
        this.errorMessage = result.message;
      }
    } catch (error) {
      this.errorMessage = '登录失败，请重试';
    }

    this.isLoading = false;
  }
}
