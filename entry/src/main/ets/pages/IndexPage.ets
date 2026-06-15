import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { RecommendService } from '../service/RecommendService';
import { ShareService } from '../service/ShareService';
import { Recipe } from '../model/Recipe';
import { CommunityRecipe } from '../model/UserPreference';
import { Constants, CategoryItem } from '../utils/Constants';
import { CoverImage } from '../components/CoverImage';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 首页 - 推荐与搜索（带底部导航栏）
 */
@Entry
@Component
struct IndexPage {
  @State searchText: string = '';
  @State recommendedRecipes: Recipe[] = [];
  @State hotRecipes: Recipe[] = [];
  @State dailyRecipes: Recipe[] = [];
  @State favoriteRecipes: Recipe[] = [];
  @State communityRecipes: CommunityRecipe[] = [];
  @State isLoading: boolean = true;
  @State currentBannerIndex: number = 0;
  @State currentTab: number = 0; // 0=首页, 1=收藏, 2=社区, 3=我的
  @State communityTab: number = 0; // 0=最新, 1=最热
  @State tabScale: number = 1;

  private dbService: DatabaseService = DatabaseService.getInstance();
  private recommendService: RecommendService = RecommendService.getInstance();
  private shareService: ShareService = ShareService.getInstance();

  aboutToAppear() {
    this.loadData();
    this.loadFavorites();
    this.loadCommunityRecipes();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.recommendedRecipes = await this.recommendService.getDailyRecommendation(6);
      this.hotRecipes = await this.recommendService.getHotRecipes(10);
      this.dailyRecipes = await this.dbService.getRecommendedRecipes(5);
    } catch (error) {
      console.error('加载数据失败:', error);
    }
    this.isLoading = false;
  }

  async loadFavorites() {
    try {
      this.favoriteRecipes = await this.dbService.getFavoriteRecipes();
    } catch (error) {
      console.error('加载收藏失败:', error);
    }
  }

  async loadCommunityRecipes() {
    try {
      this.communityRecipes = await this.dbService.getCommunityRecipes(50);
      // 如果没有社区数据，添加示例数据
      if (this.communityRecipes.length === 0) {
        await this.addSampleCommunityData();
        this.communityRecipes = await this.dbService.getCommunityRecipes(50);
      }
      // 按热度排序
      if (this.communityTab === 1) {
        this.communityRecipes.sort((a: CommunityRecipe, b: CommunityRecipe) => b.likes - a.likes);
      }
    } catch (error) {
      console.error('加载社区数据失败:', error);
    }
  }

  async addSampleCommunityData() {
    const sampleRecipes: CommunityRecipe[] = [];
    const r1: CommunityRecipe = new CommunityRecipe();
    r1.recipeId = 1;
    r1.userId = 'user1';
    r1.userName = '美食家小王';
    r1.title = '我的拿手菜：秘制红烧肉';
    r1.content = '这道红烧肉是我奶奶传下来的秘方，肥而不腻，入口即化。关键在于冰糖的用量和火候的掌握...';
    r1.likes = 128;
    r1.comments = 23;
    sampleRecipes.push(r1);

    const r2: CommunityRecipe = new CommunityRecipe();
    r2.recipeId = 2;
    r2.userId = 'user2';
    r2.userName = '厨房小白';
    r2.title = '新手也能做的番茄炒蛋';
    r2.content = '作为厨房小白，这道番茄炒蛋是我学会的第一道菜！分享给大家我的做法...';
    r2.likes = 89;
    r2.comments = 15;
    sampleRecipes.push(r2);

    const r3: CommunityRecipe = new CommunityRecipe();
    r3.recipeId = 3;
    r3.userId = 'user3';
    r3.userName = '健身达人';
    r3.title = '减脂餐：清蒸鸡胸肉';
    r3.content = '健身期间的蛋白质来源，简单又美味。搭配西兰花和糙米饭，完美的健身餐...';
    r3.likes = 156;
    r3.comments = 31;
    sampleRecipes.push(r3);

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
      // 根据当前Tab显示不同内容
      if (this.currentTab === 0) {
        this.HomeContent()
      } else if (this.currentTab === 1) {
        this.FavoriteContent()
      } else if (this.currentTab === 2) {
        this.CommunityContent()
      } else {
        this.ProfileContent()
      }

      // 底部导航栏
      this.TabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Constants.COLORS.background)
  }

  // 首页内容
  @Builder
  HomeContent() {
    Column() {
      // 顶部搜索栏
      this.SearchHeader()

      if (this.isLoading) {
        SkeletonView({ skeletonType: 'cardList' })
      } else {
        Scroll() {
          Column() {
            // 轮播Banner
            this.BannerSection()

            // 分类快捷入口
            this.CategorySection()

            // 今日推荐
            this.RecommendSection()

            // 热门菜谱
            this.HotRecipeSection()
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 收藏内容
  @Builder
  FavoriteContent() {
    Column() {
      // 标题栏
      Row() {
        Text('我的收藏')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      if (this.favoriteRecipes.length === 0) {
        // 空状态
        Column() {
          Text('❤️')
            .fontSize(60)
            .margin({ bottom: 16 })
          Text('还没有收藏')
            .fontSize(18)
            .fontColor(Constants.COLORS.textSecondary)
          Text('快去发现喜欢的菜谱吧')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 收藏列表
        List() {
          ForEach(this.favoriteRecipes, (recipe: Recipe) => {
            ListItem() {
              this.FavoriteRecipeItem(recipe)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0, color: 'transparent' })
        .padding({ top: 4, bottom: 16 })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  FavoriteRecipeItem(recipe: Recipe) {
    Row() {
      // 菜谱图片
      CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgWidth: '80vp', imgHeight: 64, imgBorderRadius: Constants.BORDER_RADIUS.normal })

      // 菜谱信息
      Column() {
        Text(recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Constants.COLORS.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text('⭐ ' + recipe.rating)
            .fontSize(12)
            .fontColor('#FFB800')

          Text(recipe.duration + '分钟')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 10 })

          Text(recipe.difficulty)
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 10 })
        }
        .margin({ top: 4 })

        Text(recipe.cuisine)
          .fontSize(12)
          .fontColor(Constants.COLORS.textLight)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.medium)
    .shadow(Constants.SHADOWS.small)
    .margin({ left: 16, right: 16, top: 6, bottom: 6 })
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
      }
    })
    .onClick(() => {
      router.pushUrl({
        url: Constants.ROUTES.RECIPE_DETAIL,
        params: { recipeId: recipe.id }
      });
    })
  }

  // 社区动态内容
  @Builder
  CommunityContent() {
    Column() {
      // 标题栏
      Row() {
        Text('美食社区')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 最新/最热切换
      Row() {
        this.CommunityTabItem('最新', 0)
        this.CommunityTabItem('最热', 1)
      }
      .width('100%')
      .height(40)
      .backgroundColor(Constants.COLORS.surface)

      if (this.communityRecipes.length === 0) {
        // 空状态
        Column() {
          Text('📝')
            .fontSize(60)
            .margin({ bottom: 16 })
          Text('还没有人分享')
            .fontSize(18)
            .fontColor(Constants.COLORS.textSecondary)
          Text('成为第一个分享的人吧！')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 8 })
          Button('发布菜谱')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(Constants.COLORS.primary)
            .borderRadius(20)
            .height(36)
            .margin({ top: 20 })
            .onClick(() => {
              router.pushUrl({ url: Constants.ROUTES.PUBLISH_RECIPE });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 社区列表
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
        .padding({ bottom: 16 })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  CommunityTabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.communityTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.communityTab === index ? Constants.COLORS.primary : Constants.COLORS.textSecondary)

      Divider()
        .strokeWidth(2)
        .color(this.communityTab === index ? Constants.COLORS.primary : 'transparent')
        .width('40%')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.communityTab = index;
      this.loadCommunityRecipes();
    })
  }

  @Builder
  CommunityRecipeCard(recipe: CommunityRecipe) {
    Column() {
      // 用户信息
      Row() {
        Stack() {
          Circle({ width: 40, height: 40 })
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
            })

          Text(recipe.userName.charAt(0))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .alignContent(Alignment.Center)

        Column() {
          Text(recipe.userName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Constants.COLORS.text)

          Text(this.formatTime(recipe.createTime))
            .fontSize(11)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 标题
      Text(recipe.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .margin({ bottom: 8 })

      // 内容
      Text(recipe.content)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .width('100%')
        .lineHeight(22)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 12 })

      // 操作栏
      Row() {
        // 点赞
        Row() {
          Text(recipe.isLiked ? '❤️' : '🤍')
            .fontSize(16)

          Text('' + recipe.likes)
            .fontSize(13)
            .fontColor(recipe.isLiked ? Constants.COLORS.primary : Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
        .onClick(() => {
          this.toggleLike(recipe);
        })

        // 评论
        Row() {
          Text('💬')
            .fontSize(16)

          Text('' + recipe.comments)
            .fontSize(13)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
        .margin({ left: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ left: 16, right: 16, top: 6, bottom: 6 })
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
      }
    })
  }

  formatTime(timeStr: string): string {
    try {
      const date: Date = new Date(timeStr);
      const now: Date = new Date();
      const diff: number = now.getTime() - date.getTime();

      const minutes: number = Math.floor(diff / 60000);
      const hours: number = Math.floor(diff / 3600000);
      const days: number = Math.floor(diff / 86400000);

      if (minutes < 1) return '刚刚';
      if (minutes < 60) return minutes + '分钟前';
      if (hours < 24) return hours + '小时前';
      if (days < 7) return days + '天前';

      return (date.getMonth() + 1) + '月' + date.getDate() + '日';
    } catch {
      return timeStr;
    }
  }

  // 个人中心内容（嵌入ProfilePage）
  @Builder
  ProfileContent() {
    Column() {
      // 标题栏
      Row() {
        Text('个人中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Scroll() {
        Column() {
          // 用户头像和信息
          Column() {
            Image($r('app.media.startIcon'))
              .width(80)
              .height(80)
              .borderRadius(40)
              .margin({ bottom: 12 })

            Text('美食爱好者')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Constants.COLORS.text)

            Text('热爱烹饪，享受生活')
              .fontSize(14)
              .fontColor(Constants.COLORS.textLight)
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 30, bottom: 20 })
          .backgroundColor(Constants.COLORS.surface)

          // 功能菜单
          Column() {
            this.MenuCard('我的收藏', '❤️', () => {
              router.pushUrl({ url: Constants.ROUTES.FAVORITE });
            })
            this.MenuCard('浏览历史', '🕐', () => {
              router.pushUrl({ url: Constants.ROUTES.FAVORITE });
            })
            this.MenuCard('发布菜谱', '📝', () => {
              router.pushUrl({ url: Constants.ROUTES.PUBLISH_RECIPE });
            })
            this.MenuCard('拍照识别', '📷', () => {
              router.pushUrl({ url: Constants.ROUTES.CAMERA });
            })
            this.MenuCard('我的创新菜谱', '🧪', () => {
              router.pushUrl({ url: Constants.ROUTES.CREATIVE_RECIPES });
            })
            this.MenuCard('食材匹配', '🥬', () => {
              router.pushUrl({ url: Constants.ROUTES.INGREDIENT });
            })
            this.MenuCard('社区动态', '👥', () => {
              router.pushUrl({ url: Constants.ROUTES.COMMUNITY });
            })
          }
          .width('100%')
          .margin({ top: 12 })
          .padding({ left: 16, right: 16 })

          // 底部
          Text('CookMaster v1.0')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 30, bottom: 20 })
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  MenuCard(title: string, icon: string, onClick: () => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })

      Text(title)
        .fontSize(16)
        .fontColor(Constants.COLORS.text)
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor(Constants.COLORS.textLight)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.normal)
    .margin({ bottom: 8 })
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
      }
    })
    .onClick(onClick)
  }

  // 底部TabBar
  @Builder
  TabBar() {
    Row() {
      this.TabItem('🏠', '首页', 0)
      this.TabItem('❤️', '收藏', 1)
      this.TabItem('👥', '社区', 2)
      this.TabItem('👤', '我的', 3)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 0.5 }, color: '#E0E0E0' })
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder
  TabItem(icon: string, label: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(22)
        .scale({ x: this.currentTab === index ? 1.15 : 1, y: this.currentTab === index ? 1.15 : 1 })
        .animation({
          duration: Constants.ANIMATION_DURATION.fast,
          curve: Curve.EaseInOut
        })

      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? Constants.COLORS.primary : Constants.COLORS.textLight)
        .margin({ top: 2 })
        .animation({
          duration: Constants.ANIMATION_DURATION.fast,
          curve: Curve.EaseInOut
        })
    }
    .width(64)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTab !== index) {
        this.currentTab = index;
        // 切换Tab时刷新数据
        if (index === 1) {
          this.loadFavorites();
        } else if (index === 2) {
          this.loadCommunityRecipes();
        }
      }
    })
  }

  @Builder
  SearchHeader() {
    Row() {
      // 搜索框
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索菜谱、食材...', text: this.searchText })
          .layoutWeight(1)
          .height(36)
          .backgroundColor('transparent')
          .fontSize(14)
          .onChange((value: string) => {
            this.searchText = value;
          })
          .onSubmit(() => {
            if (this.searchText.trim()) {
              router.pushUrl({
                url: Constants.ROUTES.CATEGORY,
                params: { keyword: this.searchText }
              });
            }
          })
      }
      .width('100%')
      .height(42)
      .backgroundColor('#FFFFFF20')
      .borderRadius(21)
      .border({ width: 1, color: '#FFFFFF30' })
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
    })
  }

  @Builder
  BannerSection() {
    Column() {
      Swiper() {
        ForEach(this.dailyRecipes.slice(0, 3), (recipe: Recipe) => {
          Stack() {
            // Banner图片（带加载失败兜底）
            CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgHeight: 180, imgBorderRadius: Constants.BORDER_RADIUS.large })

            // 渐变遮罩
            Column() {
              Text(recipe.name)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')

              Text(recipe.description)
                .fontSize(14)
                .fontColor('#FFFFFFDD')
                .margin({ top: 6 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
            .alignItems(HorizontalAlign.Start)
            .position({ x: 0, y: '100%' })
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['transparent', 0.0], ['#80000000', 1.0]]
            })
          }
          .width('100%')
          .height(180)
          .borderRadius(Constants.BORDER_RADIUS.large)
          .shadow(Constants.SHADOWS.medium)
          .clip(true)
          .onClick(() => {
            router.pushUrl({
              url: Constants.ROUTES.RECIPE_DETAIL,
              params: { recipeId: recipe.id }
            });
          })
        })
      }
      .autoPlay(true)
      .interval(3000)
      .indicator(Indicator.dot()
        .color('#FFFFFF60')
        .selectedColor('#FFFFFF')
        .itemWidth(8)
        .itemHeight(8))
      .width('100%')
      .height(180)
      .borderRadius(Constants.BORDER_RADIUS.large)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }

  @Builder
  CategorySection() {
    Column() {
      Row() {
        Text('分类')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('查看全部 >')
          .fontSize(14)
          .fontColor(Constants.COLORS.textLight)
          .onClick(() => {
            router.pushUrl({ url: Constants.ROUTES.CATEGORY });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Scroll() {
        Row() {
          ForEach(Constants.RECIPE_CATEGORIES, (category: CategoryItem) => {
            Column() {
              Text(category.icon)
                .fontSize(28)
                .margin({ bottom: 6 })

              Text(category.name)
                .fontSize(12)
                .fontColor(Constants.COLORS.textSecondary)
            }
            .width(68)
            .height(76)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Constants.COLORS.warmWhite)
            .borderRadius(Constants.BORDER_RADIUS.medium)
            .margin({ right: 8 })
            .stateStyles({
              pressed: {
                .opacity(Constants.OPACITY.pressed)
                .scale({ x: 0.95, y: 0.95 })
              }
            })
            .onClick(() => {
              router.pushUrl({
                url: Constants.ROUTES.CATEGORY,
                params: { category: category.name }
              });
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  @Builder
  RecommendSection() {
    Column() {
      Row() {
        Text('今日推荐')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('换一批')
          .fontSize(14)
          .fontColor(Constants.COLORS.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.loadData();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 推荐菜谱网格
      Grid() {
        ForEach(this.recommendedRecipes, (recipe: Recipe) => {
          GridItem() {
            this.RecipeCard(recipe)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .height(this.recommendedRecipes.length > 3 ? 380 : 190)
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  @Builder
  HotRecipeSection() {
    Column() {
      Row() {
        Text('热门菜谱')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('更多 >')
          .fontSize(14)
          .fontColor(Constants.COLORS.textLight)
          .onClick(() => {
            router.pushUrl({ url: Constants.ROUTES.CATEGORY });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 热门菜谱列表
      ForEach(this.hotRecipes.slice(0, 5), (recipe: Recipe, index: number) => {
        Row() {
          // 排名
          Text('' + (index + 1))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(index < 3 ? Constants.COLORS.primary : Constants.COLORS.textLight)
            .width(28)
            .textAlign(TextAlign.Center)

          // 菜谱图片（带加载失败兜底）
          CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgWidth: '80vp', imgHeight: 60, imgBorderRadius: Constants.BORDER_RADIUS.normal })

          // 菜谱信息
          Column() {
            Text(recipe.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Constants.COLORS.text)

            Row() {
              Text('⭐ ' + recipe.rating)
                .fontSize(12)
                .fontColor('#FFB800')

              Text(recipe.duration + '分钟')
                .fontSize(12)
                .fontColor(Constants.COLORS.textLight)
                .margin({ left: 12 })

              Text(recipe.difficulty)
                .fontSize(12)
                .fontColor(Constants.COLORS.textLight)
                .margin({ left: 12 })
            }
            .margin({ top: 4 })

            Text(recipe.viewCount + '次浏览 · ' + recipe.favoriteCount + '收藏')
              .fontSize(11)
              .fontColor(Constants.COLORS.textLight)
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .borderRadius(Constants.BORDER_RADIUS.normal)
        .stateStyles({
          pressed: {
            .backgroundColor(Constants.COLORS.warmGray)
          }
        })
        .onClick(() => {
          router.pushUrl({
            url: Constants.ROUTES.RECIPE_DETAIL,
            params: { recipeId: recipe.id }
          });
        })
      })
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12, bottom: 16 })
  }

  @Builder
  RecipeCard(recipe: Recipe) {
    Column() {
      // 菜谱图片（带加载失败兜底）
      CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgHeight: 105, imgBorderRadius: Constants.BORDER_RADIUS.medium })

      // 菜谱信息
      Column() {
        Text(recipe.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Constants.COLORS.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text('⭐' + recipe.rating)
            .fontSize(11)
            .fontColor('#FFB800')

          Text(recipe.duration + 'min')
            .fontSize(11)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .width('100%')
      .padding(8)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.medium)
    .shadow(Constants.SHADOWS.small)
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
        .scale({ x: 0.97, y: 0.97 })
      }
    })
    .onClick(() => {
      router.pushUrl({
        url: Constants.ROUTES.RECIPE_DETAIL,
        params: { recipeId: recipe.id }
      });
    })
  }
}
