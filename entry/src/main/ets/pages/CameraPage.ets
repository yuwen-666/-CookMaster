import { router } from '@kit.ArkUI';
import { cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CameraService, IngredientRecognitionResult } from '../service/CameraService';
import { CreativeRecipe } from '../service/NetworkService';
import { DatabaseService, CreativeRecipeData } from '../service/DatabaseService';
import { Constants, CategoryItem } from '../utils/Constants';
import { promptAction } from '@kit.ArkUI';

/**
 * 页面状态枚举
 */
enum PageState {
  INIT,           // 初始状态
  IMAGE_SELECTED, // 已选图片
  RECOGNIZING,    // 识别中
  RECOGNIZED,     // 识别完成
  GENERATING,     // 生成菜谱中
  RESULT,         // 结果展示
  ERROR           // 错误状态
}

/**
 * 拍照识别食材页
 */
@Entry
@Component
struct CameraPage {
  @State currentState: PageState = PageState.INIT;
  @State selectedImage: string = '';
  @State recognizedIngredients: IngredientRecognitionResult[] = [];
  @State selectedIngredients: string[] = [];
  @State creativeRecipe: CreativeRecipe | null = null;
  @State errorMessage: string = '';
  @State statusMessage: string = '';

  private cameraService: CameraService = CameraService.getInstance();
  private dbService: DatabaseService = DatabaseService.getInstance();

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavBar()

      // 主内容区域
      Scroll() {
        Column() {
          if (this.currentState === PageState.INIT) {
            this.CameraSection()
          } else if (this.currentState === PageState.IMAGE_SELECTED) {
            this.ImagePreviewSection()
          } else if (this.currentState === PageState.RECOGNIZING) {
            this.LoadingSection('正在识别食材...')
          } else if (this.currentState === PageState.RECOGNIZED) {
            this.RecognitionResultSection()
          } else if (this.currentState === PageState.GENERATING) {
            this.LoadingSection('正在生成创新菜谱...')
          } else if (this.currentState === PageState.RESULT) {
            this.CreativeRecipeSection()
          } else if (this.currentState === PageState.ERROR) {
            this.ErrorSection()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)

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
          this.handleBack();
        })

      Blank()

      Text('AI识别食材')
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
  CameraSection() {
    Column() {
      // 拍照/选择区域
      Column() {
        Text('📷')
          .fontSize(80)
          .margin({ bottom: 16 })

        Text('拍摄或选择食材照片')
          .fontSize(18)
          .fontColor(Constants.COLORS.text)
          .margin({ bottom: 8 })

        Text('AI将自动识别食材并生成创意菜谱')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 24 })

        Row() {
          Button('拍照')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(Constants.COLORS.primary)
            .borderRadius(24)
            .height(48)
            .width(140)
            .stateStyles({
              pressed: {
                .opacity(Constants.OPACITY.pressed)
                .scale({ x: 0.95, y: 0.95 })
              }
            })
            .onClick(() => {
              this.takePhoto();
            })

          Button('从相册选择')
            .fontSize(16)
            .fontColor(Constants.COLORS.primary)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .height(48)
            .width(140)
            .border({ width: 1, color: Constants.COLORS.primary })
            .margin({ left: 16 })
            .stateStyles({
              pressed: {
                .opacity(Constants.OPACITY.pressed)
              }
            })
            .onClick(() => {
              this.selectFromAlbum();
            })
        }
      }
      .width('100%')
      .height(350)
      .justifyContent(FlexAlign.Center)

