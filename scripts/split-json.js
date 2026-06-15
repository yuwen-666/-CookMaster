/**
 * 将大 JSON 文件拆分成多个小文件
 * 避免移动端 OOM
 */
const fs = require('fs');
const path = require('path');

const inputFile = path.join(__dirname, 'recipes-data.json');
const outputDir = path.join(__dirname, '..', 'entry', 'src', 'main', 'resources', 'rawfile');

console.log('正在读取数据...');
const data = JSON.parse(fs.readFileSync(inputFile, 'utf-8'));
const recipes = data.recipes;
console.log(`总菜谱数: ${recipes.length}`);

// 每个文件 300 道菜谱
const batchSize = 300;
const batches = Math.ceil(recipes.length / batchSize);

console.log(`拆分成 ${batches} 个文件，每个 ${batchSize} 道`);

for (let i = 0; i < batches; i++) {
  const start = i * batchSize;
  const end = Math.min(start + batchSize, recipes.length);
  const batch = recipes.slice(start, end);

  const output = {
    batch: i + 1,
    total: recipes.length,
    recipes: batch
  };

  const filename = `recipes_batch_${i + 1}.json`;
  const filepath = path.join(outputDir, filename);

  fs.writeFileSync(filepath, JSON.stringify(output), 'utf-8');
  const size = (fs.statSync(filepath).size / 1024).toFixed(1);
  console.log(`  ${filename}: ${batch.length} 道菜谱 (${size} KB)`);
}

console.log('\n拆分完成！');
console.log(`输出目录: ${outputDir}`);
