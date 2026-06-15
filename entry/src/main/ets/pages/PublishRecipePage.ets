import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { AuthService } from '../service/AuthService';
import { CommunityRecipe } from '../model/UserPreference';
import { RecipeInsertData } from '../service/DatabaseService';
import { Ingredient, CookingStep } from '../model/Recipe';
import { Constants } from '../utils/Constants';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 发布菜谱页 - 完整版
 * 支持：封面图片、食材编辑、步骤编辑、菜谱元信息
 */
@Entry
@Component
struct PublishRecipePage {
  // 基本信息
  @State title: string = '';
  @State content: string = '';
  @State coverImage: string = '';
  @State images: string[] = [];

  // 菜谱元信息
  @State category: string = '家常菜';
  @State cuisine: string = '家常';
  @State difficulty: string = '简单';
  @State duration: number = 30;
  @State servings: number = 2;
  @State calories: number = 200;

  // 食材列表
  @State ingredients: Ingredient[] = [];

  // 步骤列表
  @State steps: CookingStep[] = [];

  // 状态
  @State isPublishing: boolean = false;
  @State showSuccess: boolean = false;
  @State currentTab: number = 0; // 0: 基本信息, 1: 食材, 2: 步骤

  private dbService: DatabaseService = DatabaseService.getInstance();
  private authService: AuthService = AuthService.getInstance();

