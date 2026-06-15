/**
 * 营养评分结果
 */
class NutritionScoreResult {
  score: number = 0;
  level: string = '';
}

/**
 * 难度信息
 */
class DifficultyInfo {
  label: string = '';
  color: string = '';
  level: number = 0;
}

/**
 * 营养素
 */
class MacroNutrients {
  protein: number = 0;
  carbs: number = 0;
  fat: number = 0;
}

/**
 * 营养输入
 */
export class NutritionInput {
  calories: number = 0;
  protein: number = 0;
  carbs: number = 0;
  fat: number = 0;
}

/**
 * 营养计算器工具类
 */
export class NutritionCalculator {
  /**
   * 计算BMI指数
   */
  static calculateBMI(weight: number, height: number): number {
    const heightM: number = height / 100;
    return Math.round(weight / (heightM * heightM) * 10) / 10;
  }

  /**
   * 获取BMI等级
   */
  static getBMICategory(bmi: number): string {
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  /**
   * 计算每日推荐热量
   */
  static calculateDailyCalories(
    weight: number,
    height: number,
    age: number,
    gender: string,
    activityLevel: number = 3
  ): number {
    let bmr: number;
    if (gender === 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    const activityFactors: number[] = [0, 1.2, 1.375, 1.55, 1.725, 1.9];
    const factor: number = activityFactors[Math.min(activityLevel, 5)];

    return Math.round(bmr * factor);
  }

  /**
   * 计算三大营养素推荐摄入量
   */
  static calculateMacroNutrients(
    dailyCalories: number,
    goal: string = 'maintain'
  ): MacroNutrients {
    let proteinRatio: number;
    let carbsRatio: number;
    let fatRatio: number;

    switch (goal) {
      case 'lose':
        proteinRatio = 0.35;
        carbsRatio = 0.40;
        fatRatio = 0.25;
        break;
      case 'gain':
        proteinRatio = 0.30;
        carbsRatio = 0.50;
        fatRatio = 0.20;
        break;
      default:
        proteinRatio = 0.25;
        carbsRatio = 0.50;
        fatRatio = 0.25;
    }

    return {
      protein: Math.round((dailyCalories * proteinRatio) / 4),
      carbs: Math.round((dailyCalories * carbsRatio) / 4),
      fat: Math.round((dailyCalories * fatRatio) / 9)
    };
  }

  /**
   * 计算食物GI值等级
   */
  static getGILevel(giValue: number): string {
    if (giValue <= 55) return '低GI';
    if (giValue <= 70) return '中GI';
    return '高GI';
  }

  /**
   * 计算烹饪时间格式化
   */
  static formatCookingTime(minutes: number): string {
    if (minutes < 60) {
      return minutes + '分钟';
    }
    const hours: number = Math.floor(minutes / 60);
    const mins: number = minutes % 60;
    return mins > 0 ? hours + '小时' + mins + '分钟' : hours + '小时';
  }

  /**
   * 计算难度等级对应的标签
   */
  static getDifficultyInfo(difficulty: string): DifficultyInfo {
    switch (difficulty) {
      case '简单':
        return { label: '简单', color: '#4CAF50', level: 1 };
      case '中等':
        return { label: '中等', color: '#FF9800', level: 2 };
      case '困难':
        return { label: '困难', color: '#F44336', level: 3 };
      default:
        return { label: '未知', color: '#9E9E9E', level: 0 };
    }
  }

  /**
   * 计算营养评分
   */
  static calculateNutritionScore(nutrition: NutritionInput): NutritionScoreResult {
    let score: number = 100;

    if (nutrition.calories > 800) score -= 20;
    else if (nutrition.calories > 600) score -= 10;

    if (nutrition.protein > 30) score += 10;
    else if (nutrition.protein < 10) score -= 10;

    if (nutrition.fat > 40) score -= 15;
    else if (nutrition.fat > 30) score -= 5;

    if (nutrition.carbs > 100) score -= 10;

    const finalScore: number = Math.max(0, Math.min(100, score));

    let level: string;
    if (finalScore >= 80) level = '优秀';
    else if (finalScore >= 60) level = '良好';
    else level = '一般';

    return { score: finalScore, level: level };
  }
}
