import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { AuthService } from '../service/AuthService';
import { Constants } from '../utils/Constants';

/**
 * 个人中心页
 */
@Entry
@Component
struct ProfilePage {
  @State favoriteCount: number = 0;
  @State historyCount: number = 0;
  @State cookingCount: number = 0;
  @State publishCount: number = 0;
  @State userName: string = '美食爱好者';
  @State userLevel: number = 3;
  @State dailyCalories: number = 2000;
  @State todayCalories: number = 0;

  private dbService: DatabaseService = DatabaseService.getInstance();
  private authService: AuthService = AuthService.getInstance();

  aboutToAppear() {
    this.loadStats();
    this.loadUserInfo();
  }

  async loadStats() {
    try {
      const favorites = await this.dbService.getFavoriteRecipes();
      this.favoriteCount = favorites.length;

      const history = await this.dbService.getBrowseHistory(100);
      this.historyCount = history.length;

      const records = await this.dbService.getCookingRecords();
      this.cookingCount = records.length;
    } catch (error) {
      console.error('加载统计失败:', error);
    }
  }

  async loadUserInfo() {
    try {
      const email: string = await this.authService.getLoggedInEmail();
      if (email) {
        const user = await this.dbService.getUserByEmail(email);
        if (user && user.nickname) {
          this.userName = user.nickname;
        }
      }
    } catch (error) {
      console.error('加载用户信息失败:', error);
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      Scroll() {
        Column() {
          // 用户信息卡片
          this.UserInfoCard()

          // 统计数据
          this.StatsSection()

          // 功能菜单
          this.MenuSection()

          // 每日营养统计
          this.NutritionSection()

          // 设置
          this.SettingsSection()
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Constants.COLORS.background)
  }

  @Builder
  TopNavBar() {
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
          router.back();
        })

      Blank()

      Text('个人中心')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Blank()

      Text('设置')
        .fontSize(16)
        .fontColor('#FFFFFFCC')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
    })
  }

  @Builder
  UserInfoCard() {
    Column() {
      Row() {
        // 头像 - 带光环
        Stack() {
          Circle({ width: 76, height: 76 })
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
            })

          Text(this.userName.charAt(0))
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(76)
        .height(76)
        .alignContent(Alignment.Center)

        // 用户信息
        Column() {
          Text(this.userName)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)

          Row() {
            Text('Lv.' + this.userLevel)
              .fontSize(14)
              .fontColor(Constants.COLORS.primary)
              .backgroundColor(Constants.COLORS.accentLight)
              .borderRadius(Constants.BORDER_RADIUS.round)
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })

            Text('美食达人')
              .fontSize(14)
              .fontColor(Constants.COLORS.textSecondary)
              .margin({ left: 10 })
          }
          .margin({ top: 10 })

          Text('记录每一顿美味')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.medium)
    .margin({ top: 12 })
  }

  @Builder
  StatsSection() {
    Row() {
      this.StatsItem('❤️', '收藏', this.favoriteCount)
      this.StatsItem('📖', '浏览', this.historyCount)
      this.StatsItem('👨‍🍳', '做过', this.cookingCount)
      this.StatsItem('📝', '发布', this.publishCount)
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  @Builder
  StatsItem(icon: string, label: string, count: number) {
    Column() {
      Text(icon)
        .fontSize(24)

      Text('' + count)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ top: 4 })

      Text(label)
        .fontSize(12)
        .fontColor(Constants.COLORS.textLight)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MenuSection() {
    Column() {
      this.MenuItem('❤️', '我的收藏', () => {
        router.pushUrl({ url: Constants.ROUTES.FAVORITE });
      })

      this.MenuItem('📖', '浏览历史', () => {
        router.pushUrl({ url: Constants.ROUTES.FAVORITE });
      })

      this.MenuItem('👨‍🍳', '烹饪记录', () => {
        router.pushUrl({ url: Constants.ROUTES.FAVORITE });
      })

      this.MenuItem('📝', '我的发布', () => {
        router.pushUrl({ url: Constants.ROUTES.COMMUNITY });
      })

      this.MenuItem('📷', '拍照识别', () => {
        router.pushUrl({ url: Constants.ROUTES.CAMERA });
      })

      this.MenuItem('🥕', '食材推荐', () => {
        router.pushUrl({ url: Constants.ROUTES.INGREDIENT });
      })

      this.MenuItem('📥', '数据导入', () => {
        router.pushUrl({ url: 'pages/DataImportPage' });
      })
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  MenuItem(icon: string, title: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor(Constants.COLORS.warmGray)
        .borderRadius(Constants.BORDER_RADIUS.normal)

      Text(title)
        .fontSize(16)
        .fontColor(Constants.COLORS.text)
        .layoutWeight(1)
        .margin({ left: 12 })

      Text('>')
        .fontSize(16)
        .fontColor(Constants.COLORS.textLight)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .stateStyles({
      pressed: {
        .backgroundColor(Constants.COLORS.warmGray)
      }
    })
    .onClick(onClick)
  }

  @Builder
  NutritionSection() {
    Column() {
      Row() {
        Text('每日营养统计')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('设置目标')
          .fontSize(14)
          .fontColor(Constants.COLORS.primary)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 热量进度
      Column() {
        Row() {
          Text('今日热量')
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)

          Blank()

          Text(this.todayCalories + ' / ' + this.dailyCalories + ' 千卡')
            .fontSize(14)
            .fontColor(Constants.COLORS.text)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ bottom: 10 })

        Progress({
          value: this.todayCalories,
          total: this.dailyCalories,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(10)
          .color(this.todayCalories > this.dailyCalories ? Constants.COLORS.error : Constants.COLORS.primary)
          .borderRadius(5)
      }
      .width('100%')

      // 营养素比例
      Row() {
        this.NutritionItem('蛋白质', 0, '#4CAF50')
        this.NutritionItem('碳水', 0, '#FF9800')
        this.NutritionItem('脂肪', 0, '#E8453C')
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  @Builder
  NutritionItem(name: string, value: number, color: ResourceColor) {
    Column() {
      Text(name)
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)

      Text(value + 'g')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(Constants.COLORS.warmGray)
    .borderRadius(Constants.BORDER_RADIUS.medium)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 8 })
  }

  @Builder
  SettingsSection() {
    Column() {
      Text('设置')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .margin({ bottom: 12 })

      this.MenuItem('👤', '个人信息', () => {})
      this.MenuItem('🔔', '消息通知', () => {})
      this.MenuItem('🎨', '主题设置', () => {})
      this.MenuItem('❓', '帮助反馈', () => {})
      this.MenuItem('ℹ️', '关于', () => {})
      this.MenuItem('🚪', '退出登录', () => {
        this.handleLogout();
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  /**
   * 处理退出登录
   */
  private async handleLogout() {
    await this.authService.logout();
    router.replaceUrl({ url: Constants.ROUTES.LOGIN });
  }
}
