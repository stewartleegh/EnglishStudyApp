-- =============================================================================
-- 0001_core_tables_rls_seed.sql —— 迁移 0001（T-0104）
-- 依据：《教学APP开发需求规格书 v2.4》§8.8 DB-01～DB-15 + §8.8.1 SEC-1（v2.4 改写）
--
-- 内容：
--   1) 核心表 DB-01～DB-15（users / units+lessons / chunks / vocab / chunk_review /
--      grammar_points / videos / problem_logs / speaking_submissions /
--      writing_submissions / anchor_submissions / portfolio_items / streaks /
--      ai_call_logs / prompt_templates）；
--   2) 幂等唯一约束：chunks (unit_no,item_no)、vocab (unit_no,item_no)、videos (youtube_id)
--      （CSV 幂等导入业务键，SRS DB-03/04/07）；
--   3) 全部 RLS（SEC-1 v2.4）：固定 user_id 过滤，不依赖 auth.uid()，
--      由 GUC `app.seed_student_id` 承载 seed 预设的唯一学生 ID；
--   4) seed：预设唯一学生（FR-1.1 部署时预设，其余字段由 onboarding/设置页落库）。
--
-- 门禁：CI `migrations` job 等价 `supabase db reset`（全新库按文件名顺序回放本目录
-- 全部 SQL，任一失败即红）；固定 user_id 过滤验证见 scripts/verify-rls.sh。
-- =============================================================================

-- =============================================================================
-- 固定 seed 学生 ID（单用户模式唯一学生）。
-- 三处必须同值，严禁分叉：本文件 seed INSERT / 根目录 .env.example SEED_STUDENT_ID /
-- docker-compose.yml rest.PGRST_DB_PRE_CONFIG。
-- =============================================================================

-- ---------- DB-01 users（v2.4：consent_at 知情同意时间戳替代 guardian 字段） ----------
create table users (
  id uuid primary key default gen_random_uuid(),
  nickname text not null,
  role text not null default 'student' check (role in ('student','admin','test')),
  guitar_level int,           -- 吉他水平（onboarding / 设置页微调）
  english_self_eval int,      -- 英语自评（onboarding / 设置页微调）
  consent_at timestamptz,     -- 知情同意时间（FR-1.1，首次打开落库）
  created_at timestamptz not null default now()
);

-- seed 预设唯一学生（v2.4 单用户；consent_at 留空——首开同意页后写入）
insert into users (id, nickname, role) values (
  'cd283caa-17c3-4fbb-a579-e41b3e425c16', '学生', 'student'
);

-- ---------- DB-02 units / lessons（课程内容） ----------
create table units (
  id uuid primary key default gen_random_uuid(),
  unit_no int not null unique,            -- 业务键 1..8
  title text not null,
  assessment_note text,                   -- 单元评估卡观察点（FR-8.4，随内容灌装）
  content_version int not null default 1
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references units,
  lesson_no text not null check (lesson_no in ('L1','L2','L3','L4','L5','L6')),
  title text not null,
  skill_goal text,
  lang_goal text,
  grammar_point text,
  sentence_frames jsonb,
  checklist_json jsonb,                   -- 操作清单（FR-3.2）
  self_check_json jsonb,                  -- 锚点自评 checklist（FR-7.3）
  content_version int not null default 1,
  unique (unit_id, lesson_no)
);

-- ---------- DB-03 chunks（词块；幂等键 (unit_no, item_no)） ----------
create table chunks (
  id uuid primary key default gen_random_uuid(),
  unit_no int not null,
  item_no int not null,
  text text not null,
  meaning text,
  example text,
  audio_url text,                         -- 预留（FR-4.1 v2.4 用 Web Speech Synthesis，可空）
  constraint uq_chunks_unit_item unique (unit_no, item_no)
);

-- ---------- DB-04 vocab（单词；幂等键 (unit_no, item_no)） ----------
create table vocab (
  id uuid primary key default gen_random_uuid(),
  unit_no int not null,
  item_no int not null,
  word text not null,
  pos text,
  phonetic text,
  meaning text,
  example text,
  constraint uq_vocab_unit_item unique (unit_no, item_no)
);

-- ---------- DB-05 chunk_review（复习状态：每生每词条一行） ----------
create table chunk_review (
  user_id uuid not null references users,
  item_id uuid not null,                  -- 多态引用 chunks.id / vocab.id（无外键）
  item_type text not null check (item_type in ('chunk','vocab')),
  familiarity int not null default 0 check (familiarity in (0,1,2)),
  streak int not null default 0,
  next_review_at timestamptz,
  primary key (user_id, item_id, item_type)
);

