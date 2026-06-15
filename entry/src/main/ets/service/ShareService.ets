import { Want, common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

/**
 * 分享服务
 * 调用系统分享面板将菜谱信息分享到微信等应用
 * 失败时降级为复制到剪贴板
 */
export class ShareService {
  private static instance: ShareService;

  private constructor() {}

  static getInstance(): ShareService {
    if (!ShareService.instance) {
      ShareService.instance = new ShareService();
    }
    return ShareService.instance;
  }

  /**
   * 分享菜谱到系统分享面板（微信、QQ、短信等）
   */
  async shareRecipe(context: Context, recipeName: string, description: string, rating: number, duration: number): Promise<void> {
    const shareText: string = '🍳 ' + recipeName + '\n'
      + '⭐评分：' + rating + ' | ⏱️' + duration + '分钟\n'
      + description + '\n'
      + '—— 来自 CookMaster 智能菜谱助手';

    await this.shareText(context, shareText);
  }

  /**
   * 分享社区帖子
   */
  async shareCommunityPost(context: Context, title: string, content: string, userName: string): Promise<void> {
    const shareText: string = '📝 ' + title + '\n'
      + '👤 ' + userName + '\n'
      + content + '\n'
      + '—— 来自 CookMaster 美食社区';

    await this.shareText(context, shareText);
  }

  /**
   * 通用文本分享：优先调系统分享面板，失败则复制到剪贴板
   */
  async shareText(context: Context, text: string): Promise<void> {
    const want: Want = {
      action: 'ohos.want.action.shareData',
      parameters: {
        'ohos.param.key.shareContent': text,
        'ohos.param.key.shareType': 'text/plain'
      },
      entities: ['entity.system.share']
    };

    try {
      await (context as common.UIAbilityContext).startAbility(want);
    } catch (error) {
      const errCode: number = (error as BusinessError).code;
      console.error('系统分享失败，降级到剪贴板, errorCode:', errCode);
      await this.copyToClipboard(text);
    }
  }

  /**
   * 复制文本到剪贴板（降级方案）
   */
  private async copyToClipboard(text: string): Promise<void> {
    try {
      const pasteboardData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteboardData);

      promptAction.showToast({
        message: '已复制到剪贴板，可粘贴发送给好友',
        duration: 2000
      });
    } catch (error) {
      console.error('复制到剪贴板失败:', error);
      promptAction.showToast({
        message: '分享失败，请重试',
        duration: 2000
      });
    }
  }
}
