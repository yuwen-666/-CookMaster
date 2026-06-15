import { Recipe } from '../model/Recipe';
import { Constants } from '../utils/Constants';
import { CoverImage } from './CoverImage';

/**
 * 菜谱卡片组件
 * 可复用的菜谱展示卡片
 */
@Component
export struct RecipeCard {
  @Prop recipe: Recipe = new Recipe();
  @Prop cardType: string = 'vertical'; // vertical: 竖向, horizontal: 横向
  onCardClick?: (recipe: Recipe) => void;

  build() {
    if (this.cardType === 'horizontal') {
      this.HorizontalCard()
    } else {
      this.VerticalCard()
    }
  }

  @Builder
  VerticalCard() {
    Column() {
      // 菜谱图片
      Stack() {
        CoverImage({ src: this.recipe.coverImage, recipeName: this.recipe.name, imgHeight: 120, imgBorderRadius: 12 })

        // 难度标签
        Text(this.recipe.difficulty)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getDifficultyColor())
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .position({ x: 8, y: 8 })

        // 收藏状态
        if (this.recipe.isFavorite) {
          Text('❤️')
            .fontSize(16)
            .position({ x: '85%', y: 8 })
        }
      }
      .width('100%')
      .height(120)

      // 菜谱信息
      Column() {
        Text(this.recipe.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Constants.COLORS.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.recipe.description)
          .fontSize(12)
          .fontColor(Constants.COLORS.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })

        Row() {
          // 评分
          Row() {
            Text('⭐')
              .fontSize(11)

            Text('' + this.recipe.rating)
              .fontSize(12)
              .fontColor('#FFB800')
              .margin({ left: 2 })
          }

          // 时长
          Row() {
            Text('🕐')
              .fontSize(11)

            Text(this.recipe.duration + 'min')
              .fontSize(12)
              .fontColor(Constants.COLORS.textLight)
              .margin({ left: 2 })
          }
          .margin({ left: 12 })

          // 浏览量
          Row() {
            Text('👁️')
              .fontSize(11)

            Text('' + this.recipe.viewCount)
              .fontSize(12)
              .fontColor(Constants.COLORS.textLight)
              .margin({ left: 2 })
          }
          .margin({ left: 12 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
        .scale({ x: 0.97, y: 0.97 })
      }
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick(this.recipe);
      }
    })
  }

  @Builder
  HorizontalCard() {
    Row() {
      // 菜谱图片
      CoverImage({ src: this.recipe.coverImage, recipeName: this.recipe.name, imgWidth: '100vp', imgHeight: 80, imgBorderRadius: 8 })

      // 菜谱信息
      Column() {
        Text(this.recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Constants.COLORS.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.recipe.description)
          .fontSize(13)
          .fontColor(Constants.COLORS.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })

        Row() {
          Text('⭐ ' + this.recipe.rating)
            .fontSize(12)
            .fontColor('#FFB800')

          Text(this.recipe.duration + '分钟')
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 12 })

          Text(this.recipe.difficulty)
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 12 })

          Text(this.recipe.cuisine)
            .fontSize(12)
            .fontColor(Constants.COLORS.textLight)
            .margin({ left: 12 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Constants.COLORS.surface)
    .borderRadius(8)
    .stateStyles({
      pressed: {
        .opacity(Constants.OPACITY.pressed)
      }
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick(this.recipe);
      }
    })
  }

  getDifficultyColor(): ResourceColor {
    switch (this.recipe.difficulty) {
      case '简单':
        return '#4CAF50';
      case '中等':
        return '#FF9800';
      case '困难':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}
