"""
将 caipu_1.csv 转换为 CookMaster 项目使用的 batch JSON 格式
"""
import csv
import io
import json
import os
import re

# 常见食材营养数据库 [calories, protein, carbs, fat] per 100g
NUTRITION_DB = {
    # 肉类
    '猪肉': [242, 13.2, 2.4, 20.6], '五花肉': [395, 14.0, 2.4, 37.0],
    '瘦肉': [143, 20.3, 1.5, 6.2], '肉末': [295, 17.0, 1.0, 25.0],
    '猪肉末': [295, 17.0, 1.0, 25.0], '牛肉': [125, 19.9, 2.0, 4.2],
    '牛腩': [330, 17.1, 0, 29.5], '羊肉': [203, 19.0, 3.9, 14.1],
    '鸡胸肉': [133, 31.0, 0.5, 1.2], '鸡肉': [167, 19.3, 2.5, 9.4],
    '鸡翅': [222, 17.4, 4.6, 16.4], '鸡腿': [181, 16.0, 0, 13.0],
    '鸭肉': [240, 15.5, 0.2, 19.7], '排骨': [264, 18.1, 1.0, 20.4],
    '腊肉': [498, 11.8, 2.6, 48.8], '火腿': [212, 16.0, 4.9, 14.4],
    '培根': [533, 12.0, 1.5, 54.0], '午餐肉': [247, 12.5, 5.0, 20.0],
    '香肠': [508, 24.1, 1.1, 45.3],
    # 海鲜
    '鱼': [104, 18.0, 0, 3.6], '鲈鱼': [105, 18.6, 0, 3.4],
    '鲫鱼': [91, 17.1, 3.8, 1.3], '草鱼': [113, 16.6, 0, 5.2],
    '带鱼': [127, 17.7, 3.1, 4.9], '三文鱼': [139, 17.2, 0, 7.8],
    '虾': [87, 16.8, 1.5, 2.2], '虾仁': [48, 10.4, 0, 0.7],
    '螃蟹': [95, 13.8, 4.7, 2.3], '鱿鱼': [75, 17.0, 1.6, 0.8],
    '蛤蜊': [62, 10.1, 4.5, 1.1], '扇贝': [69, 12.6, 3.2, 0.5],
    '海参': [55, 16.5, 0.5, 0.2], '鲍鱼': [84, 17.0, 6.0, 0.8],
    # 蛋奶
    '鸡蛋': [144, 13.3, 1.5, 8.8], '蛋': [144, 13.3, 1.5, 8.8],
    '蛋清': [47, 11.6, 0.8, 0.1], '蛋黄': [322, 15.2, 3.4, 28.2],
    '牛奶': [54, 3.0, 3.4, 3.2], '酸奶': [72, 2.5, 9.3, 2.7],
    '奶酪': [328, 25.7, 3.5, 23.5], '黄油': [735, 0.5, 0.1, 81.0],
    '奶油': [345, 2.0, 3.6, 35.0],
    # 蔬菜
    '番茄': [18, 0.9, 3.9, 0.2], '西红柿': [18, 0.9, 3.9, 0.2],
    '土豆': [76, 2.0, 17.5, 0.1], '黄瓜': [15, 0.7, 2.9, 0.2],
    '茄子': [21, 1.1, 4.9, 0.1], '白菜': [13, 1.0, 2.2, 0.1],
    '青菜': [15, 1.5, 2.4, 0.3], '菠菜': [24, 2.6, 4.5, 0.3],
    '韭菜': [26, 2.4, 4.6, 0.4], '芹菜': [14, 0.8, 3.0, 0.1],
    '花菜': [24, 2.1, 4.6, 0.2], '菜花': [24, 2.1, 4.6, 0.2],
    '西兰花': [36, 4.1, 4.3, 0.6], '胡萝卜': [37, 1.0, 8.8, 0.2],
    '萝卜': [21, 0.9, 5.0, 0.1], '洋葱': [39, 1.1, 9.0, 0.1],
    '青椒': [20, 0.9, 4.6, 0.2], '红椒': [31, 1.0, 6.0, 0.3],
    '辣椒': [29, 1.3, 5.7, 0.4], '干辣椒': [281, 12.0, 50.0, 12.0],
    '大蒜': [126, 4.5, 27.6, 0.2], '蒜': [126, 4.5, 27.6, 0.2],
    '姜': [41, 1.3, 8.0, 0.7], '葱': [30, 1.6, 6.5, 0.3],
    '蘑菇': [20, 2.7, 3.3, 0.4], '香菇': [211, 20.0, 30.1, 3.3],
    '金针菇': [32, 2.4, 6.0, 0.4], '木耳': [205, 12.1, 35.7, 1.5],
    '豆芽': [31, 3.0, 5.2, 0.1], '豆腐': [73, 8.1, 4.2, 3.5],
    '嫩豆腐': [55, 5.0, 2.8, 2.5], '豆皮': [409, 44.6, 12.5, 17.4],
    '腐竹': [459, 44.6, 12.5, 21.7], '毛豆': [131, 13.0, 8.5, 5.0],
    '玉米': [106, 4.0, 22.8, 1.2], '玉米粒': [106, 4.0, 22.8, 1.2],
    '南瓜': [22, 0.7, 5.3, 0.1], '冬瓜': [11, 0.3, 2.4, 0.2],
    '莲藕': [70, 1.9, 15.2, 0.2], '山药': [56, 1.9, 12.4, 0.1],
    # 主食
    '米饭': [116, 2.6, 25.9, 0.3], '面条': [286, 8.3, 61.9, 0.7],
    '面粉': [344, 11.2, 73.6, 1.5], '馒头': [223, 7.0, 44.2, 1.1],
    '面包': [312, 8.3, 58.1, 5.1], '年糕': [154, 3.3, 34.7, 0.2],
    '粉丝': [338, 0.8, 82.6, 0.1], '粉条': [338, 0.8, 82.6, 0.1],
    '大米': [346, 7.4, 77.9, 0.8], '糯米': [348, 7.3, 78.3, 1.0],
    # 调料
    '盐': [0, 0, 0, 0], '糖': [387, 0, 99.9, 0],
    '白糖': [387, 0, 99.9, 0], '冰糖': [387, 0, 99.9, 0],
    '酱油': [53, 5.6, 7.9, 0.1], '生抽': [53, 5.6, 7.9, 0.1],
    '老抽': [53, 5.6, 7.9, 0.1], '醋': [31, 2.1, 4.9, 0.1],
    '料酒': [67, 1.6, 5.0, 0], '蚝油': [110, 3.5, 20.0, 1.5],
    '豆瓣酱': [178, 7.3, 20.1, 7.8], '番茄酱': [82, 1.6, 16.7, 0.2],
    '芝麻酱': [618, 17.0, 16.0, 52.7], '花生酱': [600, 25.0, 20.0, 50.0],
    '味精': [268, 40.0, 33.0, 0], '鸡精': [195, 15.0, 25.0, 3.0],
    '胡椒粉': [345, 9.6, 64.8, 3.3], '花椒': [258, 6.7, 37.8, 8.9],
    '八角': [255, 3.8, 50.0, 5.6], '桂皮': [253, 3.8, 48.5, 3.2],
    '孜然': [375, 17.8, 44.2, 22.0], '辣椒粉': [281, 12.0, 50.0, 12.0],
    '咖喱': [325, 13.0, 58.0, 14.0], '咖喱块': [480, 5.0, 30.0, 38.0],
    # 坚果
    '花生': [567, 25.8, 16.1, 49.2], '花生米': [567, 25.8, 16.1, 49.2],
    '核桃': [654, 14.9, 13.7, 58.8], '芝麻': [559, 18.4, 21.7, 48.0],
    # 油脂
    '食用油': [884, 0, 0, 100], '花生油': [884, 0, 0, 100],
    '菜籽油': [884, 0, 0, 100], '橄榄油': [884, 0, 0, 100],
    '香油': [884, 0, 0, 100],
    # 淀粉
    '淀粉': [350, 0.5, 85.0, 0.1], '玉米淀粉': [350, 0.5, 85.0, 0.1],
    # 饮品
    '可乐': [42, 0, 10.6, 0], '蜂蜜': [321, 0.3, 82.3, 0],
    # 水果
    '苹果': [52, 0.3, 13.8, 0.2], '柠檬': [29, 1.1, 9.3, 0.3],
    '红枣': [264, 3.2, 67.8, 0.5], '枸杞': [258, 13.9, 47.2, 1.5],
}