  private categories: string[] = Constants.RECIPE_CATEGORIES.map(item => item.name);
  private cuisines: string[] = Constants.CUISINES;
  private difficulties: string[] = Constants.DIFFICULTY_LEVELS.map(item => item.name);

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      if (this.showSuccess) {
        this.SuccessView()
      } else {
        // Tab 切换
        this.TabBar()

        // 内容区
        Scroll() {
          Column() {
            if (this.currentTab === 0) {
              this.BasicInfoForm()
            } else if (this.currentTab === 1) {
              this.IngredientsForm()
            } else {
              this.StepsForm()
            }
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
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
      Text('取消')
        .fontSize(16)
        .fontColor(Constants.COLORS.textSecondary)
        .padding({ left: 4, right: 4 })
        .stateStyles({
          pressed: {
            .opacity(Constants.OPACITY.pressed)
          }
        })
        .onClick(() => {
          router.back();
        })

      Blank()

      Text('发布菜谱')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)

      Blank()

      Text(this.isPublishing ? '发布中...' : '发布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.canPublish() ? Constants.COLORS.primary : Constants.COLORS.textLight)
        .onClick(() => {
          if (this.canPublish()) {
            this.publishRecipe();
          }
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Constants.COLORS.surface)
    .shadow(Constants.SHADOWS.small)
  }

  @Builder
  TabBar() {
    Row() {
      this.TabItem(0, '基本信息')
      this.TabItem(1, `食材 (${this.ingredients.length})`)
      this.TabItem(2, `步骤 (${this.steps.length})`)
    }
    .width('100%')
    .height(48)
    .backgroundColor(Constants.COLORS.surface)
    .border({ width: { bottom: 1 }, color: Constants.COLORS.divider })
  }

  @Builder
  TabItem(index: number, label: string) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.currentTab === index ? Constants.COLORS.primary : Constants.COLORS.textSecondary)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .border({ width: { bottom: this.currentTab === index ? 2 : 0 }, color: Constants.COLORS.primary })
    .onClick(() => {
      this.currentTab = index;
    })
  }

  @Builder
  BasicInfoForm() {
    Column() {
      // 封面图片
      Column() {
        Text('封面图片')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)

        if (this.coverImage) {
          Stack() {
            Image(this.coverImage)
              .width('100%')
              .height(180)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)

            Text('更换')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#00000066')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .position({ x: 'calc(100% - 70px)', y: 10 })
              .onClick(() => {
                this.selectCoverImage();
              })
          }
          .width('100%')
          .height(180)
        } else {
          Column() {
            Text('📷')
              .fontSize(40)
            Text('点击选择封面图片')
              .fontSize(14)
              .fontColor(Constants.COLORS.textLight)
              .margin({ top: 8 })
          }
          .width('100%')
          .height(120)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F5F5F5')
          .borderRadius(12)
          .border({ width: 1, color: '#EEEEEE', style: BorderStyle.Dashed })
          .onClick(() => {
            this.selectCoverImage();
          })
        }
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 标题
      Column() {
        Text('菜谱名称 *')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '给你的菜谱起个名字...', text: this.title })
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.title = value;
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 描述
      Column() {
        Text('菜谱描述 *')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)

        TextArea({ placeholder: '描述你的菜谱做法、特色、心得...', text: this.content })
          .width('100%')
          .height(120)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.content = value;
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 分类和菜系
      Row() {
        Column() {
          Text('分类')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ bottom: 6 })
            .alignSelf(ItemAlign.Start)

          Select(this.categories.map(c => ({ value: c } as SelectOption)))
            .selected(this.categories.indexOf(this.category))
            .value(this.category)
            .width('100%')
            .height(36)
            .font({ size: 13 })
            .selectedOptionFontColor('#FFFFFF')
            .selectedOptionBgColor(Constants.COLORS.primary)
            .onSelect((index: number) => {
              this.category = this.categories[index];
            })
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          Text('菜系')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ bottom: 6 })
            .alignSelf(ItemAlign.Start)

          Select(this.cuisines.map(c => ({ value: c } as SelectOption)))
            .selected(this.cuisines.indexOf(this.cuisine))
            .value(this.cuisine)
            .width('100%')
            .height(36)
            .font({ size: 13 })
            .selectedOptionFontColor('#FFFFFF')
            .selectedOptionBgColor(Constants.COLORS.primary)
            .onSelect((index: number) => {
              this.cuisine = this.cuisines[index];
            })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 难度和时间
      Row() {
        Column() {
          Text('难度')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ bottom: 6 })
            .alignSelf(ItemAlign.Start)

          Select(this.difficulties.map(d => ({ value: d } as SelectOption)))
            .selected(this.difficulties.indexOf(this.difficulty))
            .value(this.difficulty)
            .width('100%')
            .height(36)
            .font({ size: 13 })
            .selectedOptionFontColor('#FFFFFF')
            .selectedOptionBgColor(Constants.COLORS.primary)
            .onSelect((index: number) => {
              this.difficulty = this.difficulties[index];
            })
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          Text('烹饪时间(分钟)')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ bottom: 6 })
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '30', text: `${this.duration}` })
            .width('100%')
            .height(36)
            .fontSize(13)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .type(InputType.Number)
            .onChange((value: string) => {
              this.duration = parseInt(value) || 0;
            })
        }
        .layoutWeight(1)
        .margin({ right: 8 })

        Column() {
          Text('份量(人份)')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ bottom: 6 })
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '2', text: `${this.servings}` })
            .width('100%')
            .height(36)
            .fontSize(13)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .type(InputType.Number)
            .onChange((value: string) => {
              this.servings = parseInt(value) || 0;
            })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 更多图片
      Column() {
        Text('更多图片（可选，最多9张）')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.images, (image: string, index: number) => {
            Stack() {
              Image(image)
                .width(70)
                .height(70)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)

              Text('✕')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor('#00000066')
                .width(22)
                .height(22)
                .borderRadius(11)
                .textAlign(TextAlign.Center)
                .position({ x: 48, y: 0 })
                .onClick(() => {
                  this.images.splice(index, 1);
                })
            }
            .width(70)
            .height(70)
            .margin({ right: 8, bottom: 8 })
          })

          if (this.images.length < 9) {
            Column() {
              Text('+')
                .fontSize(28)
                .fontColor(Constants.COLORS.textLight)
            }
            .width(70)
            .height(70)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .border({ width: 1, color: '#EEEEEE', style: BorderStyle.Dashed })
            .onClick(() => {
              this.addMoreImage();
            })
          }
        }
        .width('100%')
      }
      .width('100%')
    }
  }

  @Builder
  IngredientsForm() {
    Column() {
      // 标题和添加按钮
      Row() {
        Text('食材清单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Button('+ 添加食材')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.addIngredient();
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.ingredients.length === 0) {
        // 空状态
        Column() {
          Text('🥬')
            .fontSize(48)
          Text('还没有添加食材')
            .fontSize(15)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ top: 12 })
          Text('点击上方按钮添加食材')
            .fontSize(13)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else {
        // 表头
        Row() {
          Text('')
            .width(24)
          Text('食材名称')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .layoutWeight(2)
          Text('用量')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .layoutWeight(1.5)
            .margin({ left: 8 })
          Text('分类')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .layoutWeight(1.2)
            .margin({ left: 8 })
          Text('')
            .width(36)
        }
        .width('100%')
        .padding({ bottom: 8 })
        .border({ width: { bottom: 1 }, color: '#EEEEEE' })

        // 食材列表
        ForEach(this.ingredients, (ingredient: Ingredient, index: number) => {
          Row() {
            Text(`${index + 1}`)
              .fontSize(14)
              .fontColor(Constants.COLORS.textSecondary)
              .width(24)
              .textAlign(TextAlign.Center)

            TextInput({ placeholder: '食材名称', text: ingredient.name })
              .layoutWeight(2)
              .height(36)
              .fontSize(14)
              .backgroundColor('#F8F8F8')
              .borderRadius(8)
              .onChange((value: string) => {
                this.ingredients[index].name = value;
              })

            TextInput({ placeholder: '用量', text: ingredient.amount })
              .layoutWeight(1.5)
              .height(36)
              .fontSize(14)
              .backgroundColor('#F8F8F8')
              .borderRadius(8)
              .margin({ left: 8 })
              .onChange((value: string) => {
                this.ingredients[index].amount = value;
              })

            Select(['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'].map(c => ({ value: c } as SelectOption)))
              .selected(['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'].indexOf(ingredient.category) >= 0 ?
                ['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'].indexOf(ingredient.category) : 0)
              .value(ingredient.category || '蔬菜')
              .layoutWeight(1.2)
              .height(36)
              .font({ size: 12 })
              .selectedOptionFontColor('#FFFFFF')
              .selectedOptionBgColor(Constants.COLORS.primary)
              .onSelect((idx: number) => {
                this.ingredients[index].category = ['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'][idx];
              })
              .margin({ left: 8 })

            Button() {
              Text('✕')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(28)
            .height(28)
            .backgroundColor('#FF4444')
            .borderRadius(14)
            .margin({ left: 8 })
            .onClick(() => {
              this.ingredients.splice(index, 1);
            })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
        })
      }
    }
  }

  @Builder
  StepsForm() {
    Column() {
      // 标题和添加按钮
      Row() {
        Text('烹饪步骤')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Button('+ 添加步骤')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            this.addStep();
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.steps.length === 0) {
        Column() {
          Text('👨‍🍳')
            .fontSize(48)
          Text('还没有添加步骤')
            .fontSize(15)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ top: 12 })
          Text('点击上方按钮添加烹饪步骤')
            .fontSize(13)
            .fontColor(Constants.COLORS.textLight)
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.steps, (step: CookingStep, index: number) => {
          Column() {
            // 步骤标题行
            Row() {
              Text(`步骤 ${index + 1}`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(Constants.COLORS.primary)

              Blank()

              Row() {
                Text('需要计时')
                  .fontSize(12)
                  .fontColor(Constants.COLORS.textSecondary)
                Toggle({ type: ToggleType.Switch, isOn: step.needTimer })
                  .width(36)
                  .height(20)
                  .selectedColor(Constants.COLORS.primary)
                  .onChange((isOn: boolean) => {
                    this.steps[index].needTimer = isOn;
                  })
              }
              .alignItems(VerticalAlign.Center)

              Button() {
                Text('删除')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
              }
              .height(26)
              .backgroundColor('#FF4444')
              .borderRadius(13)
              .margin({ left: 12 })
              .onClick(() => {
                this.steps.splice(index, 1);
              })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 步骤描述
            TextArea({ placeholder: '描述这一步的操作...', text: step.description })
              .width('100%')
              .height(80)
              .fontSize(14)
              .backgroundColor('#F8F8F8')
              .borderRadius(8)
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.steps[index].description = value;
              })

            // 提示
            TextArea({ placeholder: '小贴士（可选）...', text: step.tip })
              .width('100%')
              .height(50)
              .fontSize(13)
              .backgroundColor('#FFFBF0')
              .borderRadius(8)
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.steps[index].tip = value;
              })

            // 计时时长
            if (step.needTimer) {
              Row() {
                Text('计时时长:')
                  .fontSize(13)
                  .fontColor(Constants.COLORS.textSecondary)

                TextInput({ placeholder: '秒数', text: step.duration > 0 ? `${step.duration}` : '' })
                  .width(80)
                  .height(32)
                  .fontSize(13)
                  .backgroundColor('#F8F8F8')
                  .borderRadius(8)
                  .type(InputType.Number)
                  .margin({ left: 8 })
                  .onChange((value: string) => {
                    this.steps[index].duration = parseInt(value) || 0;
                  })

                Text('秒')
                  .fontSize(13)
                  .fontColor(Constants.COLORS.textSecondary)
                  .margin({ left: 4 })
              }
              .width('100%')
              .margin({ top: 8 })
              .alignItems(VerticalAlign.Center)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 12 })
          .shadow({
            radius: 4,
            color: '#1A000000',
            offsetX: 0,
            offsetY: 2
          })
        })
      }
    }
  }

  @Builder
  SuccessView() {
    Column() {
      Text('🎉')
        .fontSize(80)
        .margin({ bottom: 24 })

      Text('发布成功！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ bottom: 12 })

      Text('你的菜谱已成功发布到社区')
        .fontSize(16)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 32 })

      Button('返回社区')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(Constants.COLORS.primary)
        .borderRadius(24)
        .height(48)
        .width(200)
        .onClick(() => {
          router.back();
        })

      Button('继续发布')
        .fontSize(16)
        .fontColor(Constants.COLORS.primary)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .height(48)
        .width(200)
        .margin({ top: 12 })
        .border({ width: 1, color: Constants.COLORS.primary })
        .onClick(() => {
          this.resetForm();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ========== 业务方法 ==========

  canPublish(): boolean {
    return this.title.trim().length > 0 && this.content.trim().length > 0 && !this.isPublishing;
  }

  addIngredient(): void {
    const ingredient: Ingredient = new Ingredient();
    ingredient.name = '';
    ingredient.amount = '';
    ingredient.category = '蔬菜';
    this.ingredients.push(ingredient);
  }

  addStep(): void {
    const step: CookingStep = new CookingStep();
    step.stepNumber = this.steps.length + 1;
    step.description = '';
    step.tip = '';
    step.duration = 0;
    step.needTimer = false;
    this.steps.push(step);
  }

  async selectCoverImage(): Promise<void> {
    try {
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const selectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;

      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(selectOptions);

      if (result.photoUris && result.photoUris.length > 0) {
        this.coverImage = result.photoUris[0];
      }
    } catch (error) {
      console.error('选择封面图片失败:', error);
      // 如果是用户取消，不显示错误
      const errCode: number = (error as BusinessError).code;
      if (errCode !== 13900002) {
        AlertDialog.show({
          title: '提示',
          message: '选择图片失败，请重试',
          confirm: { value: '确定', action: () => {} }
        });
      }
    }
  }

  async addMoreImage(): Promise<void> {
    if (this.images.length >= 9) {
      AlertDialog.show({
        title: '提示',
        message: '最多添加9张图片',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }

    try {
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const selectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 9 - this.images.length;

      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(selectOptions);

      if (result.photoUris && result.photoUris.length > 0) {
        for (let i = 0; i < result.photoUris.length; i++) {
          if (this.images.length < 9) {
            this.images.push(result.photoUris[i]);
          }
        }
      }
    } catch (error) {
      console.error('选择图片失败:', error);
      // 如果是用户取消，不显示错误
      const errCode: number = (error as BusinessError).code;
      if (errCode !== 13900002) {
        AlertDialog.show({
          title: '提示',
          message: '选择图片失败，请重试',
          confirm: { value: '确定', action: () => {} }
        });
      }
    }
  }

  async publishRecipe(): Promise<void> {
    if (!this.title.trim() || !this.content.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请填写标题和内容',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }

    this.isPublishing = true;

    try {
      // 获取当前用户信息
      const userId: number = await this.authService.getLoggedInUserId();
      const email: string = await this.authService.getLoggedInEmail();

      // 1. 创建菜谱记录
      const recipeData: RecipeInsertData = new RecipeInsertData();
      recipeData.name = this.title;
      recipeData.coverImage = this.coverImage;
      recipeData.category = this.category;
      recipeData.cuisine = this.cuisine;
      recipeData.difficulty = this.difficulty;
      recipeData.duration = this.duration;
      recipeData.servings = this.servings;
      recipeData.calories = this.calories;
      recipeData.description = this.content;
      recipeData.rating = 0;
      recipeData.author = email || '用户';

      const recipeId: number = await this.dbService.insertRecipe(recipeData);

      if (recipeId > 0) {
        // 2. 插入食材
        for (const ingredient of this.ingredients) {
          if (ingredient.name.trim()) {
            await this.dbService.insertIngredient(recipeId, ingredient);
          }
        }

        // 3. 插入步骤
        for (let i = 0; i < this.steps.length; i++) {
          if (this.steps[i].description.trim()) {
            this.steps[i].stepNumber = i + 1;
            await this.dbService.insertStep(recipeId, this.steps[i]);
          }
        }
      }

      // 4. 发布到社区
      const communityRecipe: CommunityRecipe = {
        id: 0,
        recipeId: recipeId,
        userId: `${userId}`,
        userName: email?.split('@')[0] || '用户',
        title: this.title,
        content: this.content,
        images: this.coverImage ? [this.coverImage].concat(this.images) : this.images,
        likes: 0,
        comments: 0,
        createTime: new Date().toISOString(),
        isLiked: false
      };

      await this.dbService.publishCommunityRecipe(communityRecipe);
      this.showSuccess = true;
    } catch (error) {
      console.error('发布失败:', error);
      AlertDialog.show({
        title: '发布失败',
        message: '请稍后重试',
        confirm: { value: '确定', action: () => {} }
      });
    }

    this.isPublishing = false;
  }

  resetForm(): void {
    this.title = '';
    this.content = '';
    this.coverImage = '';
    this.images = [];
    this.category = '家常菜';
    this.cuisine = '家常';
    this.difficulty = '简单';
    this.duration = 30;
    this.servings = 2;
    this.calories = 200;
    this.ingredients = [];
    this.steps = [];
    this.currentTab = 0;
    this.showSuccess = false;
  }
}
