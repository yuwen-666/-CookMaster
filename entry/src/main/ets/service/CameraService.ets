import { NetworkService, AIIngredientResult, CreativeRecipe } from './NetworkService';
import fs from '@ohos.file.fs';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import image from '@ohos.multimedia.image';

/**
 * 食材识别结果
 */
export class IngredientRecognitionResult {
  name: string = '';
  confidence: number = 0;
  reason: string = '';
}

/**
 * 相机服务
 * 支持AI食材识别（MiMo Vision API）和本地模拟识别
 */
export class CameraService {
  private static instance: CameraService;
  private networkService: NetworkService = NetworkService.getInstance();

  private constructor() {}

  static getInstance(): CameraService {
    if (!CameraService.instance) {
      CameraService.instance = new CameraService();
    }
    return CameraService.instance;
  }

  /**
   * 获取食材分类列表
   */
  getIngredientCategories(): string[] {
    return ['蔬菜', '肉类', '海鲜', '蛋奶', '主食', '调料'];
  }

  /**
   * 食材识别（本地简单匹配版本）
   * 根据用户选择的分类，返回该分类下的食材列表
   */
  getIngredientsByCategory(category: string): string[] {
    const ingredientMap: Record<string, string[]> = {
      '蔬菜': [
        '番茄', '土豆', '黄瓜', '白菜', '青菜', '菠菜', '茄子', '辣椒',
        '洋葱', '胡萝卜', '白萝卜', '豆角', '芹菜', '韭菜', '蘑菇', '豆腐'
      ],
      '肉类': [
        '猪肉', '牛肉', '羊肉', '鸡肉', '鸭肉', '排骨', '五花肉',
        '里脊肉', '鸡翅', '鸡腿', '培根', '香肠'
      ],
      '海鲜': [
        '鱼', '虾', '蟹', '贝类', '鱿鱼', '海带', '紫菜', '龙虾'
      ],
      '蛋奶': [
        '鸡蛋', '鸭蛋', '牛奶', '酸奶', '奶酪', '黄油'
      ],
      '主食': [
        '米饭', '面条', '面粉', '饺子皮', '馒头', '面包', '年糕'
      ],
      '调料': [
        '盐', '糖', '酱油', '醋', '料酒', '生抽', '老抽', '蚝油',
        '花椒', '八角', '桂皮', '姜', '蒜', '葱', '辣椒酱'
      ]
    };

    const result: string[] | undefined = ingredientMap[category];
    return result || [];
  }

  /**
   * 使用AI识别图片中的食材
   * 读取图片文件 → 转base64 → 调用AI API → 返回识别结果
   *
   * @param imagePath 图片路径（本地URI）
   * @param context 上下文（用于读取媒体库图片）
   * @returns 识别出的食材列表
   */
  async recognizeIngredients(imagePath: string, context?: common.Context): Promise<IngredientRecognitionResult[]> {
    try {
      console.info('=== 开始识别流程 ===');
      console.info('图片路径:', imagePath);

      // 1. 读取图片文件为base64
      let base64: string = '';

      // 判断是否是媒体库路径
      if (imagePath.startsWith('file://media/') || imagePath.startsWith('media/')) {
        // 媒体库路径，需要特殊处理
        base64 = await this.readMediaImage(imagePath, context);
      } else {
        // 普通文件路径
        base64 = await this.imageToBase64(imagePath);
      }

      if (!base64) {
        console.error('图片读取失败，降级为模拟识别');
        return this.mockRecognize();
      }

      console.info('图片转base64成功，长度:', base64.length);

      // 2. 调用AI识别
      console.info('开始调用AI识别...');
      const aiResults: AIIngredientResult[] = await this.networkService.recognizeFoodWithAI(base64);

      console.info('AI返回结果数量:', aiResults.length);

      if (aiResults.length > 0) {
        // 3. 转换为本地格式
        const results: IngredientRecognitionResult[] = [];
        for (let i = 0; i < aiResults.length; i++) {
          const item: IngredientRecognitionResult = new IngredientRecognitionResult();
          item.name = aiResults[i].name;
          item.confidence = aiResults[i].confidence;
          item.reason = aiResults[i].reason;
          results.push(item);
          console.info('识别到食材:', item.name, '置信度:', item.confidence);
        }
        console.info('=== AI识别成功 ===');
        return results;
      }

      // AI返回空结果，降级为模拟
      console.warn('AI返回空结果，降级为模拟识别');
      return this.mockRecognize();
    } catch (error) {
      console.error('AI识别异常，降级为模拟识别:', error);
      return this.mockRecognize();
    }
  }

  /**
   * 读取媒体库图片并转为base64
   * @param uri 媒体库URI（如 file://media/Photo/2/...）
   * @param context 上下文
   */
  private async readMediaImage(uri: string, context?: common.Context): Promise<string> {
    try {
      console.info('读取媒体库图片:', uri);

      // 获取文件大小
      const stat: fs.Stat = fs.statSync(uri);
      const fileSize: number = stat.size;
      console.info('图片文件大小:', fileSize, 'bytes');

      // 大于1MB的图片自动压缩（AI识别不需要太高清）
      const maxFileSize: number = 1 * 1024 * 1024; // 1MB
      if (fileSize > maxFileSize) {
        console.info('图片较大，进行压缩处理...');
        const compressedBase64: string = await this.compressImage(uri, 800);
        if (compressedBase64) {
          console.info('压缩完成，base64长度:', compressedBase64.length);
          return compressedBase64;
        }
        console.warn('压缩失败，使用原图');
      }

      // 读取文件内容
      const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const buffer: ArrayBuffer = new ArrayBuffer(fileSize);
      const readLen: number = fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      if (readLen === 0) {
        console.error('读取文件内容为空');
        return '';
      }

      console.info('成功读取图片，字节数:', readLen);

      // 转base64
      const uint8Array: Uint8Array = new Uint8Array(buffer);
      const base64: string = this.arrayBufferToBase64(uint8Array);

      console.info('Base64编码完成，长度:', base64.length);
      return base64;
    } catch (error) {
      console.error('读取媒体库图片失败:', error);
      return '';
    }
  }