def lookup_nutrition(name: str):
    """查找食材营养数据"""
    # 精确匹配
    if name in NUTRITION_DB:
        return NUTRITION_DB[name]
    # 模糊匹配
    for key, val in NUTRITION_DB.items():
        if key in name or name in key:
            return val
    return None

CSV_PATH = os.path.join(os.path.dirname(__file__), 'capu_data_5w', 'caipu_1.csv')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'CookMaster', 'entry', 'src', 'main', 'resources', 'rawfile')
BATCH_SIZE = 500  # 每批500条

# 难度映射
DIFFICULTY_MAP = {
    '0': '简单',
    '1': '简单',
    '2': '中等',
    '3': '困难',
}

# 时长解析
def parse_duration(costtime: str) -> int:
    """从 '10-30分钟' 或 '10分钟左右' 解析出分钟数"""
    if not costtime:
        return 30
    nums = re.findall(r'\d+', costtime)
    if not nums:
        return 30
    if len(nums) >= 2:
        return (int(nums[0]) + int(nums[1])) // 2
    return int(nums[0])

# 分类映射
CATEGORY_MAP = {
    '家常菜': '家常菜',
    '素菜': '素菜',
    '荤菜': '荤菜',
    '汤羹': '汤羹',
    '主食': '主食',
    '甜品': '甜品',
    '早餐': '早餐',
    '小吃': '小吃',
    '饮品': '饮品',
    '海鲜': '海鲜',
    '凉菜': '凉菜',
    '烘焙': '烘焙',
}

