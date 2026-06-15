/**
 * 菜谱数据模型
 * 定义菜谱的核心数据结构
 */
export class Recipe {
  id: number = 0;
  name: string = '';                    // 菜谱名称
  coverImage: string = '';              // 封面图片路径
  category: string = '';                // 分类（家常菜/早餐/甜品等）
  cuisine: string = '';                 // 菜系（川菜/粤菜/湘菜等）
  difficulty: string = '';              // 难度：简单/中等/困难
  duration: number = 0;                 // 烹饪时长（分钟）
  servings: number = 0;                 // 份量（人份）
  calories: number = 0;                 // 总热量（千卡）
  description: string = '';             // 简介
  ingredients: Ingredient[] = [];       // 食材列表
  steps: CookingStep[] = [];            // 烹饪步骤
  tags: string[] = [];                  // 标签
  rating: number = 0;                   // 评分（1-5）
  viewCount: number = 0;                // 浏览次数
  favoriteCount: number = 0;            // 收藏次数
  isFavorite: boolean = false;          // 是否已收藏
  videoUrl: string = '';                // 视频教程URL
  author: string = '';                  // 作者
  createTime: string = '';              // 创建时间
}

/**
 * 食材模型
 */
export class Ingredient {
  id: number = 0;
  name: string = '';                    // 食材名称
  category: string = '';                // 分类：蔬菜/肉类/海鲜/蛋奶/调料
  amount: string = '';                  // 用量（如：200g）
  calories: number = 0;                 // 每100g热量
  protein: number = 0;                  // 每100g蛋白质(g)
  carbs: number = 0;                    // 每100g碳水化合物(g)
  fat: number = 0;                      // 每100g脂肪(g)
  image: string = '';                   // 食材图片
}

/**
 * 烹饪步骤模型
 */
export class CookingStep {
  stepNumber: number = 0;               // 步骤序号
  description: string = '';             // 步骤描述
  image: string = '';                   // 步骤图片
  duration: number = 0;                 // 该步骤所需时间（秒）
  tip: string = '';                     // 小贴士
  needTimer: boolean = false;           // 是否需要计时
}

/**
 * 营养成分模型
 */
export class NutritionInfo {
  calories: number = 0;                 // 总热量（千卡）
  protein: number = 0;                  // 蛋白质(g)
  carbs: number = 0;                    // 碳水化合物(g)
  fat: number = 0;                      // 脂肪(g)
  fiber: number = 0;                    // 膳食纤维(g)
}
