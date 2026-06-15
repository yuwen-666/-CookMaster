import relationalStore from '@ohos.data.relationalStore';
import { Recipe, Ingredient, CookingStep } from '../model/Recipe';
import { Comment, CommunityRecipe, CookingRecord } from '../model/UserPreference';
import { User } from '../model/User';
import { IngredientNutritionDB } from '../utils/IngredientNutritionDB';

/**
 * 数据库服务
 * 负责所有本地数据的增删改查操作
 *
 * 修复点：
 * 1. getRdbStore 正确传入 StoreConfig
 * 2. 禁止 any，全部使用明确类型
 * 3. ResultSet 用 goToNextRow() 遍历，不能当数组
 * 4. 移除不存在的图片资源引用
 */
export class DatabaseService {
  private static instance: DatabaseService;
  private store: relationalStore.RdbStore | null = null;
  private readonly DB_NAME: string = 'cookmaster.db';
  private readonly DB_VERSION: number = 1;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  /**
   * 初始化数据库
   * 修复：getRdbStore 第二个参数必须是 StoreConfig，不是版本号
   */
  async initDatabase(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: this.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    // 正确写法：传入 context + StoreConfig
    this.store = await relationalStore.getRdbStore(context, config);
    await this.createTables();
    await this.insertDefaultData();

    // 自动导入菜谱数据（从 rawfile 读取）
    await this.autoImportRecipes(context);

    // 为没有封面图的菜谱分配默认图片
    await this.assignDefaultImages();
  }

  /**
   * 自动导入菜谱数据
   * 分批从 rawfile 读取，避免 OOM
   * 动态检测所有 recipes_batch_*.json 文件
   */
  private async autoImportRecipes(context: Context): Promise<void> {
    if (!this.store) {
      return;
    }

    // 检查是否已有大量菜谱数据（超过 100 条说明已导入过）
    const countSql: string = 'SELECT COUNT(*) AS cnt FROM recipes';
    const resultSet = await this.store.querySql(countSql);
    let count: number = 0;

    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
    }
    resultSet.close();

    if (count > 100) {
      console.info('菜谱数据已存在，跳过自动导入');
      return;
    }

