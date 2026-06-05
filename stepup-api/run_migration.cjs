const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabase = createClient(
  'https://ypadjymopdbypuneqmnb.supabase.co',
  process.env.SUPABASE_KEY
);

const filePath = process.argv[2]
  ? require('path').resolve(process.cwd(), process.argv[2])
  : '/Users/harsha/StepUp/stepup-api/migrations/011_body_vitals.sql';
const statements = fs.readFileSync(filePath, 'utf8')
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0);

async function run() {
  for (const stmt of statements) {
    const { error } = await supabase.rpc('exec', { query: stmt });
    if (error) console.error('Error on:', stmt.slice(0, 60), error.message);
    else console.log('OK:', stmt.slice(0, 60));
  }
}
run();
