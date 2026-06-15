import { router } from '@kit.ArkUI';
import { DatabaseService, CreativeRecipeItem } from '../service/DatabaseService';
import { Constants } from '../utils/Constants';
import { SkeletonView } from '../components/SkeletonView';

/**
 * 我的创新菜谱页面
 * 展示AI生成并保存的创新菜谱，支持发布到社区和删除
 */
@Entry
@Component
struct CreativeRecipesPage {
  @State recipes: CreativeRecipeItem[] = [];
  @State isLoading: boolean = true;
  @State expandedId: number = -1; // 当前展开详情的菜谱ID

  private dbService: DatabaseService = DatabaseService.getInstance();

  aboutToAppear() {
    this.loadRecipes();
  }

  async loadRecipes() {
    this.isLoading = true;
    try {
      this.recipes = await this.dbService.getCreativeRecipes();
    } catch (error) {
      console.error('加载创新菜谱失败:', error);
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      if (this.isLoading) {
        SkeletonView({ skeletonType: 'cardList' })
      } else if (this.recipes.length === 0) {
        // 空状态
        this.EmptyState()
      } else {
        // 列表
        List() {
          ForEach(this.recipes, (recipe: CreativeRecipeItem) => {
            ListItem() {
              this.RecipeCard(recipe)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0, color: 'transparent' })
        .padding({ top: 8, bottom: 16 })
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

      Text('我的创新菜谱')
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
  EmptyState() {
    Column() {
      Text('🧪')
        .fontSize(60)
        .margin({ bottom: 16 })

      Text('还没有创新菜谱')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ bottom: 8 })

      Text('去拍照识别食材，让AI为你创造独特菜谱')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 24 })

      Button('去识别食材')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .borderRadius(24)
        .height(48)
        .width(160)
        .onClick(() => {
          router.pushUrl({ url: Constants.ROUTES.CAMERA });
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecipeCard(recipe: CreativeRecipeItem) {
    Column() {
      // 头部：菜名 + 状态标签
      Row() {
        Text(recipe.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (recipe.status === 'published') {
          Text('已发布')
            .fontSize(11)
            .fontColor(Constants.COLORS.success)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(Constants.COLORS.success + '15')
            .borderRadius(10)
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 简介
      Text(recipe.description)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 10 })

      // 标签行
      Row() {
        if (recipe.difficulty) {
          Text(recipe.difficulty)
            .fontSize(11)
            .fontColor(Constants.COLORS.info)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(Constants.COLORS.info + '15')
            .borderRadius(10)
            .margin({ right: 8 })
        }

        if (recipe.duration) {
          Text(recipe.duration)
            .fontSize(11)
            .fontColor(Constants.COLORS.warning)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(Constants.COLORS.warning + '15')
            .borderRadius(10)
        }

        Blank()

        Text(this.formatTime(recipe.createTime))
          .fontSize(11)
          .fontColor(Constants.COLORS.textLight)
      }
      .width('100%')
      .margin({ bottom: 10 })

      // 展开详情
      if (this.expandedId === recipe.id) {
        this.RecipeDetail(recipe)
      }

      // 操作按钮行
      Row() {
        // 展开/收起
        Text(this.expandedId === recipe.id ? '收起详情' : '查看详情')
          .fontSize(13)
          .fontColor(Constants.COLORS.primary)
          .onClick(() => {
            if (this.expandedId === recipe.id) {
              this.expandedId = -1;
            } else {
              this.expandedId = recipe.id;
            }
          })

        Blank()

        // 发布按钮（未发布时显示）
        if (recipe.status !== 'published') {
          Button('发布到社区')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(Constants.COLORS.primary)
            .borderRadius(16)
            .height(32)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              this.handlePublish(recipe);
            })
            .margin({ right: 8 })
        }

        // 删除按钮
        Button('删除')
          .fontSize(13)
          .fontColor(Constants.COLORS.error)
          .backgroundColor(Constants.COLORS.error + '10')
          .borderRadius(16)
          .height(32)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.handleDelete(recipe);
          })
      }
      .width('100%')
      .margin({ top: 4 })
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

  @Builder
  RecipeDetail(recipe: CreativeRecipeItem) {
    Column() {
      // 创意亮点
      if (recipe.creativeTip) {
        Column() {
          Text('✨ 创意亮点')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)
            .margin({ bottom: 6 })

          Text(recipe.creativeTip)
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(10)
        .margin({ bottom: 12 })
      }

      // 食材清单
      Column() {
        Text('🥬 食材清单')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .margin({ bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(recipe.ingredients, (ingredient: string) => {
            Text(ingredient)
              .fontSize(12)
              .fontColor(Constants.COLORS.text)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(Constants.COLORS.warmGray)
              .borderRadius(12)
              .margin({ right: 6, bottom: 6 })
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(10)
      .margin({ bottom: 12 })
      .border({ width: 1, color: Constants.COLORS.divider })

      // 烹饪步骤
      Column() {
        Text('👨‍🍳 烹饪步骤')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .margin({ bottom: 8 })

        ForEach(recipe.steps, (step: string, index?: number) => {
          Row() {
            Text((index !== undefined ? index + 1 : 1).toString())
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(Constants.COLORS.primary)
              .width(22)
              .height(22)
              .borderRadius(11)
              .textAlign(TextAlign.Center)
              .margin({ right: 10 })

            Text(step)
              .fontSize(13)
              .fontColor(Constants.COLORS.text)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(10)
      .border({ width: 1, color: Constants.COLORS.divider })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  /**
   * 格式化时间
   */
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
    } catch (_e) {
      return timeStr;
    }
  }

  /**
   * 发布到社区
   */
  async handlePublish(recipe: CreativeRecipeItem) {
    AlertDialog.show({
      title: '发布到社区',
      message: '确定将「' + recipe.name + '」发布到美食社区吗？发布后其他用户可以看到你的创意菜谱。',
      primaryButton: {
        value: '确定发布',
        action: async () => {
          try {
            const success: boolean = await this.dbService.publishCreativeRecipe(recipe.id);
            if (success) {
              recipe.status = 'published';
              AlertDialog.show({
                title: '发布成功',
                message: '已发布到美食社区',
                confirm: { value: '好的', action: () => {} }
              });
            } else {
              AlertDialog.show({
                title: '发布失败',
                message: '请稍后重试',
                confirm: { value: '确定', action: () => {} }
              });
            }
          } catch (error) {
            console.error('发布失败:', error);
            AlertDialog.show({
              title: '发布失败',
              message: '发生错误，请稍后重试',
              confirm: { value: '确定', action: () => {} }
            });
          }
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }

  /**
   * 删除菜谱
   */
  async handleDelete(recipe: CreativeRecipeItem) {
    AlertDialog.show({
      title: '确认删除',
      message: '确定删除创新菜谱「' + recipe.name + '」吗？删除后无法恢复。',
      primaryButton: {
        value: '确定删除',
        action: async () => {
          try {
            await this.dbService.deleteCreativeRecipe(recipe.id);
            // 从列表中移除
            this.recipes = this.recipes.filter((item: CreativeRecipeItem) => item.id !== recipe.id);
            if (this.expandedId === recipe.id) {
              this.expandedId = -1;
            }
          } catch (error) {
            console.error('删除失败:', error);
            AlertDialog.show({
              title: '删除失败',
              message: '发生错误，请稍后重试',
              confirm: { value: '确定', action: () => {} }
            });
          }
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }
}
