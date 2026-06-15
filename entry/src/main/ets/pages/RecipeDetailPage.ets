import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { RecommendService } from '../service/RecommendService';
import { ShareService } from '../service/ShareService';
import { Recipe, Ingredient, CookingStep, NutritionInfo } from '../model/Recipe';
import { Constants } from '../utils/Constants';
import { NutritionCalculator, NutritionInput } from '../utils/NutritionCalculator';
import { TimerManager } from '../utils/TimerManager';
import { CoverImage } from '../components/CoverImage';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 路由参数
 */
class RecipeDetailParams {
  recipeId: number = 0;
}

/**
 * 菜谱详情页
 */
@Entry
@Component
struct RecipeDetailPage {
  @State recipe: Recipe | null = null;
  @State nutrition: NutritionInfo | null = null;
  @State isLoading: boolean = true;
  @State isFavorite: boolean = false;
  @State activeTab: number = 0;
  @State currentStep: number = 0;
  @State showTimer: boolean = false;
  @State timerSeconds: number = 0;
  @State timerProgress: number = 0;
  @State timerRunning: boolean = false;

  private recipeId: number = 0;
  private dbService: DatabaseService = DatabaseService.getInstance();
  private recommendService: RecommendService = RecommendService.getInstance();
  private timerManager: TimerManager = TimerManager.getInstance();
  private shareService: ShareService = ShareService.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RecipeDetailParams;
    if (params && params.recipeId) {
      this.recipeId = params.recipeId;
      this.loadRecipeDetail();
    }
  }

  async loadRecipeDetail() {
    this.isLoading = true;
    try {
      const recipe: Recipe | null = await this.dbService.getRecipeById(this.recipeId);
      if (recipe) {
        this.recipe = recipe;
        this.isFavorite = recipe.isFavorite;

        // 计算营养成分
        if (recipe.ingredients.length > 0) {
          const nutritionData = this.recommendService.calculateNutrition(recipe.ingredients);
          this.nutrition = {
            calories: nutritionData.totalCalories,
            protein: nutritionData.totalProtein,
            carbs: nutritionData.totalCarbs,
            fat: nutritionData.totalFat,
            fiber: 0
          };
        }

        // 增加浏览次数
        await this.dbService.incrementViewCount(this.recipeId);
      }
    } catch (error) {
      console.error('加载菜谱详情失败:', error);
    }
    this.isLoading = false;
  }

  async toggleFavorite() {
    const result = await this.dbService.toggleFavorite(this.recipeId);
    this.isFavorite = result;
  }

  async shareRecipe() {
    if (!this.recipe) {
      return;
    }

    await this.shareService.shareRecipe(
      getContext(this),
      this.recipe.name,
      this.recipe.description,
      this.recipe.rating,
      this.recipe.duration
    );
  }

  build() {
    Column() {
      if (this.isLoading) {
        SkeletonView({ skeletonType: 'detail' })
      } else if (this.recipe) {
        // 顶部导航栏
        this.TopNavBar()

        Scroll() {
          Column() {
            // 菜谱封面图
            this.CoverImageSection()

            // 菜谱基本信息
            this.BasicInfo()

            // Tab切换
            this.TabSection()
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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

      Text(this.recipe?.name || '')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Blank()

      Row() {
        Text(this.isFavorite ? '❤️' : '🤍')
          .fontSize(24)
          .onClick(() => {
            this.toggleFavorite();
          })

        Text('分享')
          .fontSize(16)
          .fontColor(Constants.COLORS.text)
          .margin({ left: 16 })
          .onClick(() => {
            this.shareRecipe();
          })
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FAFAFAF8')
  }

  @Builder
  CoverImageSection() {
    Stack() {
      CoverImage({ src: this.recipe?.coverImage || '', recipeName: this.recipe?.name || '', imgHeight: 250, imgBorderRadius: 0 })

      // 难度标签
      Text(this.recipe?.difficulty || '')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .borderRadius(4)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .position({ x: 16, y: 16 })
    }
    .width('100%')
    .height(250)
  }

  @Builder
  BasicInfo() {
    Column() {
      // 菜谱名称
      Text(this.recipe?.name || '')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .margin({ bottom: 10 })

      // 评分和基本信息
      Row() {
        Text('⭐ ' + (this.recipe?.rating || 0))
          .fontSize(16)
          .fontColor('#FFB800')
          .fontWeight(FontWeight.Medium)

        Text((this.recipe?.viewCount || 0) + '次浏览')
          .fontSize(14)
          .fontColor(Constants.COLORS.textLight)
          .margin({ left: 16 })

        Text((this.recipe?.favoriteCount || 0) + '收藏')
          .fontSize(14)
          .fontColor(Constants.COLORS.textLight)
          .margin({ left: 16 })
      }
      .width('100%')
      .margin({ bottom: 14 })

      // 标签信息
      Row() {
        this.InfoTag((this.recipe?.duration || 0) + '分钟', '🕐')
        this.InfoTag((this.recipe?.servings || 0) + '人份', '👥')
        this.InfoTag(this.recipe?.cuisine || '', '🍜')
        this.InfoTag((this.recipe?.calories || 0) + '千卡', '🔥')
      }
      .width('100%')

      // 简介
      Text(this.recipe?.description || '')
        .fontSize(15)
        .fontColor(Constants.COLORS.textSecondary)
        .width('100%')
        .margin({ top: 14 })
        .lineHeight(24)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.large)
    .shadow(Constants.SHADOWS.small)
    .margin({ top: 12 })
  }

  @Builder
  InfoTag(text: string, icon: string) {
    Row() {
      Text(icon)
        .fontSize(14)

      Text(text)
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ left: 4 })
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(Constants.COLORS.warmGray)
    .borderRadius(Constants.BORDER_RADIUS.small)
    .margin({ right: 8 })
  }

  @Builder
  TabSection() {
    Column() {
      // Tab切换
      Row() {
        this.TabItem('食材清单', 0)
        this.TabItem('烹饪步骤', 1)
        this.TabItem('营养分析', 2)
      }
      .width('100%')
      .height(48)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius({ topLeft: Constants.BORDER_RADIUS.large, topRight: Constants.BORDER_RADIUS.large })

      // Tab内容
      if (this.activeTab === 0) {
        this.IngredientsTab()
      } else if (this.activeTab === 1) {
        this.StepsTab()
      } else {
        this.NutritionTab()
      }
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  TabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeTab === index ? Constants.COLORS.primary : Constants.COLORS.textSecondary)

      Divider()
        .strokeWidth(2)
        .color(this.activeTab === index ? Constants.COLORS.primary : 'transparent')
        .width('60%')
        .margin({ top: 4 })
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
      this.activeTab = index;
    })
  }

  @Builder
  IngredientsTab() {
    Column() {
      // 食材列表
      ForEach(this.recipe?.ingredients || [], (ingredient: Ingredient) => {
        Row() {
          // 食材图标
          Text(this.getIngredientIcon(ingredient.category))
            .fontSize(24)
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .backgroundColor(Constants.COLORS.accentLight)
            .borderRadius(22)

          // 食材信息
          Column() {
            Text(ingredient.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Constants.COLORS.text)

            Text(ingredient.amount)
              .fontSize(14)
              .fontColor(Constants.COLORS.textLight)
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })

          // 营养信息
          Text(ingredient.calories + '千卡/100g')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(Constants.BORDER_RADIUS.normal)
        .margin({ bottom: 8 })
        .shadow(Constants.SHADOWS.small)
      })
    }
    .width('100%')
    .padding({ top: 8 })
  }

  @Builder
  StepsTab() {
    Column() {
      // 烹饪步骤
      ForEach(this.recipe?.steps || [], (step: CookingStep) => {
        Column() {
          // 步骤序号
          Row() {
            Stack() {
              Circle({ width: 36, height: 36 })
                .fill(Constants.COLORS.primary)

              Text('' + step.stepNumber)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
            .width(36)
            .height(36)
            .alignContent(Alignment.Center)

            Text('步骤 ' + step.stepNumber)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(Constants.COLORS.text)
              .margin({ left: 12 })

            if (step.needTimer) {
              Text('⏱️')
                .fontSize(16)
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .margin({ bottom: 10 })

          // 步骤图片
          if (step.image) {
            Image(step.image)
              .width('100%')
              .height(200)
              .borderRadius(Constants.BORDER_RADIUS.medium)
              .margin({ bottom: 10 })
              .objectFit(ImageFit.Cover)
          }

          // 步骤描述
          Text(step.description)
            .fontSize(15)
            .fontColor(Constants.COLORS.text)
            .width('100%')
            .lineHeight(24)

          // 小贴士
          if (step.tip) {
            Row() {
              Text('💡')
                .fontSize(14)

              Text(step.tip)
                .fontSize(13)
                .fontColor(Constants.COLORS.textSecondary)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFF8E1')
            .borderRadius(Constants.BORDER_RADIUS.normal)
            .margin({ top: 10 })
          }

          // 计时器按钮
          if (step.needTimer && step.duration > 0) {
            Button('开始计时 ' + step.duration + '秒')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor(Constants.COLORS.primary)
              .borderRadius(Constants.BORDER_RADIUS.normal)
              .height(40)
              .margin({ top: 12 })
              .shadow(Constants.SHADOWS.small)
              .onClick(() => {
                this.startTimer(step.duration);
              })
          }

          Divider()
            .strokeWidth(1)
            .color(Constants.COLORS.divider)
            .margin({ top: 16 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(Constants.BORDER_RADIUS.large)
        .shadow(Constants.SHADOWS.small)
        .margin({ bottom: 12 })
      })
    }
    .width('100%')
  }

  @Builder
  NutritionTab() {
    Column() {
      if (this.nutrition) {
        // 热量卡片 - 渐变装饰
        Column() {
          Text('总热量')
            .fontSize(14)
            .fontColor('#FFFFFFCC')

          Text('' + this.nutrition.calories)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text('千卡')
            .fontSize(14)
            .fontColor('#FFFFFFCC')
        }
        .width('100%')
        .padding(28)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#FF6B35', 0.0], ['#FF8A5C', 1.0]]
        })
        .borderRadius(Constants.BORDER_RADIUS.large)
        .alignItems(HorizontalAlign.Center)
        .shadow(Constants.SHADOWS.colored)

        // 营养素详情
        Row() {
          this.NutritionItem('蛋白质', this.nutrition.protein, 'g', '#4CAF50')
          this.NutritionItem('碳水', this.nutrition.carbs, 'g', '#FF9800')
          this.NutritionItem('脂肪', this.nutrition.fat, 'g', '#E8453C')
        }
        .width('100%')
        .margin({ top: 16 })

        // 营养评分
        Column() {
          Text('营养评分')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)
            .margin({ bottom: 12 })

          Progress({
            value: this.getNutritionScore(),
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(10)
            .color(Constants.COLORS.primary)
            .borderRadius(5)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(Constants.BORDER_RADIUS.large)
        .shadow(Constants.SHADOWS.small)
        .margin({ top: 16 })
      }
    }
    .width('100%')
    .padding(16)
  }

  /**
   * 获取营养评分
   */
  getNutritionScore(): number {
    if (!this.nutrition) return 0;
    const nutritionInput: NutritionInput = {
      calories: this.nutrition.calories,
      protein: this.nutrition.protein,
      carbs: this.nutrition.carbs,
      fat: this.nutrition.fat
    };
    return NutritionCalculator.calculateNutritionScore(nutritionInput).score;
  }

  @Builder
  NutritionItem(name: string, value: number, unit: string, color: ResourceColor) {
    Column() {
      Text(name)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)

      Text('' + value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 4 })

      Text(unit)
        .fontSize(12)
        .fontColor(Constants.COLORS.textLight)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(Constants.BORDER_RADIUS.medium)
    .shadow(Constants.SHADOWS.small)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 8 })
  }

  /**
   * 获取食材图标
   */
  getIngredientIcon(category: string): string {
    const iconMap: Record<string, string> = {
      '蔬菜': '🥬',
      '肉类': '🥩',
      '海鲜': '🦐',
      '蛋奶': '🥚',
      '主食': '🍚',
      '调料': '🧂'
    };
    return iconMap[category] || '🍽️';
  }

  /**
   * 开始计时器
   */
  startTimer(seconds: number) {
    this.timerSeconds = seconds;
    this.showTimer = true;
    this.timerRunning = true;

    const timer = this.timerManager.createTimer(
      'cooking_step',
      seconds,
      (remaining: number) => {
        this.timerSeconds = remaining;
        this.timerProgress = (seconds - remaining) / seconds;
      },
      () => {
        this.timerRunning = false;
        this.showTimer = false;
        // 计时完成提示
        AlertDialog.show({
          title: '计时完成',
          message: '时间到了！请进行下一步操作',
          confirm: {
            value: '确定',
            action: () => {}
          }
        });
      }
    );

    this.timerManager.startTimer('cooking_step');
  }
}
