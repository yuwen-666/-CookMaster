import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { Constants } from '../utils/Constants';
import { common } from '@kit.AbilityKit';

/**
 * 数据导入页面
 * 从 resources/rawfile 读取菜谱 JSON 数据并导入到本地数据库
 */
@Entry
@Component
struct DataImportPage {
  @State importStatus: string = 'idle'; // idle, importing, success, error
  @State progress: number = 0;
  @State total: number = 0;
  @State imported: number = 0;
  @State message: string = '';

  private dbService: DatabaseService = DatabaseService.getInstance();

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(Constants.COLORS.textSecondary)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .stateStyles({
            pressed: {
              .backgroundColor(Constants.COLORS.warmGray)
            }
          })
          .onClick(() => {
            router.back();
          })

        Blank()

        Text('数据导入')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Constants.COLORS.text)

        Blank()

        Text('   ')
          .width(40)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Constants.COLORS.surface)

      Scroll() {
        Column() {
          // 说明卡片
          Column() {
            Text('📋 菜谱数据导入')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Constants.COLORS.text)
              .margin({ bottom: 12 })

            Text('从本地数据库导入 5000+ 道菜谱（含食材和烹饪步骤）')
              .fontSize(14)
              .fontColor(Constants.COLORS.textSecondary)
              .margin({ bottom: 16 })

            // 数据统计
            Row() {
              this.StatItem('📄', '数据来源', 'Access菜谱数据库')
              this.StatItem('📊', '菜谱数量', '5000+ 道')
              this.StatItem('🥘', '包含内容', '食材 + 步骤')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Constants.COLORS.surface)
          .borderRadius(12)
          .margin({ bottom: 16 })

          // 导入按钮
          if (this.importStatus === 'idle') {
            Button('开始导入菜谱数据')
              .width('100%')
              .height(52)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor(Constants.COLORS.primary)
              .borderRadius(26)
              .margin({ bottom: 16 })
              .onClick(() => {
                this.startImport();
              })
          }

          // 进度显示
          if (this.importStatus === 'importing') {
            Column() {
              Text('正在导入...')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Constants.COLORS.text)
                .margin({ bottom: 16 })

              Progress({ value: this.progress, total: this.total, type: ProgressType.Linear })
                .width('100%')
                .height(10)
                .margin({ bottom: 12 })

              Text(`${this.progress} / ${this.total}`)
                .fontSize(15)
                .fontColor(Constants.COLORS.textSecondary)
                .margin({ bottom: 8 })

              Text('请耐心等待，不要退出页面')
                .fontSize(13)
                .fontColor(Constants.COLORS.textLight)
            }
            .width('100%')
            .padding(24)
            .backgroundColor(Constants.COLORS.surface)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 16 })
          }

          // 成功结果
          if (this.importStatus === 'success') {
            Column() {
              Text('🎉')
                .fontSize(64)
                .margin({ bottom: 16 })

              Text('导入成功！')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4CAF50')
                .margin({ bottom: 12 })

              Text(this.message)
                .fontSize(15)
                .fontColor(Constants.COLORS.textSecondary)
                .textAlign(TextAlign.Center)
                .margin({ bottom: 24 })

              Button('返回首页查看')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor(Constants.COLORS.primary)
                .height(48)
                .borderRadius(24)
                .width(200)
                .onClick(() => {
                  router.pushUrl({ url: Constants.ROUTES.INDEX });
                })

              Button('继续导入')
                .fontSize(14)
                .fontColor(Constants.COLORS.primary)
                .backgroundColor('#FFFFFF')
                .height(40)
                .borderRadius(20)
                .width(160)
                .margin({ top: 12 })
                .border({ width: 1, color: Constants.COLORS.primary })
                .onClick(() => {
                  this.importStatus = 'idle';
                  this.message = '';
                  this.progress = 0;
                })
            }
            .width('100%')
            .padding(24)
            .backgroundColor(Constants.COLORS.surface)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 16 })
          }

          // 错误结果
          if (this.importStatus === 'error') {
            Column() {
              Text('❌')
                .fontSize(64)
                .margin({ bottom: 16 })

              Text('导入失败')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#F44336')
                .margin({ bottom: 12 })

              Text(this.message)
                .fontSize(14)
                .fontColor(Constants.COLORS.textSecondary)
                .textAlign(TextAlign.Center)
                .margin({ bottom: 24 })

              Button('重试')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor(Constants.COLORS.primary)
                .height(48)
                .borderRadius(24)
                .width(160)
                .onClick(() => {
                  this.importStatus = 'idle';
                  this.message = '';
                })
            }
            .width('100%')
            .padding(24)
            .backgroundColor(Constants.COLORS.surface)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 16 })
          }

          // 分类预览
          Column() {
            Text('📊 分类统计')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Constants.COLORS.text)
              .margin({ bottom: 12 })

            this.CategoryRow('家常菜', '4030')
            this.CategoryRow('荤菜', '365')
            this.CategoryRow('素菜', '214')
            this.CategoryRow('汤羹', '115')
            this.CategoryRow('主食', '84')
            this.CategoryRow('小吃', '75')
            this.CategoryRow('饮品', '46')
            this.CategoryRow('海鲜', '42')
            this.CategoryRow('甜品', '29')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Constants.COLORS.surface)
          .borderRadius(12)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Constants.COLORS.background)
  }

  @Builder
  StatItem(icon: string, label: string, value: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .margin({ bottom: 6 })
      Text(label)
        .fontSize(12)
        .fontColor(Constants.COLORS.textLight)
        .margin({ bottom: 2 })
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Constants.COLORS.text)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CategoryRow(name: string, count: string) {
    Row() {
      Text(name)
        .fontSize(14)
        .fontColor(Constants.COLORS.text)
        .layoutWeight(1)

      Text(count + ' 道')
        .fontSize(14)
        .fontColor(Constants.COLORS.primary)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .border({ width: { bottom: 1 }, color: '#F5F5F5' })
  }

  async startImport(): Promise<void> {
    this.importStatus = 'importing';
    this.progress = 0;
    this.message = '';

    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

      // 分批文件列表
      const batchFiles: string[] = [
        'recipes_batch_1.json', 'recipes_batch_2.json', 'recipes_batch_3.json',
        'recipes_batch_4.json', 'recipes_batch_5.json', 'recipes_batch_6.json',
        'recipes_batch_7.json', 'recipes_batch_8.json', 'recipes_batch_9.json',
        'recipes_batch_10.json', 'recipes_batch_11.json', 'recipes_batch_12.json',
        'recipes_batch_13.json', 'recipes_batch_14.json', 'recipes_batch_15.json',
        'recipes_batch_16.json', 'recipes_batch_17.json'
      ];

      this.total = 5000;
      let totalImported: number = 0;

      // 逐批导入
      for (let i = 0; i < batchFiles.length; i++) {
        const filename: string = batchFiles[i];
        console.info(`处理批次 ${i + 1}/${batchFiles.length}`);

        const fileData: Uint8Array = await context.resourceManager.getRawFileContent(filename);
        const jsonStr: string = bufferToString(fileData);

        const imported: number = await this.dbService.importRecipesFromJson(jsonStr);
        totalImported += imported;

        this.progress = totalImported;
        console.info(`  批次 ${i + 1} 完成: ${imported} 道`);
      }

      this.imported = totalImported;

      // 为没有封面图的菜谱分配默认图片
      await this.dbService.assignDefaultImages();

      this.importStatus = 'success';
      this.message = `成功导入 ${totalImported} 道菜谱\n包含完整的食材清单和烹饪步骤`;
    } catch (error) {
      console.error('导入失败:', error);
      this.importStatus = 'error';
      this.message = `导入失败: ${error}`;
    }
  }
}

