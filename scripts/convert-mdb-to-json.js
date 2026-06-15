/**
 * 将 Access 菜谱数据库转换为 App 可导入的 JSON 格式
 */
const { default: MDBReader } = require('mdb-reader');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', '8650c-main', '菜谱数据库(5000多种菜)', '菜谱数据库.mdb');
const outputPath = path.join(__dirname, 'recipes-data.json');

// 食材分类推断
function guessIngredientCategory(name) {
  const n = name.toLowerCase();
  const vegs = ['白菜', '青菜', '菠菜', '生菜', '芹菜', '韭菜', '蒜苗', '豆芽', '土豆', '番茄', '西红柿',
    '黄瓜', '茄子', '辣椒', '青椒', '洋葱', '萝卜', '胡萝卜', '南瓜', '冬瓜', '丝瓜', '苦瓜', '豆角',
    '蘑菇', '香菇', '金针菇', '木耳', '玉米', '西兰花', '花菜', '藕', '山药', '芋头', '豆腐', '豆皮',
    '毛豆', '荷兰豆', '秋葵', '莴笋', '竹笋', '芦笋', '香菜', '薄荷', '紫苏', '西葫芦', '油麦菜',
    '空心菜', '苋菜', '荠菜', '香椿', '蕨菜', '海带', '紫菜', '裙带菜', '青笋', '荸荠', '栗子',
    '莲子', '芡实', '薏仁', '荷叶', '鲜藕', '蔬菜', '芫荽'];
  const meats = ['猪肉', '牛肉', '羊肉', '鸡肉', '鸭肉', '排骨', '五花肉', '里脊', '肉末', '肉丝', '肉片',
    '鸡胸', '鸡翅', '鸡腿', '鸡爪', '鸭腿', '培根', '腊肉', '香肠', '火腿', '午餐肉', '牛腩', '肥牛',
    '猪蹄', '肘子', '猪肝', '猪肚', '鸡肝', '鹅', '野鸭', '肥膘', '鸡腿肉', '火腿薄片', '鲜虾仁',
    '虾仁', '瘦猪肉'];
  const seafood = ['鱼', '虾', '蟹', '贝', '蛤', '鱿鱼', '墨鱼', '章鱼', '龙虾', '三文鱼', '鲈鱼', '鲫鱼',
    '草鱼', '鲤鱼', '带鱼', '黄鱼', '鳕鱼', '金枪鱼', '海参', '鲍鱼', '扇贝', '生蚝', '海螺', '皮皮虾',
    '海蜇', '鲜墨鱼'];
  const dairy = ['鸡蛋', '鸭蛋', '鹌鹑蛋', '牛奶', '酸奶', '奶酪', '芝士', '黄油', '奶油', '炼乳', '淡奶',
    '蛋清', '蛋黄', '蛋', '酸奶油'];
  const staples = ['米', '饭', '面条', '面粉', '饺子', '馒头', '面包', '年糕', '粉丝', '粉条', '河粉',
    '米粉', '意面', '通心粉', '燕麦', '糯米', '小米', '红豆', '绿豆', '黑豆', '黄豆', '花生', '芝麻',
    '馄饨皮', '大米', '马铃薯', '土豆', '淀粉', '干淀粉', '湿淀粉', '芡汁'];
  const seasonings = ['盐', '糖', '醋', '酱油', '生抽', '老抽', '蚝油', '料酒', '味精', '鸡精', '胡椒',
    '花椒', '八角', '桂皮', '香叶', '辣椒粉', '花椒粉', '五香粉', '十三香', '番茄酱', '豆瓣酱',
    '甜面酱', '芝麻酱', '沙拉酱', '蜂蜜', '面包糠', '酵母', '小苏打', '泡打粉',
    '食用油', '橄榄油', '花生油', '菜籽油', '香油', '辣椒油', '咖喱', '椰浆', '椰奶', '可乐', '啤酒',
    '精盐', '味精', '绍酒', '香醋', '陈醋', '麻油', '芝麻油', '植物油', '熟猪油', '猪油', '菜油',
    '熟菜油', '红花子油', '芥末酱', '芫荽子', '胡椒粉', '花椒水', '豆瓣', '泡椒', '高汤', '鸡汤',
    '清汤', '白糖', '湿淀粉', '辣椒酱', '蒜', '葱', '姜', '葱花', '姜末', '蒜末', '葱段', '姜片',
    '蒜片', '葱白', '葱结', '香葱', '大蒜', '生姜', '淀粉浆'];

  if (vegs.some(v => n.includes(v))) return '蔬菜';
  if (meats.some(v => n.includes(v))) return '肉类';
  if (seafood.some(v => n.includes(v))) return '海鲜';
  if (dairy.some(v => n.includes(v))) return '蛋奶';
  if (staples.some(v => n.includes(v))) return '主食';
  if (seasonings.some(v => n.includes(v))) return '调料';
  return '蔬菜';
}

