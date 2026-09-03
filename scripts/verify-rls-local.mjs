/**
 * 本地 RLS 验证（T-0104 DoD）—— 使用 PGlite（WASM PostgreSQL）替代 psql/bash。
 * 等价 scripts/verify-rls.sh 的全部断言，用于无 Docker/psql 环境的本地冒烟。
 * 运行：node scripts/verify-rls-local.mjs
 */
import { PGlite } from "@electric-sql/pglite";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const fail = (msg) => { console.error(`FAIL: ${msg}`); process.exit(1); };
const ok = (msg) => console.log(`OK:   ${msg}`);

const PROBE_ROLE = "rls_probe";
const PROBE_ITEM = "00000000-0000-0000-0000-000000000001";
const OTHER_ID = "11111111-1111-4111-8111-111111111111";

console.log("=== T-0104 Smoke Test: Migration + RLS Verification (PGlite) ===\n");

// --- 0) Apply migration (equivalent to supabase db reset) ---
console.log("Step 0: Applying migration 0001_core_tables_rls_seed.sql...");
const sqlPath = join(__dirname, "..", "db", "migrations", "0001_core_tables_rls_seed.sql");
const sql = readFileSync(sqlPath, "utf-8");
const pg = new PGlite();
await pg.exec(sql);
ok("Migration applied (db reset OK)\n");

// --- 1) seed unique student ---
let res = await pg.query("SELECT count(*)::text as n FROM users WHERE role = 'student'");
if (res.rows[0].n !== "1") fail(`seed student count=${res.rows[0].n}, expected 1`);
res = await pg.query("SELECT id::text FROM users WHERE role = 'student' LIMIT 1");
const SEED_ID = res.rows[0].id;
ok(`seed unique student: ${SEED_ID}`);

// --- 2) All core tables RLS enabled ---
res = await pg.query(`
  SELECT count(*)::text as n FROM pg_tables t
  WHERE t.schemaname='public' AND t.tablename IN (
    'users','units','lessons','chunks','vocab','chunk_review',
    'grammar_points','videos','problem_logs','speaking_submissions',
    'writing_submissions','anchor_submissions','portfolio_items',
    'streaks','ai_call_logs','prompt_templates'
  ) AND NOT t.rowsecurity
`);
if (res.rows[0].n !== "0") fail(`${res.rows[0].n} tables without RLS`);
ok("All core tables (DB-01~DB-15) have RLS enabled");

// --- 3) Idempotent unique constraints ---
res = await pg.query(`
  SELECT count(*)::text as n FROM pg_constraint
  WHERE conname IN ('uq_chunks_unit_item','uq_vocab_unit_item','uq_videos_youtube_id')
`);
if (res.rows[0].n !== "3") fail(`unique constraints found ${res.rows[0].n}/3`);
ok("Idempotent unique constraints: chunks/vocab (unit_no,item_no), videos (youtube_id)");

// --- 3.5) Create probe role ---
await pg.exec(`CREATE ROLE ${PROBE_ROLE}`);
await pg.exec(`GRANT USAGE ON SCHEMA public TO ${PROBE_ROLE}`);
await pg.exec(`GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${PROBE_ROLE}`);
ok(`Probe role ${PROBE_ROLE} created (subject to RLS)`);

// --- 4) seed context can read/write own records ---
await pg.exec(`SET app.seed_student_id = '${SEED_ID}'`);
await pg.exec(`SET ROLE ${PROBE_ROLE}`);
await pg.query(
  `INSERT INTO chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) ` +
  `VALUES ('${SEED_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now() + interval '1 day')`
);
res = await pg.query("SELECT count(*)::text as n FROM chunk_review");
if (res.rows[0].n !== "1") fail(`seed context read failed (count=${res.rows[0].n})`);
ok("seed context can write and read own records");

// --- 5) Non-seed ID write rejected ---
try {
  await pg.query(
    `INSERT INTO chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) ` +
    `VALUES ('${OTHER_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now())`
  );
  fail("Non-seed ID write was NOT rejected by RLS");
} catch { /* expected: RLS with check violation */ }
ok("Non-seed ID write rejected (fixed user_id filter)");

await pg.exec("RESET ROLE");

// --- 6) Anonymous (no GUC) read/write rejected ---
// RESET GUC → returns '' (empty string) → NULLIF(..., '') → NULL → RLS 0 rows
await pg.exec("RESET app.seed_student_id");
await pg.exec(`SET ROLE ${PROBE_ROLE}`);
res = await pg.query("SELECT count(*)::text as n FROM chunk_review");
if (res.rows[0].n !== "0") fail(`anonymous read not rejected (count=${res.rows[0].n})`);
try {
  await pg.query(
    `INSERT INTO chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) ` +
    `VALUES ('${SEED_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now())`
  );
  fail("Anonymous write was NOT rejected");
} catch { /* expected */ }
ok("Anonymous read returns 0 rows, anonymous write rejected");

await pg.exec("RESET ROLE");

// --- 7) Content tables: anonymous can read, cannot write ---
await pg.exec(`SET ROLE ${PROBE_ROLE}`);
await pg.query("SELECT count(*) FROM units");
await pg.query("SELECT count(*) FROM videos");
await pg.query("SELECT count(*) FROM chunks");
try {
  await pg.query("INSERT INTO units (unit_no, title) VALUES (99, 'probe')");
  fail("Content table write was NOT rejected");
} catch { /* expected */ }
ok("Content tables: anonymous can read, cannot write");

await pg.exec("RESET ROLE");

// --- 8) Cleanup ---
await pg.exec(`DELETE FROM chunk_review WHERE item_id = '${PROBE_ITEM}'`);
await pg.exec(`DROP OWNED BY ${PROBE_ROLE}`);
await pg.exec(`DROP ROLE IF EXISTS ${PROBE_ROLE}`);
ok("Probe data and role cleaned up");

console.log("\n=== PASS: All smoke tests passed ===");
await pg.close();