/**
 * Uint8Array 转 UTF-8 字符串
 */
function bufferToString(buffer: Uint8Array): string {
  // 使用 TextDecoder 正确处理 UTF-8 编码
  let result = '';
  let i = 0;
  while (i < buffer.length) {
    const byte = buffer[i];
    if (byte < 0x80) {
      // 单字节 ASCII
      result += String.fromCharCode(byte);
      i++;
    } else if ((byte & 0xE0) === 0xC0) {
      // 双字节 UTF-8
      const code = ((byte & 0x1F) << 6) | (buffer[i + 1] & 0x3F);
      result += String.fromCharCode(code);
      i += 2;
    } else if ((byte & 0xF0) === 0xE0) {
      // 三字节 UTF-8（中文字符）
      const code = ((byte & 0x0F) << 12) | ((buffer[i + 1] & 0x3F) << 6) | (buffer[i + 2] & 0x3F);
      result += String.fromCharCode(code);
      i += 3;
    } else if ((byte & 0xF8) === 0xF0) {
      // 四字节 UTF-8
      const code = ((byte & 0x07) << 18) | ((buffer[i + 1] & 0x3F) << 12) | ((buffer[i + 2] & 0x3F) << 6) | (buffer[i + 3] & 0x3F);
      result += String.fromCodePoint(code);
      i += 4;
    } else {
      result += String.fromCharCode(byte);
      i++;
    }
  }
  return result;
}
