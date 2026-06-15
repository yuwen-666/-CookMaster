import { Constants } from '../utils/Constants';

/**
 * 加载状态组件
 */
@Component
export struct LoadingView {
  @Prop message: string = '加载中...';

  build() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(Constants.COLORS.primary)

      Text(this.message)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ top: 16 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 空状态组件
 */
@Component
export struct EmptyState {
  @Prop icon: string = '📭';
  @Prop title: string = '暂无数据';
  @Prop subtitle: string = '';
  @Prop buttonText: string = '';
  onButtonClick?: () => void;

  build() {
    Column() {
      Text(this.icon)
        .fontSize(64)
        .margin({ bottom: 16 })

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Constants.COLORS.text)

      if (this.subtitle) {
        Text(this.subtitle)
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
          .margin({ top: 8 })
      }

      if (this.buttonText && this.onButtonClick) {
        Button(this.buttonText)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(Constants.COLORS.primary)
          .borderRadius(24)
          .height(44)
          .margin({ top: 24 })
          .onClick(() => {
            if (this.onButtonClick) this.onButtonClick();
          })
      }
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
  }
}
