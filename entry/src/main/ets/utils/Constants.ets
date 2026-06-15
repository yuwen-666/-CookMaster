/**
 * 常量类型定义
 */
export class CategoryItem {
  name: string = '';
  icon: string = '';
}

export class DifficultyItem {
  name: string = '';
  color: string = '';
  icon: string = '';
}

export class CookingSceneItem {
  name: string = '';
  icon: string = '';
  time: string = '';
}

export class GradientConfig {
  primary: string[] = [];
  warm: string[] = [];
  sunset: string[] = [];
  surface: string[] = [];
  header: string[] = [];
  card: string[] = [];
}

export class ShadowConfig {
  small: ShadowOptions = { radius: 0, color: '', offsetX: 0, offsetY: 0 };
  medium: ShadowOptions = { radius: 0, color: '', offsetX: 0, offsetY: 0 };
  large: ShadowOptions = { radius: 0, color: '', offsetX: 0, offsetY: 0 };
  colored: ShadowOptions = { radius: 0, color: '', offsetX: 0, offsetY: 0 };
}

export class ColorTheme {
  primary: string = '';
  primaryDark: string = '';
  primaryLight: string = '';
  secondary: string = '';
  background: string = '';
  surface: string = '';
  text: string = '';
  textSecondary: string = '';
  textLight: string = '';
  divider: string = '';
  error: string = '';
  success: string = '';
  warning: string = '';
  info: string = '';
  accent: string = '';
  accentLight: string = '';
  warmWhite: string = '';
  warmGray: string = '';
  overlay: string = '';
}

export class FontSizeConfig {
  tiny: number = 0;
  small: number = 0;
  normal: number = 0;
  medium: number = 0;
  large: number = 0;
  xlarge: number = 0;
  xxlarge: number = 0;
  title: number = 0;
  header: number = 0;
}

export class SpacingConfig {
  tiny: number = 0;
  small: number = 0;
  normal: number = 0;
  medium: number = 0;
  large: number = 0;
  xlarge: number = 0;
  xxlarge: number = 0;
}

export class BorderRadiusConfig {
  small: number = 0;
  normal: number = 0;
  medium: number = 0;
  large: number = 0;
  round: number = 0;
}

export class AnimationDurationConfig {
  fast: number = 0;
  normal: number = 0;
  slow: number = 0;
}

export class OpacityConfig {
  disabled: number = 0;
  pressed: number = 0;
  overlay: number = 0;
}

export class RouteConfig {
  INDEX: string = '';
  CATEGORY: string = '';
  RECIPE_DETAIL: string = '';
  INGREDIENT: string = '';
  CAMERA: string = '';
  COMMUNITY: string = '';
  PUBLISH_RECIPE: string = '';
  FAVORITE: string = '';
  PROFILE: string = '';
  LOGIN: string = '';
  REGISTER: string = '';
  CREATIVE_RECIPES: string = '';
}

export class NetworkConfig {
  TIMEOUT: number = 0;
  BASE_URL: string = '';
}

export class DBConfig {
  NAME: string = '';
  VERSION: number = 0;
}

/**
 * 应用常量定义
 */
export class Constants {
  // 应用信息
  static readonly APP_NAME: string = '智能菜谱推荐助手';
  static readonly APP_VERSION: string = '1.0.0';

  // 颜色主题
  static readonly COLORS: ColorTheme = {
    primary: '#FF6B35',
    primaryDark: '#E55A2B',
    primaryLight: '#FF8A5C',
    secondary: '#4CAF50',
    background: '#FAF8F5',
    surface: '#FFFFFF',
    text: '#2D2A26',
    textSecondary: '#6B6560',
    textLight: '#A89F96',
    divider: '#F0EBE5',
    error: '#E8453C',
    success: '#3DAA5D',
    warning: '#F59E0B',
    info: '#3B82F6',
    accent: '#FF8C42',
    accentLight: '#FFF0E6',
    warmWhite: '#FFFDF9',
    warmGray: '#F5F0EA',
    overlay: '#1A000000'
  };

  // 渐变色配置
  static readonly GRADIENTS: GradientConfig = {
    primary: ['#FF6B35', '#FF8A5C'],
    warm: ['#FF8C42', '#FFB347'],
    sunset: ['#FF6B35', '#FF4E50', '#FC913A'],
    surface: ['#FFFFFF', '#FAF8F5'],
    header: ['#FF6B35', '#FF8A5C'],
    card: ['#FFFDF9', '#FFF5EC']
  };

  // 阴影配置
  static readonly SHADOWS: ShadowConfig = {
    small: { radius: 6, color: '#0D000000', offsetX: 0, offsetY: 2 },
    medium: { radius: 12, color: '#14000000', offsetX: 0, offsetY: 4 },
    large: { radius: 20, color: '#1A000000', offsetX: 0, offsetY: 8 },
    colored: { radius: 16, color: '#33FF6B35', offsetX: 0, offsetY: 6 }
  };

  // 字体大小
  static readonly FONT_SIZE: FontSizeConfig = {
    tiny: 10,
    small: 12,
    normal: 14,
    medium: 16,
    large: 18,
    xlarge: 20,
    xxlarge: 24,
    title: 28,
    header: 32
  };

  // 间距
  static readonly SPACING: SpacingConfig = {
    tiny: 4,
    small: 8,
    normal: 12,
    medium: 16,
    large: 20,
    xlarge: 24,
    xxlarge: 32
  };

  // 圆角
  static readonly BORDER_RADIUS: BorderRadiusConfig = {
    small: 6,
    normal: 10,
    medium: 14,
    large: 20,
    round: 999
  };

