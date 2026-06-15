/**
 * 营养数据条目
 */
class NutritionEntry {
  calories: number = 0;
  protein: number = 0;
  carbs: number = 0;
  fat: number = 0;

  constructor(cal: number, pro: number, carb: number, f: number) {
    this.calories = cal;
    this.protein = pro;
    this.carbs = carb;
    this.fat = f;
  }
}

/**
 * 营养输入接口（用于批量填充）
 */
class NutritionFillTarget {
  name: string = '';
  calories: number = 0;
  protein: number = 0;
  carbs: number = 0;
  fat: number = 0;
}

/**
 * 常见食材营养数据库
 * 每100g的营养成分：热量(kcal)、蛋白质(g)、碳水(g)、脂肪(g)
 */
export class IngredientNutritionDB {
  private static nutritionMap: Map<string, NutritionEntry> = IngredientNutritionDB.initMap();

  private static initMap(): Map<string, NutritionEntry> {
    const m: Map<string, NutritionEntry> = new Map();

    // ========== 肉类 ==========
    m.set('猪肉', new NutritionEntry(242, 13.2, 2.4, 20.6));
    m.set('五花肉', new NutritionEntry(395, 14.0, 2.4, 37.0));
    m.set('瘦肉', new NutritionEntry(143, 20.3, 1.5, 6.2));
    m.set('肉末', new NutritionEntry(295, 17.0, 1.0, 25.0));
    m.set('猪肉末', new NutritionEntry(295, 17.0, 1.0, 25.0));
    m.set('牛肉', new NutritionEntry(125, 19.9, 2.0, 4.2));
    m.set('牛腩', new NutritionEntry(330, 17.1, 0, 29.5));
    m.set('羊肉', new NutritionEntry(203, 19.0, 3.9, 14.1));
    m.set('鸡胸肉', new NutritionEntry(133, 31.0, 0.5, 1.2));
    m.set('鸡肉', new NutritionEntry(167, 19.3, 2.5, 9.4));
    m.set('鸡翅', new NutritionEntry(222, 17.4, 4.6, 16.4));
    m.set('鸡腿', new NutritionEntry(181, 16.0, 0, 13.0));
    m.set('鸭肉', new NutritionEntry(240, 15.5, 0.2, 19.7));
    m.set('排骨', new NutritionEntry(264, 18.1, 1.0, 20.4));
    m.set('腊肉', new NutritionEntry(498, 11.8, 2.6, 48.8));
    m.set('火腿', new NutritionEntry(212, 16.0, 4.9, 14.4));
    m.set('培根', new NutritionEntry(533, 12.0, 1.5, 54.0));
    m.set('午餐肉', new NutritionEntry(247, 12.5, 5.0, 20.0));
    m.set('香肠', new NutritionEntry(508, 24.1, 1.1, 45.3));

    // ========== 海鲜 ==========
    m.set('鲈鱼', new NutritionEntry(105, 18.6, 0, 3.4));
    m.set('鲫鱼', new NutritionEntry(91, 17.1, 3.8, 1.3));
    m.set('草鱼', new NutritionEntry(113, 16.6, 0, 5.2));
    m.set('带鱼', new NutritionEntry(127, 17.7, 3.1, 4.9));
    m.set('三文鱼', new NutritionEntry(139, 17.2, 0, 7.8));
    m.set('虾', new NutritionEntry(87, 16.8, 1.5, 2.2));
    m.set('虾仁', new NutritionEntry(48, 10.4, 0, 0.7));
    m.set('大虾', new NutritionEntry(90, 18.6, 0, 0.8));
    m.set('螃蟹', new NutritionEntry(95, 13.8, 4.7, 2.3));
    m.set('鱿鱼', new NutritionEntry(75, 17.0, 1.6, 0.8));
    m.set('蛤蜊', new NutritionEntry(62, 10.1, 4.5, 1.1));
    m.set('扇贝', new NutritionEntry(69, 12.6, 3.2, 0.5));
    m.set('海参', new NutritionEntry(55, 16.5, 0.5, 0.2));
    m.set('鲍鱼', new NutritionEntry(84, 17.0, 6.0, 0.8));

    // ========== 蛋奶 ==========
    m.set('鸡蛋', new NutritionEntry(144, 13.3, 1.5, 8.8));
    m.set('蛋清', new NutritionEntry(47, 11.6, 0.8, 0.1));
    m.set('蛋黄', new NutritionEntry(322, 15.2, 3.4, 28.2));
    m.set('鸭蛋', new NutritionEntry(180, 12.6, 3.1, 13.0));
    m.set('牛奶', new NutritionEntry(54, 3.0, 3.4, 3.2));
    m.set('酸奶', new NutritionEntry(72, 2.5, 9.3, 2.7));
    m.set('奶酪', new NutritionEntry(328, 25.7, 3.5, 23.5));
    m.set('黄油', new NutritionEntry(735, 0.5, 0.1, 81.0));
    m.set('奶油', new NutritionEntry(345, 2.0, 3.6, 35.0));

    // ========== 蔬菜 ==========
    m.set('番茄', new NutritionEntry(18, 0.9, 3.9, 0.2));
    m.set('西红柿', new NutritionEntry(18, 0.9, 3.9, 0.2));
    m.set('土豆', new NutritionEntry(76, 2.0, 17.5, 0.1));
    m.set('黄瓜', new NutritionEntry(15, 0.7, 2.9, 0.2));
    m.set('茄子', new NutritionEntry(21, 1.1, 4.9, 0.1));
    m.set('白菜', new NutritionEntry(13, 1.0, 2.2, 0.1));
    m.set('青菜', new NutritionEntry(15, 1.5, 2.4, 0.3));
    m.set('菠菜', new NutritionEntry(24, 2.6, 4.5, 0.3));
    m.set('韭菜', new NutritionEntry(26, 2.4, 4.6, 0.4));
    m.set('芹菜', new NutritionEntry(14, 0.8, 3.0, 0.1));
    m.set('花菜', new NutritionEntry(24, 2.1, 4.6, 0.2));
    m.set('菜花', new NutritionEntry(24, 2.1, 4.6, 0.2));
    m.set('西兰花', new NutritionEntry(36, 4.1, 4.3, 0.6));
    m.set('胡萝卜', new NutritionEntry(37, 1.0, 8.8, 0.2));
    m.set('萝卜', new NutritionEntry(21, 0.9, 5.0, 0.1));
    m.set('洋葱', new NutritionEntry(39, 1.1, 9.0, 0.1));
    m.set('青椒', new NutritionEntry(20, 0.9, 4.6, 0.2));
    m.set('红椒', new NutritionEntry(31, 1.0, 6.0, 0.3));
    m.set('辣椒', new NutritionEntry(29, 1.3, 5.7, 0.4));
    m.set('干辣椒', new NutritionEntry(281, 12.0, 50.0, 12.0));
    m.set('大蒜', new NutritionEntry(126, 4.5, 27.6, 0.2));
    m.set('蒜', new NutritionEntry(126, 4.5, 27.6, 0.2));
    m.set('姜', new NutritionEntry(41, 1.3, 8.0, 0.7));
    m.set('葱', new NutritionEntry(30, 1.6, 6.5, 0.3));
    m.set('蘑菇', new NutritionEntry(20, 2.7, 3.3, 0.4));
    m.set('香菇', new NutritionEntry(211, 20.0, 30.1, 3.3));
    m.set('金针菇', new NutritionEntry(32, 2.4, 6.0, 0.4));
    m.set('木耳', new NutritionEntry(205, 12.1, 35.7, 1.5));
    m.set('豆芽', new NutritionEntry(31, 3.0, 5.2, 0.1));
    m.set('豆腐', new NutritionEntry(73, 8.1, 4.2, 3.5));
    m.set('嫩豆腐', new NutritionEntry(55, 5.0, 2.8, 2.5));
    m.set('豆皮', new NutritionEntry(409, 44.6, 12.5, 17.4));
    m.set('腐竹', new NutritionEntry(459, 44.6, 12.5, 21.7));
    m.set('毛豆', new NutritionEntry(131, 13.0, 8.5, 5.0));
    m.set('玉米', new NutritionEntry(106, 4.0, 22.8, 1.2));
    m.set('玉米粒', new NutritionEntry(106, 4.0, 22.8, 1.2));
    m.set('南瓜', new NutritionEntry(22, 0.7, 5.3, 0.1));
    m.set('冬瓜', new NutritionEntry(11, 0.3, 2.4, 0.2));
    m.set('苦瓜', new NutritionEntry(19, 1.0, 4.1, 0.1));
    m.set('丝瓜', new NutritionEntry(20, 1.0, 4.2, 0.2));
    m.set('莴笋', new NutritionEntry(14, 1.0, 2.8, 0.1));
    m.set('竹笋', new NutritionEntry(19, 2.6, 3.1, 0.2));
    m.set('芦笋', new NutritionEntry(20, 2.2, 3.9, 0.1));
    m.set('山药', new NutritionEntry(56, 1.9, 12.4, 0.1));
    m.set('芋头', new NutritionEntry(79, 2.2, 17.1, 0.2));
    m.set('莲藕', new NutritionEntry(70, 1.9, 15.2, 0.2));

    // ========== 水果 ==========
    m.set('苹果', new NutritionEntry(52, 0.3, 13.8, 0.2));
    m.set('香蕉', new NutritionEntry(89, 1.1, 22.8, 0.3));
    m.set('柠檬', new NutritionEntry(29, 1.1, 9.3, 0.3));
    m.set('红枣', new NutritionEntry(264, 3.2, 67.8, 0.5));
    m.set('枸杞', new NutritionEntry(258, 13.9, 47.2, 1.5));

    // ========== 主食 ==========
    m.set('米饭', new NutritionEntry(116, 2.6, 25.9, 0.3));
    m.set('面条', new NutritionEntry(286, 8.3, 61.9, 0.7));
    m.set('面粉', new NutritionEntry(344, 11.2, 73.6, 1.5));
    m.set('馒头', new NutritionEntry(223, 7.0, 44.2, 1.1));
    m.set('面包', new NutritionEntry(312, 8.3, 58.1, 5.1));
    m.set('年糕', new NutritionEntry(154, 3.3, 34.7, 0.2));
    m.set('粉丝', new NutritionEntry(338, 0.8, 82.6, 0.1));
    m.set('粉条', new NutritionEntry(338, 0.8, 82.6, 0.1));
    m.set('大米', new NutritionEntry(346, 7.4, 77.9, 0.8));
    m.set('糯米', new NutritionEntry(348, 7.3, 78.3, 1.0));

    // ========== 调料 ==========
    m.set('盐', new NutritionEntry(0, 0, 0, 0));
    m.set('糖', new NutritionEntry(387, 0, 99.9, 0));
    m.set('白糖', new NutritionEntry(387, 0, 99.9, 0));
    m.set('冰糖', new NutritionEntry(387, 0, 99.9, 0));
    m.set('酱油', new NutritionEntry(53, 5.6, 7.9, 0.1));
    m.set('生抽', new NutritionEntry(53, 5.6, 7.9, 0.1));
    m.set('老抽', new NutritionEntry(53, 5.6, 7.9, 0.1));
    m.set('醋', new NutritionEntry(31, 2.1, 4.9, 0.1));
    m.set('料酒', new NutritionEntry(67, 1.6, 5.0, 0));
    m.set('蚝油', new NutritionEntry(110, 3.5, 20.0, 1.5));
    m.set('豆瓣酱', new NutritionEntry(178, 7.3, 20.1, 7.8));
    m.set('番茄酱', new NutritionEntry(82, 1.6, 16.7, 0.2));
    m.set('芝麻酱', new NutritionEntry(618, 17.0, 16.0, 52.7));
    m.set('花生酱', new NutritionEntry(600, 25.0, 20.0, 50.0));
    m.set('味精', new NutritionEntry(268, 40.0, 33.0, 0));
    m.set('鸡精', new NutritionEntry(195, 15.0, 25.0, 3.0));
    m.set('胡椒粉', new NutritionEntry(345, 9.6, 64.8, 3.3));
    m.set('花椒', new NutritionEntry(258, 6.7, 37.8, 8.9));
    m.set('八角', new NutritionEntry(255, 3.8, 50.0, 5.6));
    m.set('桂皮', new NutritionEntry(253, 3.8, 48.5, 3.2));
    m.set('孜然', new NutritionEntry(375, 17.8, 44.2, 22.0));
    m.set('辣椒粉', new NutritionEntry(281, 12.0, 50.0, 12.0));
    m.set('咖喱', new NutritionEntry(325, 13.0, 58.0, 14.0));
    m.set('咖喱块', new NutritionEntry(480, 5.0, 30.0, 38.0));

    // ========== 坚果 ==========
    m.set('花生', new NutritionEntry(567, 25.8, 16.1, 49.2));
    m.set('花生米', new NutritionEntry(567, 25.8, 16.1, 49.2));
    m.set('核桃', new NutritionEntry(654, 14.9, 13.7, 58.8));
    m.set('芝麻', new NutritionEntry(559, 18.4, 21.7, 48.0));

    // ========== 油脂 ==========
    m.set('食用油', new NutritionEntry(884, 0, 0, 100));
    m.set('花生油', new NutritionEntry(884, 0, 0, 100));
    m.set('菜籽油', new NutritionEntry(884, 0, 0, 100));
    m.set('橄榄油', new NutritionEntry(884, 0, 0, 100));
    m.set('香油', new NutritionEntry(884, 0, 0, 100));

    // ========== 淀粉 ==========
    m.set('淀粉', new NutritionEntry(350, 0.5, 85.0, 0.1));
    m.set('玉米淀粉', new NutritionEntry(350, 0.5, 85.0, 0.1));

    // ========== 饮品 ==========
    m.set('可乐', new NutritionEntry(42, 0, 10.6, 0));
    m.set('蜂蜜', new NutritionEntry(321, 0.3, 82.3, 0));

    return m;
  }

