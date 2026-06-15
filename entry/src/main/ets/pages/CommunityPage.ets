import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { ShareService } from '../service/ShareService';
import { CommunityRecipe } from '../model/UserPreference';
import { Constants } from '../utils/Constants';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 社区分享广场页
 */
@Entry
@Component
struct CommunityPage {
  @State communityRecipes: CommunityRecipe[] = [];
  @State isLoading: boolean = true;
  @State selectedTab: number = 0; // 0: 最新, 1: 最热

  private dbService: DatabaseService = DatabaseService.getInstance();
  private shareService: ShareService = ShareService.getInstance();

  aboutToAppear() {
    this.loadCommunityRecipes();
  }

  async loadCommunityRecipes() {
    this.isLoading = true;
    try {
      this.communityRecipes = await this.dbService.getCommunityRecipes(50);

      // 如果没有社区数据，添加一些示例数据
      if (this.communityRecipes.length === 0) {
        await this.addSampleData();
        this.communityRecipes = await this.dbService.getCommunityRecipes(50);
      }

      // 按热度排序
      if (this.selectedTab === 1) {
        this.communityRecipes.sort((a, b) => b.likes - a.likes);
      }
    } catch (error) {
      console.error('加载社区数据失败:', error);
    }
    this.isLoading = false;
  }

  async addSampleData() {
    const sampleRecipes: CommunityRecipe[] = [
      {
        id: 0,
        recipeId: 1,
        userId: 'user1',
        userName: '美食家小王',
        title: '我的拿手菜：秘制红烧肉',
        content: '这道红烧肉是我奶奶传下来的秘方，肥而不腻，入口即化。关键在于冰糖的用量和火候的掌握...',
        images: [],
        likes: 128,
        comments: 23,
        createTime: '2024-01-15T10:30:00',
        isLiked: false
      },
      {
        id: 0,
        recipeId: 2,
        userId: 'user2',
        userName: '厨房小白',
        title: '新手也能做的番茄炒蛋',
        content: '作为厨房小白，这道番茄炒蛋是我学会的第一道菜！分享给大家我的做法...',
        images: [],
        likes: 89,
        comments: 15,
        createTime: '2024-01-14T15:20:00',
        isLiked: false
      },
      {
        id: 0,
        recipeId: 3,
        userId: 'user3',
        userName: '健身达人',
        title: '减脂餐：清蒸鸡胸肉',
        content: '健身期间的蛋白质来源，简单又美味。搭配西兰花和糙米饭，完美的健身餐...',
        images: [],
        likes: 156,
        comments: 31,
        createTime: '2024-01-13T08:45:00',
        isLiked: false
      }
    ];

    for (let i = 0; i < sampleRecipes.length; i++) {
      await this.dbService.publishCommunityRecipe(sampleRecipes[i]);
    }
  }

