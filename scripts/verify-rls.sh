#!/usr/bin/env bash
# =============================================================================
# scripts/verify-rls.sh —— T-0104 DoD「固定 user_id 过滤验证」（SEC-1 v2.4）
#
# 断言（对应《测试方案》§3.2 RLS 用例）：
#   1) seed 唯一学生已预设（users.role='student' 恰 1 行）；
#   2) 全部核心表（DB-01～DB-15）均已启用 RLS；
#   3) 幂等唯一约束存在：chunks(uq_chunks_unit_item) / vocab(uq_vocab_unit_item) /
#      videos(uq_videos_youtube_id)；
#   4) seed 上下文（GUC app.seed_student_id = seed ID）可读写自己的记录（合法路径）；
#   5) 非种子 ID 写入被拒（GUC 仍为 seed → 插入 user_id=非种子失败）；
#   6) 匿名（未设 GUC）读取被拒（返回 0 行）且匿名写入被拒；
#   7) 课程内容表匿名可读、匿名不可写（写入仅 service role / 导入脚本）；
#   8) 清理探测数据与探测角色。
#
# 前提：db/migrations/*.sql 已全量回放（等价 `supabase db reset` 从零重建）
#       —— CI migrations job 先回放后调用本脚本；本地可用相同顺序回放。
#
# 用法：
#   默认：本机装有 psql 时直连 TEST_DATABASE_URL（CI 已装 postgresql-client）。
#   无 psql（如本机 Windows）：自动改用 `docker compose exec` 进 Supabase db 容器
#   执行（需 `docker compose up -d` 已启动，密码取 PGPASSWORD，默认开发值）。
#
# 环境变量：
#   TEST_DATABASE_URL   直连串（默认 .env.example 六段等价）；
#   PGPASSWORD          docker exec 模式密码（默认本地开发值）；
#   POSTGRES_PORT       本地 Postgres 端口（默认 5432）。
# =============================================================================
set -euo pipefail

if command -v psql >/dev/null 2>&1; then
  URL="${TEST_DATABASE_URL:-postgres://postgres:${PGPASSWORD:-local-dev-postgres-password-change-me}@localhost:${POSTGRES_PORT:-5432}/postgres}"
  PSQL=(psql "$URL")
else
  echo "[verify-rls] 本机无 psql，改用 docker compose exec 执行（需 Supabase 栈已启动）" >&2
  PSQL=(docker compose exec -T -e PGPASSWORD="${PGPASSWORD:-local-dev-postgres-password-change-me}" db psql -U postgres -h localhost -d postgres)
fi

fail() { echo "FAIL: $1" >&2; exit 1; }
ok()   { echo "OK:   $1"; }

# 执行单条 SQL（ON_ERROR_STOP 下任何错误即非零退出）
run()   { "${PSQL[@]}" -X -q -v ON_ERROR_STOP=1 -c "$1" >/dev/null; }
# 执行查询并返回末行单值（-tA 仅元组无对齐；tail 取末行，排除 SET 等命令标签噪音）
query() { "${PSQL[@]}" -X -qtA -c "$1" | tail -n 1; }

PROBE_ROLE="rls_probe"            # 非 owner、非 superuser 的探测角色（模拟匿名客户端）
PROBE_ITEM="00000000-0000-0000-0000-000000000001"   # 探测用 item_id（无对应内容行，验证后清理）
OTHER_ID="11111111-1111-4111-8111-111111111111"     # 非种子 ID

# ---------- 1) seed 唯一学生已预设 ----------
n_student=$(query "select count(*) from users where role = 'student'")
[ "$n_student" = "1" ] || fail "seed 唯一学生未正确预设（users.role='student' 行数=${n_student}，应为 1）"
SEED_ID=$(query "select id from users where role = 'student' limit 1")
ok "seed 唯一学生已预设：${SEED_ID}"