  /**
   * 将图片文件转为base64字符串
   * @param uri 图片文件URI（file:// 或 internal:// 开头）
   * @returns base64编码字符串
   */
  private async imageToBase64(uri: string): Promise<string> {
    try {
      // 去掉 file:// 前缀获取实际路径
      let filePath: string = uri;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7);
      }

      console.info('读取图片文件:', filePath);

      const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(filePath);
      const fileSize: number = stat.size;

      console.info('图片文件大小:', fileSize, 'bytes');

      // 如果文件太大（>5MB），提示用户
      if (fileSize > 5 * 1024 * 1024) {
        console.warn('图片文件较大，可能影响识别速度');
      }

      // 读取文件内容
      const buffer: ArrayBuffer = new ArrayBuffer(fileSize);
      const readLen: number = fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      if (readLen === 0) {
        console.error('读取文件内容为空');
        return '';
      }

      // ArrayBuffer 转 base64
      const uint8Array: Uint8Array = new Uint8Array(buffer);
      const base64: string = this.arrayBufferToBase64(uint8Array);

      console.info('Base64编码完成，长度:', base64.length);
      return base64;
    } catch (error) {
      console.error('图片转base64失败:', error);
      return '';
    }
  }

  /**
   * Uint8Array 转 base64 字符串
   */
  private arrayBufferToBase64(buffer: Uint8Array): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result: string = '';
    const len: number = buffer.length;

    for (let i: number = 0; i < len; i += 3) {
      const b1: number = buffer[i];
      const b2: number = i + 1 < len ? buffer[i + 1] : 0;
      const b3: number = i + 2 < len ? buffer[i + 2] : 0;

      result += chars.charAt(b1 >> 2);
      result += chars.charAt(((b1 & 3) << 4) | (b2 >> 4));
      result += i + 1 < len ? chars.charAt(((b2 & 15) << 2) | (b3 >> 6)) : '=';
      result += i + 2 < len ? chars.charAt(b3 & 63) : '=';
    }

    return result;
  }

  /**
   * 压缩图片
   * @param uri 图片URI
   * @param maxSize 最大尺寸（宽或高）
   * @returns 压缩后的base64
   */
  private async compressImage(uri: string, maxSize: number = 800): Promise<string> {
    try {
      // 创建图片源
      const imageSource: image.ImageSource = image.createImageSource(uri);

      // 获取图片信息
      const imageInfo: image.ImageInfo = await imageSource.getImageInfo();
      console.info('原图尺寸:', imageInfo.size.width, 'x', imageInfo.size.height);

      // 计算缩放比例
      let scale: number = 1;
      if (imageInfo.size.width > maxSize || imageInfo.size.height > maxSize) {
        scale = Math.min(maxSize / imageInfo.size.width, maxSize / imageInfo.size.height);
      }

      // 解码图片
      const decodeOpts: image.DecodingOptions = {
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pixelMap: image.PixelMap = await imageSource.createPixelMap(decodeOpts);

      // 缩放图片
      if (scale < 1) {
        const targetWidth: number = Math.floor(imageInfo.size.width * scale);
        const targetHeight: number = Math.floor(imageInfo.size.height * scale);
        console.info('缩放到:', targetWidth, 'x', targetHeight);
        await pixelMap.scale(targetWidth, targetHeight);
      }

      // 使用 ImagePacker 打包为 JPEG
      const imagePacker: image.ImagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 70  // 压缩质量70%
      };

      const compressedData: ArrayBuffer = await imagePacker.packToData(pixelMap, packOpts);
      console.info('压缩后大小:', compressedData.byteLength, 'bytes');

      // 释放资源
      pixelMap.release();
      imagePacker.release();
      imageSource.release();

      // 转base64
      return this.arrayBufferToBase64(new Uint8Array(compressedData));
    } catch (error) {
      console.error('图片压缩失败:', error);
      return '';
    }
  }

  /**
   * 模拟识别（降级方案）
   */
  private mockRecognize(): IngredientRecognitionResult[] {
    return [
      { name: '番茄', confidence: 95, reason: '图中红色圆形带蒂的果实，特征明显' },
      { name: '鸡蛋', confidence: 90, reason: '椭圆形白色物体，蛋壳纹理清晰' },
      { name: '葱', confidence: 85, reason: '细长绿色条状，有白色根部' },
      { name: '姜', confidence: 80, reason: '不规则黄色块茎，表面有纹理' }
    ];
  }

  /**
   * 根据食材列表生成创新菜谱
   * @param ingredients 食材名称列表
   * @returns 创新菜谱，失败返回null
   */
  async generateCreativeRecipe(ingredients: string[]): Promise<CreativeRecipe | null> {
    if (!ingredients || ingredients.length === 0) {
      console.error('食材列表为空');
      return null;
    }

    try {
      const result: CreativeRecipe | null = await this.networkService.generateCreativeRecipe(ingredients);
      if (result) {
        console.info('AI生成创新菜谱成功:', result.name);
      }
      return result;
    } catch (error) {
      console.error('生成创新菜谱失败:', error);
      return null;
    }
  }
}
