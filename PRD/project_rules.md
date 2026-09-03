# Project Rules —— Coding Agent 约束规则

> 本文件约束一切参与本项目开发的 AI 编程助手（Claude Code / Cursor / Kimi 等）。
> 每次编码会话开始前必须完整读取本文件；与需求冲突时，以《教学APP开发需求规格书 v2.4》为准（v2.4 为单用户简化版，见 SRS V23-2；v2.3 部署架构变更见 V23-1；v2.2 需求冻结基线见 SRS §0.1）。
> 规则等级：**【禁止】**= 不可违反；**【必须】**= 每次都要做到；**【应该】**= 默认做，偏离需在 PR 说明理由。

---

## 1. 项目定位（一句话）

面向吉他 10 级初中生（入学约 A2、目标**音乐领域内 B1**——对外表述禁用"A2→B1"整级宣称，课程设计 v2.1 口径）的"用英语学音乐素养"PWA：8 单元闯关，YouTube 嵌入视频 + 词块/语法 + 问答（L1 预测/L2 大意）+ 实操锚点录像 + AI 口语/写作反馈。**MVP 只做 M1 模块，不做教师后台页面化、不做支付、不做原生 App。**

## 2. 技术栈（固定，不得自行更换）

| 层 | 固定选型 | 备注 |
|---|---|---|
| 框架 | Next.js 14+ App Router + TypeScript `strict` | 页面与 API 同仓 |
| UI | Tailwind CSS + shadcn/ui + lucide-react | 组件源码在 `components/ui`，可直接改 |
| 图表 | Recharts | 热力图自绘格子 |
| AI | Vercel AI SDK（`ai` + `@ai-sdk/deepseek`） | 模型固定 `deepseek-v4-flash` |
| 语音转写 | 云端 Whisper 兼容 ASR 服务（国内供应商优先） | Web Speech 仅 iOS Safari 增强预览，**不作主路径**（S-1） |
| DB/Storage | Supabase 自托管（Docker：Postgres + Storage，全部私有桶） | v2.3 定案；v2.4 单用户模式不启 Auth（NFR-3），RLS 固定 user_id 过滤；ORM 用 Drizzle |
| 视频 | YouTube iframe（`react-youtube`），自存字幕 JSON | **永不下载视频本体** |
| 测试 | Vitest + RTL + MSW + Playwright | 见《测试方案.md》 |
| 包管理 | pnpm | lockfile 必须入库 |

**【禁止】** 引入未列入上表的新依赖，除非：在 PR 描述中说明理由且包周下载量 >10k、license 为 MIT/Apache/BSD。

## 3. 目录结构约定

```
app/                    # App Router：页面 + api/ 路由（路由只做编排，不写业务逻辑）
components/             # ui/（shadcn）与业务组件；业务组件按域分目录
lib/
  ai/                   # 【圣地】唯一允许触碰 LLM 的目录
    provider.ts  prompts/  schemas/  retry.ts  usage.ts  guard.ts  logger.ts
  supabase/             # server/client 两个入口，永不混用
  review/               # SM-2 简化调度
  content/              # 课程数据读取（带 content_version 缓存）
db/migrations/          # 手写 SQL 迁移，序号递增，永不修改已合入的迁移
scripts/                # import-content.ts 等内容灌装脚本
evals/golden/           # LLM golden 样本集
docs/                   # PRD 全套文档（本目录文件即需求源）
```

**【必须】** 新文件归入上述结构；**【禁止】** 在 `app/api/**/route.ts` 里写超过 50 行业务逻辑——抽到 `lib/`。

## 4. AI 编排层铁律（最高优先级）

