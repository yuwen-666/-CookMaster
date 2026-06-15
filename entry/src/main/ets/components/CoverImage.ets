import { Constants } from '../utils/Constants';

/**
 * 封面图片组件
 * 自动处理图片加载失败，显示兜底占位图
 */
@Component
export struct CoverImage {
  @Prop src: string = '';
  @Prop recipeName: string = '';
  @Prop imgWidth: string = '100%';
  @Prop imgHeight: number = 180;
  @Prop imgBorderRadius: number = 14;
  @State loadError: boolean = false;
  @State loading: boolean = true;

  /**
   * 根据菜名生成占位图的渐变色
   */
  private getGradientColors(): string[] {
    const gradients: string[][] = [
      ['#FF6B35', '#FF8A5C'],
      ['#4CAF50', '#81C784'],
      ['#2196F3', '#64B5F6'],
      ['#FF9800', '#FFB74D'],
      ['#9C27B0', '#CE93D8'],
      ['#E91E63', '#F48FB1'],
      ['#00BCD4', '#4DD0E1'],
      ['#FF5722', '#FF8A65'],
    ];

    // 根据菜名的字符编码选择颜色，保证同一道菜每次显示相同颜色
    let hash: number = 0;
    for (let i = 0; i < this.recipeName.length; i++) {
      hash = ((hash << 5) - hash) + this.recipeName.charCodeAt(i);
      hash = hash & hash; // 转为32位整数
    }
    const index: number = Math.abs(hash) % gradients.length;
    return gradients[index];
  }

  /**
   * 获取菜名首字（用于占位图显示）
   */
  private getDisplayText(): string {
    if (this.recipeName.length > 0) {
      return this.recipeName.charAt(0);
    }
    return '🍽';
  }

  build() {
    Stack() {
      // 图片（正常加载时显示）
      if (!this.loadError && this.src) {
        Image(this.src)
          .width(this.imgWidth)
          .height(this.imgHeight)
          .borderRadius(this.imgBorderRadius)
          .objectFit(ImageFit.Cover)
          .onAppear(() => {
            this.loading = false;
          })
          .onError(() => {
            this.loadError = true;
            this.loading = false;
          })
      }

      // 加载失败或无图片时的占位图
      if (this.loadError || !this.src) {
        Column() {
          Text(this.getDisplayText())
            .fontSize(this.imgHeight * 0.3)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .justifyContent(FlexAlign.Center)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [[this.getGradientColors()[0], 0.0], [this.getGradientColors()[1], 1.0]] as [ResourceColor, number][]
        })
      }

      // 加载中指示器
      if (this.loading && this.src && !this.loadError) {
        Column() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color('#FFFFFF')
        }
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .backgroundColor('#E0E0E0')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.imgWidth)
    .height(this.imgHeight)
  }
}