// 解析原料字段为食材列表
function parseIngredients(rawMaterial, rawSeasoning) {
  const ingredients = [];

  // 解析原料
  if (rawMaterial) {
    // 分隔符可能是逗号、分号、顿号
    const parts = rawMaterial.split(/[,;，；、]/).map(s => s.trim()).filter(s => s.length > 0);
    for (const part of parts) {
      // 尝试提取数量，格式如 "鸡蛋3个180克" 或 "猪肉100克" 或 "盐适量"
      const match = part.match(/^(.+?)(\d[\d.\/]*\s*(克|千克|g|kg|斤|两|个|条|只|根|片|块|颗|粒|把|束|汤匙|茶匙|小匙|大匙|毫升|ml|张|束|碗|杯|少许|适量|若干).*?)?$/i);
      let name = part;
      let amount = '适量';

      if (match && match[1]) {
        name = match[1].trim();
        if (match[2]) {
          amount = match[2].trim();
        }
      }

      // 清理名称
      name = name.replace(/^\d+[\s.]*/, '').trim();
      if (name.length > 0 && name.length < 20) {
        ingredients.push({
          name: name,
          category: guessIngredientCategory(name),
          amount: amount,
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          image: ''
        });
      }
    }
  }

  // 解析调料（如果原料中没有的）
  if (rawSeasoning) {
    const parts = rawSeasoning.split(/[,;，；、]/).map(s => s.trim()).filter(s => s.length > 0);
    const existingNames = new Set(ingredients.map(i => i.name));
    for (const part of parts) {
      let name = part.replace(/^\d+[\s.]*/, '').replace(/\d[\d.]*\s*(克|g|ml|毫升|汤匙|茶匙|小匙|大匙)/gi, '').trim();
      if (name.length > 0 && name.length < 15 && !existingNames.has(name)) {
        ingredients.push({
          name: name,
          category: '调料',
          amount: '适量',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          image: ''
        });
        existingNames.add(name);
      }
    }
  }

  return ingredients;
}

// 解析做法字段为步骤列表
function parseSteps(cookingMethod) {
  if (!cookingMethod) return [];

  const steps = [];
  // 按编号分割：(1)(2)... 或 1. 2. ... 或 1、2、...
  const parts = cookingMethod.split(/(?:^|\n)\s*(?:\((\d+)\)|(\d+)[.、．])/);

  // 如果没有明确编号，按句号分割
  if (parts.length <= 1) {
    const sentences = cookingMethod.split(/[。；;]/).filter(s => s.trim().length > 5);
    for (let i = 0; i < sentences.length; i++) {
      const desc = sentences[i].trim();
      if (desc.length > 5) {
        // 检测是否有时间提示
        const timeMatch = desc.match(/(\d+)\s*分[钟钟]/);
        const duration = timeMatch ? parseInt(timeMatch[1]) * 60 : 0;

        steps.push({
          stepNumber: i + 1,
          description: desc,
          image: '',
          duration: duration,
          tip: '',
          needTimer: duration > 0
        });
      }
    }
  } else {
    // 按编号解析
    let currentStep = '';
    let stepNum = 1;

    for (let i = 0; i < parts.length; i++) {
      const text = parts[i];
      if (!text || /^\d+$/.test(text.trim())) continue; // 跳过纯数字（编号）

      const desc = text.trim();
      if (desc.length < 3) continue;

      // 检测时间
      const timeMatch = desc.match(/(\d+)\s*分[钟钟]/);
      const duration = timeMatch ? parseInt(timeMatch[1]) * 60 : 0;

      steps.push({
        stepNumber: stepNum++,
        description: desc,
        image: '',
        duration: duration,
        tip: '',
        needTimer: duration > 0
      });
    }
  }

  // 如果还是没解析出步骤，把整个做法作为一步
  if (steps.length === 0 && cookingMethod.length > 10) {
    steps.push({
      stepNumber: 1,
      description: cookingMethod.substring(0, 500),
      image: '',
      duration: 0,
      tip: '',
      needTimer: false
    });
  }

  return steps;
}

// 推断菜谱分类
function guessRecipeCategory(typeId, typeName) {
  const categoryMap = {
    '家常菜': '家常菜', '全荤': '荤菜', '半荤': '荤菜', '小荤': '荤菜', '素菜': '素菜',
    '汤类': '汤羹', '家常主食': '主食', '主食类': '主食', '凉菜类': '小吃', '家常凉菜': '小吃',
    '甜品及点心类': '甜品', '家常点心': '甜品', '饮料': '饮品', '保健饮品': '饮品',
    '水产类': '海鲜', '猪肉类': '荤菜', '牛羊肉类': '荤菜', '禽肉及其他肉类': '荤菜',
    '蔬菜类': '素菜', '鸡蛋及豆制品类': '素菜', '汤煲类': '汤羹',
  };
  return categoryMap[typeName] || '家常菜';
}

