const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function migrate() {
  const connectionString = 'postgresql://postgres:Vimalvimal@666@db.ipfqnaqihgsqbbatayks.supabase.co:5432/postgres';
  
  const client = new Client({
    connectionString,
  });

  try {
    console.log('Connecting to Supabase...');
    await client.connect();
    console.log('Connected successfully!');

    const schemaPath = path.join(__dirname, '..', 'supabase_schema.sql');
    console.log(`Reading SQL from ${schemaPath}`);
    const sql = fs.readFileSync(schemaPath, 'utf8');

    console.log('Executing SQL schema...');
    await client.query(sql);
    console.log('Schema created successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await client.end();
  }
}

migrate();