def guess_category(cid: str, zid: str, title: str) -> str:
    """从 cid/zid 字段猜测分类"""
    all_text = (cid + ',' + zid + ',' + title).replace('\n', ',')
    for key in CATEGORY_MAP:
        if key in all_text:
            return key
    return '家常菜'

def parse_steps(steptext: str, steppic: str) -> list:
    """解析步骤文本和图片"""
    steps = []
    # 步骤文本用 # 分割
    step_lines = [s.strip() for s in steptext.split('#') if s.strip()]
    # 步骤图片用 # 分割
    pic_lines = [p.strip() for p in steppic.split('#') if p.strip()]

    for i, desc in enumerate(step_lines):
        # 去掉步骤编号前缀如 "1. " "2. "
        desc_clean = re.sub(r'^\d+[\.\、\s]+', '', desc).strip()
        if not desc_clean:
            continue

        step = {
            'stepNumber': i + 1,
            'description': desc_clean,
            'image': pic_lines[i] if i < len(pic_lines) else '',
            'duration': 0,
            'tip': '',
            'needTimer': False
        }
        steps.append(step)

    return steps

def parse_ingredients(yl: str, fl: str) -> list:
    """解析食材和用量，并自动填充营养数据"""
    ingredients = []
    names = [s.strip() for s in yl.split('#') if s.strip()]
    amounts = [s.strip() for s in fl.split('#') if s.strip()]

    for i, name in enumerate(names):
        amount = amounts[i] if i < len(amounts) else ''
        # 查找营养数据
        nutrition = lookup_nutrition(name)
        ingredient = {
            'name': name,
            'category': '',
            'amount': amount,
            'calories': nutrition[0] if nutrition else 0,
            'protein': nutrition[1] if nutrition else 0,
            'carbs': nutrition[2] if nutrition else 0,
            'fat': nutrition[3] if nutrition else 0,
            'image': ''
        }
        ingredients.append(ingredient)

    return ingredients