  async toggleLike(recipe: CommunityRecipe) {
    await this.dbService.toggleLikeCommunityRecipe(recipe.id);
    recipe.isLiked = !recipe.isLiked;
    recipe.likes += recipe.isLiked ? 1 : -1;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      // Tab切换
      this.TabSection()

      if (this.isLoading) {
        SkeletonView({ skeletonType: 'cardList' })
      } else if (this.communityRecipes.length === 0) {
        // 空状态
        Column() {
          Text('📝')
            .fontSize(64)
            .margin({ bottom: 16 })

          Text('还没有人分享')
            .fontSize(18)
            .fontColor(Constants.COLORS.textSecondary)

          Text('成为第一个分享的人吧！')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 8 })

          Button('发布菜谱')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(Constants.COLORS.primary)
            .borderRadius(24)
            .height(44)
            .margin({ top: 24 })
            .onClick(() => {
              router.pushUrl({ url: Constants.ROUTES.PUBLISH_RECIPE });
            })
        }
        .width('100%')
        .height(400)
        .justifyContent(FlexAlign.Center)
      } else {
        // 社区菜谱列表
        List() {
          ForEach(this.communityRecipes, (recipe: CommunityRecipe) => {
            ListItem() {
              this.CommunityRecipeCard(recipe)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#EEEEEE' })
      }

      // 底部发布按钮
      this.PublishButton()
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
        .fontColor(Constants.COLORS.text)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .stateStyles({
          pressed: {
            .backgroundColor(Constants.COLORS.warmGray)
          }
        })
        .onClick(() => {
          router.back();
        })

      Blank()

      Text('美食社区')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)

      Blank()

      Text('')
        .width(40)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Constants.COLORS.surface)
    .shadow(Constants.SHADOWS.small)
  }

  @Builder
  TabSection() {
    Row() {
      this.TabItem('最新', 0)
      this.TabItem('最热', 1)
    }
    .width('100%')
    .height(44)
    .backgroundColor(Constants.COLORS.surface)
  }

  @Builder
  TabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedTab === index ? Constants.COLORS.primary : Constants.COLORS.textSecondary)

      Divider()
        .strokeWidth(2)
        .color(this.selectedTab === index ? Constants.COLORS.primary : 'transparent')
        .width('40%')
        .margin({ top: 4 })
        .animation({
          duration: Constants.ANIMATION_DURATION.fast,
          curve: Curve.EaseInOut
        })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .stateStyles({
      pressed: {
        .backgroundColor(Constants.COLORS.warmGray)
      }
    })
    .onClick(() => {
      this.selectedTab = index;
      this.loadCommunityRecipes();
    })
  }

  @Builder
  CommunityRecipeCard(recipe: CommunityRecipe) {
    Column() {
      // 用户信息
      Row() {
        Stack() {
          Circle({ width: 44, height: 44 })
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
            })

          Text(recipe.userName.charAt(0))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(44)
        .height(44)
        .alignContent(Alignment.Center)

        Column() {
          Text(recipe.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Constants.COLORS.text)

          Text(this.formatTime(recipe.createTime))
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .margin({ bottom: 14 })

      // 标题
      Text(recipe.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .margin({ bottom: 10 })

      // 内容
      Text(recipe.content)
        .fontSize(15)
        .fontColor(Constants.COLORS.textSecondary)
        .width('100%')
        .lineHeight(24)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 14 })

      // 图片（如果有）
      if (recipe.images.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(recipe.images.slice(0, 3), (image: string) => {
            Image(image)
              .width(100)
              .height(100)
              .borderRadius(Constants.BORDER_RADIUS.normal)
              .objectFit(ImageFit.Cover)
          })
        }
        .width('100%')
        .margin({ bottom: 14 })
      }

      // 操作栏
      Row() {
        // 点赞
        Row() {
          Text(recipe.isLiked ? '❤️' : '🤍')
            .fontSize(18)

          Text('' + recipe.likes)
            .fontSize(14)
            .fontColor(recipe.isLiked ? Constants.COLORS.primary : Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
        .onClick(() => {
          this.toggleLike(recipe);
        })

        // 评论
        Row() {
          Text('💬')
            .fontSize(18)

          Text('' + recipe.comments)
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
        .margin({ left: 28 })

        // 分享
        Row() {
          Text('↗️')
            .fontSize(18)
        }
        .margin({ left: 28 })
        .onClick(() => {
          this.shareService.shareCommunityPost(getContext(this), recipe.title, recipe.content, recipe.userName);
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.medium)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
      }
    })
  }

  @Builder
  PublishButton() {
    Column() {
      Button('发布我的菜谱')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .borderRadius(Constants.BORDER_RADIUS.round)
        .height(52)
        .width('90%')
        .shadow(Constants.SHADOWS.colored)
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          router.pushUrl({ url: Constants.ROUTES.PUBLISH_RECIPE });
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 20 })
    .backgroundColor(Constants.COLORS.surface)
  }

  formatTime(timeStr: string): string {
    try {
      const date = new Date(timeStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();

      const minutes = Math.floor(diff / 60000);
      const hours = Math.floor(diff / 3600000);
      const days = Math.floor(diff / 86400000);

      if (minutes < 1) return '刚刚';
      if (minutes < 60) return minutes + '分钟前';
      if (hours < 24) return hours + '小时前';
      if (days < 7) return days + '天前';

      return (date.getMonth() + 1) + '月' + date.getDate() + '日';
    } catch {
      return timeStr;
    }
  }
}
