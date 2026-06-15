import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { RecommendService } from '../service/RecommendService';
import { Recipe } from '../model/Recipe';
import { Constants, CategoryItem } from '../utils/Constants';
import { CoverImage } from '../components/CoverImage';

/**
 * 推荐结果
 */
class RecommendResult {
  recipe: Recipe = new Recipe();
  matchScore: number = 0;
  matchedIngredients: string[] = [];
  missingIngredients: string[] = [];
}

/**
 * 食材选择与推荐页
 */
@Entry
@Component
struct IngredientPage {
  @State selectedIngredients: string[] = [];
  @State currentCategory: string = '蔬菜';
  @State categoryIngredients: string[] = [];
  @State recommendedRecipes: RecommendResult[] = [];
  @State isLoading: boolean = false;
  @State showResults: boolean = false;

  private dbService: DatabaseService = DatabaseService.getInstance();
  private recommendService: RecommendService = RecommendService.getInstance();

  aboutToAppear() {
    this.loadCategoryIngredients();
  }

  loadCategoryIngredients() {
    const categoryMap: Record<string, string[]> = {
      '蔬菜': ['番茄', '土豆', '黄瓜', '白菜', '青菜', '菠菜', '茄子', '辣椒', '洋葱', '胡萝卜', '白萝卜', '豆角', '芹菜', '韭菜', '蘑菇', '豆腐'],
      '肉类': ['猪肉', '牛肉', '羊肉', '鸡肉', '鸭肉', '排骨', '五花肉', '里脊肉', '鸡翅', '鸡腿', '培根', '香肠'],
      '海鲜': ['鱼', '虾', '蟹', '贝类', '鱿鱼', '海带', '紫菜', '龙虾'],
      '蛋奶': ['鸡蛋', '鸭蛋', '牛奶', '酸奶', '奶酪', '黄油'],
      '主食': ['米饭', '面条', '面粉', '饺子皮', '馒头', '面包', '年糕'],
      '调料': ['盐', '糖', '酱油', '醋', '料酒', '生抽', '老抽', '蚝油', '花椒', '八角', '桂皮', '姜', '蒜', '葱', '辣椒酱']
    };
    this.categoryIngredients = categoryMap[this.currentCategory] || [];
  }

  toggleIngredient(ingredient: string) {
    const index = this.selectedIngredients.indexOf(ingredient);
    if (index > -1) {
      this.selectedIngredients.splice(index, 1);
    } else {
      this.selectedIngredients.push(ingredient);
    }
  }

  isSelected(ingredient: string): boolean {
    return this.selectedIngredients.includes(ingredient);
  }

  async findRecipes() {
    if (this.selectedIngredients.length === 0) {
      AlertDialog.show({
        title: '提示',
        message: '请至少选择一种食材',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }

    this.isLoading = true;
    this.showResults = true;

    try {
      this.recommendedRecipes = await this.recommendService.recommendByIngredients(this.selectedIngredients);
    } catch (error) {
      console.error('推荐失败:', error);
    }

    this.isLoading = false;
  }

  clearSelection() {
    this.selectedIngredients = [];
    this.showResults = false;
    this.recommendedRecipes = [];
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      if (this.showResults) {
        // 推荐结果
        this.RecommendResults()
      } else {
        // 食材选择
        this.IngredientSelection()
      }

      // 底部操作栏
      this.BottomActionBar()
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
          if (this.showResults) {
            this.showResults = false;
          } else {
            router.back();
          }
        })

      Blank()

      Text(this.showResults ? '推荐结果' : '选择食材')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)

      Blank()

