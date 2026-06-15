import http from '@ohos.net.http';
import { Constants } from '../utils/Constants';

/**
 * 邮箱发送验证码响应
 */
export class SendCodeResponse {
  success: boolean = false;
  message: string = '';
}

/**
 * 邮箱验证响应
 */
export class VerifyCodeResponse {
  success: boolean = false;
  message: string = '';
}

/**
 * 天气信息
 */
class WeatherInfo {
  temperature: number = 0;
  weather: string = '';
  humidity: number = 0;
  wind: string = '';
}

/**
 * 食材识别项
 */
class FoodItem {
  name: string = '';
  score: number = 0;
}

/**
 * AI食材识别结果项
 */
export class AIIngredientResult {
  name: string = '';
  confidence: number = 0;
  reason: string = '';
}

/**
 * AI请求相关接口定义
 */
interface ChatMessage {
  role: string;
  content: string | ContentPart[];
}

interface ContentPart {
  type: string;
  text?: string;
  image_url?: ImageUrl;
}

interface ImageUrl {
  url: string;
}

interface ChatRequest {
  model: string;
  messages: ChatMessage[];
  max_completion_tokens: number;
  temperature: number;
}

interface ChatResponse {
  choices: Choice[];
}

interface Choice {
  message: MessageContent;
}

interface MessageContent {
  content: string;
}

interface ParsedIngredients {
  ingredients: AIIngredientResult[];
}

/**
 * AI返回的创新菜谱JSON结构
 */
interface CreativeRecipeRaw {
  name?: string;
  description?: string;
  ingredients?: string[];
  steps?: string[];
  difficulty?: string;
  duration?: string;
  creativeTip?: string;
}

/**
 * AI创新菜谱结果
 */
export class CreativeRecipe {
  name: string = '';
  description: string = '';
  ingredients: string[] = [];
  steps: string[] = [];
  difficulty: string = '';
  duration: string = '';
  creativeTip: string = '';
}

/**
 * 网络请求服务
 */
export class NetworkService {
  private static instance: NetworkService;

  private constructor() {}

  static getInstance(): NetworkService {
    if (!NetworkService.instance) {
      NetworkService.instance = new NetworkService();
    }
    return NetworkService.instance;
  }

