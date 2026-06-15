import { Constants } from '../utils/Constants';
import { CookingStep } from '../model/Recipe';

/**
 * 烹饪步骤编辑组件
 * 用于发布菜谱时编辑单个步骤信息
 */
@Component
export struct StepEditor {
  @Prop index: number = 0;
  @Prop description: string = '';
  @Prop tip: string = '';
  @Prop duration: number = 0;
  @Prop needTimer: boolean = false;
  onChange?: (index: number, step: CookingStep) => void;
  onDelete?: (index: number) => void;

  build() {
    Column() {
      // 步骤标题行
      Row() {
        // 步骤序号
        Text(`步骤 ${this.index + 1}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.primary)

        Blank()

        // 计时器开关
        Row() {
          Text('需要计时')
            .fontSize(12)
            .fontColor(Constants.COLORS.textSecondary)
          Toggle({ type: ToggleType.Switch, isOn: this.needTimer })
            .width(36)
            .height(20)
            .selectedColor(Constants.COLORS.primary)
            .onChange((isOn: boolean) => {
              this.needTimer = isOn;
              this.notifyChange();
            })
        }
        .alignItems(VerticalAlign.Center)

        // 删除按钮
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
          if (this.onDelete) this.onDelete(this.index);
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 步骤描述
      TextArea({ placeholder: '描述这一步的操作...', text: this.description })
        .width('100%')
        .height(80)
        .fontSize(14)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.description = value;
          this.notifyChange();
        })

      // 提示
      TextArea({ placeholder: '小贴士（可选）...', text: this.tip })
        .width('100%')
        .height(50)
        .fontSize(13)
        .backgroundColor('#FFFBF0')
        .borderRadius(8)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.tip = value;
          this.notifyChange();
        })

      // 计时时长（仅在需要计时时显示）
      if (this.needTimer) {
        Row() {
          Text('计时时长:')
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)

          TextInput({ placeholder: '秒数', text: this.duration > 0 ? `${this.duration}` : '' })
            .width(80)
            .height(32)
            .fontSize(13)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .type(InputType.Number)
            .margin({ left: 8 })
            .onChange((value: string) => {
              this.duration = parseInt(value) || 0;
              this.notifyChange();
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
    .margin({ top: 8 })
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  private notifyChange(): void {
    if (this.onChange) {
      const step: CookingStep = new CookingStep();
      step.stepNumber = this.index + 1;
      step.description = this.description;
      step.tip = this.tip;
      step.duration = this.duration;
      step.needTimer = this.needTimer;
      this.onChange(this.index, step);
    }
  }
}