def convert_row(row: list) -> dict | None:
    """将一行CSV数据转换为菜谱JSON对象"""
    if len(row) < 21:
        return None

    recipe_id = row[0]
    title = row[4].strip()
    thumb = row[5].strip()
    videourl = row[6].strip()
    desc = row[7].strip()
    difficulty = row[8].strip()
    costtime = row[9].strip()
    tip = row[10].strip()
    yl = row[11].strip()  # 食材
    fl = row[12].strip()  # 用量
    steptext = row[13].strip()
    steppic = row[14].strip()
    grade = row[15].strip()
    viewnum = row[17].strip()
    favnum = row[18].strip()
    cid = row[2].strip()
    zid = row[3].strip()

    if not title:
        return None

    # 解析步骤
    steps = parse_steps(steptext, steppic)
    if not steps:
        return None  # 没有步骤的跳过

    # 解析食材
    ingredients = parse_ingredients(yl, fl)

    # 确定分类
    category = guess_category(cid, zid, title)

    # 解析难度
    diff_str = DIFFICULTY_MAP.get(difficulty, '简单')

    # 解析时长
    duration = parse_duration(costtime)

    # 解析评分
    try:
        rating = float(grade) if grade else 4.5
        if rating > 5:
            rating = 5.0
        if rating < 1:
            rating = 4.5
    except:
        rating = 4.5

    recipe = {
        'name': title,
        'coverImage': thumb,
        'category': category,
        'cuisine': zid if zid else '家常',
        'difficulty': diff_str,
        'duration': duration,
        'servings': 2,
        'calories': 200,
        'description': desc if desc else f'{title}的做法',
        'rating': rating,
        'viewCount': int(viewnum) if viewnum.isdigit() else 0,
        'favoriteCount': int(favnum) if favnum.isdigit() else 0,
        'videoUrl': videourl,
        'author': '豆果美食',
        'ingredients': ingredients,
        'steps': steps
    }

    return recipe

def main():
    print(f'读取CSV: {CSV_PATH}')
    print(f'输出目录: {OUTPUT_DIR}')

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    batch_num = 1
    batch_recipes = []
    total_imported = 0
    total_skipped = 0

    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # 跳过表头
        print(f'表头: {header}')

        for i, row in enumerate(reader):
            recipe = convert_row(row)
            if recipe:
                batch_recipes.append(recipe)
                total_imported += 1
            else:
                total_skipped += 1

            # 每 BATCH_SIZE 条写一个文件
            if len(batch_recipes) >= BATCH_SIZE:
                output_path = os.path.join(OUTPUT_DIR, f'recipes_batch_{batch_num}.json')
                batch_data = {
                    'batch': batch_num,
                    'total': len(batch_recipes),
                    'recipes': batch_recipes
                }
                with open(output_path, 'w', encoding='utf-8') as out_f:
                    json.dump(batch_data, out_f, ensure_ascii=False)
                print(f'  批次 {batch_num}: {len(batch_recipes)} 条 -> {output_path}')
                batch_num += 1
                batch_recipes = []

            if (i + 1) % 5000 == 0:
                print(f'  已处理 {i + 1} 行, 导入 {total_imported}, 跳过 {total_skipped}')

    # 写最后一批
    if batch_recipes:
        output_path = os.path.join(OUTPUT_DIR, f'recipes_batch_{batch_num}.json')
        batch_data = {
            'batch': batch_num,
            'total': len(batch_recipes),
            'recipes': batch_recipes
        }
        with open(output_path, 'w', encoding='utf-8') as out_f:
            json.dump(batch_data, out_f, ensure_ascii=False)
        print(f'  批次 {batch_num}: {len(batch_recipes)} 条 -> {output_path}')

    print(f'\n转换完成!')
    print(f'  总导入: {total_imported} 条')
    print(f'  总跳过: {total_skipped} 条')
    print(f'  批次数: {batch_num}')

if __name__ == '__main__':
    main()
