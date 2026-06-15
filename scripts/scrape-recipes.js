/**
 * 下厨房菜谱爬虫脚本
 * 从 xiachufang.com 爬取菜谱数据（含食材、烹饪步骤）
 * 输出为 JSON 格式，供 CookMaster App 导入
 */

const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  baseUrl: 'https://www.xiachufang.com',
  // 下厨房分类页面
  categories: [
    { name: '家常菜', url: '/category/40076/' },
    { name: '素菜', url: '/category/40077/' },
    { name: '荤菜', url: '/category/40078/' },
    { name: '汤羹', url: '/category/40079/' },
    { name: '主食', url: '/category/40080/' },
    { name: '甜品', url: '/category/40081/' },
    { name: '早餐', url: '/category/40082/' },
    { name: '小吃', url: '/category/40083/' },
    { name: '饮品', url: '/category/40084/' },
    { name: '海鲜', url: '/category/40256/' },
  ],
  // 每个分类爬取的页数（每页约20道菜谱）
  pagesPerCategory: 12,
  // 请求间隔（毫秒）
  requestDelay: 1500,
  // 输出文件
  outputFile: path.join(__dirname, 'recipes-data.json'),
  // 请求头
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
  }
};

// 已爬取的菜谱URL集合（去重用）
const scrapedUrls = new Set();
// 所有菜谱数据
const allRecipes = [];

/**
 * 延迟函数
 */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 带重试的请求
 */
async function fetchWithRetry(url, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await axios.get(url, {
        headers: CONFIG.headers,
        timeout: 15000,
      });
      return response.data;
    } catch (error) {
      console.warn(`  请求失败 (尝试 ${i + 1}/${retries}): ${url} - ${error.message}`);
      if (i < retries - 1) {
        await delay(3000);
      }
    }
  }
  return null;
}

/**
 * 从分类页面获取菜谱详情页链接
 */
async function getRecipeLinksFromCategory(categoryUrl, page) {
  const url = `${CONFIG.baseUrl}${categoryUrl}?page=${page}`;
  console.log(`  获取分类页: ${url}`);

  const html = await fetchWithRetry(url);
  if (!html) return [];

  const $ = cheerio.load(html);
  const links = [];

  // 下厨房分类页的菜谱链接在 .recipe 类下的 a 标签中
  $('div.recipe a.cover, li.recipe a.cover, a[href*="/recipe/"]').each((i, el) => {
    const href = $(el).attr('href');
    if (href && href.includes('/recipe/')) {
      const fullUrl = href.startsWith('http') ? href : CONFIG.baseUrl + href;
      if (!scrapedUrls.has(fullUrl)) {
        links.push(fullUrl);
      }
    }
  });

  return [...new Set(links)];
}

/**
 * 解析食材分类
 */
function guessIngredientCategory(name) {
  const vegs = ['白菜', '青菜', '菠菜', '生菜', '芹菜', '韭菜', '蒜苗', '豆芽', '土豆', '番茄', '西红柿',
    '黄瓜', '茄子', '辣椒', '青椒', '洋葱', '萝卜', '胡萝卜', '南瓜', '冬瓜', '丝瓜', '苦瓜', '豆角',
    '蘑菇', '香菇', '金针菇', '木耳', '玉米', '西兰花', '花菜', '藕', '山药', '芋头', '豆腐', '豆皮',
    '毛豆', '荷兰豆', '秋葵', '莴笋', '竹笋', '芦笋', '香菜', '葱', '姜', '蒜', '薄荷', '紫苏',
    '西葫芦', '油麦菜', '空心菜', '苋菜', '荠菜', '香椿', '蕨菜', '海带', '紫菜', '裙带菜'];
  const meats = ['猪肉', '牛肉', '羊肉', '鸡肉', '鸭肉', '排骨', '五花肉', '里脊', '肉末', '肉丝', '肉片',
    '鸡胸', '鸡翅', '鸡腿', '鸡爪', '鸭腿', '培根', '腊肉', '香肠', '火腿', '午餐肉', '牛腩', '肥牛',
    '猪蹄', '肘子', '猪肝', '猪肚', '鸡肝', '鹅'];
  const seafood = ['鱼', '虾', '蟹', '贝', '蛤', '鱿鱼', '墨鱼', '章鱼', '龙虾', '三文鱼', '鲈鱼', '鲫鱼',
    '草鱼', '鲤鱼', '带鱼', '黄鱼', '鳕鱼', '金枪鱼', '海参', '鲍鱼', '扇贝', '生蚝', '海螺', '皮皮虾'];
  const dairy = ['鸡蛋', '鸭蛋', '鹌鹑蛋', '牛奶', '酸奶', '奶酪', '芝士', '黄油', '奶油', '炼乳', '淡奶'];
  const staples = ['米', '饭', '面条', '面粉', '饺子', '馒头', '面包', '年糕', '粉丝', '粉条', '河粉',
    '米粉', '意面', '通心粉', '燕麦', '糯米', '小米', '红豆', '绿豆', '黑豆', '黄豆', '花生', '芝麻'];
  const seasonings = ['盐', '糖', '醋', '酱油', '生抽', '老抽', '蚝油', '料酒', '味精', '鸡精', '胡椒',
    '花椒', '八角', '桂皮', '香叶', '辣椒粉', '花椒粉', '五香粉', '十三香', '番茄酱', '豆瓣酱',
    '甜面酱', '芝麻酱', '沙拉酱', '蜂蜜', '淀粉', '面粉', '面包糠', '酵母', '小苏打', '泡打粉',
    '食用油', '橄榄油', '花生油', '菜籽油', '香油', '辣椒油', '咖喱', '椰浆', '椰奶', '可乐', '啤酒'];

  const n = name.toLowerCase();
  if (vegs.some(v => n.includes(v))) return '蔬菜';
  if (meats.some(v => n.includes(v))) return '肉类';
  if (seafood.some(v => n.includes(v))) return '海鲜';
  if (dairy.some(v => n.includes(v))) return '蛋奶';
  if (staples.some(v => n.includes(v))) return '主食';
  if (seasonings.some(v => n.includes(v))) return '调料';
  return '蔬菜'; // 默认归类为蔬菜
}

