import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { Recipe } from '../model/Recipe';
import { Constants, CategoryItem, DifficultyItem } from '../utils/Constants';
import { CoverImage } from '../components/CoverImage';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 路由参数
 */
class CategoryPageParams {
  category: string = '';
  keyword: string = '';
}

/**
 * 分类浏览页
 */
@Entry
@Component
struct CategoryPage {
  @State recipes: Recipe[] = [];
  @State isLoading: boolean = true;
  @State selectedCategory: string = '';
  @State selectedCuisine: string = '';
  @State selectedDifficulty: string = '';
  @State searchKeyword: string = '';

  private dbService: DatabaseService = DatabaseService.getInstance();

  aboutToAppear() {
    const params = router.getParams() as CategoryPageParams;
    if (params) {
      if (params.category) {
        this.selectedCategory = params.category;
      }
      if (params.keyword) {
        this.searchKeyword = params.keyword;
      }
    }
    this.loadRecipes();
  }

  async loadRecipes() {
    this.isLoading = true;
    try {
      if (this.searchKeyword) {
        this.recipes = await this.dbService.searchRecipes(this.searchKeyword);
      } else if (this.selectedCategory) {
        this.recipes = await this.dbService.getRecipesByCategory(this.selectedCategory);
      } else {
        this.recipes = await this.dbService.getAllRecipes();
      }

      // 应用筛选
      if (this.selectedCuisine) {
        this.recipes = this.recipes.filter(r => r.cuisine === this.selectedCuisine);
      }
      if (this.selectedDifficulty) {
        this.recipes = this.recipes.filter(r => r.difficulty === this.selectedDifficulty);
      }
    } catch (error) {
      console.error('加载菜谱失败:', error);
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      // 筛选条件
      this.FilterSection()

      if (this.isLoading) {
        SkeletonView({ skeletonType: 'cardList' })
      } else if (this.recipes.length === 0) {
        // 空状态
        Column() {
          Text('🍽️')
            .fontSize(72)
            .margin({ bottom: 20 })

          Text('暂无菜谱')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Constants.COLORS.textSecondary)

          Text('换个关键词试试吧')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 10 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        // 菜谱列表
        List() {
          ForEach(this.recipes, (recipe: Recipe) => {
            ListItem() {
              this.RecipeListItem(recipe)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0, color: 'transparent' })
        .padding({ top: 8 })
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

      Text(this.searchKeyword ? '搜索: ' + this.searchKeyword : (this.selectedCategory || '全部菜谱'))
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
  FilterSection() {
    Column() {
      // 菜系筛选
      Scroll() {
        Row() {
          this.FilterChip('全部', this.selectedCuisine === '', () => {
            this.selectedCuisine = '';
            this.loadRecipes();
          })

          ForEach(Constants.CUISINES, (cuisine: string) => {
            this.FilterChip(cuisine, this.selectedCuisine === cuisine, () => {
              this.selectedCuisine = cuisine;
              this.loadRecipes();
            })
          })
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 难度筛选
      Row() {
        this.FilterChip('全部难度', this.selectedDifficulty === '', () => {
          this.selectedDifficulty = '';
          this.loadRecipes();
        })

        ForEach(Constants.DIFFICULTY_LEVELS, (level: DifficultyItem) => {
          this.FilterChip(level.name, this.selectedDifficulty === level.name, () => {
            this.selectedDifficulty = level.name;
            this.loadRecipes();
          })
        })
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Constants.COLORS.surface)
    .shadow(Constants.SHADOWS.small)
  }

  @Builder
  FilterChip(text: string, isSelected: boolean, onClick: () => void) {
    Text(text)
      .fontSize(13)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(isSelected ? '#FFFFFF' : Constants.COLORS.textSecondary)
      .backgroundColor(isSelected ? Constants.COLORS.primary : Constants.COLORS.warmGray)
      .borderRadius(Constants.BORDER_RADIUS.round)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .margin({ right: 8 })
      .onClick(onClick)
  }

  @Builder
  RecipeListItem(recipe: Recipe) {
    Row() {
      // 菜谱图片（带加载失败兜底）
      CoverImage({ src: recipe.coverImage, recipeName: recipe.name, imgWidth: '100vp', imgHeight: 80, imgBorderRadius: Constants.BORDER_RADIUS.normal })

      // 菜谱信息
      Column() {
        Text(recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Constants.COLORS.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(recipe.description)
          .fontSize(13)
          .fontColor(Constants.COLORS.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

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

          Text(recipe.cuisine)
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 12 })
        }
        .margin({ top: 8 })
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
}
