const { Client } = require('pg');

async function insertSampleData() {
  const connectionString = 'postgresql://postgres.ipfqnaqihgsqbbatayks:Vimalvimal@666@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres';
  
  const client = new Client({
    connectionString,
  });

  try {
    console.log('Connecting to Supabase...');
    await client.connect();
    
    // 1. Insert a sample user
    console.log('Inserting sample user...');
    const insertUserQuery = `
      INSERT INTO users (id, email, display_name, household_id) 
      VALUES ($1, $2, $3, $4) 
      ON CONFLICT (id) DO NOTHING
      RETURNING *;
    `;
    const userResult = await client.query(insertUserQuery, [
      'user-vimal-001', 
      'vimal.test@example.com', 
      'Vimal (Test User)', 
      'household-test-1'
    ]);
    if (userResult.rows.length > 0) {
       console.log('✅ Added User:', userResult.rows[0].display_name);
    } else {
       console.log('✅ User already exists.');
    }

    // 2. Insert a sample category linked to that household
    console.log('Inserting sample category...');
    const insertCategoryQuery = `
      INSERT INTO categories (id, household_id, kind, name, is_deduction) 
      VALUES ($1, $2, $3, $4, $5) 
      ON CONFLICT (id) DO NOTHING
      RETURNING *;
    `;
    const categoryResult = await client.query(insertCategoryQuery, [
      'cat-groceries-001', 
      'household-test-1', 
      'expense', 
      'Groceries', 
      true
    ]);
    if (categoryResult.rows.length > 0) {
       console.log('✅ Added Category:', categoryResult.rows[0].name);
    } else {
       console.log('✅ Category already exists.');
    }

    console.log('\n🎉 Sample data inserted successfully and will remain in Supabase!');
  } catch (error) {
    console.error('❌ Insertion failed:', error);
  } finally {
    await client.end();
  }
}

insertSampleData();