  // 动画时长（毫秒）
  static readonly ANIMATION_DURATION: AnimationDurationConfig = {
    fast: 150,
    normal: 250,
    slow: 400
  };

  // 透明度预设
  static readonly OPACITY: OpacityConfig = {
    disabled: 0.4,
    pressed: 0.7,
    overlay: 0.5
  };

  // 菜谱分类
  static readonly RECIPE_CATEGORIES: CategoryItem[] = [
    { name: '家常菜', icon: '🍳' },
    { name: '素菜', icon: '🥬' },
    { name: '荤菜', icon: '🥩' },
    { name: '汤羹', icon: '🍲' },
    { name: '主食', icon: '🍚' },
    { name: '甜品', icon: '🍰' },
    { name: '早餐', icon: '🥞' },
    { name: '小吃', icon: '🥟' },
    { name: '饮品', icon: '🥤' },
    { name: '海鲜', icon: '🦐' }
  ];

  // 菜系
  static readonly CUISINES: string[] = [
    '川菜', '粤菜', '湘菜', '鲁菜',
    '苏菜', '浙菜', '闽菜', '徽菜',
    '家常', '西餐', '日韩', '东南亚'
  ];

  // 难度等级
  static readonly DIFFICULTY_LEVELS: DifficultyItem[] = [
    { name: '简单', color: '#4CAF50', icon: '⭐' },
    { name: '中等', color: '#FF9800', icon: '⭐⭐' },
    { name: '困难', color: '#F44336', icon: '⭐⭐⭐' }
  ];

  // 食材分类
  static readonly INGREDIENT_CATEGORIES: CategoryItem[] = [
    { name: '蔬菜', icon: '🥬' },
    { name: '肉类', icon: '🥩' },
    { name: '海鲜', icon: '🦐' },
    { name: '蛋奶', icon: '🥚' },
    { name: '主食', icon: '🍚' },
    { name: '调料', icon: '🧂' }
  ];

  // 口味偏好
  static readonly TASTE_PREFERENCES: string[] = [
    '清淡', '微辣', '中辣', '重辣',
    '甜', '咸', '酸', '鲜', '香'
  ];

  // 烹饪场景
  static readonly COOKING_SCENES: CookingSceneItem[] = [
    { name: '早餐', icon: '🌅', time: '7:00-9:00' },
    { name: '午餐', icon: '☀️', time: '11:30-13:00' },
    { name: '晚餐', icon: '🌇', time: '17:30-19:00' },
    { name: '夜宵', icon: '🌙', time: '21:00-23:00' },
    { name: '便当', icon: '🍱', time: '随时' },
    { name: '下午茶', icon: '☕', time: '14:00-16:00' }
  ];

  // 路由路径
  static readonly ROUTES: RouteConfig = {
    INDEX: 'pages/IndexPage',
    CATEGORY: 'pages/CategoryPage',
    RECIPE_DETAIL: 'pages/RecipeDetailPage',
    INGREDIENT: 'pages/IngredientPage',
    CAMERA: 'pages/CameraPage',
    COMMUNITY: 'pages/CommunityPage',
    PUBLISH_RECIPE: 'pages/PublishRecipePage',
    FAVORITE: 'pages/FavoritePage',
    PROFILE: 'pages/ProfilePage',
    LOGIN: 'pages/LoginPage',
    REGISTER: 'pages/RegisterPage',
    CREATIVE_RECIPES: 'pages/CreativeRecipesPage'
  };

  // 网络请求
  static readonly NETWORK: NetworkConfig = {
    TIMEOUT: 10000,
    BASE_URL: 'https://api.example.com'
  };

  // 邮箱验证服务地址（本地开发用电脑IP，真机测试需同一WiFi）
  // TODO: 部署前替换为你的服务器地址
  static readonly EMAIL_API_URL: string = 'http://YOUR_SERVER_IP:3000';

  // 认证相关常量
  static readonly AUTH_PREFS_NAME: string = 'auth_prefs';
  static readonly AUTH_KEY_LOGGED_IN: string = 'is_logged_in';
  static readonly AUTH_KEY_EMAIL: string = 'user_email';
  static readonly AUTH_KEY_USER_ID: string = 'user_id';

  // 硅基流动 API 配置（OpenAI 兼容协议）
  // TODO: 替换为你的 API Key，从 https://cloud.siliconflow.cn 获取
  static readonly MIMO_API_BASE: string = 'https://api.siliconflow.cn/v1';
  static readonly MIMO_API_KEY: string = 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  // 视觉模型：用于食材识别（支持图片输入）
  static readonly MIMO_VISION_MODEL: string = 'Qwen/Qwen3-VL-32B-Instruct';
  // 文本模型：用于菜谱生成
  static readonly MIMO_TEXT_MODEL: string = 'deepseek-ai/DeepSeek-V4-Pro';

  // AI 食材识别提示词
  static readonly AI_FOOD_PROMPT: string = `你是一个专业的食材识别助手，仅识别图中真实存在、清晰可见的食材，严格遵守以下规则：
1. 优先识别图像中最明显、最清晰的食材，忽略背景、阴影、模糊的部分；
2. 不要猜测不存在的物体，图中没有的食材绝对不能输出；
3. 只要是食物都可以识别，包括蔬菜、水果、肉类、海鲜、蛋奶、主食、调料、零食等；
4. 每个结果必须附带简短的判断依据（比如"番茄：图中红色圆形带蒂的果实，特征明显"）；
5. 置信度低于80%的结果直接不输出，不要强行猜测；
6. 不限制识别数量，识别出所有可见的食物。

请按以下格式返回JSON：
{"ingredients":[{"name":"食材名称","confidence":85,"reason":"判断依据"}]}
只返回JSON，不要其他文字。`;
}