  /**
   * 发送POST请求到邮箱验证服务
   */
  async postSendCode(url: string, email: string): Promise<SendCodeResponse | null> {
    try {
      const httpRequest: http.HttpRequest = http.createHttp();

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({ email: email }),
        readTimeout: 10000,
        connectTimeout: 10000
      };

      const response: http.HttpResponse = await httpRequest.request(url, options);

      if (response.responseCode === 200) {
        const result: SendCodeResponse = JSON.parse(String(response.result)) as SendCodeResponse;
        httpRequest.destroy();
        return result;
      }

      httpRequest.destroy();
      return null;
    } catch (error) {
      console.error('发送验证码请求失败:', error);
      return null;
    }
  }

  /**
   * 发送POST请求验证验证码
   */
  async postVerifyCode(url: string, email: string, code: string): Promise<VerifyCodeResponse | null> {
    try {
      const httpRequest: http.HttpRequest = http.createHttp();

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({ email: email, code: code }),
        readTimeout: 10000,
        connectTimeout: 10000
      };

      const response: http.HttpResponse = await httpRequest.request(url, options);

      if (response.responseCode === 200) {
        const result: VerifyCodeResponse = JSON.parse(String(response.result)) as VerifyCodeResponse;
        httpRequest.destroy();
        return result;
      }

      httpRequest.destroy();
      return null;
    } catch (error) {
      console.error('验证请求失败:', error);
      return null;
    }
  }

  /**
   * 获取天气信息
   */
  async getWeather(city: string): Promise<WeatherInfo | null> {
    const url: string = 'https://api.seniverse.com/v3/weather/now.json?key=your_api_key&location=' + city + '&language=zh-Hans&unit=c';

    try {
      const httpRequest: http.HttpRequest = http.createHttp();

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 10000,
        connectTimeout: 10000
      };

      const response: http.HttpResponse = await httpRequest.request(url, options);

      if (response.responseCode === 200) {
        const jsonStr: string = response.result as string;
        const jsonObj: object = JSON.parse(jsonStr) as object;
        const jsonMap: Map<string, object> = new Map();
        const keys: string[] = Object.keys(jsonObj);
        for (let i = 0; i < keys.length; i++) {
          jsonMap.set(keys[i], (jsonObj as Record<string, object>)[keys[i]]);
        }

        httpRequest.destroy();

        const weatherInfo: WeatherInfo = {
          temperature: 0,
          weather: '晴',
          humidity: 0,
          wind: '无风'
        };
        return weatherInfo;
      }

      httpRequest.destroy();
      return null;
    } catch (error) {
      console.error('获取天气失败:', error);
      return null;
    }
  }

  /**
   * 使用AI识别图片中的食材（优化版：多次识别取共识）
   * @param imageBase64 图片的base64编码
   * @returns 识别出的食材列表
   */
  async recognizeFoodWithAI(imageBase64: string): Promise<AIIngredientResult[]> {
    try {
      // 单次识别（避免超时）
      const results: AIIngredientResult[] = await this.singleRecognition(imageBase64, 1);

      console.info('AI识别结果数量:', results.length);

      return this.filterResults(results);
    } catch (error) {
      console.error('AI识别流程异常:', error);
      return [];
    }
  }

  /**
   * 单次AI识别
   * @param imageBase64 图片base64
   * @param attempt 第几次尝试（用于不同提示词策略）
   */
  private async singleRecognition(imageBase64: string, attempt: number): Promise<AIIngredientResult[]> {
    const url: string = Constants.MIMO_API_BASE + '/chat/completions';

    // 不同尝试使用略有不同的提示词，提高识别覆盖率
    let prompt: string = '';
    if (attempt === 1) {
      prompt = `请仔细观察这张图片，识别其中所有可见的食材和食物原料。

要求：
1. 只识别图片中清晰可见、确实存在的食材
2. 每个食材附带判断依据（颜色、形状、位置等特征）
3. 置信度用0-100的整数表示，低于75分的不要输出
4. 返回JSON格式，不要其他文字

返回格式：
{"ingredients":[{"name":"食材名","confidence":85,"reason":"判断依据"}]}`;
    } else {
      prompt = `请以专业厨师的眼光分析这张图片中的食材。

重点关注：
1. 蔬菜水果：注意颜色、形状、大小特征
2. 肉类海鲜：注意纹理、颜色、部位特征
3. 调味料：注意包装、颜色、状态特征
4. 主食：注意形态、颜色特征

每个食材需要说明识别理由，置信度低于75分的不要返回。

返回JSON格式：
{"ingredients":[{"name":"食材名","confidence":90,"reason":"识别理由"}]}`;
    }

    const userContent: ContentPart[] = [
      {
        type: 'text',
        text: prompt
      },
      {
        type: 'image_url',
        image_url: {
          url: 'data:image/jpeg;base64,' + imageBase64
        }
      }
    ];

    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: '你是专业的食材识别AI，擅长从图片中准确识别各种食材。只返回JSON格式结果。'
      },
      {
        role: 'user',
        content: userContent
      }
    ];

    const requestBody: ChatRequest = {
      model: Constants.MIMO_VISION_MODEL,
      messages: messages,
      max_completion_tokens: 1500,
      temperature: 0.2  // 低温度，结果更稳定
    };

    try {
      const httpRequest: http.HttpRequest = http.createHttp();

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + Constants.MIMO_API_KEY
        },
        extraData: JSON.stringify(requestBody),
        readTimeout: 90000,  // 90秒，视觉模型需要更长时间
        connectTimeout: 30000
      };

      const response: http.HttpResponse = await httpRequest.request(url, options);
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        console.info(`第${attempt}次识别返回:`, resultStr.substring(0, 200));
        return this.parseAIResponse(resultStr);
      }

      console.error(`第${attempt}次识别失败, statusCode:`, response.responseCode);
      return [];
    } catch (error) {
      console.error(`第${attempt}次识别异常:`, error);
      return [];
    }
  }

  /**
   * 合并两次识别结果，取共同食材
   */
  private mergeRecognitionResults(results1: AIIngredientResult[], results2: AIIngredientResult[]): AIIngredientResult[] {
    const merged: AIIngredientResult[] = [];

    for (let i = 0; i < results1.length; i++) {
      const item1: AIIngredientResult = results1[i];

      for (let j = 0; j < results2.length; j++) {
        const item2: AIIngredientResult = results2[j];

        // 食材名称匹配（包含关系也算）
        if (this.isIngredientMatch(item1.name, item2.name)) {
          // 取平均置信度
          const mergedItem: AIIngredientResult = new AIIngredientResult();
          mergedItem.name = item1.name;
          mergedItem.confidence = Math.round((item1.confidence + item2.confidence) / 2);
          mergedItem.reason = item1.reason || item2.reason;
          merged.push(mergedItem);
          break;
        }
      }
    }

    return merged;
  }

  /**
   * 判断两个食材名称是否匹配
   */
  private isIngredientMatch(name1: string, name2: string): boolean {
    if (name1 === name2) {
      return true;
    }
    // 包含关系
    if (name1.includes(name2) || name2.includes(name1)) {
      return true;
    }
    // 常见别名映射
    const aliases: Record<string, string[]> = {
      '番茄': ['西红柿', '蕃茄'],
      '土豆': ['马铃薯', '洋芋'],
      '黄瓜': ['青瓜'],
      '白菜': ['大白菜'],
      '猪肉': ['五花肉', '里脊肉', '排骨'],
      '牛肉': ['牛腩', '牛排'],
      '鸡肉': ['鸡胸肉', '鸡腿', '鸡翅'],
      '鸡蛋': ['蛋'],
      '虾': ['大虾', '虾仁'],
      '鱼': ['鲈鱼', '鲫鱼', '草鱼']
    };

    // 使用数组遍历替代for..in
    const aliasEntries: string[][] = [
      ['番茄', '西红柿', '蕃茄'],
      ['土豆', '马铃薯', '洋芋'],
      ['黄瓜', '青瓜'],
      ['白菜', '大白菜'],
      ['猪肉', '五花肉', '里脊肉', '排骨'],
      ['牛肉', '牛腩', '牛排'],
      ['鸡肉', '鸡胸肉', '鸡腿', '鸡翅'],
      ['鸡蛋', '蛋'],
      ['虾', '大虾', '虾仁'],
      ['鱼', '鲈鱼', '鲫鱼', '草鱼']
    ];

    for (let i = 0; i < aliasEntries.length; i++) {
      const group: string[] = aliasEntries[i];
      const name1InGroup: boolean = group.includes(name1);
      const name2InGroup: boolean = group.includes(name2);
      if (name1InGroup && name2InGroup) {
        return true;
      }
    }

    return false;
  }

  /**
   * 过滤识别结果
   */
  private filterResults(results: AIIngredientResult[]): AIIngredientResult[] {
    return results.filter((item: AIIngredientResult) => {
      // 过滤置信度过低的
      if (item.confidence < 75) {
        return false;
      }
      // 过滤名称为空或太短的
      if (!item.name || item.name.length < 1) {
        return false;
      }
      // 过滤明显不是食材的
      const invalidKeywords: string[] = ['盘子', '碗', '桌子', '背景', '盘', '碟', '杯'];
      for (const keyword of invalidKeywords) {
        if (item.name.includes(keyword)) {
          return false;
        }
      }
      return true;
    });
  }

  /**
   * 解析MiMo AI的响应，提取食材列表
   */
  private parseAIResponse(responseStr: string): AIIngredientResult[] {
    try {
      const chatResponse: ChatResponse = JSON.parse(responseStr) as ChatResponse;
      const choices: Choice[] = chatResponse.choices;

      if (!choices || choices.length === 0) {
        return [];
      }

      const content: string = choices[0].message.content;

      // 从AI回复中提取JSON（可能包含```json```包裹）
      let jsonStr: string = content.trim();
      const jsonStart: number = jsonStr.indexOf('{');
      const jsonEnd: number = jsonStr.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      const parsed: ParsedIngredients = JSON.parse(jsonStr) as ParsedIngredients;
      const ingredients: AIIngredientResult[] = parsed.ingredients;

      if (!ingredients || !Array.isArray(ingredients)) {
        return [];
      }

      const results: AIIngredientResult[] = [];
      for (let i = 0; i < ingredients.length; i++) {
        const item: AIIngredientResult = ingredients[i];
        const result: AIIngredientResult = new AIIngredientResult();
        result.name = item.name || '';
        result.confidence = item.confidence || 0;
        result.reason = item.reason || '';
        if (result.name) {
          results.push(result);
        }
      }

      return results;
    } catch (error) {
      console.error('解析AI响应失败:', error);
      return [];
    }
  }

  /**
   * 使用AI生成创新菜谱
   * @param ingredients 识别出的食材列表
   * @returns 创新菜谱，失败返回null
   */
  async generateCreativeRecipe(ingredients: string[]): Promise<CreativeRecipe | null> {
    if (!ingredients || ingredients.length === 0) {
      console.error('食材列表为空，无法生成菜谱');
      return null;
    }

    const url: string = Constants.MIMO_API_BASE + '/chat/completions';
    const ingredientStr: string = ingredients.join('、');

    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: '你是一位创意厨师，擅长用常见食材创造新颖美味的菜品。请根据用户提供的食材，设计一道有创意的菜品。只返回JSON格式结果，不要其他文字。'
      },
      {
        role: 'user',
        content: `我有这些食材：${ingredientStr}。请帮我设计一道创新菜谱，返回以下JSON格式：
{
  "name": "创意菜名",
  "description": "一句话简介这道菜的创意点",
  "ingredients": ["食材1 用量", "食材2 用量", ...],
  "steps": ["步骤1", "步骤2", ...],
  "difficulty": "简单/中等/困难",
  "duration": "预计烹饪时间",
  "creativeTip": "这道菜的创意亮点说明"
}
要求：
1. 菜名要有创意，能吸引人
2. 食材用量要具体
3. 步骤要详细可操作，5-8步
4. 充分利用提供的食材
5. 只返回JSON，不要其他文字`
      }
    ];

    const requestBody: ChatRequest = {
      model: Constants.MIMO_TEXT_MODEL,
      messages: messages,
      max_completion_tokens: 2048,
      temperature: 0.7
    };

    try {
      const httpRequest: http.HttpRequest = http.createHttp();

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + Constants.MIMO_API_KEY
        },
        extraData: JSON.stringify(requestBody),
        readTimeout: 60000,
        connectTimeout: 15000
      };

      const response: http.HttpResponse = await httpRequest.request(url, options);
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        return this.parseCreativeRecipeResponse(resultStr);
      }

      console.error('AI生成菜谱请求失败, statusCode:', response.responseCode);
      return null;
    } catch (error) {
      console.error('AI生成菜谱请求异常:', error);
      return null;
    }
  }

  /**
   * 解析AI生成的创新菜谱响应
   */
  private parseCreativeRecipeResponse(responseStr: string): CreativeRecipe | null {
    try {
      const chatResponse: ChatResponse = JSON.parse(responseStr) as ChatResponse;
      const choices: Choice[] = chatResponse.choices;

      if (!choices || choices.length === 0) {
        return null;
      }

      const content: string = choices[0].message.content;

      // 从AI回复中提取JSON（可能包含```json```包裹）
      let jsonStr: string = content.trim();
      const jsonStart: number = jsonStr.indexOf('{');
      const jsonEnd: number = jsonStr.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      const parsed: CreativeRecipeRaw = JSON.parse(jsonStr) as CreativeRecipeRaw;
      const recipe: CreativeRecipe = new CreativeRecipe();

      recipe.name = parsed.name || '创意菜';
      recipe.description = parsed.description || '';
      recipe.difficulty = parsed.difficulty || '中等';
      recipe.duration = parsed.duration || '30分钟';
      recipe.creativeTip = parsed.creativeTip || '';

      // 解析食材数组
      if (parsed.ingredients && Array.isArray(parsed.ingredients)) {
        recipe.ingredients = parsed.ingredients;
      }

      // 解析步骤数组
      if (parsed.steps && Array.isArray(parsed.steps)) {
        recipe.steps = parsed.steps;
      }

      if (!recipe.name || recipe.steps.length === 0) {
        console.error('AI返回的菜谱数据不完整');
        return null;
      }

      return recipe;
    } catch (error) {
      console.error('解析AI菜谱响应失败:', error);
      return null;
    }
  }
}
