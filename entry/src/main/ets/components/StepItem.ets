import { CookingStep } from '../model/Recipe';
import { Constants } from '../utils/Constants';

/**
 * 烹饪步骤组件
 */
@Component
export struct StepItem {
  @Prop step: CookingStep = new CookingStep();
  @Prop isActive: boolean = false;
  onStartTimer?: (duration: number) => void;

  build() {
    Column() {
      // 步骤头部
      Row() {
        // 步骤序号
        Stack() {
          Circle({ width: 36, height: 36 })
            .fill(this.isActive ? Constants.COLORS.primary : '#E0E0E0')

          Text('' + this.step.stepNumber)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isActive ? '#FFFFFF' : Constants.COLORS.text)
        }
        .width(36)
        .height(36)
        .alignContent(Alignment.Center)

        // 步骤标题
        Text('步骤 ' + this.step.stepNumber)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .margin({ left: 12 })

        // 计时器标识
        if (this.step.needTimer) {
          Row() {
            Text('⏱️')
              .fontSize(14)

            Text(this.step.duration + '秒')
              .fontSize(12)
              .fontColor(Constants.COLORS.primary)
              .margin({ left: 4 })
          }
          .margin({ left: 'auto' })
        }
      }
      .width('100%')

      // 步骤图片
      if (this.step.image) {
        Image(this.step.image)
          .width('100%')
          .height(180)
          .borderRadius(8)
          .margin({ top: 12 })
          .objectFit(ImageFit.Cover)
      }

      // 步骤描述
      Text(this.step.description)
        .fontSize(14)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .lineHeight(22)
        .margin({ top: 12 })

      // 小贴士
      if (this.step.tip) {
        Row() {
          Text('💡')
            .fontSize(14)

          Text(this.step.tip)
            .fontSize(13)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ left: 8 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .margin({ top: 12 })
      }

      // 计时器按钮
      if (this.step.needTimer && this.step.duration > 0) {
        Button('开始计时 ' + this.step.duration + '秒')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .borderRadius(8)
          .height(40)
          .width('100%')
          .margin({ top: 12 })
          .onClick(() => {
            if (this.onStartTimer) {
              this.onStartTimer(this.step.duration);
            }
          })
      }

      // 分割线
      Divider()
        .strokeWidth(1)
        .color('#EEEEEE')
        .margin({ top: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Constants.COLORS.surface)
  }
}
