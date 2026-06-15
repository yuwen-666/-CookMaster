import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { Recipe } from '../model/Recipe';
import { CookingRecord } from '../model/UserPreference';
import { Constants } from '../utils/Constants';
import { CoverImage } from '../components/CoverImage';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 收藏与历史页
 */
@Entry
@Component
struct FavoritePage {
  @State favoriteRecipes: Recipe[] = [];
  @State browseHistory: Recipe[] = [];
  @State cookingRecords: CookingRecord[] = [];
  @State selectedTab: number = 0; // 0: 收藏, 1: 历史, 2: 烹饪记录
  @State isLoading: boolean = true;

  private dbService: DatabaseService = DatabaseService.getInstance();

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.favoriteRecipes = await this.dbService.getFavoriteRecipes();
      this.browseHistory = await this.dbService.getBrowseHistory(20);
      this.cookingRecords = await this.dbService.getCookingRecords();
    } catch (error) {
      console.error('加载数据失败:', error);
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      // Tab切换
      this.TabSection()

      if (this.isLoading) {
        SkeletonView({ skeletonType: 'cardList' })
      } else {
        // 内容区域
        if (this.selectedTab === 0) {
          this.FavoriteList()
        } else if (this.selectedTab === 1) {
          this.HistoryList()
        } else {
          this.CookingRecordList()
        }
      }
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

      Text('我的收藏')
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
      this.TabItem('收藏', 0, this.favoriteRecipes.length)
      this.TabItem('浏览历史', 1, this.browseHistory.length)
      this.TabItem('烹饪记录', 2, this.cookingRecords.length)
    }
    .width('100%')
    .height(48)
    .backgroundColor(Constants.COLORS.surface)
  }

  @Builder
  TabItem(title: string, index: number, count: number) {
    Column() {
      Row() {
        Text(title)
          .fontSize(15)
          .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedTab === index ? Constants.COLORS.primary : Constants.COLORS.textSecondary)

        if (count > 0) {
          Text('' + count)
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(Constants.COLORS.primary)
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
        }
      }

      Divider()
        .strokeWidth(2)
        .color(this.selectedTab === index ? Constants.COLORS.primary : 'transparent')
        .width('60%')
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
    })
  }

  @Builder
  FavoriteList() {
    if (this.favoriteRecipes.length === 0) {
      this.EmptyState('❤️', '还没有收藏', '快去发现喜欢的菜谱吧')
    } else {
      List() {
        ForEach(this.favoriteRecipes, (recipe: Recipe) => {
          ListItem() {
            this.RecipeItem(recipe)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0, color: 'transparent' })
      .padding({ top: 8 })
    }
  }

  @Builder
  HistoryList() {
    if (this.browseHistory.length === 0) {
      this.EmptyState('📖', '还没有浏览记录', '去看看有哪些美味菜谱')
    } else {
      List() {
        ForEach(this.browseHistory, (recipe: Recipe) => {
          ListItem() {
            this.RecipeItem(recipe)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0, color: 'transparent' })
      .padding({ top: 8 })
    }
  }

  @Builder
  CookingRecordList() {
    if (this.cookingRecords.length === 0) {
      this.EmptyState('👨‍🍳', '还没有烹饪记录', '做完菜记得记录哦')
    } else {
      List() {
        ForEach(this.cookingRecords, (record: CookingRecord) => {
          ListItem() {
            this.CookingRecordItem(record)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0, color: 'transparent' })
      .padding({ top: 8 })
    }
  }

  @Builder
  EmptyState(icon: string, title: string, subtitle: string) {
    Column() {
      Text(icon)
        .fontSize(72)
        .margin({ bottom: 20 })

      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(Constants.COLORS.textSecondary)

      Text(subtitle)
        .fontSize(14)
        .fontColor(Constants.COLORS.textLight)
        .margin({ top: 10 })
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecipeItem(recipe: Recipe) {
    Row() {
      // 菜谱图片（带加载失败兜底）
      CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgWidth: '80vp', imgHeight: 64, imgBorderRadius: Constants.BORDER_RADIUS.normal })

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
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
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

  @Builder
  CookingRecordItem(record: CookingRecord) {
    Column() {
      Row() {
        // 图片
        if (record.image) {
          Image(record.image)
            .width(64)
            .height(64)
            .borderRadius(Constants.BORDER_RADIUS.normal)
            .objectFit(ImageFit.Cover)
        } else {
          Text('🍽️')
            .fontSize(40)
            .width(64)
            .height(64)
            .textAlign(TextAlign.Center)
            .backgroundColor(Constants.COLORS.warmGray)
            .borderRadius(Constants.BORDER_RADIUS.normal)
        }

        // 记录信息
        Column() {
          Text(record.recipeName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Constants.COLORS.text)

          Row() {
            Text('⭐ ' + record.rating)
              .fontSize(12)
              .fontColor('#FFB800')

            Text(record.duration + '分钟')
              .fontSize(12)
              .fontColor(Constants.COLORS.textLight)
              .margin({ left: 12 })
          }
          .margin({ top: 4 })

          Text(this.formatDate(record.cookTime))
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')

      // 心得笔记
      if (record.note) {
        Text(record.note)
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .width('100%')
          .margin({ top: 10 })
          .padding(12)
          .backgroundColor(Constants.COLORS.warmGray)
          .borderRadius(Constants.BORDER_RADIUS.normal)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.medium)
    .shadow(Constants.SHADOWS.small)
    .margin({ left: 16, right: 16, top: 6, bottom: 6 })
  }

  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      return date.getFullYear() + '年' + (date.getMonth() + 1) + '月' + date.getDate() + '日';
    } catch {
      return dateStr;
    }
  }
}
