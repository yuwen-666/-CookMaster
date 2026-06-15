/**
 * 读取 Access 数据库，查看表结构和数据
 */
const { default: MDBReader } = require('mdb-reader');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', '8650c-main', '菜谱数据库(5000多种菜)', '菜谱数据库.mdb');

async function main() {
  console.log('正在读取数据库:', dbPath);
  const buffer = fs.readFileSync(dbPath);
  const db = new MDBReader(buffer);

  console.log('\n=== 表列表 ===');
  const tables = db.getTableNames();
  console.log(tables);

  // 读取每个表的前几条数据
  for (const tableName of tables) {
    console.log(`\n=== 表: ${tableName} ===`);
    const table = db.getTable(tableName);
    const columns = table.getColumnNames();
    console.log('列名:', columns);

    // 读取前3条数据
    const allData = table.getData();
    console.log('总行数:', allData.length);
    const rows = allData.slice(0, 3);
    rows.forEach((row, i) => {
      console.log(`\n--- 第 ${i + 1} 条 ---`);
      for (const [key, value] of Object.entries(row)) {
        if (value !== null && value !== undefined && value !== '') {
          const displayVal = typeof value === 'string' && value.length > 100
            ? value.substring(0, 100) + '...'
            : value;
          console.log(`  ${key}: ${displayVal}`);
        }
      }
    });
  }
}

main().catch(console.error);