      if (this.selectedIngredients.length > 0) {
        Text('已选' + this.selectedIngredients.length)
          .fontSize(14)
          .fontColor(Constants.COLORS.primary)
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Constants.COLORS.surface)
    .shadow(Constants.SHADOWS.small)
  }

  @Builder
  IngredientSelection() {
    Column() {
      // 已选食材展示
      if (this.selectedIngredients.length > 0) {
        Column() {
          Text('已选食材')
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)
            .width('100%')
            .margin({ bottom: 8 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.selectedIngredients, (ingredient: string) => {
              Row() {
                Text(ingredient)
                  .fontSize(13)
                  .fontColor(Constants.COLORS.primary)

                Text('✕')
                  .fontSize(12)
                  .fontColor(Constants.COLORS.textLight)
                  .margin({ left: 6 })
                  .onClick(() => {
                    this.toggleIngredient(ingredient);
                  })
              }
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#FFF3E0')
              .borderRadius(16)
              .border({ width: 1, color: Constants.COLORS.primary })
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Constants.COLORS.surface)
      }

      // 食材分类
      Scroll() {
        Row() {
          ForEach(Constants.INGREDIENT_CATEGORIES, (category: CategoryItem) => {
            Column() {
              Text(category.icon)
                .fontSize(24)

              Text(category.name)
                .fontSize(12)
                .fontColor(this.currentCategory === category.name ? Constants.COLORS.primary : Constants.COLORS.textSecondary)
                .margin({ top: 4 })
            }
            .width(56)
            .height(60)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.currentCategory === category.name ? '#FFF3E0' : 'transparent')
            .borderRadius(8)
            .onClick(() => {
              this.currentCategory = category.name;
              this.loadCategoryIngredients();
            })
          })
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Constants.COLORS.surface)

      // 食材网格
      Grid() {
        ForEach(this.categoryIngredients, (ingredient: string) => {
          GridItem() {
            Column() {
              Text(this.getIngredientEmoji(ingredient))
                .fontSize(28)

              Text(ingredient)
                .fontSize(13)
                .fontColor(this.isSelected(ingredient) ? Constants.COLORS.primary : Constants.COLORS.text)
                .margin({ top: 4 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isSelected(ingredient) ? Constants.COLORS.accentLight : Constants.COLORS.surface)
            .borderRadius(Constants.BORDER_RADIUS.medium)
            .border({
              width: this.isSelected(ingredient) ? 2 : 1,
              color: this.isSelected(ingredient) ? Constants.COLORS.primary : Constants.COLORS.divider
            })
            .shadow(this.isSelected(ingredient) ? Constants.SHADOWS.small : { radius: 0, color: 'transparent', offsetX: 0, offsetY: 0 })
          }
          .stateStyles({
            pressed: {
              .scale({ x: 0.95, y: 0.95 })
              .opacity(Constants.OPACITY.pressed)
            }
          })
          .onClick(() => {
            this.toggleIngredient(ingredient);
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  RecommendResults() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)

          Text('正在智能匹配...')
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ top: 16 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else if (this.recommendedRecipes.length === 0) {
        Column() {
          Text('😅')
            .fontSize(64)
            .margin({ bottom: 16 })

          Text('暂无匹配的菜谱')
            .fontSize(18)
            .fontColor(Constants.COLORS.textSecondary)

          Text('试试选择更多食材吧')
            .fontSize(14)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 8 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        Text('为您找到 ' + this.recommendedRecipes.length + ' 道菜谱')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        List() {
          ForEach(this.recommendedRecipes, (item: RecommendResult) => {
            ListItem() {
              this.RecommendCard(item)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#EEEEEE' })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  RecommendCard(item: RecommendResult) {
    Column() {
      Row() {
        // 菜谱图片（带加载失败兜底）
        CoverImage({ src: item.recipe.coverImage, recipeName: item.recipe.name, imgWidth: '90vp', imgHeight: 70, imgBorderRadius: Constants.BORDER_RADIUS.normal })

        // 菜谱信息
        Column() {
          Text(item.recipe.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Constants.COLORS.text)

          // 匹配度
          Row() {
            Text('匹配度: ' + Math.round(item.matchScore * 100) + '%')
              .fontSize(12)
              .fontColor(Constants.COLORS.primary)
              .fontWeight(FontWeight.Medium)

            Text(item.recipe.duration + '分钟')
              .fontSize(12)
              .fontColor(Constants.COLORS.textLight)
              .margin({ left: 12 })
          }
          .margin({ top: 4 })

          // 匹配的食材
          Text('已有: ' + item.matchedIngredients.join('、'))
            .fontSize(12)
            .fontColor(Constants.COLORS.success)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          // 缺少的食材
          if (item.missingIngredients.length > 0) {
            Text('还缺: ' + item.missingIngredients.join('、'))
              .fontSize(12)
              .fontColor(Constants.COLORS.warning)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
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
        params: { recipeId: item.recipe.id }
      });
    })
  }

  @Builder
  BottomActionBar() {
    Row() {
      Button('清空选择')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .backgroundColor(Constants.COLORS.warmGray)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .height(48)
        .layoutWeight(1)
        .margin({ right: 10 })
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
          }
        })
        .onClick(() => {
          this.clearSelection();
        })

      Button('查找菜谱 (' + this.selectedIngredients.length + ')')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .height(48)
        .layoutWeight(2)
        .shadow(Constants.SHADOWS.colored)
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
            .scale({ x: 0.97, y: 0.97 })
          }
        })
        .onClick(() => {
          this.findRecipes();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .backgroundColor(Constants.COLORS.surface)
    .shadow(Constants.SHADOWS.small)
  }

  getIngredientEmoji(ingredient: string): string {
    const emojiMap: Record<string, string> = {
      // 蔬菜
      '番茄': '🍅', '土豆': '🥔', '黄瓜': '🥒', '白菜': '🥬',
      '青菜': '🥬', '菠菜': '🥬', '茄子': '🍆', '辣椒': '🌶️',
      '洋葱': '🧅', '胡萝卜': '🥕', '白萝卜': '🥕', '豆角': '🫘',
      '芹菜': '🥬', '韭菜': '🥬', '蘑菇': '🍄', '豆腐': '🧈',
      // 肉类
      '猪肉': '🥩', '牛肉': '🥩', '羊肉': '🥩', '鸡肉': '🍗',
      '鸭肉': '🍗', '排骨': '🥩', '五花肉': '🥓', '里脊肉': '🥩',
      '鸡翅': '🍗', '鸡腿': '🍗', '培根': '🥓', '香肠': '🌭',
      // 海鲜
      '鱼': '🐟', '虾': '🦐', '蟹': '🦀', '贝类': '🦪',
      '鱿鱼': '🦑', '海带': '🌿', '紫菜': '🌿', '龙虾': '🦞',
      // 蛋奶
      '鸡蛋': '🥚', '鸭蛋': '🥚', '牛奶': '🥛', '酸奶': '🥛',
      '奶酪': '🧀', '黄油': '🧈',
      // 主食
      '米饭': '🍚', '面条': '🍜', '面粉': '🌾', '饺子皮': '🥟',
      '馒头': '🍞', '面包': '🍞', '年糕': '🍡',
      // 调料
      '盐': '🧂', '糖': '🍬', '酱油': '🫗', '醋': '🫗',
      '料酒': '🍶', '生抽': '🫗', '老抽': '🫗', '蚝油': '🫗',
      '花椒': '🌶️', '八角': '⭐', '桂皮': '🌿', '姜': '🫚',
      '蒜': '🧄', '葱': '🧅', '辣椒酱': '🌶️'
    };
    // 有专属emoji则用专属的，否则用分类emoji兜底
    if (emojiMap[ingredient]) {
      return emojiMap[ingredient];
    }
    const categoryEmoji: Record<string, string> = {
      '蔬菜': '🥬', '肉类': '🥩', '海鲜': '🦐',
      '蛋奶': '🥚', '主食': '🍚', '调料': '🧂'
    };
    // 根据当前选中的分类返回对应emoji
    return categoryEmoji[this.currentCategory] || '🍽️';
  }
}