# ---------- 2) 全部核心表 RLS 已启用 ----------
not_rls=$(query "select count(*) from pg_tables t where t.schemaname='public' and t.tablename in ('users','units','lessons','chunks','vocab','chunk_review','grammar_points','videos','problem_logs','speaking_submissions','writing_submissions','anchor_submissions','portfolio_items','streaks','ai_call_logs','prompt_templates') and not t.rowsecurity")
[ "$not_rls" = "0" ] || fail "存在未启用 RLS 的核心表（${not_rls} 张）"
ok "全部核心表（DB-01～DB-15）均已启用 RLS"

# ---------- 3) 幂等唯一约束存在 ----------
uq_count=$(query "select count(*) from pg_constraint where conname in ('uq_chunks_unit_item','uq_vocab_unit_item','uq_videos_youtube_id')")
[ "$uq_count" = "3" ] || fail "幂等唯一约束缺失（找到 ${uq_count}/3）"
ok "幂等唯一约束齐全：chunks/vocab (unit_no,item_no)、videos (youtube_id)"

# ---------- 3.5) 创建探测角色（非 owner、非 superuser → 受 RLS 约束） ----------
# 清理上次残留（fresh db reset 后无残留，本地重复跑时清理）
run "do \$\$ begin if exists (select 1 from pg_roles where rolname = '${PROBE_ROLE}') then drop owned by ${PROBE_ROLE}; drop role ${PROBE_ROLE}; end if; end \$\$"
run "create role ${PROBE_ROLE}"
run "grant usage on schema public to ${PROBE_ROLE}"
run "grant select, insert, update, delete on all tables in schema public to ${PROBE_ROLE}"
ok "探测角色 ${PROBE_ROLE} 已创建（受 RLS 约束）"

# ---------- 4) seed 上下文可读写自己的记录（合法路径） ----------
# GUC 先由 superuser 预置、再切探测角色 —— 对齐运行时 PostgREST 行为
run "set app.seed_student_id = '${SEED_ID}'; set role ${PROBE_ROLE}; insert into chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) values ('${SEED_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now() + interval '1 day')"
got=$(query "set app.seed_student_id = '${SEED_ID}'; set role ${PROBE_ROLE}; select count(*) from chunk_review")
[ "$got" = "1" ] || fail "seed 上下文读取自己的记录失败（count=${got}）"
ok "seed 上下文可写入并读到自己的记录"

# ---------- 5) 非种子 ID 写入被拒（GUC 恒定 = seed，模拟攻击者伪造 user_id） ----------
if run "set app.seed_student_id = '${SEED_ID}'; set role ${PROBE_ROLE}; insert into chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) values ('${OTHER_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now())" 2>/dev/null; then
  fail "非种子 ID 写入未被 RLS 拒绝"
fi
ok "非种子 ID 写入被拒（固定 user_id 过滤生效）"

# ---------- 6) 匿名（未设 GUC）读取/写入均被拒 ----------
anon_got=$(query "set role ${PROBE_ROLE}; select count(*) from chunk_review")
[ "$anon_got" = "0" ] || fail "匿名读取未被拒绝（count=${anon_got}，应为 0）"
if run "set role ${PROBE_ROLE}; insert into chunk_review (user_id, item_id, item_type, familiarity, streak, next_review_at) values ('${SEED_ID}', '${PROBE_ITEM}', 'chunk', 1, 0, now())" 2>/dev/null; then
  fail "匿名写入未被 RLS 拒绝"
fi
ok "匿名读取返回 0 行、匿名写入被拒"

# ---------- 7) 课程内容表：匿名可读（公开只读）、匿名不可写 ----------
run "set role ${PROBE_ROLE}; select count(*) from units; select count(*) from videos; select count(*) from chunks"
if run "set role ${PROBE_ROLE}; insert into units (unit_no, title) values (99, 'probe')" 2>/dev/null; then
  fail "内容表匿名写入未被拒绝（内容写入应仅 service role）"
fi
ok "课程内容表匿名可读、匿名写入被拒（内容上线走导入脚本）"

# ---------- 8) 清理探测数据与探测角色 ----------
run "delete from chunk_review where item_id = '${PROBE_ITEM}'"
run "drop owned by ${PROBE_ROLE}"
run "drop role if exists ${PROBE_ROLE}"
ok "探测数据与探测角色已清理"

echo ""
echo "PASS: 固定 user_id（v2.4）RLS 验证全部通过"