  /**
   * 根据食材名称查找营养数据
   * @returns [calories, protein, carbs, fat] per 100g，未找到返回 null
   */
  static lookup(ingredientName: string): number[] | null {
    // 精确匹配
    const exact: NutritionEntry | undefined = IngredientNutritionDB.nutritionMap.get(ingredientName);
    if (exact) {
      return [exact.calories, exact.protein, exact.carbs, exact.fat];
    }

    // 模糊匹配
    let result: number[] | null = null;
    IngredientNutritionDB.nutritionMap.forEach((entry: NutritionEntry, key: string) => {
      if (result !== null) {
        return;
      }
      if (ingredientName.includes(key) || key.includes(ingredientName)) {
        result = [entry.calories, entry.protein, entry.carbs, entry.fat];
      }
    });

    return result;
  }

  /**
   * 批量填充食材营养数据
   */
  static fillNutrition(ingredients: NutritionFillTarget[]): void {
    for (let i = 0; i < ingredients.length; i++) {
      const ing: NutritionFillTarget = ingredients[i];
      if (ing.calories > 0) {
        continue; // 已有数据，跳过
      }

      const nutrition: number[] | null = IngredientNutritionDB.lookup(ing.name);
      if (nutrition) {
        ing.calories = nutrition[0];
        ing.protein = nutrition[1];
        ing.carbs = nutrition[2];
        ing.fat = nutrition[3];
      }
    }
  }
}
