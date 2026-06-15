import { Recipe, Ingredient } from '../model/Recipe';
import { UserPreference } from '../model/UserPreference';
import { DatabaseService } from './DatabaseService';

/**
 * 推荐结果
 */
export class RecommendResult {
  recipe: Recipe = new Recipe();
  matchScore: number = 0;
  matchedIngredients: string[] = [];
  missingIngredients: string[] = [];
}

/**
 * 营养计算结果
 */
export class NutritionResult {
  totalCalories: number = 0;
  totalProtein: number = 0;
  totalCarbs: number = 0;
  totalFat: number = 0;
  proteinRatio: number = 0;
  carbsRatio: number = 0;
  fatRatio: number = 0;
}

/**
 * 评分菜谱
 */
class ScoredRecipe {
  recipe: Recipe = new Recipe();
  score: number = 0;
}

/**
 * 推荐算法服务
 */
export class RecommendService {
  private static instance: RecommendService;
  private dbService: DatabaseService;

  private constructor() {
    this.dbService = DatabaseService.getInstance();
  }

  static getInstance(): RecommendService {
    if (!RecommendService.instance) {
      RecommendService.instance = new RecommendService();
    }
    return RecommendService.instance;
  }

  /**
   * 算法1：食材匹配推荐算法
   */
  async recommendByIngredients(selectedIngredients: string[]): Promise<RecommendResult[]> {
    const allRecipes: Recipe[] = await this.dbService.getAllRecipes();
    const results: RecommendResult[] = [];

    for (let r = 0; r < allRecipes.length; r++) {
      const recipe: Recipe = allRecipes[r];
      const fullRecipe: Recipe | null = await this.dbService.getRecipeById(recipe.id);
      if (!fullRecipe || fullRecipe.ingredients.length === 0) {
        continue;
      }

      const recipeIngredientNames: string[] = [];
      for (let i = 0; i < fullRecipe.ingredients.length; i++) {
        recipeIngredientNames.push(fullRecipe.ingredients[i].name);
      }

      const matchedIngredients: string[] = [];
      const missingIngredients: string[] = [];
      for (let i = 0; i < recipeIngredientNames.length; i++) {
        const name: string = recipeIngredientNames[i];
        let found: boolean = false;
        for (let j = 0; j < selectedIngredients.length; j++) {
          if (name.includes(selectedIngredients[j]) || selectedIngredients[j].includes(name)) {
            found = true;
            break;
          }
        }
        if (found) {
          matchedIngredients.push(name);
        } else {
          missingIngredients.push(name);
        }
      }

      const coverage: number = matchedIngredients.length / recipeIngredientNames.length;
      const popularity: number = Math.min(recipe.viewCount / 1000, 1);
      const ratingScore: number = recipe.rating / 5;
      const matchScore: number = coverage * 0.7 + popularity * 0.2 + ratingScore * 0.1;

      if (coverage > 0) {
        const result: RecommendResult = new RecommendResult();
        result.recipe = fullRecipe;
        result.matchScore = matchScore;
        result.matchedIngredients = matchedIngredients;
        result.missingIngredients = missingIngredients;
        results.push(result);
      }
    }

    results.sort((a: RecommendResult, b: RecommendResult) => b.matchScore - a.matchScore);
    return results;
  }