/**
 * 猜测菜谱分类和菜系
 */
function guessCategoryAndCuisine(name, description) {
  const text = (name + ' ' + description).toLowerCase();
  let category = '家常菜';
  let cuisine = '家常';

  // 分类判断
  if (text.includes('汤') || text.includes('羹') || text.includes('煲')) category = '汤羹';
  else if (text.includes('甜') || text.includes('蛋糕') || text.includes('饼') || text.includes('酥') || text.includes('派')) category = '甜品';
  else if (text.includes('饮') || text.includes('汁') || text.includes('茶') || text.includes('奶') || text.includes('冰')) category = '饮品';
  else if (text.includes('早') || text.includes('粥')) category = '早餐';
  else if (text.includes('小吃') || text.includes('零食') || text.includes('零食')) category = '小吃';
  else if (text.includes('面') || text.includes('饭') || text.includes('饺') || text.includes('馒头') || text.includes('饼')) category = '主食';
  else if (text.includes('虾') || text.includes('蟹') || text.includes('鱼') || text.includes('海鲜') || text.includes('贝')) category = '海鲜';

  // 菜系判断
  if (text.includes('川') || text.includes('辣') || text.includes('麻') || text.includes('花椒')) cuisine = '川菜';
  else if (text.includes('粤') || text.includes('广式') || text.includes('煲仔') || text.includes('蒸')) cuisine = '粤菜';
  else if (text.includes('湘') || text.includes('湖南')) cuisine = '湘菜';
  else if (text.includes('鲁') || text.includes('山东')) cuisine = '鲁菜';
  else if (text.includes('苏') || text.includes('淮扬') || text.includes('扬州')) cuisine = '苏菜';
  else if (text.includes('浙') || text.includes('杭州')) cuisine = '浙菜';
  else if (text.includes('闽') || text.includes('福建') || text.includes('沙茶')) cuisine = '闽菜';
  else if (text.includes('徽') || text.includes('安徽')) cuisine = '徽菜';
  else if (text.includes('西') || text.includes('牛排') || text.includes('意面') || text.includes('沙拉')) cuisine = '西餐';
  else if (text.includes('日') || text.includes('寿司') || text.includes('刺身') || text.includes('韩') || text.includes('泡菜')) cuisine = '日韩';

  return { category, cuisine };
}

/**
 * 从详情页解析菜谱数据
 */
