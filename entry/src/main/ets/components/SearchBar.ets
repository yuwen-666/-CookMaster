import { Constants } from '../utils/Constants';

/**
 * 搜索栏组件
 */
@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索菜谱、食材...';
  @Prop searchText: string = '';
  onSearch?: (keyword: string) => void;
  onTextChange?: (text: string) => void;

  build() {
    Row() {
      // 搜索图标
      Text('🔍')
        .fontSize(16)
        .margin({ right: 8 })

      // 输入框
      TextInput({ placeholder: this.placeholder, text: this.searchText })
        .layoutWeight(1)
        .height(36)
        .backgroundColor('transparent')
        .fontSize(14)
        .onChange((value: string) => {
          if (this.onTextChange) {
            this.onTextChange(value);
          }
        })
        .onSubmit(() => {
          if (this.onSearch && this.searchText.trim()) {
            this.onSearch(this.searchText.trim());
          }
        })

      // 清除按钮
      if (this.searchText) {
        Text('✕')
          .fontSize(14)
          .fontColor(Constants.COLORS.textLight)
          .padding(4)
          .onClick(() => {
            if (this.onTextChange) {
              this.onTextChange('');
            }
          })
      }
    }
    .width('100%')
    .height(44)
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
    .padding({ left: 16, right: 16 })
  }
}
