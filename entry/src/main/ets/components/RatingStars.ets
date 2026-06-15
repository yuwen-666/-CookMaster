import { Constants } from '../utils/Constants';

/**
 * 评分星级组件
 */
@Component
export struct RatingStars {
  @Prop rating: number = 0;
  @Prop maxRating: number = 5;
  @Prop size: number = 16;
  @Prop editable: boolean = false;
  onRatingChange?: (rating: number) => void;

  build() {
    Row() {
      ForEach(this.getStars(), (star: string, index: number) => {
        Text(star)
          .fontSize(this.size)
          .margin({ right: 2 })
          .onClick(() => {
            if (this.editable && this.onRatingChange) {
              this.onRatingChange(index + 1);
            }
          })
      })
    }
  }

  getStars(): string[] {
    const stars: string[] = [];
    for (let i = 1; i <= this.maxRating; i++) {
      if (i <= this.rating) {
        stars.push('⭐');
      } else if (i - 0.5 <= this.rating) {
        stars.push('🌟');
      } else {
        stars.push('☆');
      }
    }
    return stars;
  }
}