  /**
   * 算法2：营养成分计算算法
   */
  calculateNutrition(ingredients: Ingredient[]): NutritionResult {
    let totalCalories: number = 0;
    let totalProtein: number = 0;
    let totalCarbs: number = 0;
    let totalFat: number = 0;

    for (let i = 0; i < ingredients.length; i++) {
      const ingredient: Ingredient = ingredients[i];
      const amountGrams: number = this.parseAmount(ingredient.amount);
      const ratio: number = amountGrams / 100;

      totalCalories += ingredient.calories * ratio;
      totalProtein += ingredient.protein * ratio;
      totalCarbs += ingredient.carbs * ratio;
      totalFat += ingredient.fat * ratio;
    }

    const totalMacro: number = totalProtein + totalCarbs + totalFat;
    const proteinRatio: number = totalMacro > 0 ? totalProtein / totalMacro : 0;
    const carbsRatio: number = totalMacro > 0 ? totalCarbs / totalMacro : 0;
    const fatRatio: number = totalMacro > 0 ? totalFat / totalMacro : 0;

    const result: NutritionResult = new NutritionResult();
    result.totalCalories = Math.round(totalCalories);
    result.totalProtein = Math.round(totalProtein * 10) / 10;
    result.totalCarbs = Math.round(totalCarbs * 10) / 10;
    result.totalFat = Math.round(totalFat * 10) / 10;
    result.proteinRatio = Math.round(proteinRatio * 100);
    result.carbsRatio = Math.round(carbsRatio * 100);
    result.fatRatio = Math.round(fatRatio * 100);
    return result;
  }

  /**
   * 解析食材用量字符串
   */
  private parseAmount(amount: string): number {
    if (!amount || amount === '适量') return 50;

    const match: RegExpMatchArray | null = amount.match(/(\d+(\.\d+)?)/);
    if (match) {
      return parseFloat(match[1]);
    }
    return 50;
  }

  /**
   * 算法3：用户偏好协同过滤推荐
   */
  async recommendByPreference(
    userPreference: UserPreference,
    limit: number = 10
  ): Promise<Recipe[]> {
    const allRecipes: Recipe[] = await this.dbService.getAllRecipes();
    const scoredRecipes: ScoredRecipe[] = [];

    for (let r = 0; r < allRecipes.length; r++) {
      const recipe: Recipe = allRecipes[r];
      let score: number = 0;

      if (userPreference.favoriteCuisines.includes(recipe.cuisine)) {
        score += 0.3;
      }

      const recipeTags: string[] = recipe.tags;
      let tasteMatch: number = 0;
      for (let t = 0; t < recipeTags.length; t++) {
        if (userPreference.favoriteTastes.includes(recipeTags[t])) {
          tasteMatch++;
        }
      }
      score += (tasteMatch / Math.max(recipeTags.length, 1)) * 0.2;

      score += (recipe.rating / 5) * 0.3;

      const popularity: number = Math.min(recipe.viewCount / 1000, 1);
      score += popularity * 0.2;

      const scored: ScoredRecipe = new ScoredRecipe();
      scored.recipe = recipe;
      scored.score = score;
      scoredRecipes.push(scored);
    }

    scoredRecipes.sort((a: ScoredRecipe, b: ScoredRecipe) => b.score - a.score);

    const resultRecipes: Recipe[] = [];
    const endIdx: number = Math.min(limit, scoredRecipes.length);
    for (let i = 0; i < endIdx; i++) {
      resultRecipes.push(scoredRecipes[i].recipe);
    }
    return resultRecipes;
  }

  /**
   * 获取热门菜谱
   */
  async getHotRecipes(limit: number = 10): Promise<Recipe[]> {
    const allRecipes: Recipe[] = await this.dbService.getAllRecipes();

    allRecipes.sort((a: Recipe, b: Recipe) => {
      const scoreA: number = a.favoriteCount * 3 + a.viewCount;
      const scoreB: number = b.favoriteCount * 3 + b.viewCount;
      return scoreB - scoreA;
    });

    return allRecipes.slice(0, limit);
  }

  /**
   * 获取每日推荐
   */
  async getDailyRecommendation(limit: number = 6): Promise<Recipe[]> {
    const allRecipes: Recipe[] = await this.dbService.getAllRecipes();

    const goodRecipes: Recipe[] = allRecipes.filter((r: Recipe) => r.rating >= 4.0);

    // 随机打乱
    const shuffled: Recipe[] = goodRecipes.sort(() => Math.random() - 0.5);

    return shuffled.slice(0, limit);
  }
}