    try {
      console.info('开始自动导入菜谱数据（分批处理）...');

      // 动态检测所有批次文件（从 1 开始递增，直到找不到文件）
      const batchFiles: string[] = [];
      let batchIndex: number = 1;

      while (true) {
        const filename: string = `recipes_batch_${batchIndex}.json`;
        try {
          // 尝试读取文件，如果不存在会抛出异常
          await context.resourceManager.getRawFileContent(filename);
          batchFiles.push(filename);
          batchIndex++;
        } catch (_e) {
          // 文件不存在，停止检测
          break;
        }
      }

      if (batchFiles.length === 0) {
        console.info('未找到菜谱批次文件');
        return;
      }

      console.info(`检测到 ${batchFiles.length} 个批次文件`);

      let totalImported: number = 0;

      // 逐个文件处理，每处理完一个文件释放内存
      for (let i = 0; i < batchFiles.length; i++) {
        const filename: string = batchFiles[i];
        console.info(`处理批次 ${i + 1}/${batchFiles.length}: ${filename}`);

        try {
          // 读取单个批次文件
          const fileData: Uint8Array = await context.resourceManager.getRawFileContent(filename);
          const jsonStr: string = this.bufferToString(fileData);

          // 导入当前批次
          const imported: number = await this.importRecipesFromJson(jsonStr);
          totalImported += imported;

          console.info(`  批次 ${i + 1} 完成: 导入 ${imported} 道菜谱`);

          // 释放内存（让 GC 回收）
          // jsonStr 和 fileData 会在作用域结束后自动释放
        } catch (batchError) {
          console.error(`  批次 ${i + 1} 失败:`, batchError);
          // 继续处理下一批次，不中断
        }
      }

      console.info(`自动导入完成: 共 ${totalImported} 道菜谱`);
    } catch (error) {
      console.error('自动导入菜谱数据失败:', error);
      // 不影响 App 正常启动，只记录错误
    }
  }

  /**
   * 分类默认图片（Unsplash 免费图片）
   */
  private static readonly DEFAULT_COVER_IMAGES: Record<string, string> = {
    '家常菜': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop',
    '素菜': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop',
    '荤菜': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
    '汤羹': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&h=300&fit=crop',
    '主食': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&h=300&fit=crop',
    '甜品': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400&h=300&fit=crop',
    '早餐': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&h=300&fit=crop',
    '小吃': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&h=300&fit=crop',
    '饮品': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop',
    '海鲜': 'https://images.unsplash.com/photo-1534766555764-ce878a4e947d?w=400&h=300&fit=crop',
    '凉菜': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop',
    '烘焙': 'https://images.unsplash.com/photo-1486427944544-d2c246c4df14?w=400&h=300&fit=crop'
  };

  /**
   * 为没有封面图的菜谱自动分配默认图片
   * 在数据导入完成后调用
   */
  async assignDefaultImages(): Promise<void> {
    if (!this.store) {
      return;
    }

    // 查找所有没有封面图的菜谱
    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT id, category, name FROM recipes WHERE coverImage = \'\' OR coverImage IS NULL'
    );

    const updates: RecipeUpdateItem[] = [];
    while (resultSet.goToNextRow()) {
      const item: RecipeUpdateItem = new RecipeUpdateItem();
      item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      item.category = resultSet.getString(resultSet.getColumnIndex('category'));
      item.name = resultSet.getString(resultSet.getColumnIndex('name'));
      updates.push(item);
    }
    resultSet.close();

    if (updates.length === 0) {
      return;
    }

    console.info(`为 ${updates.length} 道菜谱分配默认封面图...`);

    for (const item of updates) {
      // 根据分类获取默认图片
      const defaultUrl: string = DatabaseService.DEFAULT_COVER_IMAGES[item.category]
        || 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';

      await this.store.executeSql(
        'UPDATE recipes SET coverImage = ? WHERE id = ?',
        [defaultUrl, item.id]
      );
    }

    console.info('默认封面图分配完成');
  }

  /**
   * Uint8Array 转 UTF-8 字符串
   */
  private bufferToString(buffer: Uint8Array): string {
    let result: string = '';
    let i: number = 0;
    while (i < buffer.length) {
      const byte: number = buffer[i];
      if (byte < 0x80) {
        result += String.fromCharCode(byte);
        i++;
      } else if ((byte & 0xE0) === 0xC0) {
        const code: number = ((byte & 0x1F) << 6) | (buffer[i + 1] & 0x3F);
        result += String.fromCharCode(code);
        i += 2;
      } else if ((byte & 0xF0) === 0xE0) {
        const code: number = ((byte & 0x0F) << 12) | ((buffer[i + 1] & 0x3F) << 6) | (buffer[i + 2] & 0x3F);
        result += String.fromCharCode(code);
        i += 3;
      } else if ((byte & 0xF8) === 0xF0) {
        const code: number = ((byte & 0x07) << 18) | ((buffer[i + 1] & 0x3F) << 12) | ((buffer[i + 2] & 0x3F) << 6) | (buffer[i + 3] & 0x3F);
        result += String.fromCodePoint(code);
        i += 4;
      } else {
        result += String.fromCharCode(byte);
        i++;
      }
    }
    return result;
  }

  /**
   * 创建数据表
   */
  private async createTables(): Promise<void> {
    if (!this.store) {
      return;
    }

    // 菜谱表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS recipes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'name TEXT NOT NULL, ' +
      'coverImage TEXT, ' +
      'category TEXT, ' +
      'cuisine TEXT, ' +
      'difficulty TEXT, ' +
      'duration INTEGER, ' +
      'servings INTEGER, ' +
      'calories INTEGER, ' +
      'description TEXT, ' +
      'rating REAL DEFAULT 0, ' +
      'viewCount INTEGER DEFAULT 0, ' +
      'favoriteCount INTEGER DEFAULT 0, ' +
      'isFavorite INTEGER DEFAULT 0, ' +
      'videoUrl TEXT, ' +
      'author TEXT, ' +
      'createTime TEXT)'
    );

    // 食材表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS ingredients (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'name TEXT NOT NULL, ' +
      'category TEXT, ' +
      'amount TEXT, ' +
      'calories REAL DEFAULT 0, ' +
      'protein REAL DEFAULT 0, ' +
      'carbs REAL DEFAULT 0, ' +
      'fat REAL DEFAULT 0, ' +
      'image TEXT)'
    );

    // 烹饪步骤表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS cooking_steps (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'stepNumber INTEGER, ' +
      'description TEXT, ' +
      'image TEXT, ' +
      'duration INTEGER DEFAULT 0, ' +
      'tip TEXT, ' +
      'needTimer INTEGER DEFAULT 0)'
    );

    // 评论表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS comments (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'userId TEXT, ' +
      'userName TEXT, ' +
      'content TEXT, ' +
      'rating INTEGER DEFAULT 5, ' +
      'createTime TEXT, ' +
      'likes INTEGER DEFAULT 0)'
    );

    // 社区发布表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS community_recipes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'userId TEXT, ' +
      'userName TEXT, ' +
      'title TEXT, ' +
      'content TEXT, ' +
      'images TEXT, ' +
      'likes INTEGER DEFAULT 0, ' +
      'commentCount INTEGER DEFAULT 0, ' +
      'createTime TEXT, ' +
      'isLiked INTEGER DEFAULT 0)'
    );

    // 烹饪记录表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS cooking_records (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'recipeName TEXT, ' +
      'cookTime TEXT, ' +
      'duration INTEGER, ' +
      'rating INTEGER DEFAULT 5, ' +
      'note TEXT, ' +
      'image TEXT)'
    );

    // 浏览历史表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS browse_history (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'recipeId INTEGER, ' +
      'browseTime TEXT)'
    );

    // AI创新菜谱表
    await this.store.executeSql(
      'CREATE TABLE IF NOT EXISTS creative_recipes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'name TEXT NOT NULL, ' +
      'description TEXT, ' +
      'ingredients TEXT, ' +
      'steps TEXT, ' +
      'difficulty TEXT, ' +
      'duration TEXT, ' +
      'creativeTip TEXT, ' +
      'status TEXT DEFAULT \'saved\', ' +
      'createTime TEXT)'
    );

    // 用户表（先删除旧表重建，解决phone->email的字段变更）
    await this.store.executeSql('DROP TABLE IF EXISTS users');
    await this.store.executeSql(
      'CREATE TABLE users (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'email TEXT NOT NULL UNIQUE, ' +
      'password TEXT NOT NULL, ' +
      'nickname TEXT DEFAULT \'\', ' +
      'avatar TEXT DEFAULT \'\', ' +
      'createTime TEXT, ' +
      'lastLoginTime TEXT)'
    );
  }

  /**
   * 插入默认菜谱数据
   * 修复：移除不存在的图片资源引用，使用空字符串
   */
  private async insertDefaultData(): Promise<void> {
    if (!this.store) {
      return;
    }

    // 插入测试账号（无论是否有菜谱数据都执行）
    await this.insertDefaultUsers();

    // 检查是否已有菜谱数据
    const countSql: string = 'SELECT COUNT(*) AS cnt FROM recipes';
    const resultSet = await this.store.querySql(countSql);
    let count: number = 0;

    // 正确遍历 ResultSet：用 goToNextRow()
    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
    }
    resultSet.close();

    if (count > 0) {
      return; // 已有菜谱数据，跳过菜谱插入
    }

    // 插入示例菜谱（不引用图片资源，避免报错）
    const recipes: RecipeInsertData[] = [];

    // Unsplash 免费图片（按菜品匹配真实美食照片）
    const r1: RecipeInsertData = new RecipeInsertData();
    r1.name = '番茄炒蛋';
    r1.coverImage = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop';
    r1.category = '家常菜';
    r1.cuisine = '川菜';
    r1.difficulty = '简单';
    r1.duration = 15;
    r1.servings = 2;
    r1.calories = 180;
    r1.description = '经典家常菜，酸甜可口，营养丰富';
    r1.rating = 4.8;
    r1.author = '系统推荐';
    recipes.push(r1);

    const r2: RecipeInsertData = new RecipeInsertData();
    r2.name = '红烧肉';
    r2.coverImage = 'https://images.unsplash.com/photo-1623689043834-8db10f4dd41e?w=400&h=300&fit=crop';
    r2.category = '家常菜';
    r2.cuisine = '湘菜';
    r2.difficulty = '中等';
    r2.duration = 60;
    r2.servings = 4;
    r2.calories = 450;
    r2.description = '肥而不腻，入口即化的经典红烧肉';
    r2.rating = 4.9;
    r2.author = '系统推荐';
    recipes.push(r2);

    const r3: RecipeInsertData = new RecipeInsertData();
    r3.name = '清炒时蔬';
    r3.coverImage = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop';
    r3.category = '素菜';
    r3.cuisine = '粤菜';
    r3.difficulty = '简单';
    r3.duration = 10;
    r3.servings = 2;
    r3.calories = 80;
    r3.description = '清淡爽口，健康低脂';
    r3.rating = 4.5;
    r3.author = '系统推荐';
    recipes.push(r3);

    const r4: RecipeInsertData = new RecipeInsertData();
    r4.name = '宫保鸡丁';
    r4.coverImage = 'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=400&h=300&fit=crop';
    r4.category = '家常菜';
    r4.cuisine = '川菜';
    r4.difficulty = '中等';
    r4.duration = 25;
    r4.servings = 3;
    r4.calories = 280;
    r4.description = '香辣可口的经典川菜';
    r4.rating = 4.7;
    r4.author = '系统推荐';
    recipes.push(r4);

    const r5: RecipeInsertData = new RecipeInsertData();
    r5.name = '蛋炒饭';
    r5.coverImage = 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&h=300&fit=crop';
    r5.category = '主食';
    r5.cuisine = '家常';
    r5.difficulty = '简单';
    r5.duration = 15;
    r5.servings = 1;
    r5.calories = 350;
    r5.description = '粒粒分明，香气四溢的蛋炒饭';
    r5.rating = 4.6;
    r5.author = '系统推荐';
    recipes.push(r5);

    const r6: RecipeInsertData = new RecipeInsertData();
    r6.name = '酸辣土豆丝';
    r6.coverImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';
    r6.category = '素菜';
    r6.cuisine = '川菜';
    r6.difficulty = '简单';
    r6.duration = 15;
    r6.servings = 2;
    r6.calories = 120;
    r6.description = '开胃下饭的经典素菜';
    r6.rating = 4.4;
    r6.author = '系统推荐';
    recipes.push(r6);

    const r7: RecipeInsertData = new RecipeInsertData();
    r7.name = '可乐鸡翅';
    r7.coverImage = 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&h=300&fit=crop';
    r7.category = '家常菜';
    r7.cuisine = '家常';
    r7.difficulty = '简单';
    r7.duration = 30;
    r7.servings = 3;
    r7.calories = 320;
    r7.description = '甜香入味的可乐鸡翅，做法简单，大人小孩都喜欢';
    r7.rating = 4.7;
    r7.author = '系统推荐';
    recipes.push(r7);

    const r8: RecipeInsertData = new RecipeInsertData();
    r8.name = '清蒸鱼';
    r8.coverImage = 'https://images.unsplash.com/photo-1534766555764-ce878a4e947d?w=400&h=300&fit=crop';
    r8.category = '荤菜';
    r8.cuisine = '粤菜';
    r8.difficulty = '中等';
    r8.duration = 20;
    r8.servings = 3;
    r8.calories = 150;
    r8.description = '清淡鲜美的清蒸鱼，保留鱼的原汁原味';
    r8.rating = 4.8;
    r8.author = '系统推荐';
    recipes.push(r8);

    const r9: RecipeInsertData = new RecipeInsertData();
    r9.name = '麻婆豆腐';
    r9.coverImage = 'https://images.unsplash.com/photo-1582452919408-aca4cd4cff2e?w=400&h=300&fit=crop';
    r9.category = '家常菜';
    r9.cuisine = '川菜';
    r9.difficulty = '中等';
    r9.duration = 20;
    r9.servings = 2;
    r9.calories = 200;
    r9.description = '麻辣鲜香的麻婆豆腐，豆腐嫩滑，肉末香浓';
    r9.rating = 4.6;
    r9.author = '系统推荐';
    recipes.push(r9);

    const r10: RecipeInsertData = new RecipeInsertData();
    r10.name = '糖醋排骨';
    r10.coverImage = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop';
    r10.category = '荤菜';
    r10.cuisine = '浙菜';
    r10.difficulty = '中等';
    r10.duration = 40;
    r10.servings = 3;
    r10.calories = 380;
    r10.description = '酸甜可口的糖醋排骨，外酥里嫩，色泽诱人';
    r10.rating = 4.8;
    r10.author = '系统推荐';
    recipes.push(r10);

    for (let i = 0; i < recipes.length; i++) {
      const recipeId: number = await this.insertRecipe(recipes[i]);
      if (recipeId > 0) {
        await this.insertPresetIngredients(recipeId, recipes[i].name);
        await this.insertPresetSteps(recipeId, recipes[i].name);
      }
    }
  }

  /**
   * 插入默认测试账号
   */
  private async insertDefaultUsers(): Promise<void> {
    if (!this.store) {
      return;
    }

    // 检查是否已有用户数据
    const countSql: string = 'SELECT COUNT(*) AS cnt FROM users';
    const resultSet = await this.store.querySql(countSql);
    let count: number = 0;

    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
    }
    resultSet.close();

    if (count > 0) {
      return; // 已有用户，跳过
    }

    // 插入测试账号
    await this.insertUser('test@test.com', '123456', '测试用户');
    await this.insertUser('admin@cook.com', '123456', '美食达人');
  }

  /**
   * 插入预置菜谱的食材数据
   */
  private async insertPresetIngredients(recipeId: number, recipeName: string): Promise<void> {
    const ingredientMap: Record<string, string[][]> = {
      // [名称, 分类, 用量, 热量, 蛋白质, 碳水, 脂肪]
      '番茄炒蛋': [
        ['番茄', '蔬菜', '2个', '44', '1.8', '8.8', '0.4'],
        ['鸡蛋', '蛋奶', '3个', '210', '18', '2.1', '15'],
        ['食用油', '调料', '15ml', '135', '0', '0', '15'],
        ['盐', '调料', '3g', '0', '0', '0', '0'],
        ['白糖', '调料', '5g', '20', '0', '5', '0'],
        ['葱花', '调料', '10g', '3', '0.3', '0.5', '0'],
      ],
      '红烧肉': [
        ['五花肉', '肉类', '500g', '2500', '45', '0', '250'],
        ['冰糖', '调料', '30g', '120', '0', '30', '0'],
        ['生抽', '调料', '15ml', '10', '1', '1.5', '0'],
        ['老抽', '调料', '10ml', '5', '0.5', '0.8', '0'],
        ['料酒', '调料', '15ml', '10', '0', '0.5', '0'],
        ['八角', '调料', '2个', '5', '0.2', '0.8', '0.1'],
        ['桂皮', '调料', '1小块', '3', '0.1', '0.5', '0'],
        ['姜片', '调料', '3片', '2', '0.1', '0.4', '0'],
        ['葱段', '调料', '2根', '5', '0.3', '0.8', '0'],
      ],
      '清炒时蔬': [
        ['时令蔬菜', '蔬菜', '300g', '60', '4.5', '9', '0.6'],
        ['蒜末', '调料', '10g', '15', '0.6', '3', '0'],
        ['食用油', '调料', '10ml', '90', '0', '0', '10'],
        ['盐', '调料', '2g', '0', '0', '0', '0'],
        ['鸡精', '调料', '2g', '5', '0.3', '0.8', '0'],
      ],
      '宫保鸡丁': [
        ['鸡胸肉', '肉类', '250g', '325', '57.5', '0', '7.5'],
        ['花生米', '主食', '50g', '285', '12.5', '8', '25'],
        ['干辣椒', '调料', '8个', '20', '0.8', '3.5', '0.3'],
        ['花椒', '调料', '10粒', '5', '0.2', '0.8', '0.1'],
        ['黄瓜', '蔬菜', '1根', '30', '1.5', '5.5', '0.3'],
        ['葱段', '调料', '2根', '5', '0.3', '0.8', '0'],
        ['蒜片', '调料', '3瓣', '10', '0.4', '2', '0'],
        ['生抽', '调料', '15ml', '10', '1', '1.5', '0'],
        ['醋', '调料', '10ml', '3', '0', '0.5', '0'],
        ['白糖', '调料', '10g', '40', '0', '10', '0'],
        ['淀粉', '调料', '10g', '35', '0', '8.5', '0'],
      ],
      '蛋炒饭': [
        ['米饭', '主食', '300g', '350', '6.5', '78', '0.6'],
        ['鸡蛋', '蛋奶', '2个', '140', '12', '1.4', '10'],
        ['火腿', '肉类', '50g', '130', '6.5', '2', '10.5'],
        ['青豆', '蔬菜', '30g', '35', '3', '5', '0.3'],
        ['玉米粒', '蔬菜', '30g', '30', '1.2', '6', '0.3'],
        ['食用油', '调料', '15ml', '135', '0', '0', '15'],
        ['盐', '调料', '3g', '0', '0', '0', '0'],
        ['葱花', '调料', '10g', '3', '0.3', '0.5', '0'],
      ],
      '酸辣土豆丝': [
        ['土豆', '蔬菜', '2个(约400g)', '308', '8', '68', '0.8'],
        ['干辣椒', '调料', '5个', '12', '0.5', '2', '0.2'],
        ['花椒', '调料', '5粒', '3', '0.1', '0.5', '0.1'],
        ['蒜末', '调料', '5g', '8', '0.3', '1.5', '0'],
        ['醋', '调料', '15ml', '5', '0', '0.8', '0'],
        ['食用油', '调料', '10ml', '90', '0', '0', '10'],
        ['盐', '调料', '3g', '0', '0', '0', '0'],
        ['葱花', '调料', '5g', '2', '0.15', '0.25', '0'],
      ],
      '可乐鸡翅': [
        ['鸡翅', '肉类', '500g(约8个)', '1000', '80', '0', '72'],
        ['可乐', '饮品', '330ml(1罐)', '140', '0', '35', '0'],
        ['生抽', '调料', '15ml', '10', '1', '1.5', '0'],
        ['老抽', '调料', '5ml', '3', '0.3', '0.4', '0'],
        ['姜片', '调料', '3片', '2', '0.1', '0.4', '0'],
        ['料酒', '调料', '10ml', '7', '0', '0.3', '0'],
        ['食用油', '调料', '5ml', '45', '0', '0', '5'],
      ],
      '清蒸鱼': [
        ['鲈鱼', '海鲜', '1条(约500g)', '500', '90', '0', '15'],
        ['葱丝', '调料', '20g', '6', '0.5', '1', '0'],
        ['姜丝', '调料', '10g', '5', '0.2', '0.8', '0'],
        ['蒸鱼豉油', '调料', '15ml', '10', '0.8', '1.5', '0'],
        ['料酒', '调料', '10ml', '7', '0', '0.3', '0'],
        ['食用油', '调料', '15ml', '135', '0', '0', '15'],
        ['红椒丝', '调料', '少许', '2', '0.1', '0.3', '0'],
      ],
      '麻婆豆腐': [
        ['嫩豆腐', '蔬菜', '1块(约400g)', '280', '28', '8', '16'],
        ['猪肉末', '肉类', '100g', '395', '17', '0.5', '37'],
        ['豆瓣酱', '调料', '15g', '20', '1', '2.5', '0.5'],
        ['花椒粉', '调料', '3g', '5', '0.2', '0.8', '0.1'],
        ['蒜末', '调料', '10g', '15', '0.6', '3', '0'],
        ['姜末', '调料', '5g', '2', '0.1', '0.4', '0'],
        ['葱花', '调料', '10g', '3', '0.3', '0.5', '0'],
        ['生抽', '调料', '10ml', '7', '0.7', '1', '0'],
        ['淀粉', '调料', '5g', '18', '0', '4.3', '0'],
        ['食用油', '调料', '10ml', '90', '0', '0', '10'],
      ],
      '糖醋排骨': [
        ['排骨', '肉类', '500g', '1300', '95', '0', '100'],
        ['白糖', '调料', '40g', '160', '0', '40', '0'],
        ['醋', '调料', '30ml', '10', '0', '1.5', '0'],
        ['生抽', '调料', '15ml', '10', '1', '1.5', '0'],
        ['料酒', '调料', '15ml', '10', '0', '0.5', '0'],
        ['番茄酱', '调料', '15g', '15', '0.3', '3', '0'],
        ['姜片', '调料', '3片', '2', '0.1', '0.4', '0'],
        ['白芝麻', '调料', '5g', '30', '1', '1.2', '2.5'],
        ['食用油', '调料', '10ml', '90', '0', '0', '10'],
      ],
    };

    const presetIngredients: string[][] = ingredientMap[recipeName] ?? [];
    for (const data of presetIngredients) {
      const ingredient: Ingredient = new Ingredient();
      ingredient.name = data[0];
      ingredient.category = data[1];
      ingredient.amount = data[2];
      ingredient.calories = parseFloat(data[3]) || 0;
      ingredient.protein = parseFloat(data[4]) || 0;
      ingredient.carbs = parseFloat(data[5]) || 0;
      ingredient.fat = parseFloat(data[6]) || 0;
      await this.insertIngredient(recipeId, ingredient);
    }
  }

  /**
   * 插入预置菜谱的步骤数据
   */
  private async insertPresetSteps(recipeId: number, recipeName: string): Promise<void> {
    const stepsMap: Record<string, string[][]> = {
      // [步骤描述, 提示, 时长秒数, 是否需要计时]
      '番茄炒蛋': [
        ['番茄顶部划十字，用开水烫一下去皮，切成小块备用', '番茄用开水烫30秒更容易去皮', '0', 'false'],
        ['鸡蛋打入碗中，加少许盐和几滴料酒，搅拌均匀', '加一点水或料酒可以让鸡蛋更嫩滑', '0', 'false'],
        ['锅中倒油烧热，倒入蛋液，用筷子快速搅散，蛋液凝固后盛出备用', '油温要高，蛋液下锅后快速搅散', '60', 'true'],
        ['锅中再加少许油，放入番茄块翻炒出汁，加入少许白糖提鲜', '番茄要炒出汁水才好吃', '120', 'true'],
        ['倒入炒好的鸡蛋，加盐调味，翻炒均匀，撒上葱花即可出锅', '不要炒太久，保持鸡蛋嫩滑', '30', 'true'],
      ],
      '红烧肉': [
        ['五花肉切成3厘米见方的块，冷水下锅焯水3分钟，捞出洗净', '冷水下锅可以更好地去除血水', '180', 'true'],
        ['锅中放少许油，放入冰糖，小火慢慢炒至焦糖色', '小火慢炒，注意不要炒糊了', '120', 'true'],
        ['放入焯好的五花肉，翻炒均匀使每块肉都裹上糖色', '翻炒要均匀，让肉上色一致', '120', 'true'],
        ['加入生抽、老抽、料酒、八角、桂皮、姜片、葱段，翻炒均匀', '调味料的量可以根据口味调整', '0', 'false'],
        ['加入没过肉的热水，大火烧开后转小火炖煮45分钟', '一定要加热水，冷水会让肉变硬', '2700', 'true'],
        ['大火收汁至汤汁浓稠，出锅装盘即可', '收汁时要不停翻动，避免糊底', '300', 'true'],
      ],
      '清炒时蔬': [
        ['蔬菜洗净，切成适当大小；蒜切末备用', '蔬菜要沥干水分，避免下锅溅油', '0', 'false'],
        ['锅中倒油烧热，放入蒜末爆香', '蒜末不要炒糊，微黄即可', '30', 'true'],
        ['放入蔬菜大火翻炒，加盐和鸡精调味，炒至断生即可出锅', '大火快炒保持蔬菜脆嫩', '90', 'true'],
      ],
      '宫保鸡丁': [
        ['鸡胸肉切丁，加料酒、生抽、淀粉腌制15分钟', '腌制可以让鸡肉更嫩滑入味', '900', 'true'],
        ['花生米小火炒熟备用；黄瓜切丁；干辣椒剪段；葱切段', '花生米要小火慢炒，避免炒糊', '180', 'true'],
        ['调碗汁：生抽、醋、白糖、淀粉、水混合均匀', '提前调好碗汁，炒的时候更快速', '0', 'false'],
        ['锅中倒油烧热，放入花椒和干辣椒爆香，捞出花椒', '花椒炸出香味后捞出，避免口感发麻', '30', 'true'],
        ['放入鸡丁滑炒至变色，加入黄瓜丁和葱段翻炒', '鸡丁不要炒太久，变色即可', '90', 'true'],
        ['倒入碗汁快速翻炒均匀，最后加入花生米翻炒几下出锅', '花生米最后放，保持酥脆', '30', 'true'],
      ],
      '蛋炒饭': [
        ['鸡蛋打散，火腿切丁，青豆和玉米粒焯水备用', '隔夜米饭炒出来更粒粒分明', '0', 'false'],
        ['锅中倒油烧热，倒入蛋液快速炒散成小块', '蛋液下锅后要快速搅散', '30', 'true'],
        ['加入米饭，用锅铲压散翻炒，使每粒米饭都裹上蛋液', '中大火翻炒，米饭要压散', '120', 'true'],
        ['加入火腿丁、青豆、玉米粒翻炒均匀，加盐调味，撒葱花出锅', '最后大火翻炒几下更香', '60', 'true'],
      ],
      '酸辣土豆丝': [
        ['土豆去皮切细丝，用清水浸泡10分钟洗去淀粉', '泡水可以去除多余淀粉，炒出来更脆', '600', 'true'],
        ['锅中倒油烧热，放入花椒和干辣椒爆香', '花椒炸香后可以捞出', '30', 'true'],
        ['放入沥干水分的土豆丝，大火翻炒2分钟', '一定要大火快炒，保持脆度', '120', 'true'],
        ['加入醋、盐、蒜末翻炒均匀，撒上葱花出锅', '醋要沿锅边淋入，香味更浓', '30', 'true'],
      ],
      '可乐鸡翅': [
        ['鸡翅洗净，两面各划两刀方便入味', '划刀可以让鸡翅更容易入味', '0', 'false'],
        ['锅中放少许油，放入鸡翅煎至两面金黄', '中小火慢煎，两面都要煎到', '180', 'true'],
        ['加入姜片、生抽、老抽、料酒翻炒均匀', '翻炒让鸡翅均匀上色', '60', 'true'],
        ['倒入可乐没过鸡翅，大火烧开后转中小火炖煮20分钟', '可乐要用常温的，不要用冰的', '1200', 'true'],
        ['大火收汁至汤汁浓稠，出锅装盘即可', '收汁时不停翻动，让每个鸡翅都裹上酱汁', '300', 'true'],
      ],
      '清蒸鱼': [
        ['鲈鱼处理干净，两面各划三刀，抹上料酒和少许盐腌制10分钟', '划刀让鱼更容易入味和蒸熟', '600', 'true'],
        ['鱼身上铺上葱丝和姜丝，放入蒸锅', '蒸锅水要先烧开再放鱼', '0', 'false'],
        ['大火蒸8-10分钟，关火后虚蒸2分钟', '蒸的时间根据鱼的大小调整', '600', 'true'],
        ['取出蒸好的鱼，倒掉盘中的蒸汁，铺上新鲜的葱丝和红椒丝', '倒掉蒸汁可以去除腥味', '0', 'false'],
        ['淋上蒸鱼豉油，将烧热的油浇在葱丝上即可', '油要烧至冒烟，浇上去才会香', '30', 'true'],
      ],
      '麻婆豆腐': [
        ['豆腐切成2厘米见方的小块，放入加了盐的开水中焯水2分钟', '焯水可以去除豆腥味，也让豆腐更结实', '120', 'true'],
        ['锅中倒油烧热，放入肉末炒至变色出油', '肉末要炒散，不要结块', '90', 'true'],
        ['加入豆瓣酱、姜末、蒜末炒出红油', '小火炒出红油，颜色更漂亮', '60', 'true'],
        ['加入适量水烧开，放入豆腐块，轻轻推动避免碎裂', '不要用铲子翻炒，轻轻推动即可', '180', 'true'],
        ['加生抽调味，用水淀粉勾芡，撒上花椒粉和葱花出锅', '勾芡后轻轻推匀，让豆腐裹上酱汁', '30', 'true'],
      ],
      '糖醋排骨': [
        ['排骨剁成小段，冷水下锅焯水3分钟，捞出洗净沥干', '冷水下锅焯水去血沫更干净', '180', 'true'],
        ['调糖醋汁：白糖、醋、生抽、料酒、番茄酱混合均匀', '糖醋比例约为4:3，可根据口味调整', '0', 'false'],
        ['锅中倒油烧热，放入排骨煎至两面微黄', '中火慢煎，让排骨表面焦香', '180', 'true'],
        ['倒入糖醋汁，加适量水没过排骨，大火烧开后转小火炖煮30分钟', '小火慢炖让排骨入味', '1800', 'true'],
        ['大火收汁至汤汁浓稠，撒上白芝麻出锅即可', '收汁时不停翻动，让每块排骨都裹上酱汁', '300', 'true'],
      ],
    };

    const presetSteps: string[][] = stepsMap[recipeName] ?? [];
    for (let i = 0; i < presetSteps.length; i++) {
      const data = presetSteps[i];
      const step: CookingStep = new CookingStep();
      step.stepNumber = i + 1;
      step.description = data[0];
      step.tip = data[1];
      step.duration = parseInt(data[2]) || 0;
      step.needTimer = data[3] === 'true';
      await this.insertStep(recipeId, step);
    }
  }

  /**
   * 插入菜谱
   * 修复：参数类型不能用 any，定义明确接口
   */
  async insertRecipe(recipe: RecipeInsertData): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      name: recipe.name,
      coverImage: recipe.coverImage ?? '',
      category: recipe.category,
      cuisine: recipe.cuisine,
      difficulty: recipe.difficulty,
      duration: recipe.duration,
      servings: recipe.servings,
      calories: recipe.calories,
      description: recipe.description,
      rating: recipe.rating ?? 0,
      viewCount: recipe.viewCount ?? 0,
      favoriteCount: recipe.favoriteCount ?? 0,
      isFavorite: 0,
      videoUrl: recipe.videoUrl ?? '',
      author: recipe.author ?? '匿名',
      createTime: new Date().toISOString()
    };

    const rowId: number = await this.store.insert('recipes', valueBucket);
    return rowId;
  }

  /**
   * 插入食材
   */
  async insertIngredient(recipeId: number, ingredient: Ingredient): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: recipeId,
      name: ingredient.name,
      category: ingredient.category ?? '',
      amount: ingredient.amount ?? '',
      calories: ingredient.calories ?? 0,
      protein: ingredient.protein ?? 0,
      carbs: ingredient.carbs ?? 0,
      fat: ingredient.fat ?? 0,
      image: ingredient.image ?? '',
    };

    const rowId: number = await this.store.insert('ingredients', valueBucket);
    return rowId;
  }

  /**
   * 插入烹饪步骤
   */
  async insertStep(recipeId: number, step: CookingStep): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: recipeId,
      stepNumber: step.stepNumber,
      description: step.description,
      image: step.image ?? '',
      duration: step.duration ?? 0,
      tip: step.tip ?? '',
      needTimer: step.needTimer ? 1 : 0,
    };

    const rowId: number = await this.store.insert('cooking_steps', valueBucket);
    return rowId;
  }

  /**
   * 批量导入菜谱（从JSON数据）
   * @param jsonData 包含 recipes 数组的 JSON 字符串
   * @param onProgress 进度回调 (current, total)
   */
  async importRecipesFromJson(jsonData: string, onProgress?: (current: number, total: number) => void): Promise<number> {
    if (!this.store) {
      return 0;
    }

    let data: object;
    try {
      data = JSON.parse(jsonData) as object;
    } catch (e) {
      console.error('JSON解析失败');
      return 0;
    }

    // 兼容两种格式：直接数组 或 { recipes: [...] }
    let recipes: object[] = [];
    if (Array.isArray(data)) {
      recipes = data as object[];
    } else {
      const dataObj = data as Record<string, object>;
      if (dataObj['recipes'] && Array.isArray(dataObj['recipes'])) {
        recipes = dataObj['recipes'] as object[];
      }
    }

    const total: number = recipes.length;
    let imported: number = 0;

    for (let i = 0; i < recipes.length; i++) {
      const r: Record<string, object> = recipes[i] as Record<string, object>;
      try {
        // 插入菜谱
        const recipeData: RecipeInsertData = new RecipeInsertData();
        recipeData.name = String(r['name'] ?? '');
        recipeData.coverImage = String(r['coverImage'] ?? '');
        recipeData.category = String(r['category'] ?? '家常菜');
        recipeData.cuisine = String(r['cuisine'] ?? '家常');
        recipeData.difficulty = String(r['difficulty'] ?? '简单');
        recipeData.duration = Number(r['duration'] ?? 30);
        recipeData.servings = Number(r['servings'] ?? 2);
        recipeData.calories = Number(r['calories'] ?? 200);
        recipeData.description = String(r['description'] ?? '');
        recipeData.rating = Number(r['rating'] ?? 4.5);
        recipeData.author = String(r['author'] ?? '用户分享');
        recipeData.videoUrl = String(r['videoUrl'] ?? '');
        recipeData.viewCount = Number(r['viewCount'] ?? 0);
        recipeData.favoriteCount = Number(r['favoriteCount'] ?? 0);

        const recipeId: number = await this.insertRecipe(recipeData);
        if (recipeId <= 0) continue;

        // 插入食材（自动填充营养数据）
        const ingredients: object[] = r['ingredients'] as object[];
        if (ingredients && Array.isArray(ingredients)) {
          for (let j = 0; j < ingredients.length; j++) {
            const ingObj: Record<string, object> = ingredients[j] as Record<string, object>;
            const ingredient: Ingredient = new Ingredient();
            ingredient.name = String(ingObj['name'] ?? '');
            ingredient.category = String(ingObj['category'] ?? '');
            ingredient.amount = String(ingObj['amount'] ?? '');
            ingredient.calories = Number(ingObj['calories'] ?? 0);
            ingredient.protein = Number(ingObj['protein'] ?? 0);
            ingredient.carbs = Number(ingObj['carbs'] ?? 0);
            ingredient.fat = Number(ingObj['fat'] ?? 0);

            // 如果没有营养数据，从营养数据库查找填充
            if (ingredient.calories === 0 && ingredient.name) {
              const nutrition: number[] | null = IngredientNutritionDB.lookup(ingredient.name);
              if (nutrition) {
                ingredient.calories = nutrition[0];
                ingredient.protein = nutrition[1];
                ingredient.carbs = nutrition[2];
                ingredient.fat = nutrition[3];
              }
            }

            await this.insertIngredient(recipeId, ingredient);
          }
        }

        // 插入步骤
        const steps: object[] = r['steps'] as object[];
        if (steps && Array.isArray(steps)) {
          for (let k = 0; k < steps.length; k++) {
            const sObj: Record<string, object> = steps[k] as Record<string, object>;
            const step: CookingStep = new CookingStep();
            step.stepNumber = Number(sObj['stepNumber'] ?? 0);
            step.description = String(sObj['description'] ?? '');
            step.image = String(sObj['image'] ?? '');
            step.duration = Number(sObj['duration'] ?? 0);
            step.tip = String(sObj['tip'] ?? '');
            step.needTimer = Boolean(sObj['needTimer'] ?? false);
            await this.insertStep(recipeId, step);
          }
        }

        imported++;
        if (onProgress) {
          onProgress(i + 1, total);
        }
      } catch (e) {
        console.error(`导入第 ${i + 1} 条失败: ${e}`);
      }
    }

    return imported;
  }

  /**
   * 获取所有菜谱
   */
  async getAllRecipes(): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes ORDER BY id DESC'
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 根据分类获取菜谱
   */
  async getRecipesByCategory(category: string): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes WHERE category = ? ORDER BY rating DESC',
      [category]
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 搜索菜谱
   */
  async searchRecipes(keyword: string): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const keywordParam: string = '%' + keyword + '%';
    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes WHERE name LIKE ? OR description LIKE ? OR cuisine LIKE ?',
      [keywordParam, keywordParam, keywordParam]
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 获取推荐菜谱（按评分和热度）
   */
  async getRecommendedRecipes(limit: number = 10): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes ORDER BY rating DESC, favoriteCount DESC LIMIT ?',
      [limit]
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 获取菜谱详情
   */
  async getRecipeById(id: number): Promise<Recipe | null> {
    if (!this.store) {
      return null;
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes WHERE id = ?',
      [id]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return null;
    }

    resultSet.goToFirstRow();
    const recipe: Recipe = this.mapRecipeFromRow(resultSet);
    resultSet.close();

    // 获取食材列表
    recipe.ingredients = await this.getIngredientsByRecipeId(id);

    // 获取烹饪步骤
    recipe.steps = await this.getStepsByRecipeId(id);

    return recipe;
  }

  /**
   * 获取菜谱的食材列表
   * 修复：ResultSet 不能用 .map()，必须用 goToNextRow() 遍历
   */
  async getIngredientsByRecipeId(recipeId: number): Promise<Ingredient[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM ingredients WHERE recipeId = ?',
      [recipeId]
    );

    const ingredients: Ingredient[] = [];
    while (resultSet.goToNextRow()) {
      const ingredient: Ingredient = new Ingredient();
      ingredient.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      ingredient.name = resultSet.getString(resultSet.getColumnIndex('name'));
      ingredient.category = resultSet.getString(resultSet.getColumnIndex('category'));
      ingredient.amount = resultSet.getString(resultSet.getColumnIndex('amount'));
      ingredient.calories = resultSet.getDouble(resultSet.getColumnIndex('calories'));
      ingredient.protein = resultSet.getDouble(resultSet.getColumnIndex('protein'));
      ingredient.carbs = resultSet.getDouble(resultSet.getColumnIndex('carbs'));
      ingredient.fat = resultSet.getDouble(resultSet.getColumnIndex('fat'));
      ingredient.image = resultSet.getString(resultSet.getColumnIndex('image'));
      ingredients.push(ingredient);
    }
    resultSet.close();

    return ingredients;
  }

  /**
   * 获取菜谱的烹饪步骤
   */
  async getStepsByRecipeId(recipeId: number): Promise<CookingStep[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM cooking_steps WHERE recipeId = ? ORDER BY stepNumber',
      [recipeId]
    );

    const steps: CookingStep[] = [];
    while (resultSet.goToNextRow()) {
      const step: CookingStep = new CookingStep();
      step.stepNumber = resultSet.getLong(resultSet.getColumnIndex('stepNumber'));
      step.description = resultSet.getString(resultSet.getColumnIndex('description'));
      step.image = resultSet.getString(resultSet.getColumnIndex('image'));
      step.duration = resultSet.getLong(resultSet.getColumnIndex('duration'));
      step.tip = resultSet.getString(resultSet.getColumnIndex('tip'));
      step.needTimer = resultSet.getLong(resultSet.getColumnIndex('needTimer')) === 1;
      steps.push(step);
    }
    resultSet.close();

    return steps;
  }

  /**
   * 收藏/取消收藏菜谱
   */
  async toggleFavorite(recipeId: number): Promise<boolean> {
    if (!this.store) {
      return false;
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT isFavorite FROM recipes WHERE id = ?',
      [recipeId]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return false;
    }

    resultSet.goToFirstRow();
    const currentVal: number = resultSet.getLong(resultSet.getColumnIndex('isFavorite'));
    resultSet.close();

    const newVal: number = currentVal === 1 ? 0 : 1;
    const delta: number = newVal === 1 ? 1 : -1;

    await this.store.executeSql(
      'UPDATE recipes SET isFavorite = ?, favoriteCount = favoriteCount + ? WHERE id = ?',
      [newVal, delta, recipeId]
    );

    return newVal === 1;
  }

  /**
   * 获取收藏的菜谱列表
   */
  async getFavoriteRecipes(): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM recipes WHERE isFavorite = 1 ORDER BY id DESC'
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 增加浏览次数
   */
  async incrementViewCount(recipeId: number): Promise<void> {
    if (!this.store) {
      return;
    }

    await this.store.executeSql(
      'UPDATE recipes SET viewCount = viewCount + 1 WHERE id = ?',
      [recipeId]
    );

    // 记录浏览历史
    await this.store.executeSql(
      'INSERT INTO browse_history (recipeId, browseTime) VALUES (?, ?)',
      [recipeId, new Date().toISOString()]
    );
  }

  /**
   * 获取浏览历史
   */
  async getBrowseHistory(limit: number = 20): Promise<Recipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT DISTINCT r.* FROM recipes r INNER JOIN browse_history bh ON r.id = bh.recipeId ORDER BY bh.browseTime DESC LIMIT ?',
      [limit]
    );
    return this.mapRecipesFromResultSet(resultSet);
  }

  /**
   * 添加评论
   */
  async addComment(comment: Comment): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: comment.recipeId,
      userId: comment.userId,
      userName: comment.userName,
      content: comment.content,
      rating: comment.rating,
      createTime: new Date().toISOString(),
      likes: 0
    };

    const rowId: number = await this.store.insert('comments', valueBucket);
    return rowId;
  }

  /**
   * 获取菜谱的评论列表
   */
  async getCommentsByRecipeId(recipeId: number): Promise<Comment[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM comments WHERE recipeId = ? ORDER BY createTime DESC',
      [recipeId]
    );

    const comments: Comment[] = [];
    while (resultSet.goToNextRow()) {
      const comment: Comment = new Comment();
      comment.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      comment.recipeId = resultSet.getLong(resultSet.getColumnIndex('recipeId'));
      comment.userId = resultSet.getString(resultSet.getColumnIndex('userId'));
      comment.userName = resultSet.getString(resultSet.getColumnIndex('userName'));
      comment.content = resultSet.getString(resultSet.getColumnIndex('content'));
      comment.rating = resultSet.getLong(resultSet.getColumnIndex('rating'));
      comment.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
      comment.likes = resultSet.getLong(resultSet.getColumnIndex('likes'));
      comments.push(comment);
    }
    resultSet.close();

    return comments;
  }

  /**
   * 发布社区菜谱
   */
  async publishCommunityRecipe(recipe: CommunityRecipe): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: recipe.recipeId,
      userId: recipe.userId,
      userName: recipe.userName,
      title: recipe.title,
      content: recipe.content,
      images: JSON.stringify(recipe.images),
      likes: 0,
      commentCount: 0,
      createTime: new Date().toISOString(),
      isLiked: 0
    };

    const rowId: number = await this.store.insert('community_recipes', valueBucket);
    return rowId;
  }

  /**
   * 获取社区菜谱列表
   */
  async getCommunityRecipes(limit: number = 50): Promise<CommunityRecipe[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM community_recipes ORDER BY createTime DESC LIMIT ?',
      [limit]
    );

    const recipes: CommunityRecipe[] = [];
    while (resultSet.goToNextRow()) {
      const recipe: CommunityRecipe = new CommunityRecipe();
      recipe.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      recipe.recipeId = resultSet.getLong(resultSet.getColumnIndex('recipeId'));
      recipe.userId = resultSet.getString(resultSet.getColumnIndex('userId'));
      recipe.userName = resultSet.getString(resultSet.getColumnIndex('userName'));
      recipe.title = resultSet.getString(resultSet.getColumnIndex('title'));
      recipe.content = resultSet.getString(resultSet.getColumnIndex('content'));

      const imagesStr: string = resultSet.getString(resultSet.getColumnIndex('images'));
      recipe.images = JSON.parse(imagesStr) as string[];

      recipe.likes = resultSet.getLong(resultSet.getColumnIndex('likes'));
      recipe.comments = resultSet.getLong(resultSet.getColumnIndex('commentCount'));
      recipe.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
      recipe.isLiked = resultSet.getLong(resultSet.getColumnIndex('isLiked')) === 1;
      recipes.push(recipe);
    }
    resultSet.close();

    return recipes;
  }

  /**
   * 点赞/取消点赞社区菜谱
   */
  async toggleLikeCommunityRecipe(id: number): Promise<boolean> {
    if (!this.store) {
      return false;
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT isLiked FROM community_recipes WHERE id = ?',
      [id]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return false;
    }

    resultSet.goToFirstRow();
    const currentVal: number = resultSet.getLong(resultSet.getColumnIndex('isLiked'));
    resultSet.close();

    const newVal: number = currentVal === 1 ? 0 : 1;
    const delta: number = newVal === 1 ? 1 : -1;

    await this.store.executeSql(
      'UPDATE community_recipes SET isLiked = ?, likes = likes + ? WHERE id = ?',
      [newVal, delta, id]
    );

    return newVal === 1;
  }

  /**
   * 添加烹饪记录
   */
  async addCookingRecord(record: CookingRecord): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: record.recipeId,
      recipeName: record.recipeName,
      cookTime: new Date().toISOString(),
      duration: record.duration,
      rating: record.rating,
      note: record.note,
      image: record.image
    };

    const rowId: number = await this.store.insert('cooking_records', valueBucket);
    return rowId;
  }

  /**
   * 获取烹饪记录
   */
  async getCookingRecords(): Promise<CookingRecord[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM cooking_records ORDER BY cookTime DESC'
    );

    const records: CookingRecord[] = [];
    while (resultSet.goToNextRow()) {
      const record: CookingRecord = new CookingRecord();
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.recipeId = resultSet.getLong(resultSet.getColumnIndex('recipeId'));
      record.recipeName = resultSet.getString(resultSet.getColumnIndex('recipeName'));
      record.cookTime = resultSet.getString(resultSet.getColumnIndex('cookTime'));
      record.duration = resultSet.getLong(resultSet.getColumnIndex('duration'));
      record.rating = resultSet.getLong(resultSet.getColumnIndex('rating'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.image = resultSet.getString(resultSet.getColumnIndex('image'));
      records.push(record);
    }
    resultSet.close();

    return records;
  }

  /**
   * 根据食材名称列表查找可做的菜谱
   */
  async getRecipesByIngredients(ingredientNames: string[]): Promise<Recipe[]> {
    if (!this.store || ingredientNames.length === 0) {
      return [];
    }

    const placeholders: string = ingredientNames.map((): string => '?').join(',');
    const sql: string = 'SELECT DISTINCT r.* FROM recipes r INNER JOIN ingredients i ON r.id = i.recipeId WHERE i.name IN (' + placeholders + ') GROUP BY r.id ORDER BY COUNT(DISTINCT i.name) DESC';

    const resultSet: relationalStore.ResultSet = await this.store.querySql(sql, ingredientNames);
    return this.mapRecipesFromResultSet(resultSet);
  }

  // ==================== AI创新菜谱方法 ====================

  /**
   * 保存AI创新菜谱
   */
  async insertCreativeRecipe(recipe: CreativeRecipeData): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      name: recipe.name,
      description: recipe.description,
      ingredients: JSON.stringify(recipe.ingredients),
      steps: JSON.stringify(recipe.steps),
      difficulty: recipe.difficulty,
      duration: recipe.duration,
      creativeTip: recipe.creativeTip,
      status: 'saved',
      createTime: new Date().toISOString()
    };

    const rowId: number = await this.store.insert('creative_recipes', valueBucket);
    return rowId;
  }

  /**
   * 获取用户保存的创新菜谱列表
   */
  async getCreativeRecipes(): Promise<CreativeRecipeItem[]> {
    if (!this.store) {
      return [];
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM creative_recipes WHERE status != \'deleted\' ORDER BY createTime DESC'
    );

    const recipes: CreativeRecipeItem[] = [];
    while (resultSet.goToNextRow()) {
      const item: CreativeRecipeItem = new CreativeRecipeItem();
      item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      item.name = resultSet.getString(resultSet.getColumnIndex('name'));
      item.description = resultSet.getString(resultSet.getColumnIndex('description'));

      const ingredientsStr: string = resultSet.getString(resultSet.getColumnIndex('ingredients'));
      try {
        item.ingredients = JSON.parse(ingredientsStr) as string[];
      } catch (_e) {
        item.ingredients = [];
      }

      const stepsStr: string = resultSet.getString(resultSet.getColumnIndex('steps'));
      try {
        item.steps = JSON.parse(stepsStr) as string[];
      } catch (_e) {
        item.steps = [];
      }

      item.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty'));
      item.duration = resultSet.getString(resultSet.getColumnIndex('duration'));
      item.creativeTip = resultSet.getString(resultSet.getColumnIndex('creativeTip'));
      item.status = resultSet.getString(resultSet.getColumnIndex('status'));
      item.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
      recipes.push(item);
    }
    resultSet.close();

    return recipes;
  }

  /**
   * 删除创新菜谱（软删除）
   */
  async deleteCreativeRecipe(id: number): Promise<void> {
    if (!this.store) {
      return;
    }

    await this.store.executeSql(
      'UPDATE creative_recipes SET status = \'deleted\' WHERE id = ?',
      [id]
    );
  }

  /**
   * 发布创新菜谱到社区
   * 将创意菜谱信息写入 community_recipes 表
   */
  async publishCreativeRecipe(id: number): Promise<boolean> {
    if (!this.store) {
      return false;
    }

    // 查询创新菜谱
    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM creative_recipes WHERE id = ?',
      [id]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return false;
    }

    resultSet.goToFirstRow();
    const name: string = resultSet.getString(resultSet.getColumnIndex('name'));
    const description: string = resultSet.getString(resultSet.getColumnIndex('description'));
    const ingredientsStr: string = resultSet.getString(resultSet.getColumnIndex('ingredients'));
    const stepsStr: string = resultSet.getString(resultSet.getColumnIndex('steps'));
    const creativeTip: string = resultSet.getString(resultSet.getColumnIndex('creativeTip'));
    resultSet.close();

    // 构造社区发布内容
    let ingredients: string[] = [];
    try {
      ingredients = JSON.parse(ingredientsStr) as string[];
    } catch (_e) {
      ingredients = [];
    }

    let steps: string[] = [];
    try {
      steps = JSON.parse(stepsStr) as string[];
    } catch (_e) {
      steps = [];
    }

    // 拼接详细内容
    let content: string = description + '\n\n';
    content += '🥬 食材清单：\n';
    for (let i = 0; i < ingredients.length; i++) {
      content += '• ' + ingredients[i] + '\n';
    }
    content += '\n👨‍🍳 烹饪步骤：\n';
    for (let i = 0; i < steps.length; i++) {
      content += (i + 1) + '. ' + steps[i] + '\n';
    }
    if (creativeTip) {
      content += '\n✨ 创意亮点：' + creativeTip;
    }

    // 写入社区表
    const valueBucket: relationalStore.ValuesBucket = {
      recipeId: 0,
      userId: 'local_user',
      userName: '创意厨师',
      title: '🎉 AI创意菜谱：' + name,
      content: content,
      images: JSON.stringify([]),
      likes: 0,
      commentCount: 0,
      createTime: new Date().toISOString(),
      isLiked: 0
    };

    await this.store.insert('community_recipes', valueBucket);

    // 更新状态为已发布
    await this.store.executeSql(
      'UPDATE creative_recipes SET status = \'published\' WHERE id = ?',
      [id]
    );

    return true;
  }

  // ==================== 用户相关方法 ====================

  /**
   * 插入新用户
   */
  async insertUser(email: string, password: string, nickname: string): Promise<number> {
    if (!this.store) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      email: email,
      password: password,
      nickname: nickname || '美食家',
      avatar: '',
      createTime: new Date().toISOString(),
      lastLoginTime: new Date().toISOString()
    };

    const rowId: number = await this.store.insert('users', valueBucket);
    return rowId;
  }

  /**
   * 根据邮箱查询用户
   */
  async getUserByEmail(email: string): Promise<User | null> {
    if (!this.store) {
      return null;
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return null;
    }

    resultSet.goToFirstRow();
    const user: User = this.mapUserFromRow(resultSet);
    resultSet.close();
    return user;
  }

  /**
   * 验证用户登录
   */
  async verifyUserLogin(email: string, password: string): Promise<User | null> {
    if (!this.store) {
      return null;
    }

    const resultSet: relationalStore.ResultSet = await this.store.querySql(
      'SELECT * FROM users WHERE email = ? AND password = ?',
      [email, password]
    );

    if (resultSet.rowCount === 0) {
      resultSet.close();
      return null;
    }

    resultSet.goToFirstRow();
    const user: User = this.mapUserFromRow(resultSet);
    resultSet.close();
    return user;
  }

  /**
   * 更新最后登录时间
   */
  async updateLastLoginTime(userId: number): Promise<void> {
    if (!this.store) {
      return;
    }

    await this.store.executeSql(
      'UPDATE users SET lastLoginTime = ? WHERE id = ?',
      [new Date().toISOString(), userId]
    );
  }

  /**
   * 从 ResultSet 当前行映射出 User 对象
   */
  private mapUserFromRow(resultSet: relationalStore.ResultSet): User {
    const user: User = new User();
    user.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    user.email = resultSet.getString(resultSet.getColumnIndex('email'));
    user.password = resultSet.getString(resultSet.getColumnIndex('password'));
    user.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'));
    user.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'));
    user.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
    user.lastLoginTime = resultSet.getString(resultSet.getColumnIndex('lastLoginTime'));
    return user;
  }

  /**
   * 从 ResultSet 映射出 Recipe 数组
   * 修复：ResultSet 不能当数组，必须用 goToNextRow() 遍历
   */
  private mapRecipesFromResultSet(resultSet: relationalStore.ResultSet): Recipe[] {
    const recipes: Recipe[] = [];
    while (resultSet.goToNextRow()) {
      recipes.push(this.mapRecipeFromRow(resultSet));
    }
    resultSet.close();
    return recipes;
  }

  /**
   * 从 ResultSet 当前行映射出 Recipe 对象
   * 修复：禁止 any，用明确类型从 ResultSet 取值
   */
  private mapRecipeFromRow(resultSet: relationalStore.ResultSet): Recipe {
    const recipe: Recipe = new Recipe();
    recipe.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    recipe.name = resultSet.getString(resultSet.getColumnIndex('name'));
    recipe.coverImage = resultSet.getString(resultSet.getColumnIndex('coverImage'));
    recipe.category = resultSet.getString(resultSet.getColumnIndex('category'));
    recipe.cuisine = resultSet.getString(resultSet.getColumnIndex('cuisine'));
    recipe.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty'));
    recipe.duration = resultSet.getLong(resultSet.getColumnIndex('duration'));
    recipe.servings = resultSet.getLong(resultSet.getColumnIndex('servings'));
    recipe.calories = resultSet.getLong(resultSet.getColumnIndex('calories'));
    recipe.description = resultSet.getString(resultSet.getColumnIndex('description'));
    recipe.rating = resultSet.getDouble(resultSet.getColumnIndex('rating'));
    recipe.viewCount = resultSet.getLong(resultSet.getColumnIndex('viewCount'));
    recipe.favoriteCount = resultSet.getLong(resultSet.getColumnIndex('favoriteCount'));
    recipe.isFavorite = resultSet.getLong(resultSet.getColumnIndex('isFavorite')) === 1;
    recipe.videoUrl = resultSet.getString(resultSet.getColumnIndex('videoUrl'));
    recipe.author = resultSet.getString(resultSet.getColumnIndex('author'));
    recipe.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
    return recipe;
  }
}

/**
 * 插入菜谱数据的类
 */
export class RecipeInsertData {
  name: string = '';
  coverImage: string = '';
  category: string = '';
  cuisine: string = '';
  difficulty: string = '';
  duration: number = 0;
  servings: number = 0;
  calories: number = 0;
  description: string = '';
  rating: number = 0;
  videoUrl: string = '';
  author: string = '';
  viewCount: number = 0;
  favoriteCount: number = 0;
}

/**
 * 菜谱更新项（用于 assignDefaultImages）
 */
class RecipeUpdateItem {
  id: number = 0;
  category: string = '';
  name: string = '';
}

/**
 * 创新菜谱插入数据
 */
export class CreativeRecipeData {
  name: string = '';
  description: string = '';
  ingredients: string[] = [];
  steps: string[] = [];
  difficulty: string = '';
  duration: string = '';
  creativeTip: string = '';
}

/**
 * 创新菜谱列表项（含数据库字段）
 */
export class CreativeRecipeItem {
  id: number = 0;
  name: string = '';
  description: string = '';
  ingredients: string[] = [];
  steps: string[] = [];
  difficulty: string = '';
  duration: string = '';
  creativeTip: string = '';
  status: string = 'saved';
  createTime: string = '';
}
