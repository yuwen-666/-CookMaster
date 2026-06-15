import { Constants } from '../utils/Constants';
import { Ingredient } from '../model/Recipe';

/**
 * 食材编辑组件
 * 用于发布菜谱时编辑单个食材信息
 */
@Component
export struct IngredientEditor {
  @Prop index: number = 0;
  @Prop name: string = '';
  @Prop amount: string = '';
  @Prop category: string = '蔬菜';
  onChange?: (index: number, ingredient: Ingredient) => void;
  onDelete?: (index: number) => void;

  private categories: string[] = ['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'];

  build() {
    Row() {
      // 序号
      Text(`${this.index + 1}`)
        .fontSize(14)
        .fontColor(Constants.COLORS.textSecondary)
        .width(24)
        .textAlign(TextAlign.Center)

      // 食材名称
      TextInput({ placeholder: '食材名称', text: this.name })
        .layoutWeight(2)
        .height(36)
        .fontSize(14)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .onChange((value: string) => {
          this.name = value;
          this.notifyChange();
        })

      // 用量
      TextInput({ placeholder: '用量', text: this.amount })
        .layoutWeight(1.5)
        .height(36)
        .fontSize(14)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .margin({ left: 8 })
        .onChange((value: string) => {
          this.amount = value;
          this.notifyChange();
        })

      // 分类选择
      Select(this.categories.map(cat => ({ value: cat } as SelectOption)))
        .selected(this.categories.indexOf(this.category) >= 0 ? this.categories.indexOf(this.category) : 0)
        .value(this.category)
        .layoutWeight(1.2)
        .height(36)
        .font({ size: 12 })
        .selectedOptionFontColor('#FFFFFF')
        .selectedOptionBgColor(Constants.COLORS.primary)
        .onSelect((index: number) => {
          this.category = this.categories[index];
          this.notifyChange();
        })
        .margin({ left: 8 })

      // 删除按钮
      Button() {
        Text('✕')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width(28)
      .height(28)
      .backgroundColor('#FF4444')
      .borderRadius(14)
      .margin({ left: 8 })
      .onClick(() => {
        if (this.onDelete) this.onDelete(this.index);
      })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  private notifyChange(): void {
    if (this.onChange) {
      const ingredient: Ingredient = new Ingredient();
      ingredient.name = this.name;
      ingredient.amount = this.amount;
      ingredient.category = this.category;
      this.onChange(this.index, ingredient);
    }
  }
}
