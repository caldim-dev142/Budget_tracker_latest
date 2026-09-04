const { Client } = require('pg');

async function testConnection() {
  // Using the exact IPv4 Pooler URL provided by the user
  const connectionString = 'postgresql://postgres.ipfqnaqihgsqbbatayks:Vimalvimal@666@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres';
  
  const client = new Client({
    connectionString,
  });

  try {
    console.log('Connecting to Supabase (IPv4 Pooler)...');
    await client.connect();
    console.log('✅ Connected successfully!');

    // 1. Insert a sample user
    console.log('\n--- 1. Testing INSERT ---');
    const insertQuery = `
      INSERT INTO users (id, email, display_name, household_id) 
      VALUES ($1, $2, $3, $4) 
      RETURNING *;
    `;
    const insertResult = await client.query(insertQuery, [
      'sample-uuid-1234', 
      'test@example.com', 
      'Test User', 
      'household-1'
    ]);
    console.log('✅ Inserted sample user:', insertResult.rows[0]);

    // 2. Query the user back
    console.log('\n--- 2. Testing SELECT ---');
    const selectQuery = `SELECT * FROM users WHERE id = $1;`;
    const selectResult = await client.query(selectQuery, ['sample-uuid-1234']);
    console.log('✅ Retrieved sample user:', selectResult.rows[0]);

    // 3. Delete the sample user
    console.log('\n--- 3. Testing DELETE (Cleanup) ---');
    const deleteQuery = `DELETE FROM users WHERE id = $1 RETURNING *;`;
    const deleteResult = await client.query(deleteQuery, ['sample-uuid-1234']);
    console.log('✅ Deleted sample user:', deleteResult.rows[0].id);

    console.log('\n🎉 Connection and Database Verification 100% Successful!');
  } catch (error) {
    console.error('❌ Database operation failed:', error);
  } finally {
    await client.end();
  }
}

testConnection();