// 推断菜系
function guessCuisine(typeId, typeName) {
  const cuisineMap = {
    '川菜': '川菜', '粤菜': '粤菜', '湘菜': '湘菜', '鲁菜': '鲁菜',
    '苏菜': '苏菜', '浙菜': '浙菜', '闽菜': '闽菜', '徽菜': '徽菜',
    '沪菜': '苏菜', '淮扬菜': '苏菜', '京菜': '鲁菜', '东北菜': '鲁菜',
    '云南菜': '家常', '陕西菜': '家常', '湖北菜': '家常', '豫菜': '家常',
    '海派菜': '苏菜', '民族菜': '家常',
    '韩国料理': '日韩', '日本料理': '日韩', '东南亚风味': '东南亚',
    '法国菜': '西餐', '意大利菜': '西餐', '其他西餐': '西餐',
  };
  return cuisineMap[typeName] || '家常';
}

// 推断难度
function guessDifficulty(steps, method) {
  if (steps.length > 6 || (method && method.length > 500)) return '困难';
  if (steps.length > 3 || (method && method.length > 200)) return '中等';
  return '简单';
}

// 推断烹饪时间
function guessDuration(steps, method) {
  // 从步骤中提取时间
  let totalMinutes = 0;
  for (const step of steps) {
    if (step.duration > 0) {
      totalMinutes += step.duration / 60;
    }
  }
  if (totalMinutes > 0) return Math.round(totalMinutes);

  // 根据步骤数估算
  if (steps.length > 5) return 45;
  if (steps.length > 3) return 30;
  return 20;
}

function main() {
  console.log('正在读取数据库...');
  const buffer = fs.readFileSync(dbPath);
  const db = new MDBReader(buffer);

  // 读取类型树
  const typeTable = db.getTable('类型树');
  const typeData = typeTable.getData();
  const typeMap = {}; // typeId -> typeName
  for (const row of typeData) {
    typeMap[row['节点ID']] = row['类型名称'];
  }

  // 读取菜谱
  const recipeTable = db.getTable('菜谱');
  const recipeData = recipeTable.getData();
  console.log(`读取到 ${recipeData.length} 道菜谱`);

  const recipes = [];
  let skipped = 0;

  for (const row of recipeData) {
    const name = row['菜谱名称'];
    if (!name || name.trim().length === 0) {
      skipped++;
      continue;
    }

    const typeId = row['菜谱类型号'];
    const typeName = typeMap[typeId] || '家常菜';

    // 解析食材
    const ingredients = parseIngredients(row['原料'], row['调料']);
    if (ingredients.length === 0) {
      skipped++;
      continue;
    }

    // 解析步骤
    const steps = parseSteps(row['做法']);
    if (steps.length === 0) {
      skipped++;
      continue;
    }

    // 推断元信息
    const category = guessRecipeCategory(typeId, typeName);
    const cuisine = guessCuisine(typeId, typeName);
    const difficulty = guessDifficulty(steps, row['做法']);
    const duration = guessDuration(steps, row['做法']);
    const calories = ingredients.length * 35;

    recipes.push({
      name: name.trim(),
      category: category,
      cuisine: cuisine,
      difficulty: difficulty,
      duration: duration,
      servings: 2,
      calories: calories,
      description: (row['特性'] || `${name}的做法，简单易学，美味可口`).substring(0, 100),
      rating: (3.5 + Math.random() * 1.5).toFixed(1),
      author: '菜谱数据库',
      ingredients: ingredients,
      steps: steps
    });
  }

  console.log(`\n转换完成: ${recipes.length} 道菜谱 (跳过 ${skipped} 道)`);

  // 统计分类
  const categoryStats = {};
  for (const r of recipes) {
    categoryStats[r.category] = (categoryStats[r.category] || 0) + 1;
  }
  console.log('\n分类统计:');
  Object.entries(categoryStats).sort((a, b) => b[1] - a[1]).forEach(([cat, count]) => {
    console.log(`  ${cat}: ${count} 道`);
  });

  // 输出JSON
  const output = {
    convertTime: new Date().toISOString(),
    total: recipes.length,
    recipes: recipes
  };

  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`\n已保存到: ${outputPath}`);
  console.log(`文件大小: ${(fs.statSync(outputPath).size / 1024 / 1024).toFixed(2)} MB`);
}

main().catch(console.error);