async function parseRecipeDetail(recipeUrl) {
  if (scrapedUrls.has(recipeUrl)) return null;
  scrapedUrls.add(recipeUrl);

  const html = await fetchWithRetry(recipeUrl);
  if (!html) return null;

  const $ = cheerio.load(html);

  try {
    // 菜谱名称
    const name = $('h1.recipe-title, .recipe-name, h1').first().text().trim();
    if (!name) {
      console.warn(`  未找到菜名: ${recipeUrl}`);
      return null;
    }

    // 描述
    const description = $('.recipe-desc, .recipe-summary, [class*="desc"]').first().text().trim()
      || `${name}的做法，简单易学，美味可口`;

    // 评分（下厨房有"做过"人数，转换为评分）
    const cookedText = $('.cooked-num, [class*="cooked"], [class*="做过"]').text();
    const cookedNum = parseInt(cookedText.replace(/[^\d]/g, '')) || 0;
    const rating = Math.min(5, 3.5 + Math.log10(cookedNum + 1) * 0.3);

    // 烹饪时间
    const timeText = $('[class*="time"], [class*="时间"]').text();
    const timeMatch = timeText.match(/(\d+)/);
    const duration = timeMatch ? parseInt(timeMatch[1]) : 30;

    // 份量
    const servingsText = $('[class*="quant"], [class*="份量"], [class*="人份"]').text();
    const servingsMatch = servingsText.match(/(\d+)/);
    const servings = servingsMatch ? parseInt(servingsMatch[1]) : 2;

    // 食材列表
    const ingredients = [];
    // 下厨房食材在 .ingredient 或 table 中
    $('table.ingredientt tr, .recipe-ingredients li, [class*="ingredient"] li, [class*="材料"] li').each((i, el) => {
      const text = $(el).text().trim();
      if (!text) return;
      // 格式通常是 "食材名  用量"
      const parts = text.split(/\s{2,}|\t/);
      if (parts.length >= 2) {
        ingredients.push({
          name: parts[0].trim(),
          category: guessIngredientCategory(parts[0]),
          amount: parts[1].trim(),
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          image: '',
        });
      } else if (text.length < 30) {
        // 可能只有名称没有用量
        ingredients.push({
          name: text,
          category: guessIngredientCategory(text),
          amount: '适量',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          image: '',
        });
      }
    });

    // 烹饪步骤
    const steps = [];
    // 下厨房步骤在 .step 或 .recipe-step 中
    $('.recipe-step li, [class*="step"] li, .step ol li, [class*="步骤"] li').each((i, el) => {
      const desc = $(el).find('p, .text, [class*="desc"]').text().trim() || $(el).text().trim();
      if (desc && desc.length > 2) {
        // 检查是否有时长信息
        const stepTimeMatch = desc.match(/(\d+)\s*分[钟钟]/);
        const stepDuration = stepTimeMatch ? parseInt(stepTimeMatch[1]) * 60 : 0;

        steps.push({
          stepNumber: steps.length + 1,
          description: desc.replace(/^\d+[.、]?\s*/, '').substring(0, 200),
          image: '',
          duration: stepDuration,
          tip: '',
          needTimer: stepDuration > 0,
        });
      }
    });

    // 封面图片
    const coverImage = $('img[class*="cover"], .recipe-photo img, [class*="main-photo"] img').first().attr('src') || '';

    // 推测分类和菜系
    const { category, cuisine } = guessCategoryAndCuisine(name, description);

    // 推测难度
    let difficulty = '简单';
    if (steps.length > 6 || duration > 60) difficulty = '困难';
    else if (steps.length > 3 || duration > 30) difficulty = '中等';

    // 估算热量
    const calories = ingredients.length * 40;

    return {
      name,
      category,
      cuisine,
      difficulty,
      duration,
      servings,
      calories,
      description: description.substring(0, 200),
      rating: Math.round(rating * 10) / 10,
      coverImage,
      ingredients,
      steps,
    };
  } catch (error) {
    console.warn(`  解析失败: ${recipeUrl} - ${error.message}`);
    return null;
  }
}

/**
 * 主函数
 */
async function main() {
  console.log('=== 下厨房菜谱爬虫 ===');
  console.log(`目标: 每个分类爬取 ${CONFIG.pagesPerCategory} 页`);
  console.log(`分类数: ${CONFIG.categories.length}`);
  console.log('');

  for (const category of CONFIG.categories) {
    console.log(`\n--- 开始爬取分类: ${category.name} ---`);
    let categoryCount = 0;

    for (let page = 1; page <= CONFIG.pagesPerCategory; page++) {
      const links = await getRecipeLinksFromCategory(category.url, page);
      console.log(`  第 ${page} 页: 找到 ${links.length} 个菜谱链接`);

      if (links.length === 0) {
        console.log(`  第 ${page} 页无更多数据，跳过后续页`);
        break;
      }

      for (const link of links) {
        if (allRecipes.length >= 1200) {
          console.log(`\n已达到目标数量 1200，停止爬取`);
          break;
        }

        const recipe = await parseRecipeDetail(link);
        if (recipe && recipe.ingredients.length > 0 && recipe.steps.length > 0) {
          allRecipes.push(recipe);
          categoryCount++;
          console.log(`  [${allRecipes.length}] ✓ ${recipe.name} (${recipe.ingredients.length}种食材, ${recipe.steps.length}步)`);
        } else if (recipe) {
          console.log(`  ✗ ${recipe.name} - 食材或步骤为空，跳过`);
        }

        await delay(CONFIG.requestDelay);
      }

      if (allRecipes.length >= 1200) break;
      await delay(CONFIG.requestDelay);
    }

    console.log(`分类 ${category.name} 完成: ${categoryCount} 道菜谱`);
    if (allRecipes.length >= 1200) break;
  }

  // 输出结果
  console.log(`\n=== 爬取完成 ===`);
  console.log(`总计: ${allRecipes.length} 道菜谱`);

  const output = {
    scrapeTime: new Date().toISOString(),
    total: allRecipes.length,
    recipes: allRecipes,
  };

  fs.writeFileSync(CONFIG.outputFile, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`已保存到: ${CONFIG.outputFile}`);

  // 统计信息
  const categories = {};
  allRecipes.forEach(r => {
    categories[r.category] = (categories[r.category] || 0) + 1;
  });
  console.log('\n分类统计:');
  Object.entries(categories).sort((a, b) => b[1] - a[1]).forEach(([cat, count]) => {
    console.log(`  ${cat}: ${count} 道`);
  });
}

main().catch(console.error);