1. **【禁止】** 在 `lib/ai/` 之外的任何文件 import LLM SDK 或直接 fetch DeepSeek/Whisper 端点。
2. **【必须】** 所有模型调用携带固化参数：`thinking: {type:"disabled"}`（v4-flash 默认开思考，不关会打爆延迟与成本——审查报告 I-1）；`temperature ≤0.3`；`timeout 9000ms`。
3. **【必须】** 结构化输出一律 `generateObject` + Zod schema；解析失败走 `retry.ts`（重试恰好 1 次、t=0），仍失败落 `pending`，**绝不向学生抛错、绝不阻塞过关**。
4. **【必须】** prompt 模板带 `version` 常量；改模板 = 新常量 + 旧版保留（供 golden 回归重放）；**【禁止】** 原地改字符串不留版本。
5. **【必须】** `logger.ts` 只写元数据（kind/prompt_version/tokens/latency/status/submission_id），**【禁止】** 把学生录音转写/作文原文写进 `ai_call_logs`（未成年人脱敏红线）。
6. **【必须】** 配额口径：只计学生主动调用（每日 ≤3）；系统重试不计；`role ∈ {admin, test}` 豁免；陪练按会话计次、≤10 轮硬断；媒体上传每生每日 ≤10 次（QUOTA-5，上传入口统一校验）。
7. **【必须】** 学生可见文本输出过 `guard.ts` 输出侧扫描；陪练 system prompt 必须含"不索取个人信息、只聊音乐与英语学习、越界固定话术转向"。

## 5. 数据与安全规则

1. **【必须】** 每张新表默认 `enable row level security`；v2.4 单用户模式不启 Supabase Auth，RLS 策略改为**固定 user_id 过滤**（seed 预设的唯一学生 ID），不依赖 `auth.uid()`；迁移 PR 未带 RLS 策略不予合入。
2. **【必须】** Storage 全部私有桶 + 签名 URL（≤15 分钟）；**【禁止】** 把 Storage 公开 URL 写进前端或分享链接；分享走 `share_tokens` 只读视图。
3. **【必须】** 媒体路径规范：`{user_id}/{unit_no}/{kind}/{uuid}.{ext}`；记录 `mime_type`（iOS 产出 mp4，Chrome 产出 webm——前端录制用 `MediaRecorder.isTypeSupported` 探测，**【禁止】** 硬编码 webm）。
4. **【必须】** 清理策略：锚点录像 14 天滚动转元数据、草稿音频 24h 删除、U8 毕业作品永久——写成 cron 迁移而非口头约定；配额 ≥80% 触发告警。
5. **【禁止】** 在任何环境把 `SUPABASE_SERVICE_ROLE_KEY`、`DEEPSEEK_API_KEY` 暴露到客户端代码（`NEXT_PUBLIC_` 前缀只允许匿名 key）。
6. **【必须】** 环境变量集中登记在 `.env.example`，新增变量同步登记并写注释。
7. **【必须】** 时区口径（NFR-8）：所有"每日"统计（QUOTA-1/QUOTA-5、streaks 打卡、复习队列）与到期计算一律按**北京时间 UTC+8** 固定偏移计算日界，统一复用 `lib/time.ts` 的 `beijingDayStart()`；**【禁止】** 使用服务器本地时间（`setHours`/`toLocaleString` 切日界均违规——Linux 服务器时区可能非 UTC+8）。
8. **【必须】** 前端运行时错误统一上报 `/api/errors/report`（window.onerror + unhandledrejection + React error boundary，NFR-5/API-19），stack 截断 ≤2KB，上报失败必须静默、不影响用户。
9. **【必须】** 问答判分一律服务端进行：`quiz_questions.answer` **不得下发前端**（关卡页接口只返回题目与选项，防 F12 抄答案）；L2 判分不调 LLM。

## 6. 前端与 UI 规则

1. **【必须】** 遵循设计 Token（SRS §7.2）：白底、卡片 `#F7F7F5`、正文 `#191919`、唯一强调色 `#2E7D6B`、圆角 6/4px、Lucide 图标；**【禁止】** 新增强调色、渐变、徽章/奖杯式游戏化元素。
2. **【必须】** 移动优先：点击目标 ≥44px；录音/录像/提交按钮底部固定；竖屏可用；仅浅色模式（MVP 不做深色）。
3. **【必须】** AI 反馈卡片固定结构：分数条 → 亮点 → ≤3 改进点（各带示范改写）→ 👍/👎 入口；失败态显示"反馈稍后送达"而非报错。
4. **【必须】** 媒体采集全部有降级路径：无摄像头 → 纯音频；权限被拒 → 引导页且本关可稍后再来。
5. **【必须】** 视频播放失败（iframe onError 101/150/oEmbed 探测失败）→ 自动切备选视频并上报 `videos.status`；**【禁止】** 给学生展示 YouTube 原生错误页了事。
6. **【应该】** 服务器组件优先；`"use client"` 只加在真正需要交互/浏览器 API 的组件上。

## 7. 测试规则

