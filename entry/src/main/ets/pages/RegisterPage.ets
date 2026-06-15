import { router } from '@kit.ArkUI';
import { AuthService } from '../service/AuthService';
import { Constants } from '../utils/Constants';
import { LoginResult } from '../model/User';

/**
 * 注册页面（真实邮箱验证）
 */
@Entry
@Component
struct RegisterPage {
  @State currentStep: number = 1;
  @State email: string = '';
  @State emailCode: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showPassword: boolean = false;
  @State countdown: number = 0;
  @State verifyAttempts: number = 0;
  @State sliderOffset: number = 0;
  @State isVerified: boolean = false;
  @State trackWidth: number = 0;
  @State sliderTarget: number = 0.6;

  private authService: AuthService = AuthService.getInstance();
  private countdownTimer: number = -1;
  private readonly thumbSize: number = 44;

  aboutToAppear() {
    this.sliderTarget = 0.3 + Math.random() * 0.5;
  }

  aboutToDisappear() {
    this.clearCountdown();
  }

  build() {
    Column() {
      // 导航栏 - 渐变背景
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .stateStyles({
            pressed: {
              .opacity(Constants.OPACITY.pressed)
            }
          })
          .onClick(() => {
            if (this.currentStep > 1 && this.currentStep < 5) {
              this.currentStep--;
              this.errorMessage = '';
            } else {
              router.back();
            }
          })
        Text('注册账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('    ').fontSize(16)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
      })

      // 步骤指示器
      Row() {
        Row().width(this.currentStep >= 1 ? 28 : 16).height(5).backgroundColor(this.currentStep >= 1 ? Constants.COLORS.primary : Constants.COLORS.divider).borderRadius(3).margin({ right: 8 })
        Row().width(this.currentStep >= 2 ? 28 : 16).height(5).backgroundColor(this.currentStep >= 2 ? Constants.COLORS.primary : Constants.COLORS.divider).borderRadius(3).margin({ right: 8 })
        Row().width(this.currentStep >= 3 ? 28 : 16).height(5).backgroundColor(this.currentStep >= 3 ? Constants.COLORS.primary : Constants.COLORS.divider).borderRadius(3).margin({ right: 8 })
        Row().width(this.currentStep >= 4 ? 28 : 16).height(5).backgroundColor(this.currentStep >= 4 ? Constants.COLORS.primary : Constants.COLORS.divider).borderRadius(3)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 16 })