-- ---------- DB-06 grammar_points ----------
create table grammar_points (
  id uuid primary key default gen_random_uuid(),
  unit_no int not null,
  name text not null,
  explain_md text,
  exercises_json jsonb
);

-- ---------- DB-07 videos（幂等键 youtube_id） ----------
create table videos (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references lessons,
  youtube_id text not null,
  start_sec int,
  end_sec int,
  title text,
  channel text,
  priority int not null default 1,        -- 1 主 / 2 备选（FR-3.6 自动切换）
  subtitle_json jsonb,
  status text not null default 'active' check (status in ('active','disabled','region_blocked')),
  constraint uq_videos_youtube_id unique (youtube_id)
);

-- ---------- DB-08 problem_logs（写作素材；source 区分手工记录与 L1 问答同步） ----------
create table problem_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  lesson_id uuid not null references lessons,
  source text not null check (source in ('manual','quiz_l1')),
  content text not null,
  created_at timestamptz not null default now()
);

-- ---------- DB-09 speaking_submissions（口语作品+反馈；version 重录递增） ----------
create table speaking_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  lesson_id uuid not null references lessons,
  audio_path text not null,
  mime_type text,
  transcript text,
  duration_ms int,
  scores_json jsonb,
  feedback_md text,
  status text not null default 'ok' check (status in ('ok','pending','transcript_pending')),
  is_final boolean not null default false,
  version int not null default 1
);

-- ---------- DB-10 writing_submissions ----------
create table writing_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  lesson_id uuid not null references lessons,
  content text not null,
  review_json jsonb,                      -- 含 stats.error_rate（服务端计算）
  grammar_hits_json jsonb,
  version int not null default 1,
  created_at timestamptz not null default now()
);

-- ---------- DB-11 anchor_submissions（锚点录像/录音；is_final 仅保留终版） ----------
create table anchor_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  lesson_id uuid not null references lessons,
  video_path text not null,
  mime_type text,
  media_type text not null check (media_type in ('video','audio')),
  self_check_json jsonb,
  note text,                              -- 一句英语感想（FR-7.3）
  is_final boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- DB-12 portfolio_items（作品集归档；ref_id 多态引用三子表） ----------
create table portfolio_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  type text not null check (type in ('speaking','writing','anchor')),
  ref_id uuid not null,                   -- 对应子表（speaking/writing/anchor_submissions）id
  unit_no int not null
);

-- ---------- DB-13 streaks（打卡；每生每日一次） ----------
create table streaks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  date date not null,
  lesson_id uuid not null references lessons,
  constraint uq_streaks_user_date unique (user_id, date)
);

-- ---------- DB-14 ai_call_logs（脱敏：仅元数据 + submission_id 引用，不存原文） ----------
create table ai_call_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users,
  kind text not null,
  prompt_version text,
  tokens_in int,
  tokens_out int,
  latency_ms int,
  status text,
  error_code text,
  source text not null default 'student' check (source in ('student','system')),
  submission_id uuid,                     -- 引用，不存原文（I-6 脱敏红线）
  created_at timestamptz not null default now()
);

-- ---------- DB-15 prompt_templates（LLM 模板版本化，恒服务端使用） ----------
create table prompt_templates (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  version text not null,                  -- 模板版本号（如 speaking_eval.v1）
  content text not null,
  active boolean not null default false,
  constraint uq_prompt_templates_kind_version unique (kind, version)
);

-- 常用查询索引（内容按单元加载、视频按关卡取主备、进度/队列/日志按用户）
create index idx_chunks_unit_no on chunks (unit_no);
create index idx_vocab_unit_no on vocab (unit_no);
create index idx_lessons_unit_id on lessons (unit_id);
create index idx_videos_lesson_id on videos (lesson_id);
create index idx_grammar_points_unit_no on grammar_points (unit_no);
create index idx_chunk_review_user_next on chunk_review (user_id, next_review_at);
create index idx_problem_logs_user on problem_logs (user_id);
create index idx_speaking_submissions_user on speaking_submissions (user_id);
create index idx_writing_submissions_user on writing_submissions (user_id);
create index idx_anchor_submissions_user on anchor_submissions (user_id);
create index idx_portfolio_items_user_unit on portfolio_items (user_id, unit_no);
create index idx_ai_call_logs_user_created on ai_call_logs (user_id, created_at);

