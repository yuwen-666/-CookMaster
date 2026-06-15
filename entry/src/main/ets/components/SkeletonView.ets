import { Constants } from '../utils/Constants';

/**
 * 骨架屏组件 - 用于加载状态的占位显示
 * 支持卡片列表、详情页等多种骨架样式
 */
@Component
export struct SkeletonView {
  @Prop skeletonType: string = 'cardList'; // cardList | detail | profile
  @State shimmerOffset: number = -1;

  aboutToAppear() {
    this.startShimmer();
  }

  startShimmer() {
    animateTo({
      duration: 1500,
      iterations: -1,
      curve: Curve.Linear,
      onFinish: () => {}
    }, () => {
      this.shimmerOffset = 1;
    })
  }

  build() {
    Column() {
      if (this.skeletonType === 'cardList') {
        this.CardListSkeleton()
      } else if (this.skeletonType === 'detail') {
        this.DetailSkeleton()
      } else if (this.skeletonType === 'profile') {
        this.ProfileSkeleton()
      }
    }
    .width('100%')
  }

  // 单个骨架块 - 带微光效果
  @Builder
  SkeletonBlock(width: string | number, height: string | number, borderRadius: number = 6) {
    Row()
      .width(width)
      .height(height)
      .borderRadius(borderRadius)
      .backgroundColor(Constants.COLORS.warmGray)
      .opacity(0.6 + this.shimmerOffset * 0.2)
  }

  // 卡片列表骨架（首页/分类/收藏通用）
  @Builder
  CardListSkeleton() {
    Column() {
      ForEach([0, 1, 2, 3, 4], (idx: number) => {
        Row() {
          // 左侧图片占位
          this.SkeletonBlock(80, 64, Constants.BORDER_RADIUS.normal)

          // 右侧文字占位
          Column() {
            this.SkeletonBlock('70%', 16, 4)
            this.SkeletonBlock('50%', 12, 4)
            Row() {
              this.SkeletonBlock(40, 12, 4)
              this.SkeletonBlock(50, 12, 4)
            }
            .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .backgroundColor(Constants.COLORS.surface)
        .borderRadius(Constants.BORDER_RADIUS.medium)
        .shadow(Constants.SHADOWS.small)
        .margin({ left: 16, right: 16, top: 6, bottom: 6 })
      })
    }
    .width('100%')
    .padding({ top: 8 })
  }

  // 详情页骨架
  @Builder
  DetailSkeleton() {
    Column() {
      // 封面图占位
      this.SkeletonBlock('100%', 250, 0)

      // 标题占位
      Column() {
        this.SkeletonBlock('80%', 26, 6)
        Row() {
          this.SkeletonBlock(60, 16, 4)
          this.SkeletonBlock(80, 16, 4)
          this.SkeletonBlock(60, 16, 4)
        }
        .margin({ top: 12 })

        // 标签占位
        Row() {
          this.SkeletonBlock(60, 28, 14)
          this.SkeletonBlock(60, 28, 14)
          this.SkeletonBlock(60, 28, 14)
          this.SkeletonBlock(60, 28, 14)
        }
        .margin({ top: 14 })

        // 描述占位
        this.SkeletonBlock('100%', 14, 4)
        this.SkeletonBlock('90%', 14, 4)
        this.SkeletonBlock('60%', 14, 4)
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(Constants.BORDER_RADIUS.large)
      .shadow(Constants.SHADOWS.small)
      .margin({ top: 12 })

      // Tab占位
      Row() {
        this.SkeletonBlock('30%', 40, 8)
        this.SkeletonBlock('30%', 40, 8)
        this.SkeletonBlock('30%', 40, 8)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(16)
      .margin({ top: 12 })

      // 列表项占位
      Column() {
        ForEach([0, 1, 2], (idx: number) => {
          Row() {
            this.SkeletonBlock(44, 44, 22)
            Column() {
              this.SkeletonBlock('60%', 16, 4)
              this.SkeletonBlock('40%', 12, 4)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(Constants.COLORS.surface)
          .borderRadius(Constants.BORDER_RADIUS.normal)
          .margin({ bottom: 8 })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
  }

  // 个人中心骨架
  @Builder
  ProfileSkeleton() {
    Column() {
      // 头像和用户名占位
      Row() {
        this.SkeletonBlock(76, 76, 38)
        Column() {
          this.SkeletonBlock(120, 22, 6)
          this.SkeletonBlock(80, 14, 4)
          this.SkeletonBlock(150, 14, 4)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(Constants.BORDER_RADIUS.large)
      .shadow(Constants.SHADOWS.medium)

      // 统计数据占位
      Row() {
        ForEach([0, 1, 2, 3], (idx: number) => {
          Column() {
            this.SkeletonBlock(24, 24, 4)
            this.SkeletonBlock(30, 20, 4)
            this.SkeletonBlock(30, 12, 4)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(Constants.BORDER_RADIUS.large)
      .shadow(Constants.SHADOWS.small)
      .margin({ top: 12 })

      // 菜单项占位
      Column() {
        ForEach([0, 1, 2, 3, 4], (idx: number) => {
          Row() {
            this.SkeletonBlock(36, 36, Constants.BORDER_RADIUS.normal)
            this.SkeletonBlock('60%', 16, 4)
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
        })
      }
      .padding({ top: 12 })
      .backgroundColor(Constants.COLORS.surface)
      .borderRadius(Constants.BORDER_RADIUS.large)
      .shadow(Constants.SHADOWS.small)
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }
}