      Scroll() {
        Column() {
          if (this.currentStep === 1) {
            this.StepEmail()
          } else if (this.currentStep === 2) {
            this.StepCaptcha()
          } else if (this.currentStep === 3) {
            this.StepEmailCode()
          } else if (this.currentStep === 4) {
            this.StepPassword()
          } else if (this.currentStep === 5) {
            this.StepDone()
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Constants.COLORS.background)
  }

  /**
   * 步骤1：输入邮箱
   */
  @Builder
  StepEmail() {
    Column() {
      Text('请输入邮箱')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ top: 20, bottom: 8 })
      Text('注册后即可使用邮箱登录')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 32 })

      TextInput({ placeholder: '请输入邮箱地址', text: this.email })
        .type(InputType.Email)
        .height(50)
        .fontSize(16)
        .backgroundColor(Constants.COLORS.warmWhite)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .border({ width: 1, color: Constants.COLORS.divider })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.email = value;
          this.errorMessage = '';
        })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(Constants.COLORS.error)
          .margin({ top: 8 })
      }

      Button('下一步')
        .type(ButtonType.Capsule)
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .shadow(Constants.SHADOWS.colored)
        .enabled(this.email.length > 0)
        .margin({ top: 32 })
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          if (/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(this.email)) {
            this.currentStep = 2;
            this.errorMessage = '';
            this.sliderTarget = 0.3 + Math.random() * 0.5;
            this.sliderOffset = 0;
            this.isVerified = false;
          } else {
            this.errorMessage = '请输入正确的邮箱地址';
          }
        })
    }
  }

  /**
   * 步骤2：滑块验证
   */
  @Builder
  StepCaptcha() {
    Column() {
      Text('安全验证')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ top: 20, bottom: 8 })
      Text('请将滑块拖到目标位置')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 32 })

      // 滑块验证
      Column() {
        Row() {
          Text(this.isVerified ? '验证通过 ✓' : '请滑动到绿色区域')
            .fontSize(14)
            .fontColor(this.isVerified ? Constants.COLORS.success : Constants.COLORS.textSecondary)
        }
        .width('100%')
        .margin({ bottom: 12 })

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(this.thumbSize)
            .backgroundColor('#EEEEEE')
            .borderRadius(this.thumbSize / 2)

          Row()
            .width(this.thumbSize + 8)
            .height(this.thumbSize)
            .position({ x: this.sliderTarget * (this.trackWidth - this.thumbSize - 8) })
            .backgroundColor('#C8E6C9')
            .borderRadius(this.thumbSize / 2)
            .opacity(this.isVerified ? 0 : 0.7)

          Row()
            .width(this.sliderOffset + this.thumbSize / 2)
            .height(this.thumbSize)
            .backgroundColor(this.isVerified ? '#E8F5E9' : '#FFF3E0')
            .borderRadius(this.thumbSize / 2)

          Row() {
            Text(this.isVerified ? '✓' : '⟫')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(this.thumbSize)
          .height(this.thumbSize)
          .backgroundColor(this.isVerified ? Constants.COLORS.success : Constants.COLORS.primary)
          .borderRadius(this.thumbSize / 2)
          .justifyContent(FlexAlign.Center)
          .offset({ x: this.sliderOffset })
          .gesture(
            PanGesture()
              .onActionUpdate((event: GestureEvent) => {
                if (!this.isVerified && this.trackWidth > 0) {
                  const max: number = this.trackWidth - this.thumbSize;
                  this.sliderOffset = Math.max(0, Math.min(event.offsetX, max));
                }
              })
              .onActionEnd(() => {
                if (!this.isVerified) {
                  this.checkSlider();
                }
              })
          )
        }
        .width('100%')
        .height(this.thumbSize)
        .clip(true)
        .onAreaChange((_old: Area, newVal: Area) => {
          this.trackWidth = newVal.width as number;
        })
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Constants.COLORS.warmWhite)
      .borderRadius(Constants.BORDER_RADIUS.large)
      .shadow(Constants.SHADOWS.medium)

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(Constants.COLORS.error)
          .margin({ top: 12 })
      }
    }
  }

  /**
   * 步骤3：输入邮箱验证码
   */
  @Builder
  StepEmailCode() {
    Column() {
      Text('输入验证码')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ top: 20, bottom: 8 })
      Text('验证码已发送到: ' + this.email)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })
      Text('请查看您的邮箱（包括垃圾邮件）')
        .fontSize(12)
        .fontColor(Constants.COLORS.textLight)
        .margin({ bottom: 24 })

      TextInput({ placeholder: '请输入6位验证码', text: this.emailCode })
        .type(InputType.Number)
        .maxLength(6)
        .height(50)
        .fontSize(16)
        .backgroundColor(Constants.COLORS.warmWhite)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .border({ width: 1, color: Constants.COLORS.divider })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.emailCode = value;
          this.errorMessage = '';
        })

      Row() {
        if (this.countdown > 0) {
          Text(this.countdown + '秒后可重新发送')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
        } else {
          Text('重新发送验证码')
            .fontSize(12)
            .fontColor(Constants.COLORS.primary)
            .onClick(() => {
              this.resendCode();
            })
        }
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.End)

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(Constants.COLORS.error)
          .margin({ top: 8 })
      }

      Button(this.isLoading ? '验证中...' : '验证')
        .type(ButtonType.Capsule)
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .shadow(Constants.SHADOWS.colored)
        .enabled(!this.isLoading && this.emailCode.length === 6)
        .margin({ top: 32 })
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          this.verifyCode();
        })
    }
  }

  /**
   * 步骤4：设置密码
   */
  @Builder
  StepPassword() {
    Column() {
      Text('设置密码')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ top: 20, bottom: 8 })
      Text('请设置6位以上密码')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 32 })

      Text('昵称（选填）')
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '给自己取个好听的名字', text: this.nickname })
        .height(50)
        .fontSize(16)
        .backgroundColor(Constants.COLORS.warmWhite)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .border({ width: 1, color: Constants.COLORS.divider })
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.nickname = value;
        })

      Text('密码')
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Row() {
        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .layoutWeight(1)
          .height(50)
          .fontSize(16)
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
      .margin({ bottom: 20 })

      Text('确认密码')
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
        .type(this.showPassword ? InputType.Normal : InputType.Password)
        .height(50)
        .fontSize(16)
        .backgroundColor(Constants.COLORS.warmWhite)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .border({ width: 1, color: Constants.COLORS.divider })
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.confirmPassword = value;
          this.errorMessage = '';
        })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(Constants.COLORS.error)
          .margin({ top: 8 })
      }

      Button(this.isLoading ? '注册中...' : '完成注册')
        .type(ButtonType.Capsule)
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .shadow(Constants.SHADOWS.colored)
        .enabled(!this.isLoading && this.password.length >= 6 && this.confirmPassword.length >= 6)
        .margin({ top: 32 })
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          this.doRegister();
        })
    }
  }

  /**
   * 步骤5：注册成功
   */
  @Builder
  StepDone() {
    Column() {
      Text('🎉')
        .fontSize(80)
        .margin({ top: 60, bottom: 24 })
      Text('注册成功')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ bottom: 12 })
      Text('欢迎加入智能菜谱推荐助手')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 40 })
      Button('开始使用')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .shadow(Constants.SHADOWS.colored)
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          router.replaceUrl({ url: Constants.ROUTES.INDEX });
        })
    }
  }

  /**
   * 检查滑块验证
   */
  private async checkSlider(): Promise<void> {
    if (this.trackWidth <= this.thumbSize) {
      return;
    }
    const max: number = this.trackWidth - this.thumbSize;
    const pos: number = this.sliderOffset / max;
    if (Math.abs(pos - this.sliderTarget) < 0.08) {
      this.isVerified = true;
      this.errorMessage = '';

      // 发送验证码到邮箱
      const result: string = await this.authService.sendVerificationCode(this.email);
      if (result === 'sent') {
        this.currentStep = 3;
        this.startCountdown();
      } else {
        this.errorMessage = '验证码发送失败，请重试';
        this.isVerified = false;
        this.sliderOffset = 0;
      }
    } else {
      this.errorMessage = '验证失败，请重试';
      animateTo({ duration: 200 }, () => {
        this.sliderOffset = 0;
      });
    }
  }

  /**
   * 验证邮箱验证码
   */
  private async verifyCode(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    const success: boolean = await this.authService.verifyCode(this.email, this.emailCode);

    if (success) {
      this.currentStep = 4;
      this.verifyAttempts = 0;
    } else {
      this.verifyAttempts++;
      if (this.verifyAttempts >= 3) {
        this.errorMessage = '验证次数过多，请重新验证';
        this.currentStep = 2;
        this.emailCode = '';
        this.verifyAttempts = 0;
        this.sliderOffset = 0;
        this.isVerified = false;
        this.sliderTarget = 0.3 + Math.random() * 0.5;
      } else {
        this.errorMessage = '验证码错误，还可尝试' + (3 - this.verifyAttempts) + '次';
      }
    }

    this.isLoading = false;
  }

  /**
   * 重新发送验证码
   */
  private async resendCode(): Promise<void> {
    const result: string = await this.authService.sendVerificationCode(this.email);
    if (result === 'sent') {
      this.startCountdown();
    } else {
      this.errorMessage = '验证码发送失败，请重试';
    }
  }

  /**
   * 执行注册
   */
  private async doRegister(): Promise<void> {
    if (this.password.length < 6) {
      this.errorMessage = '密码不能少于6位';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const result: LoginResult = await this.authService.registerAndLogin(
        this.email, this.password, this.nickname || '美食家'
      );
      if (result.success) {
        this.currentStep = 5;
      } else {
        this.errorMessage = result.message;
      }
    } catch (error) {
      this.errorMessage = '注册失败，请重试';
    }
    this.isLoading = false;
  }

  /**
   * 开始倒计时
   */
  private startCountdown(): void {
    this.clearCountdown();
    this.countdown = 60;
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        this.clearCountdown();
      }
    }, 1000);
  }

  /**
   * 清除倒计时
   */
  private clearCountdown(): void {
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }
}