1. **【必须】** 每个 PR：`pnpm test:unit` 全绿 + `tsc --noEmit` 零错 + eslint 零 error；改动 `app/api/**` 必须附集成测试。
2. **【必须】** **CI/单测中禁止真调 LLM/Whisper**——一律 MSW fixture；真模型只在 `pnpm eval:golden`（手动触发）。
3. **【必须】** 覆盖率门槛：`lib/ai ≥90%`、`app/api ≥80%`、整体 ≥70%，CI 卡线。
4. **【必须】** 修 bug 先写复现测试再修；验收标准（SRS §10）与 E2E 用例（测试方案 §4）一一对应，不许只测不测收。
5. **【应该】** golden 样本集随 prompt 版本演进扩充；每次模板变更跑回归，无回退才切换 active 版本。

## 8. 内容与版权红线

1. **【禁止】** 任何代码路径下载/转存/剪辑 YouTube 视频本体；只允许 iframe 嵌入 + CC 字幕提取（字幕仅库内自用，不提供导出接口）。
2. **【禁止】** 把 Rick Beato 频道内容配进学生端（Content ID 高风险）；每关卡视频必须预置 2 个备选。
3. **【必须】** 内容上线只走 `scripts/import-content.ts`（Zod 校验 + 幂等 upsert）；**【禁止】** 手写 SQL 直接插内容表。
4. **【必须】** 词块/术语以《课程内容细化-U1-U8.md》附录 A.2《统一乐理术语英中对照表》为准，新术语先入表再进内容。

## 9. 合规红线（未成年人）

1. **【必须】** 首次打开显示知情同意页（v2.4，IX-0 替代注册与监护人确认链路）：学生点击"我已知晓并同意"并落库 `users.consent_at` 前，不可进入学习流程；本地部署由家长完成安装配置即视为监护人授权（NFR-4）。~~注册/监护人确认邮件~~ 已废止（FR-1.2/1.6 v2.4 废止）。
2. **【必须】** 学生数据默认私有；任何"分享/公开"动作需显式操作 + 二次确认文案。
3. **【禁止】** 采集与学习无关的个人信息；AI 交互中不主动索要学生真实姓名、学校、住址（guard.ts 双向 enforced）。
4. **【必须】** 数据清除通道真实可用（v2.4 改写，替代原账号删除流）：单用户模式无账号删除流程（FR-1.5/SEC-4 已废止）；需清除数据时由开发者直接操作 Docker Supabase 管理界面（媒体文件 + 行数据同步清除）；学生个人作品可随时经 FR-7.5 单独下载导出兜底。

## 10. 部署与运行

1. **【必须】** 纯本地部署可运行（v2.3 定案）：`npm run build && npm start`（node 进程）+ Docker Compose Supabase + mkcert HTTPS；部署于独立 Linux 主机，systemd 管理常驻。**【禁止】** 写死任何云平台专属 API（Vercel KV/Blob、边缘函数等）——所有存储与 DB 只走本地 Docker Supabase。
2. **【必须】** API Route 设 60s 请求超时兜底降级（`export const maxDuration = 60` 保留以兼容潜在未来云迁移）；非流式调用 10s 内必须返回或降级。
3. **【应该】** StorageAdapter 接口抽象为可选项（v2.3 降级 P2）：STO-5 已归并，Storage 直写 Docker Supabase 本地卷，接口抽象可做但不阻塞交付。

## 11. 提交规范

- 分支：`feat/*`、`fix/*`、`content/*`；commit 信息中文、祈使句，前缀 `feat:|fix:|test:|content:|chore:`。
- PR 模板必填：对应需求编号（FR-x.x 或审查报告修复项编号）、测试证据（截图/测试输出）、是否触碰 `lib/ai`（触碰则需双人/人工复核）。
- **【禁止】** 直接推 main；**【禁止】** 合入未过 CI 的 PR。

## 12. 与文档的同步义务

- 改功能 → 同步改 SRS 对应条目；改 prompt → 版本 +1 并记 changelog；改数据模型 → 迁移文件 + SRS §8.8 表同步。
- **【必须】** 开发期需求冻结（SRS v2.2 §0.1）：自 W1 起仅接受缺陷修复与条款澄清；任何新需求一律记二期 backlog，**不得进入当前 8 周排期**；试用数据证明必须变更时走 v2.3 版本升级 + 变更评审。
- 发现文档自相矛盾 → 停下，在 PR 描述中提出，**不要自行二选一**。
