import { Constants } from '../utils/Constants';

/**
 * 烹饪计时器组件
 */
@Component
export struct TimerComponent {
  @Prop timerId: string = '';
  @Prop totalSeconds: number = 0;
  @Prop remainingSeconds: number = 0;
  @Prop isRunning: boolean = false;
  @Prop progress: number = 0;
  onStart?: () => void;
  onPause?: () => void;
  onStop?: () => void;

  build() {
    Column() {
      // 计时器标题
      Row() {
        Text('⏱️')
          .fontSize(20)

        Text('烹饪计时器')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 圆形进度条
      Stack() {
        // 背景圆环
        Circle({ width: 160, height: 160 })
          .stroke('#E0E0E0')
          .strokeWidth(8)
          .fill('transparent')

        // 进度圆环
        Circle({ width: 160, height: 160 })
          .stroke(Constants.COLORS.primary)
          .strokeWidth(8)
          .fill('transparent')
          .strokeLineCap(LineCapStyle.Round)

        // 时间显示
        Column() {
          Text(this.formatTime(this.remainingSeconds))
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(Constants.COLORS.text)

          Text(this.isRunning ? '计时中' : (this.progress > 0 ? '已暂停' : '准备'))
            .fontSize(14)
            .fontColor(Constants.COLORS.textSecondary)
            .margin({ top: 4 })
        }
        .justifyContent(FlexAlign.Center)
      }
      .width(160)
      .height(160)
      .margin({ top: 16, bottom: 16 })

      // 进度信息
      Row() {
        Text('已完成: ' + Math.round(this.progress * 100) + '%')
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)

        Blank()

        Text('剩余: ' + this.formatTime(this.remainingSeconds))
          .fontSize(14)
          .fontColor(Constants.COLORS.textSecondary)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 操作按钮
      Row() {
        // 开始/暂停按钮
        Button(this.isRunning ? '暂停' : '开始')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isRunning ? '#FF9800' : Constants.COLORS.primary)
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .onClick(() => {
            if (this.isRunning) {
              if (this.onPause) this.onPause();
            } else {
              if (this.onStart) this.onStart();
            }
          })

        // 重置按钮
        Button('重置')
          .fontSize(16)
          .fontColor(Constants.COLORS.textSecondary)
          .backgroundColor('#F5F5F5')
          .borderRadius(24)
          .height(48)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            if (this.onStop) this.onStop();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }

  /**
   * 格式化时间
   */
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return mins.toString().padStart(2, '0') + ':' + secs.toString().padStart(2, '0');
  }
}
