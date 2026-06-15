import { Constants } from '../utils/Constants';

/**
 * 营养成分图表组件
 * 使用Canvas绘制环形图
 */
@Component
export struct NutritionChart {
  @Prop calories: number = 0;
  @Prop protein: number = 0;
  @Prop carbs: number = 0;
  @Prop fat: number = 0;
  @Prop proteinRatio: number = 0;
  @Prop carbsRatio: number = 0;
  @Prop fatRatio: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column() {
      // 标题
      Text('营养成分分析')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Constants.COLORS.text)
        .width('100%')
        .margin({ bottom: 16 })

      Row() {
        // 环形图
        Canvas(this.context)
          .width(150)
          .height(150)
          .onReady(() => {
            this.drawChart();
          })

        // 营养素详情
        Column() {
          // 热量
          Column() {
            Text('总热量')
              .fontSize(12)
              .fontColor(Constants.COLORS.textSecondary)

            Text('' + this.calories)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(Constants.COLORS.primary)

            Text('千卡')
              .fontSize(12)
              .fontColor(Constants.COLORS.textLight)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 营养素列表
          this.NutrientRow('蛋白质', this.protein, this.proteinRatio, '#4CAF50')
          this.NutrientRow('碳水', this.carbs, this.carbsRatio, '#FF9800')
          this.NutrientRow('脂肪', this.fat, this.fatRatio, '#F44336')
        }
        .layoutWeight(1)
        .margin({ left: 20 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(12)
  }

  @Builder
  NutrientRow(name: string, value: number, ratio: number, color: ResourceColor) {
    Row() {
      // 颜色指示器
      Circle({ width: 10, height: 10 })
        .fill(color)

      // 名称
      Text(name)
        .fontSize(14)
        .fontColor(Constants.COLORS.text)
        .margin({ left: 8 })

      // 进度条
      Progress({
        value: ratio,
        total: 100,
        type: ProgressType.Linear
      })
        .width(80)
        .height(6)
        .color(color)
        .margin({ left: 8 })

      // 数值
      Text(value + 'g (' + ratio + '%)')
        .fontSize(12)
        .fontColor(Constants.COLORS.textSecondary)
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  /**
   * 绘制环形图
   */
  drawChart() {
    const centerX = 75;
    const centerY = 75;
    const radius = 60;
    const lineWidth = 20;

    // 清空画布
    this.context.clearRect(0, 0, 150, 150);

    // 绘制背景圆环
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius, 0, Math.PI * 2);
    this.context.strokeStyle = '#E0E0E0';
    this.context.lineWidth = lineWidth;
    this.context.stroke();

    // 计算角度
    const total = this.proteinRatio + this.carbsRatio + this.fatRatio;
    if (total === 0) return;

    let startAngle = -Math.PI / 2;

    // 绘制蛋白质
    const proteinAngle = (this.proteinRatio / total) * Math.PI * 2;
    this.drawArc(centerX, centerY, radius, lineWidth, startAngle, startAngle + proteinAngle, '#4CAF50');
    startAngle += proteinAngle;

    // 绘制碳水
    const carbsAngle = (this.carbsRatio / total) * Math.PI * 2;
    this.drawArc(centerX, centerY, radius, lineWidth, startAngle, startAngle + carbsAngle, '#FF9800');
    startAngle += carbsAngle;

    // 绘制脂肪
    const fatAngle = (this.fatRatio / total) * Math.PI * 2;
    this.drawArc(centerX, centerY, radius, lineWidth, startAngle, startAngle + fatAngle, '#F44336');
  }

  /**
   * 绘制圆弧
   */
  drawArc(
    centerX: number,
    centerY: number,
    radius: number,
    lineWidth: number,
    startAngle: number,
    endAngle: number,
    color: string
  ) {
    this.context.beginPath();
    this.context.arc(centerX, centerY, radius, startAngle, endAngle);
    this.context.strokeStyle = color;
    this.context.lineWidth = lineWidth;
    this.context.lineCap = LineCapStyle.Round;
    this.context.stroke();
  }
}