-- =============================================================================
-- PostgREST 角色幂等创建 + 表权限授予
-- Supabase 镜像已有 anon/authenticator/service_role（init 脚本创建）；
-- 纯 Postgres（CI migrations job）无上述角色 → DO 幂等创建，两种环境均通过。
-- anon：全表 CRUD（RLS 策略负责行级过滤，限制 anon 只能操作 seed 学生数据）
-- service_role：全表 CRUD + BYPASSRLS（绕过 RLS，用于导入脚本 / 服务端逻辑）
-- =============================================================================
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticator') then
    create role authenticator nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end $$;

grant usage on schema public to anon, service_role;
grant select, insert, update, delete on all tables in schema public to anon, service_role;

-- =============================================================================
-- RLS（SEC-1 v2.4：固定 user_id 过滤，GUC app.seed_student_id）
-- 约定：
--   1) 学生数据表（含 user_id）→ for all + with check 双写 GUC 过滤（仅 seed 学生可读写
--      自己的数据；非种子 ID 写入与未设 GUC 的匿名读取均被拒）；
--   2) 课程内容表（units/lessons/chunks/vocab/grammar_points/videos）→ 公开只读
--      （select using(true)：单用户下学生无需认证即可读课程内容；写入仅 service role，
--      内容上线走 scripts/import-content.ts，project_rules §8.3）；
--   3) ai_call_logs（脱敏）与 prompt_templates（LLM 内部模板）→ 启用 RLS 但不建客户端策略
--      = 仅 service role 可访问（对齐《代码示例.md》§13 content_versions 约定）。
-- 运行时 GUC 由 ALTER ROLE anon SET + pre_config 函数预置
-- （PostgREST v14 每次 SET ROLE anon 时自动注入；pre_config 在 schema cache reload 时冗余保障）。
-- 注：current_setting(..., true) 在 GUC 未设置时返回 NULL（而非报错）。
--     NULLIF(..., '') 兼顾 GUC 被 RESET 后返回空串的情况（空串无法 ::uuid 转型）→
--     NULL → 策略条件为 NULL = 不匹配 → 匿名读取返回 0 行而非 500。
-- =============================================================================

-- 学生数据表：启用 RLS + 固定 user_id 过滤策略
alter table users enable row level security;
alter table chunk_review enable row level security;
alter table problem_logs enable row level security;
alter table speaking_submissions enable row level security;
alter table writing_submissions enable row level security;
alter table anchor_submissions enable row level security;
alter table portfolio_items enable row level security;
alter table streaks enable row level security;
alter table ai_call_logs enable row level security;

-- users：可读写自己的行（onboarding/设置页读写 consent_at 与昵称等；seed 行已存在，无需 INSERT）
create policy rls_users_own on users
  for all using (id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_chunk_review_own on chunk_review
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_problem_logs_own on problem_logs
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_speaking_submissions_own on speaking_submissions
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_writing_submissions_own on writing_submissions
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_anchor_submissions_own on anchor_submissions
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_portfolio_items_own on portfolio_items
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

create policy rls_streaks_own on streaks
  for all using (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid)
  with check (user_id = NULLIF(current_setting('app.seed_student_id', true), '')::uuid);

-- 课程内容表：启用 RLS + 公开只读
alter table units enable row level security;
alter table lessons enable row level security;
alter table chunks enable row level security;
alter table vocab enable row level security;
alter table grammar_points enable row level security;
alter table videos enable row level security;

create policy content_read_units on units for select using (true);
create policy content_read_lessons on lessons for select using (true);
create policy content_read_chunks on chunks for select using (true);
create policy content_read_vocab on vocab for select using (true);
create policy content_read_grammar_points on grammar_points for select using (true);
create policy content_read_videos on videos for select using (true);

-- 仅 service role 可访问（无客户端策略）
alter table prompt_templates enable row level security;

-- =============================================================================
-- PostgREST GUC 预置（v2.4 固定 user_id 过滤）
-- PostgREST v14 连接流程：authenticator → SET ROLE anon/service_role → 执行查询。
-- ALTER ROLE SET 在每次 SET ROLE 时自动注入 GUC，确保 RLS 策略能读到 seed 学生 ID。
-- pre_config 函数在 schema cache reload 时调用（冗余保障 + 满足 db-config 默认期望）。
-- =============================================================================
alter role anon set app.seed_student_id = 'cd283caa-17c3-4fbb-a579-e41b3e425c16';
alter role authenticator set app.seed_student_id = 'cd283caa-17c3-4fbb-a579-e41b3e425c16';

create schema if not exists postgrest;

create or replace function postgrest.pre_config() returns void as $$
  select set_config('app.seed_student_id', 'cd283caa-17c3-4fbb-a579-e41b3e425c16', false);
$$ language sql;

grant usage on schema postgrest to authenticator, anon;
grant execute on function postgrest.pre_config() to authenticator, anon;