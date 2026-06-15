import { Constants } from '../utils/Constants';

/**
 * 分类标签组件
 */
@Component
export struct CategoryTag {
  @Prop label: string = '';
  @Prop icon: string = '';
  @Prop isSelected: boolean = false;
  @Prop size: string = 'medium'; // small, medium, large
  onClick?: () => void;

  build() {
    Column() {
      if (this.icon) {
        Text(this.icon)
          .fontSize(this.getIconSize())
      }

      Text(this.label)
        .fontSize(this.getTextSize())
        .fontColor(this.isSelected ? '#FFFFFF' : Constants.COLORS.textSecondary)
        .margin({ top: this.icon ? 4 : 0 })
    }
    .padding({
      left: this.getPadding(),
      right: this.getPadding(),
      top: this.icon ? 8 : 4,
      bottom: this.icon ? 8 : 4
    })
    .backgroundColor(this.isSelected ? Constants.COLORS.primary : '#F5F5F5')
    .borderRadius(this.getBorderRadius())
    .onClick(() => {
      if (this.onClick) this.onClick();
    })
  }

  getIconSize(): number {
    switch (this.size) {
      case 'small': return 16;
      case 'large': return 32;
      default: return 24;
    }
  }

  getTextSize(): number {
    switch (this.size) {
      case 'small': return 11;
      case 'large': return 16;
      default: return 13;
    }
  }

  getPadding(): number {
    switch (this.size) {
      case 'small': return 8;
      case 'large': return 16;
      default: return 12;
    }
  }

  getBorderRadius(): number {
    switch (this.size) {
      case 'small': return 12;
      case 'large': return 20;
      default: return 16;
    }
  }
}