      // 提示信息
      Column() {
        Text('💡 拍照提示')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .margin({ bottom: 12 })

        this.TipItem('确保食材清晰可见')
        this.TipItem('避免光线过暗或过亮')
        this.TipItem('多种食材分开摆放效果更好')
        this.TipItem('AI识别后可手动调整食材')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(12)
      .margin({ top: 16 })
    }
    .width('100%')
  }

  @Builder
  ImagePreviewSection() {
    Column() {
      Text('已选择图片')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ bottom: 16 })

      Stack() {
        Image(this.selectedImage)
          .width('100%')
          .height(300)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)

        // 重新选择按钮
        Text('重新选择')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#00000066')
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .position({ x: 16, y: 16 })
          .onClick(() => {
            this.resetToInit();
          })
      }
      .width('100%')
      .height(300)

      Text('点击下方按钮开始AI识别')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ top: 16 })
    }
    .width('100%')
  }

  @Builder
  LoadingSection(message: string) {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)

      Text(message)
        .fontSize(16)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ top: 16 })

      Text('正在进行AI分析，请稍候...')
        .fontSize(14)
        .fontColor(Constants.COLORS.textLight)
        .margin({ top: 8 })

      if (message.includes('识别')) {
        Text('多次识别以提高准确率')
          .fontSize(12)
          .fontColor(Constants.COLORS.textLight)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecognitionResultSection() {
    Column() {
      // 标题
      Row() {
        Text('AI识别结果')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('重新识别')
          .fontSize(14)
          .fontColor(Constants.COLORS.primary)
          .onClick(() => {
            this.resetToInit();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 预览图
      Image(this.selectedImage)
        .width('100%')
        .height(180)
        .borderRadius(12)
        .objectFit(ImageFit.Cover)
        .margin({ bottom: 16 })

      // 识别结果提示
      Text('AI识别到以下食材，请确认或修改：')
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ bottom: 12 })

      // 食材列表
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.recognizedIngredients, (item: IngredientRecognitionResult) => {
          this.IngredientChip(item)
        })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 已选食材统计
      if (this.selectedIngredients.length > 0) {
        Row() {
          Text('已选择 ' + this.selectedIngredients.length + ' 种食材')
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)

          Blank()

          Text('生成创意菜谱 →')
            .fontSize(14)
            .fontColor(Constants.COLORS.primary)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .border({ width: { top: 1 }, color: Constants.COLORS.divider })
      }

      // 状态提示
      if (this.statusMessage) {
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Constants.COLORS.warning)
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  @Builder
  IngredientChip(item: IngredientRecognitionResult) {
    Column() {
      Row() {
        Text(item.name)
          .fontSize(14)
          .fontColor(this.selectedIngredients.includes(item.name) ? '#FFFFFF' : Constants.COLORS.text)

        if (item.confidence > 0) {
          Text(item.confidence + '%')
            .fontSize(11)
            .fontColor(this.selectedIngredients.includes(item.name) ? '#FFFFFF99' : Constants.COLORS.textLight)
            .margin({ left: 4 })
        }
      }

      if (item.reason) {
        Text(item.reason)
          .fontSize(11)
          .fontColor(this.selectedIngredients.includes(item.name) ? '#FFFFFFCC' : Constants.COLORS.textSecondary)
          .margin({ top: 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.selectedIngredients.includes(item.name) ? Constants.COLORS.primary : Constants.COLORS.surface)
    .borderRadius(12)
    .border({
      width: 1,
      color: this.selectedIngredients.includes(item.name) ? Constants.COLORS.primary : '#EEEEEE'
    })
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.toggleIngredient(item.name);
    })
  }

  @Builder
  CreativeRecipeSection() {
    Column() {
      if (this.creativeRecipe) {
        // 标题
        Row() {
          Text('🎉 AI创意菜谱')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)

          Blank()

          Text('重新生成')
            .fontSize(14)
            .fontColor(Constants.COLORS.primary)
            .onClick(() => {
              this.generateRecipe();
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 菜名
        Text(this.creativeRecipe.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.primary)
          .margin({ bottom: 8 })

        // 简介
        Text(this.creativeRecipe.description)
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ bottom: 16 })

        // 标签
        Row() {
          this.RecipeTag(this.creativeRecipe.difficulty, Constants.COLORS.info)
          this.RecipeTag(this.creativeRecipe.duration, Constants.COLORS.success)
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 创意亮点
        Column() {
          Text('✨ 创意亮点')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)
            .margin({ bottom: 8 })

          Text(this.creativeRecipe.creativeTip)
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFF8E1')
        .borderRadius(12)
        .margin({ bottom: 16 })

        // 食材清单
        Column() {
          Text('🥬 食材清单')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)
            .margin({ bottom: 12 })

          ForEach(this.creativeRecipe.ingredients, (ingredient: string) => {
            Row() {
              Text('•')
                .fontSize(14)
                .fontColor(Constants.COLORS.primary)
                .margin({ right: 8 })

              Text(ingredient)
                .fontSize(14)
                .fontColor(Constants.COLORS.text)
            }
            .width('100%')
            .margin({ bottom: 6 })
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(12)
        .margin({ bottom: 16 })

        // 烹饪步骤
        Column() {
          Text('👨‍🍳 烹饪步骤')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)
            .margin({ bottom: 12 })

          ForEach(this.creativeRecipe.steps, (step: string, index?: number) => {
            Row() {
              Text((index !== undefined ? index + 1 : 1).toString())
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(Constants.COLORS.primary)
                .width(24)
                .height(24)
                .borderRadius(12)
                .textAlign(TextAlign.Center)
                .margin({ right: 12 })

              Text(step)
                .fontSize(14)
                .fontColor(Constants.COLORS.text)
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ bottom: 12 })
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(12)
      }
    }
    .width('100%')
  }

  @Builder
  RecipeTag(text: string, color: string) {
    Text(text)
      .fontSize(12)
      .fontColor(color)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(color + '15')
      .borderRadius(12)
      .margin({ right: 8 })
  }

  @Builder
  ErrorSection() {
    Column() {
      Text('😞')
        .fontSize(60)
        .margin({ bottom: 16 })

      Text('出了点问题')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .margin({ bottom: 8 })

      Text(this.errorMessage)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Row() {
        Button('重试')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .borderRadius(24)
          .height(48)
          .width(120)
          .onClick(() => {
            this.handleRetry();
          })

        Button('手动选择')
          .fontSize(16)
          .fontColor(Constants.COLORS.primary)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .height(48)
          .width(120)
          .border({ width: 1, color: Constants.COLORS.primary })
          .margin({ left: 16 })
          .onClick(() => {
            this.goToManualSelect();
          })
      }
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TipItem(text: string) {
    Row() {
      Text('•')
        .fontSize(14)
        .fontColor(Constants.COLORS.primary)
        .margin({ right: 8 })

      Text(text)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
    }
    .width('100%')
    .margin({ bottom: 6 })
  }

  @Builder
  BottomActionBar() {
    Row() {
      if (this.currentState === PageState.IMAGE_SELECTED) {
        Button('开始AI识别')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .stateStyles({
            pressed: {
              .opacity(Constants.OPACITY.pressed)
              .scale({ x: 0.97, y: 0.97 })
            }
          })
          .onClick(() => {
            this.startRecognition();
          })
      } else if (this.currentState === PageState.RECOGNIZED) {
        Button('生成创意菜谱')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedIngredients.length > 0 ? Constants.COLORS.primary : '#CCCCCC')
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .enabled(this.selectedIngredients.length > 0)
          .stateStyles({
            pressed: {
              .opacity(Constants.OPACITY.pressed)
              .scale({ x: 0.97, y: 0.97 })
            }
          })
          .onClick(() => {
            this.generateRecipe();
          })
      } else if (this.currentState === PageState.RESULT) {
        Button('保存菜谱')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .stateStyles({
            pressed: {
              .opacity(Constants.OPACITY.pressed)
              .scale({ x: 0.97, y: 0.97 })
            }
          })
          .onClick(() => {
            this.saveRecipe();
          })
      } else if (this.currentState === PageState.INIT) {
        Button('手动选择食材')
          .fontSize(16)
          .fontColor(Constants.COLORS.primary)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .border({ width: 1, color: Constants.COLORS.primary })
          .onClick(() => {
            this.goToManualSelect();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Constants.COLORS.surface)
  }

  // ==================== 业务方法 ====================

  /**
   * 返回按钮处理
   */
  handleBack() {
    if (this.currentState === PageState.RESULT || this.currentState === PageState.ERROR) {
      this.resetToInit();
    } else if (this.currentState !== PageState.INIT) {
      this.currentState = PageState.INIT;
      this.selectedImage = '';
    } else {
      router.back();
    }
  }

  /**
   * 重试处理
   */
  handleRetry() {
    if (this.selectedImage) {
      this.startRecognition();
    } else {
      this.resetToInit();
    }
  }

  /**
   * 重置到初始状态
   */
  resetToInit() {
    this.currentState = PageState.INIT;
    this.selectedImage = '';
    this.recognizedIngredients = [];
    this.selectedIngredients = [];
    this.creativeRecipe = null;
    this.errorMessage = '';
    this.statusMessage = '';
  }

  /**
   * 跳转到手动选择食材
   */
  goToManualSelect() {
    router.pushUrl({ url: Constants.ROUTES.INGREDIENT });
  }

  /**
   * 拍照
   */
  async takePhoto() {
    try {
      const ctx: Context = getContext(this);
      const saveUri: string = ctx.cacheDir + '/camera_photo.jpg';
      const pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: 0,
        saveUri: saveUri
      };
      const pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(
        ctx,
        [cameraPicker.PickerMediaType.PHOTO],
        pickerProfile
      );

      if (pickerResult && pickerResult.resultUri) {
        this.selectedImage = pickerResult.resultUri;
        this.currentState = PageState.IMAGE_SELECTED;
      }
    } catch (error) {
      const errCode: number = (error as BusinessError).code;
      if (errCode === 13900002) {
        return;
      }
      console.error('拍照失败，降级到相册选择:', error);
      this.selectFromAlbum();
    }
  }

  /**
   * 从相册选择
   */
  async selectFromAlbum() {
    try {
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const selectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;

      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(selectOptions);

      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImage = result.photoUris[0];
        this.currentState = PageState.IMAGE_SELECTED;
      }
    } catch (error) {
      const errCode: number = (error as BusinessError).code;
      if (errCode !== 13900002) {
        console.error('选择图片失败:', error);
        AlertDialog.show({
          title: '提示',
          message: '选择图片失败，请重试',
          confirm: { value: '确定', action: () => {} }
        });
      }
    }
  }

  /**
   * 开始AI识别食材
   */
  async startRecognition() {
    if (!this.selectedImage) {
      return;
    }

    this.currentState = PageState.RECOGNIZING;
    this.errorMessage = '';
    this.statusMessage = '';

    try {
      const ctx: Context = getContext(this);
      const results: IngredientRecognitionResult[] = await this.cameraService.recognizeIngredients(this.selectedImage, ctx);

      if (results && results.length > 0) {
        this.recognizedIngredients = results;
        // 默认选中置信度高的食材
        this.selectedIngredients = results
          .filter((item: IngredientRecognitionResult) => item.confidence >= 0.7)
          .map((item: IngredientRecognitionResult) => item.name);
        this.currentState = PageState.RECOGNIZED;
      } else {
        this.errorMessage = '未能识别出食材，请尝试更清晰的照片或手动选择';
        this.currentState = PageState.ERROR;
      }
    } catch (error) {
      console.error('识别过程出错:', error);
      this.errorMessage = '识别过程出错，请重试或手动选择食材';
      this.currentState = PageState.ERROR;
    }
  }

  /**
   * 切换食材选中状态
   */
  toggleIngredient(name: string) {
    const index: number = this.selectedIngredients.indexOf(name);
    if (index > -1) {
      this.selectedIngredients.splice(index, 1);
    } else {
      this.selectedIngredients.push(name);
    }
  }

  /**
   * 生成创意菜谱
   */
  async generateRecipe() {
    if (this.selectedIngredients.length === 0) {
      this.statusMessage = '请至少选择一种食材';
      return;
    }

    this.currentState = PageState.GENERATING;
    this.errorMessage = '';

    try {
      const recipe: CreativeRecipe | null = await this.cameraService.generateCreativeRecipe(this.selectedIngredients);

      if (recipe) {
        this.creativeRecipe = recipe;
        this.currentState = PageState.RESULT;
      } else {
        this.errorMessage = '生成菜谱失败，请重试';
        this.currentState = PageState.ERROR;
      }
    } catch (error) {
      console.error('生成菜谱过程出错:', error);
      this.errorMessage = '生成菜谱过程出错，请重试';
      this.currentState = PageState.ERROR;
    }
  }

  /**
   * 保存创新菜谱到数据库
   */
  async saveRecipe() {
    if (!this.creativeRecipe) {
      return;
    }

    try {
      const recipeData: CreativeRecipeData = new CreativeRecipeData();
      recipeData.name = this.creativeRecipe.name;
      recipeData.description = this.creativeRecipe.description;
      recipeData.ingredients = this.creativeRecipe.ingredients;
      recipeData.steps = this.creativeRecipe.steps;
      recipeData.difficulty = this.creativeRecipe.difficulty;
      recipeData.duration = this.creativeRecipe.duration;
      recipeData.creativeTip = this.creativeRecipe.creativeTip;

      const id: number = await this.dbService.insertCreativeRecipe(recipeData);

      if (id > 0) {
        AlertDialog.show({
          title: '保存成功',
          message: '创新菜谱「' + this.creativeRecipe.name + '」已保存到本地',
          primaryButton: {
            value: '查看我的创新菜谱',
            action: () => {
              router.pushUrl({ url: Constants.ROUTES.CREATIVE_RECIPES });
            }
          },
          secondaryButton: {
            value: '继续识别',
            action: () => {
              this.resetToInit();
            }
          }
        });
      } else {
        AlertDialog.show({
          title: '保存失败',
          message: '请稍后重试',
          confirm: { value: '确定', action: () => {} }
        });
      }
    } catch (error) {
      console.error('保存创新菜谱失败:', error);
      AlertDialog.show({
        title: '保存失败',
        message: '发生错误，请稍后重试',
        confirm: { value: '确定', action: () => {} }
      });
    }
  }
}
