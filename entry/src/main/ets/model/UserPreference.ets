/**
 * 用户偏好模型
 */
export class UserPreference {
  userId: string = '';
  favoriteCuisines: string[] = [];      // 偏好菜系
  favoriteTastes: string[] = [];        // 偏好口味（辣/甜/清淡等）
  favoriteIngredients: string[] = [];   // 偏好食材
  dislikedIngredients: string[] = [];   // 不喜欢的食材
  spiceLevel: number = 3;               // 辣度偏好（1-5）
  sweetnessLevel: number = 3;           // 甜度偏好（1-5）
}

/**
 * 社区评论模型
 */
export class Comment {
  id: number = 0;
  recipeId: number = 0;                 // 关联菜谱ID
  userId: string = '';                  // 用户ID
  userName: string = '';                // 用户名
  content: string = '';                 // 评论内容
  rating: number = 5;                   // 评分
  createTime: string = '';              // 评论时间
  likes: number = 0;                    // 点赞数
}

/**
 * 社区发布菜谱模型
 */
export class CommunityRecipe {
  id: number = 0;
  recipeId: number = 0;                 // 关联菜谱ID
  userId: string = '';                  // 发布者ID
  userName: string = '';                // 发布者名称
  title: string = '';                   // 标题
  content: string = '';                 // 详细内容
  images: string[] = [];                // 图片列表
  likes: number = 0;                    // 点赞数
  comments: number = 0;                 // 评论数
  createTime: string = '';              // 发布时间
  isLiked: boolean = false;             // 是否已点赞
}

/**
 * 烹饪记录模型
 */
export class CookingRecord {
  id: number = 0;
  recipeId: number = 0;                 // 菜谱ID
  recipeName: string = '';              // 菜谱名称
  cookTime: string = '';                // 烹饪时间
  duration: number = 0;                 // 实际用时（分钟）
  rating: number = 5;                   // 用户评分
  note: string = '';                    // 心得笔记
  image: string = '';                   // 成品照片
}
