# 教学 APP 开发需求规格书（SRS）

> 产品代号：Music in English（任务型英语学习 Web 应用）
> 版本：**v2.4（2026-09-02）** · MVP 范围：M1 音乐素养模块 · 目标周期：8 周交付
>
> **v2.4 变更摘要（单用户简化版）**：① MVP 移除全部用户注册管理功能，改为**单用户模式**——无注册、无登录、无认证，APP 直接进入学习（首次显示知情同意页）；② ~~FR-1.1 注册登录~~ / ~~FR-1.2 监护人确认链路~~ / ~~FR-1.5 监护人入口/删除/导出~~ / ~~FR-1.6 重发确认邮件~~ 废止；③ FR-1.3 Onboarding 简化（去注册表单与监护人邮箱）；④ NFR-3 Docker Supabase 去掉 Auth 组件（仅 Postgres + Storage）；⑤ API-12/13/16/17/18、DB-24、IX-0、AC-10、SEC-4、RSK-6 同步废止或改写；⑥ 本版为 v2.3 基础上的用户授权变更（V23-2）。
>
> **v2.3 变更摘要（部署架构变更版）**：① 部署模式由"云端 Vercel + Supabase Cloud / 本地 node"双模式改为**纯本地部署**——独立 Linux 主机 Docker 自托管 Supabase 全套（Postgres + Auth + Storage + RLS），node 进程 + mkcert HTTPS 局域网访问；② 移除 Vercel 云端模式（Vercel `*.vercel.app` 大陆不可达 + 云端函数无法访问本机数据库，双模式失去意义）；③ NFR-3/NFR-6/NFR-7/NFR-8、§8.2/8.3/8.4、STO-4/5、RSK-5/8、MS-W1/W5、AC-07 同步更新；④ 本版为 v2.2 基础上的用户授权部署变更（V23-1），需求冻结期内架构级变更经用户确认。
>
> **v2.2 变更摘要（需求访谈定稿版）**：① 补齐**问答系统**（FR-4.6 L1 预测问答开放记录不判分 + FR-3.7 L2 大意问答选择题即时判分，DB-21/22、API-15，不调 LLM）；② 注册收敛为**仅邮箱**（FR-1.1，短信留二期）；③ 监护人链路补全（guardian_tokens 表 DB-24、portal/导出/重发 API-16/17/18、删除 7 天冷静期，FR-1.5/1.6）；④ U8 毕业评估**砍管理员终审**（AI 出分即终分）；⑤ 新增时区口径 NFR-8（每日统计一律北京时间 UTC+8）、媒体上传限流 QUOTA-5、前端错误上报（NFR-5/DB-26/API-19）、content_version 锁定表 DB-25；⑥ 教学口径定案：音乐领域内 B1、U1 首作作成长基线、AI 分数仅作反馈工具（FR-8.2）；⑦ 新增试用期量化成功标准（§10.1）；⑧ **本版定稿后 SRS 进入需求冻结（§0.1）**；⑨ 修复 LC-L4 判据与 API-10 冲突、FR-3.2 示例错位，补 notes 表（DB-23）；⑩ 补录**单元评估卡 FR-8.4**（V22-13，X 类缺陷修复：课程设计 v2.1 §6.2 定稿内容传递遗漏，LC-L6/§7.3/API-16/DB-02 联动）。
>
> **v2.1 变更摘要**：① 文档做**可寻址结构化改造**（新增 §0 寻址规范，全部需求/接口/数据表/验收/风险/里程碑获得稳定编号，供任务清单索引定位）；② 并入《审查报告.md》13 项修复行动（ASR 主路径反转、存储参数重算、补 5 张表、监护人确认链路、配额口径、thinking 模式显式关闭、RLS 安全策略、MediaRecorder 格式探测、视频失效双通道、CSV 幂等导入、日志脱敏与重放关系、L1–L6 完成判据、写作错误率口径）；③ 6 项一般性优化（仅浅色模式、无障碍、分享链接安全、内容灌装前置、mkcert iOS 指引、生词点查降级）。
>
> **v2.0 变更摘要**：① 教学对象改为吉他 10 级学生，课程技能线由"零基础学琴"改为"音乐素养拓展"（乐理深化 / 风格文化 / 创作即兴）；② 视频方案由"自托管自制视频"改为"YouTube 公开教学视频引用（iframe 嵌入 + 字幕自存）"；③ AI 应用形式定案：DeepSeek API（v4-flash）+ Vercel AI SDK（开源 harness）+ 自建轻量编排层，不自部署任何组件；④ 新增实操锚点录像存档（MediaRecorder 视频）、语法微课堂组件；⑤ 新增业务流程（学习侧 / 内容生产 / AI 质量运营）与用户交互设计章节；⑥ 架构、数据模型、API 契约、界面线框全面深化；⑦ 新增本地部署模式（同一代码库双模式运行）。

---

## §0 文档寻址规范（v2.1 新增）

本文档所有可引用单元均有**稳定编号**，编写任务清单、提交记录、测试用例时按 `SRS:<编号>` 引用（如 `SRS:FR-5.2`、`SRS:AC-03`）。编号一旦发布**永不复用、永不重排**；条目废止标注 `~~删除线~~` 并注明替代编号，条目不跨版本改号。

| 前缀 | 范围 | 所在章节 |
|---|---|---|
| `FR-x.y` | 功能需求 | §3 |
| `NFR-x` | 非功能需求 | §4 |
| `LC-Ln` | 关卡完成判据 | §5.2 |
| `QUOTA-x` | AI 用量规则 | §5.3 |
| `IX-x` | 交互流条目 | §6 |
| `DT-x` | 设计 Token | §7.2 |
| `API-xx` | API 契约 | §8.6 |
| `DB-xx` | 数据表 | §8.8 |
| `SEC-x` | 安全策略 | §8.8.1 |
| `STO-x` | 存储与配额规则 | §8.9 |
| `MS-Wn` | 排期里程碑 | §9 |
| `AC-xx` | 验收标准 | §10 |
| `RSK-x` | 风险与对策 | §11 |

配套文档：《用英语学音乐课程设计方案 v2.1》《课程内容细化-U1-U8.md》《审查报告.md》（已归档）《流程图与推演.md》《代码示例.md》《测试方案.md》《project_rules.md》。

### 0.1 需求冻结（v2.2 定稿）

本版定稿即进入开发期**需求冻结**：自 W1 起仅接受 ① 缺陷修复（与既有编号条款冲突的实现问题）与 ② 条款澄清（不改变语义的表述完善）；任何新需求、新功能、范围调整一律记入二期 backlog，不影响 8 周排期。解除冻结的唯一条件：试用数据证明必须变更，此时走版本升级（v2.3）+ 变更评审（影响面评估 + 排期重排）。

## 1. 引言

### 1.1 目的
本文档定义 MVP 版本的全部功能与非功能需求，作为小团队 + AI 编程助手协同开发的唯一需求基准。v2.1 在 v2.0 基础上完成可寻址结构化改造并并入审查发现的 13 项修复；**v2.2 为需求访谈定稿版**：补齐问答系统与监护人链路、注册收敛为仅邮箱、定案教学评估口径与试用期成功标准，**定稿后进入需求冻结（§0.1）**。

### 1.2 范围
- **包含**：M1 音乐素养模块完整学习闭环（视频学习 → 任务操作 → 实操锚点录像 → 口语/写作产出 → AI 评估 → 作品集）；
- **不包含（二期以后）**：教师端正式后台、班级管理、M2/M3/M4 内容、原生 App、支付、演奏音频分析评估。

### 1.3 用户角色

| 角色 | 说明 | MVP 权限 |
|---|---|---|
| 学生 | 12–15 岁初中生，**吉他 10 级（可独立弹奏）**，英语约 A2，自主学习 | 全部学习功能（v2.4 单用户模式，首次显示知情同意页后直接进入） |
| ~~监护人~~ | ~~学生家长~~ | ~~确认激活/查看作品集/导出/删除~~ → **v2.4 废止**（单用户模式无监护人链路，部署由家长完成即视为知情同意） |
| 管理员（开发者兼任） | 维护视频池、字幕、词块/单词/语法点、句型框架、任务卡 | 简易后台 + CSV/SQL 直灌；AI 调用配额豁免（QUOTA-4） |
| 测试账号 | 验收测试专用（role=test） | 配额豁免，数据定期清理（v2.4 单用户无认证：验收/CI 期间将 seed 用户 role 置 test 或设 `QUOTA_BYPASS=true` 实现豁免，验收完毕恢复 student，见 QUOTA-4） |

### 1.4 术语
- **关卡（Lesson）**：一个单元的 6 个环节（L1–L6）之一；
- **词块（Chunk）**：最小词汇学习单位（如 keep the beat）；
- **实操锚点（Anchor Task）**：每单元的吉他实操任务，以"演奏录像 + checklist 自评"存档，演奏本身不做 AI 评估；
- **语法微课堂（Grammar Mini-lesson）**：每单元 L1 关卡内置的语法点讲解 + 操练组件；
- **作品集（Portfolio）**：学生全部口语录音、写作文本与锚点录像的归档。

## 2. 产品概述

帮助学生"用英语拓展音乐素养"的 PWA Web 应用：以 8 单元闯关式课程为主线（乐理深化 / 风格文化 / 创作即兴三条线均衡混排），内嵌 YouTube 引用视频学习、词块卡片、语法微课堂、实操锚点录像、AI 口语陪练、AI 写作批改与成长曲线。风格对标 Notion 的简洁工具风，不做重度游戏化。

**核心价值主张**：素养是真的懂了，英语是真的用出来，作品是带得走的，进步是看得见的。

**教学目标口径（v2.2 定案）**：课程结束时学生的英语水平目标为**"音乐领域内 B1"**——能在音乐话题（乐理/风格/创作）范围内听懂教学视频大意、用句型框架进行可理解的口语与书面表达；不承诺全域 CEFR B1（按每日 20–30 分钟 × 8 周约 23 小时引导学习时长，不足以支撑整级跃迁）。**成长证据口径**：不设独立入学前测，以 U1 各关卡首次作品为天然基线（FR-8.2 基线参考线）；**AI 分数定位为学习反馈工具，不作教学评估结论或能力认证**。

## 3. 功能需求

优先级：P0 = MVP 必须；P1 = MVP 内尽力；P2 = 二期。

### 3.1 账户与个人档案

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-1.1 | **~~仅邮箱注册登录~~ → v2.4 废止（单用户模式）**：无注册、无登录、无认证；APP 首次打开显示未成年人数据使用知情同意页，点击"我已知晓并同意"后直接进入学习；用户信息在部署时通过 seed 脚本预设（DB-01），后续可在设置页微调 | P0 |
| FR-1.2 | **~~监护人确认链路~~ → v2.4 废止**：单用户本地部署由家长完成安装配置，启动 APP 即视为监护人知情同意；知情同意页（IX-0 改写）替代原确认链路作为合规措施 | ~~P0~~ → 废止 |
| FR-1.3 | 首次进入完成轻量 onboarding（v2.4 简化）：确认吉他水平（默认 10 级，可微调自评）、英语自评、昵称——**无注册表单、无监护人邮箱**；首次同意页后弹出，完成后不再出现 | P0 |
| FR-1.4 | 个人主页：连续打卡天数、总词块数、实操锚点存档数、作品集入口 | P0 |
| FR-1.5 | **~~监护人入口/删除/导出~~ → v2.4 废止**（单用户模式无监护人链路、无账号删除流程；学生个人作品可随时通过 FR-7.5 单独下载到本地） | ~~P0~~ → 废止 |
| FR-1.6 | **~~重发监护人确认邮件~~ → v2.4 废止**（单用户模式无注册即无确认邮件链路） | ~~P0~~ → 废止 |

### 3.2 课程地图与关卡引擎

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-2.1 | 课程地图页：8 单元 × 6 关卡的线性进度视图（Notion 式列表 + 进度状态图标），每单元标注素养线（乐理/风格/创作） | P0 |
| FR-2.2 | 关卡状态机：未解锁 → 进行中 → 已完成；L 关卡依次解锁，单元需 L6 完成后解锁下一单元；**各关卡完成判据见 §5.2 表（LC-L1–LC-L6）；已完成关卡重做不回退状态，仅新增版本** | P0 |
| FR-2.3 | 每关卡顶部固定展示"本关任务卡"：素养目标 + 语言目标（词块/语法点）+ 预计时长（**标准时长表定案：L1 25′/L2 20′/L3 30′/L4 20′/L5 25′/L6 10′，见《课程设计方案》§三，v2.2 补齐**） | P0 |
| FR-2.4 | 断点续学：记住每关卡内的进度位置（持久化于 `lesson_progress` 表，DB-16） | P1 |

### 3.3 视频学习器（L2/L3 关卡核心）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-3.1 | 内嵌 YouTube 播放（iframe embed，不下载不分发），支持起止时间切片（start_sec/end_sec）、英文字幕开关；视频源与切片元数据由管理端配置 | P0 |
| FR-3.2 | 操作清单（Checklist）：随视频出现"跟做检查项"，学生勾选确认（如"已在两个把位弹出 C 大调音阶"；**各单元清单内容见《课程内容细化》各单元"L2 操作清单"，v2.2 补齐**） | P0 |
| FR-3.3 | 时间戳笔记：暂停视频即在当前时间点记一条英语关键词笔记（**落库 notes 表 DB-23，v2.2 补数据模型**） | P1 |
| FR-3.4 | 问题日志入口：随时记录 I got stuck when…，文本自动带入写作任务素材库 | P0 |
| FR-3.5 | 生词点查：点击字幕中的单词/词块弹出释义（基于自存字幕 + 预制术语词表），词块学习状态同步；**词表外生词（OOV）不调用 LLM，降级为系统词典/浏览器翻译跳转（v2.1 明确，G-6）** | P1 |
| FR-3.6 | 视频失效检测（v2.1 细化为双通道，修复 I-4）：① 管理端 cron 每日走 YouTube oEmbed 端点探测（可探下架/禁嵌，无配额限制）；② 学生端 iframe `onError`（码 101/150 = 禁止嵌入）实时上报 `videos.status`；任一通道触发即自动切换备选视频（每关卡预置 2 个备选） | P1 |
| FR-3.7 | **L2 大意理解问答（v2.2 新增，补 LC-L2 硬依赖）**：视频看完后回答 3 道选择题（固定答案库随内容灌装入库 quiz_questions，DB-21），提交即时判分并展示对错与解析（API-15，**不调 LLM**）；**答对与否不阻塞过关**（LC-L2）；作答落库 quiz_submissions（DB-22） | P0 |

### 3.4 词块卡片与语法微课堂（L1 关卡 + 日常复习）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-4.1 | 词块卡：正面语块 + 发音，背面释义 + 例句 + 单元出处 | P0 |
| FR-4.2 | 单词提炼：每单元的乐理术语与高频通用词进入词汇表（含音标、词性、释义、例句），与词块卡共用复习队列 | P0 |
| FR-4.3 | 语法微课堂：每单元 1–2 个语法点，呈现"微讲解（≤120 词）+ 2 道交互操练（选择/填空）"，操练即时反馈 | P0 |
| FR-4.4 | 简单间隔重复（SM-2 简化版）：掌握/模糊/陌生三档自评，词块与单词统一调度（算法参考实现见《代码示例.md》§7） | P1 |
| FR-4.5 | 每日复习队列：首页呈现"今日待复习 N 张" | P1 |
| FR-4.6 | **L1 预测问答（v2.2 新增，补 LC-L1 硬依赖）**：进入单元后、看视频前回答 2 道开放式预测题（激活背景知识，如 "What do you think a half step means on the guitar?"）；**只记录不判分**，作答自动进入问题日志素材库（与 FR-3.4 打通，供 L5 写作引用，API-15）；完成判据为全部提交 | P0 |

### 3.5 口语任务与 AI 陪练（L4 关卡核心）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-5.1 | 录音组件：浏览器内录音（MediaRecorder，纯音频），展示参考提纲（句型框架卡片，按 U1–U8 进度逐级撤除）；**录制格式必须经 `MediaRecorder.isTypeSupported` 探测（iOS 产出 audio/mp4，Chrome 产出 webm），mimeType 随上传入库（修复 I-3）** | P0 |
| FR-5.2 | ASR 转写（**v2.1 主路径反转，修复 S-1**）：**主路径为云端 Whisper 兼容服务**（录音文件上传后服务端转写，大陆 Android Chrome 可用、支持事后转写）；Web Speech API 仅作 iOS Safari 上的**实时转写预览增强**，最终以服务端转写为准 | P0 |
| FR-5.3 | AI 反馈：LLM 按"完整度/流利度/清晰度"三维打分（各 1–5 分）+ 结构化文字反馈（先肯定 → 最多 3 个改进点 → 1 个示范改写） | P0 |
| FR-5.4 | 重录对比：同一任务可多次录音，并排展示各版本转写与得分，学生自选"入档版本" | P1 |
| FR-5.5 | AI 口语陪练对话（U6"教 AI"环节）：LLM 扮演初学者对学生讲解进行追问，流式返回；**≤10 轮硬断，会话落库 `coach_sessions`/`coach_messages`（DB-17/18）；配额按会话计次（QUOTA-3）** | P1 |
| FR-5.6 | TTS 示范朗读：句型框架与示范文本可收听标准发音（Web Speech Synthesis） | P1 |

### 3.6 写作任务与 AI 批改（L5 关卡核心）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-6.1 | 写作编辑器：纯文本 + 可展开的句型框架侧边栏（点击句型插入光标处）+ 实时词数 | P0 |
| FR-6.2 | AI 批改：按 Rubric 输出——阻碍理解的错误（必改，逐条标注原文→修改→原因）、润色建议（可选层，默认折叠）、亮点句（肯定 1–2 处） | P0 |
| FR-6.3 | 版本历史：每次提交保存一版，学生可对比修改前后 | P0 |
| FR-6.4 | 问题日志一键引用：L3 记录的问题可插入写作素材 | P1 |
| FR-6.5 | 语法点针对性反馈：批改结果中与本单元语法点相关的错误单独归类提示（如"本单元语法点：过去时——你写了 start，应为 started"），对应 Zod 字段 `hits_unit_grammar` | P1 |

### 3.7 实操锚点与录像存档（L3 关卡核心）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-7.1 | 锚点任务卡：展示本单元吉他实操任务说明 + 自评 checklist（3–5 项）+ 示范要点 | P0 |
| FR-7.2 | 录像组件：浏览器内录制视频+音频（MediaRecorder，前置/后置摄像头可选，无摄像头时降级为纯音频），限时 ≤3 分钟；**码率 700Kbps / 540p（单条 ≤16MB，v2.1 重算，修复 S-2）；mimeType 探测同 FR-5.1** | P0 |
| FR-7.3 | 自评存档：录制完成 → 回看 → 逐项勾选自评 checklist + 一句英语感想 → 保存入档；支持重录，仅保留学生最终确认版本 | P0 |
| FR-7.4 | 毕业展示录像（U8）：录制"演奏+讲解"综合作品，限时 ≤5 分钟，永久保留入作品集；**毕业判据 = 完成录像提交即毕业，无质量门槛、无管理员终审环节（v2.2 定案：AI 反馈即出分即终分，仅作反馈参考，与 FR-8.2 口径一致）** | P0 |
| FR-7.5 | 学生导出：任意存档录像/录音可随时下载到本地（配额清理前的兜底） | P1 |

### 3.8 作品集与成长曲线（L6 关卡 + 个人主页）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-8.1 | 作品集：按单元归档最终版口语录音、写作文本与锚点录像，卡片式陈列 | P0 |
| FR-8.2 | 成长曲线页：四张折线图——词块累计量、口语 AI 得分趋势、写作词数与错误率趋势、打卡热力图；**首图叠加 U1 基线参考线（U1 各关卡首次成绩，虚线展示，与当前成绩形成前后对照——v2.2 新增：不设独立入学前测，U1 首作即天然基线）**；写作错误率口径定死：`必改错误数 / 总词数 × 100`，由服务端算好存 `review_json.stats.error_rate`，前端只读不算（v2.1 修复 I-8）；**页脚固定文案"AI 评分为学习反馈参考，非权威语言测评"（v2.2 新增：AI 分数仅作反馈工具，不作教学评估结论）** | P0 |
| FR-8.3 | 毕业页（U8 完成后）：生成个人毕业作品汇总页，可分享只读链接；**分享走 `share_tokens` 表（DB-20）：不可猜测 UUID token + 默认 30 天有效期**（v2.4：~~"监护人可见"提示~~ 移除，单用户模式无监护人） | P1 |
| FR-8.4 | **单元评估卡（v2.2 补录，V22-13——X 类缺陷修复：课程设计 v2.1 §6.2 定稿内容传递遗漏）**：每单元 L6 归档时自动汇总生成本单元评估卡，学生可见（v2.4：~~监护人入口同步只读可见~~ 移除）；**只呈现证据、不评级不打分**。三行固定：① 素养锚点 = 实操录像已入档 ✓ + 自评 checklist 完成数 + 一句英语感想摘录；② 语言产出 = L4 口语完成（AI 三维分仅小字标注"反馈参考"）+ L5 写作词数与错误率变化（同口径小字）；③ 过程证据 = 本单元词块过卡数 / 预测与大意问答提交 ✓ / 打卡天数 + **单元专属观察点**（文案随内容灌装，存 units.assessment_note，源为《课程内容细化》各单元"评估卡观察点"）。数据全部来自既有表聚合（anchor_submissions / speaking & writing_submissions / chunk_review / quiz_submissions / streaks），**不新建表、不调 AI** | P0 |

### 3.9 打卡与进度

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-9.1 | 完成任一关卡即自动打卡，首页显示连续天数（断签不清零历史总天数，弱惩罚设计） | P0 |
| FR-9.2 | 不做排行榜、不做虚拟货币（符合 Notion 工具风定位） | P0 |

### 3.10 内容管理后台（管理员）

| 编号 | 需求 | 优先级 |
|---|---|---|
| FR-10.1 | 视频池管理：添加/编辑 YouTube 视频引用（youtube_id、切片起止秒、所属关卡、备选视频），字幕 CC 提取导入 + 人工校对；**CSV 导入必须经 Zod 校验 + 以业务键（如 youtube_id / (unit_no,item_no)）幂等 upsert，重跑不产生重复行（v2.1 明确，修复 I-5；参考实现见《代码示例.md》§8）** | P0（CSV/SQL 直灌即可，页面 P1） |
| FR-10.2 | 语言内容管理：按单元维护词块、单词、语法点（讲解 + 操练题）、句型框架、功能句（内容颗粒度见《课程内容细化-U1-U8.md》） | P0（同上） |
| FR-10.3 | 任务卡管理：每关卡素养目标/语言目标/预计时长/操作清单/自评 checklist | P0（同上） |
| FR-10.4 | AI 质量看板：反馈调用量、JSON 解析失败率、平均延迟、token 消耗、抽检入口（数据源含 `feedback_votes`，DB-19） | P1 |
| FR-10.5 | 视频失效检测任务（见 FR-3.6 双通道） | P1 |

## 4. 非功能需求

| 编号 | 类别 | 要求 |
|---|---|---|
| NFR-1 | 兼容性 | 移动浏览器优先（**试用学生 iOS Safari 与 Android Chrome 各半，双端一等公民，v2.2 明确**：双端全功能适配、无主次之分，E2E 双内核每周与发布前必跑）；PWA 支持"添加到主屏幕"（manifest + 图标 + 安装引导；离线仅可浏览已缓存课程地图，不做离线学习）；摄像头/麦克风依赖 secure context（HTTPS 或 localhost） |
| NFR-2 | 性能 | 首屏 < 3s（4G）；录音 ≤5MB/条、锚点录像 ≤16MB/条（540p/700Kbps/≤3min）、毕业作品 ≤25MB/条（≤5min/≤500Kbps，v2.1 重算）；AI 反馈响应 < 10s，超时给降级文案 |
| NFR-3 | 部署 | **纯本地部署（v2.3 定案，v2.4 去认证）**：独立 Linux 主机 Docker 自托管 Supabase（Postgres + Storage，**v2.4 不启 Auth**——单用户模式无需认证服务）；同一代码库 `npm run build && npm start`（node 进程）+ mkcert 自签证书局域网 HTTPS；学生同一局域网访问，AI 调用（DeepSeek API）与 YouTube 嵌入需外网 |
| NFR-4 | 隐私合规 | 面向未成年人（v2.4 改写）：**首次知情同意页（IX-0 改写）+ 本地部署由家长完成配置即视为监护人授权**；录音录像与文本默认私有，分享需显式操作 + 二次确认；AI 调用日志脱敏（不存学生原文，仅存 submission_id 引用）；**知情同意页如实披露第三方 AI 数据传输（口语转写文本 → DeepSeek、录音音频 → ASR 服务商，仅用于反馈生成、不发送学生身份信息，传输最小化，服务商清单与条款见 §12.3，2026-09-02 修正）**；~~监护人入口/删除链路~~ 废止（FR-1.5 v2.4 废止）；上线前过个保法自评清单并留存记录 |
| NFR-5 | 可靠性 | AI 服务不可用时，任务可标记"稍后获取反馈"，**pending 不阻塞过关、只阻塞入档（§5.2 核心规则）**；视频失效双通道检测自动切换备选（FR-3.6）；**前端运行时错误上报（v2.2 新增）：window.onerror / unhandledrejection 上报 API-19 落 error_logs（DB-26），管理端可查——试用排障刚需** |
| NFR-6 | 存储 | Supabase 自托管本地磁盘（v2.3 改为本地部署，无 1GB 免费层限制）：**锚点录像 14 天滚动保留**（到期转仅元数据并提前 7 天提示导出），草稿音频 24h 清理，仅 U8 毕业作品永久保留；**磁盘占用 ≥80% 触发管理端告警并提前清理最旧非毕业媒体**（STO-4）；磁盘容量为主机磁盘大小，不受云免费层约束 |
| NFR-7 | 成本 | 单学生 8 周 AI 调用成本目标 < 15 元（LLM 实测测算约 0.3 元/生；ASR 国内按量服务 20 生合计预估约 10–110 元区间——各家按量报价差异大，**W5–W6 选型实测后定**，见 §8.10）；v2.3 改为本地自托管后**云服务费 = 0**（无 Vercel/Supabase 订阅费用），主机为自有 Linux 机器，无月租 |
| NFR-8 | **时区口径（v2.2 新增）** | 所有"每日"统计（QUOTA-1 反馈配额、QUOTA-5 上传限流、streaks 打卡、复习队列生成）一律按**北京时间 UTC+8** 计算日界；服务端用固定 +8 偏移计算当日 0 点，**禁止使用服务器本地时间**（Linux 服务器时区可能非 UTC+8，直接用 `setHours` 会导致跨日错算——参考实现见《代码示例.md》§10） |

## 5. 业务流程

### 5.1 学生主旅程

```
首次打开 → 知情同意页（未成年人数据使用说明 + "我已知晓并同意"按钮）
  → Onboarding（吉他水平确认/英语自评/昵称）
  → 进入课程地图 → 首页（今日三件事：待复习词卡 / 当前关卡 / 连续天数）
  → 单元学习循环 ×8（U1→U8，L1→L6 依次解锁）
  → U8 毕业展示（演奏+讲解录像 → 作品集 → 可分享只读链接）
```

### 5.2 单元内学习循环（L1–L6 状态流转 + 完成判据）

```
L1 热身启程   预测问答（看视频前，激活背景知识）→ 词块卡 + 单词表学习 → 语法微课堂（讲解+操练）
L2 看懂视频   YouTube 切片第一遍 → 大意理解问答 → 操作清单勾选
L3 动手操作   精看片段（生词点查/时间戳笔记） → 跟做练习
              → 实操锚点：录像 → 回看 → checklist 自评 → 一句感想 → 入档
              → 问题日志（I got stuck when…）
L4 说出来     录音 → 服务端 ASR 转写 → AI 三维评分+结构化反馈 → 重录对比 → 选版入档
L5 写下来     写作（句型框架侧栏） → AI 分层批改 → 按反馈修改 → 版本入档
L6 展示归档   本单元作品归档 → 成长曲线更新 → 解锁下一单元
```

关卡状态机：`未解锁 → 进行中 → 已完成`；关卡内任意步骤退出后重进恢复断点（P1）。状态机图与各异常路径推演见《流程图与推演.md》§1、§3。

**各关卡完成判据（v2.1 形式化，修复 I-7）**：

| 编号 | 关卡 | 完成判据（全部满足） | 不阻塞项 |
|---|---|---|---|
| LC-L1 | 热身启程 | 词块卡全部过一遍 + 语法操练 2 题提交过 + 预测问答提交 | 自评档位、答对与否 |
| LC-L2 | 看懂视频 | 视频播放到 end_sec（或手动标记"已看完"）+ 大意问答提交 + 操作清单勾选 ≥80% | 问答正确率 |
| LC-L3 | 动手操作 | 锚点录像（或降级纯音频）上传成功 + 自评 checklist 全勾 + 一句感想提交 | 录像质量、问题日志是否填写 |
| LC-L4 | 说出来 | 至少 1 次录音上传成功 + 转写完成（**或已标记 transcript_pending，与 API-10 对齐，v2.2 修复 X-2**） | **AI 反馈 pending 不阻塞**；选版入档可在反馈到达后补 |
| LC-L5 | 写下来 | 至少 1 版作文提交 + AI 批改已返回（或标记 pending 后学生手动确认"先看下一关"） | 是否按反馈修改 |
| LC-L6 | 展示归档 | 确认归档页（单元评估卡 FR-8.4 + 本单元作品集快照）+ 点击"完成本单元" | 成长曲线加载失败不阻塞 |

> **核心规则：AI 反馈 pending 只阻塞"入档"，永不阻塞"过关"。**

### 5.3 AI 反馈流程（含异常与用量控制）

```
[1] 学生提交（口语转写文本+元数据 / 写作文本）
[2] 编排层：用量检查（规则 QUOTA-1～4，见下表）
[3] Prompt 组装：场景模板（版本化）+ 任务卡 + 句型框架 + Rubric + 学生输入
[4] Vercel AI SDK generateObject（deepseek-v4-flash，thinking 显式关闭，JSON 输出）
     ├─ 成功 → Zod schema 校验通过 → [5]
     └─ 失败/校验不通过 → 原样重试 1 次（temperature=0）
          ├─ 成功 → [5]
          └─ 仍失败 → [6]
[5] 结果落库（含 prompt_version、tokens、延迟）→ 前端结构化渲染
[6] 标记 status=pending，展示降级文案（"反馈稍后送达"）
    → 学生下次进入该关卡自动重试（系统重试不占学生配额）→ 仍失败 → 管理员人工处理队列
```

**用量规则（v2.1 口径定死，修复 S-5）**：

| 编号 | 规则 |
|---|---|
| QUOTA-1 | 每生每日**学生主动触发**的反馈调用 ≤3 次，超出提示明日再来；**录音与转写保留，次日可一键重提** |
| QUOTA-2 | 系统自动重试（[4][6] 中的重试）不计入学生配额 |
| QUOTA-3 | 陪练对话**按会话计 1 次**（而非按轮），另设每生每周陪练 ≤2 次；单会话 ≤10 轮硬断 |
| QUOTA-4 | `role ∈ {admin, test}` 账号豁免全部限额（验收测试用测试账号执行；**v2.4 单用户实施口径**：无认证机制，验收/CI 环境将 seed 唯一用户 role 临时置 test 或设环境变量 `QUOTA_BYPASS=true` 豁免，usage.ts 仍按 users.role 判定，验收完毕恢复 student） |
| QUOTA-5 | **媒体上传限流（v2.2 新增）**：每生每日媒体上传（口语录音 + 锚点录像 + 毕业作品合计）≤10 次，超出当日拒绝上传（提示明日再传，学习流程不受影响）；在媒体上传入口统一校验，日界按 NFR-8 北京时间计算 |

陪练对话（P1）走流式接口（`streamText`），不做结构化校验，仅做未成年人护栏（双层：关键词表 + 输出扫描，命中替换固定转向话术并标记复核）。

### 5.4 内容生产流程（管理员，与开发并行）

```
[1] 频道池维护：按单元映射 P0/P1 频道（见课程文档第七节）
[2] 视频筛选：≤5 分钟或可切片 / 有 CC 字幕 / 无区域屏蔽 / 无版权警示 / 语言难度标注
    （操作化检查单见《课程内容细化-U1-U8.md》附录 A.3）
[3] 字幕提取：CC 字幕导出 → 人工校对（对照统一乐理术语表，附录 A.2）→ subtitle_json 落库
[4] 切片打点：确定 start_sec/end_sec，配置 2 个备选视频
[5] 语言内容标注：词块 8–12 + 单词 8–10 + 语法点 1–2 + 句型框架 3 + 功能句
[6] 任务卡编写：素养目标 / 语言目标 / 操作清单 / 自评 checklist
[7] 预生成：词块释义与例句由 LLM 批量生成后人工抽查入库（不进实时调用）
[8] 导入发布：CSV → 导入脚本（Zod 校验 + 幂等 upsert）→ content_version +1；
    进行中学生锁定当前版本完成本单元，下一单元起用新版本（灰度规则）
```

### 5.5 AI 质量抽检与 Prompt 迭代流程（运营）

```
周节奏：
[1] 每周从 ai_call_logs 抽取 20 条反馈样本（口语/写作各半）
[2] 人工按 1–5 分评定反馈质量（是否对齐 Rubric / 是否有幻觉错误）
[3] 平均分 < 4 的场景 → 定位 prompt 问题 → 修改模板（版本 +1，旧版本保留）
[4] 回归验证：新模板对 golden 样本集（20 条，evals/golden/）重放——
    重放按 ai_call_logs.submission_id 回 submissions 表取原文（日志本身不存原文，修复 I-6）；
    门槛：schema 通过率 100%、分数漂移 ≤1 分、必中点命中率不下降 → 激活新版本
监控指标（AI 质量看板）：
  · JSON 解析失败率（目标 < 2%） · 平均响应时长（目标 < 8s）
  · 日 token 消耗与费用 · 学生"反馈没用"点踩率（feedback_votes，DB-19）
```

## 6. 用户交互设计

### 6.1 交互原则
- **一页一事**：每个关卡一个页面，顶栏只放返回、任务卡、打卡状态；
- **拇指可达**：核心操作（录音/录像/提交）底部固定，点击目标 ≥ 44px；
- **反馈分层呈现**：AI 反馈先给结论（分数条）再给细节（可折叠），不一次性砸给读者；
- **失败永远有出口**：AI 超时给降级文案，视频失效切备选，录像失败转纯音频；
- **无障碍底线（v2.1 新增，G-2）**：录音/录像/提交按钮可键盘聚焦并有 aria-label；字幕与正文对比度 ≥ 4.5:1。

### 6.2 知情同意交互流（v2.4 改写，IX-0）
1. APP 首次打开显示知情同意页：未成年人数据使用说明（录音/录像/AI 反馈/作品集用途 + 数据存储于本地服务器 + **如实披露第三方数据传输：口语转写文本发送至 DeepSeek、录音音频发送至 ASR 服务商，仅用于生成学习反馈，不发送学生身份信息，服务商清单见 §12.3**——2026-09-02 修正原"不上传至第三方"的不准确表述）；
2. 学生点击"我已知晓并同意"按钮 → 记录 `users.consent_at` 时间戳 → 进入 onboarding；
3. 同意状态持久化于 DB-01 `users.consent_at`，后续打开不再显示；
4. **~~原监护人确认链路（v2.1 IX-0）废止~~**：单用户本地部署由家长完成安装配置即视为监护人知情同意（NFR-4）。

### 6.3 视频学习器交互流（IX-1）
1. 进入关卡 → 自动定位上次断点（P1）；
2. 播放器（YouTube iframe API）+ 下方字幕条同步滚动高亮当前句；
3. 点击字幕中单词/词块 → 弹出释义卡（预制词表优先，缺失则显示"待收录"+ 系统词典跳转）→ 可一键加入复习队列；
4. 暂停即出现"记一笔"浮层（时间戳笔记）；右侧常驻问题日志入口；
5. 操作清单随播放到指定时间点逐条浮现，勾选后打勾动画；
6. L3 精看模式：字幕可切换 英文/中英/关；
7. 播放错误（onError 101/150）→ 自动切备选视频 + 静默上报，不展示 YouTube 原生错误页；
8. L2 视频播放到 end_sec → 弹出**大意理解问答**（3 道选择题）：逐题作答 → 提交 → 即时展示对错与解析（不调 LLM）；答错不拦过关，解析展示后出现"进入操作清单"按钮（FR-3.7，v2.2 新增）。

### 6.4 口语任务交互流（IX-2）
1. 任务卡展示句型框架（提纲）→ 可折叠；
2. 点击大录音按钮 → 3 秒倒计时 → 波形动画 + 计时；再点停止；
3. 提交 → "转写中…"（服务端 Whisper；iOS 可有 Web Speech 实时预览）→ "AI 评估中…"（骨架屏 ≤ 10s）；
4. 反馈卡片：三个维度分数条（1–5）→ 亮点句（高亮）→ 最多 3 个改进点（每条含示范改写）→ 点踩入口；
5. "再录一次" / "就用这版入档" 二选一；多版本并排对比（转写 + 分数）；
6. 配额超限：提示明日再来，**录音与转写保留**，次日打开一键重提；
7. U6 陪练：对话气泡流式打字机呈现，AI 追问最多 10 轮，随时退出。

### 6.5 写作任务交互流（IX-3）
1. 左侧编辑器 + 右侧可展开句型框架栏，点击句型插入光标处；
2. 实时词数与目标词数（如 100–120 词）进度条；
3. 提交批改 → 分层渲染：① 必改错误（原文红色下划线 + 修改对照行，逐条"知道了"确认）；② 润色建议（默认折叠）；③ 亮点句（绿色高亮 + 一句肯定）；
4. 本单元语法点相关错误单独成组置顶（P1）；
5. "基于反馈修改" → 新版本保存 → 版本对比（diff 高亮）。

### 6.6 实操锚点录像交互流（IX-4）
1. 锚点任务卡：任务说明 + 示范要点 + 自评 checklist 预览；
2. "开始录像" → 摄像头选择（前置默认）→ 设备检测（无摄像头则提示改用纯音频）→ 3 秒倒计时；
3. 录制中：计时上限 3 分钟（U8 为 5 分钟），剩余 30 秒提醒；
4. 录制完成 → 回看（可拖动）→ "重录" 或 "进入自评"；
5. 自评：逐项勾选 checklist + 一句英语感想（输入框，含句型提示）→ "确认入档"；
6. 入档提示存储与清理规则（**14 天滚动**，可随时下载导出）。

### 6.7 AI 反馈呈现统一规范（IX-5）
- 结构固定：先肯定 1 点 → 最多 3 个改进点 → 1 个示范；
- 口语分数条三色阶（青绿系单色深浅，不引入红色差评色）；
- 所有反馈卡片底部："这条反馈有用吗 👍/👎"（写 `feedback_votes`，进质量看板）。

## 7. UI/UX 设计规范（Notion 风）

### 7.1 设计原则
- **内容优先，装饰克制**：白底、大量留白、无渐变无阴影堆砌；
- **一页一事**（同 6.1）；
- **打字机质感**：排版以字体层级而非色块区分信息；
- **仅浅色模式（v2.1 明确，G-1）**：MVP 不做深色模式，不预留半成品切换。

### 7.2 设计 Token

| 编号 | 项 | 规范 |
|---|---|---|
| DT-1 | 背景 | #FFFFFF 主背景；#F7F7F5 卡片底 |
| DT-2 | 文字 | #191919 正文；#737373 次要 |
| DT-3 | 点缀色 | 单一强调色 #2E7D6B（青绿，取"音乐生长"意象），仅用于进度、按钮、当前状态；录像中状态用同色系呼吸圆点 |
| DT-4 | 圆角 | 6px（卡片）/ 4px（按钮） |
| DT-5 | 字体 | 系统字体栈；中文思源黑体，英文 Inter |
| DT-6 | 图标 | Lucide 线性图标，16/20px |
| DT-7 | 进度表达 | 细进度条 + 状态图标（○◐●），不用徽章奖杯 |

### 7.3 关键页面线框（文字级）

**首页**：问候语（按时间）→ 今日三件事卡片（待复习词卡 N 张 / 当前关卡入口 / 连续天数）→ 成长曲线缩略图（最近 4 周一条线）。

**知情同意页（v2.4 改写，替代原待激活页）**：未成年人数据使用说明 + "我已知晓并同意"按钮；同意后写入 `users.consent_at` 并跳转 onboarding。

**课程地图**：Notion 式树状列表；单元行 = 展开箭头 + 单元号与主题 + 素养线标签（乐理/风格/创作，灰色小标签）+ 进度图标（0/6–6/6）；展开后 6 行关卡，右端状态图标。

**关卡页统一骨架**：顶部任务卡（素养目标 + 语言目标 + 时长，可折叠）→ 中部主操作区 → 底部操作栏（提交/下一步）。

**视频学习器页**：上半屏播放器（竖屏时），下半屏 Tab（字幕 / 操作清单 / 笔记）；字幕句同步高亮。

**词卡与语法页**：卡片翻转式词块卡 + 底部三档自评（陌生/模糊/掌握）；语法微课堂 = 上讲解下操练，操练即时打勾。

**L1 预测问答页（v2.2 新增）**：2 道开放题逐题呈现（题干 + 多行输入框 + 参考句型提示）→ "提交"后直接进入词卡学习；页脚说明"没有对错，只记录你的想法"。

**L2 大意问答页（v2.2 新增）**：3 道选择题（单选，选项 ≥44px 点击区）→ 提交后逐题标对错 + 折叠解析 → 底部"进入操作清单"。

**口语任务页**：提纲折叠区（顶部）→ 录音大按钮（底部固定）→ 反馈区（分数条 + 分组反馈 + 版本对比）。

**写作任务页**：编辑器（含字数条）+ 右侧句型框架抽屉 → 批改结果分层卡片 → 版本对比 diff 视图。

**实操锚点页**：任务卡与示范 → 录像区（取景框 + 大按钮）→ 回看 → 自评 checklist → 入档确认。

**作品集/成长曲线页**：时间倒序卡片流（口语/写作/锚点三类卡片，锚点卡片带视频缩略图）；成长曲线页四张折线图 + 热力图。

**L6 归档页（v2.2 补录，FR-8.4）**：单元评估卡（素养锚点 / 语言产出 / 过程证据 + 观察点，三行卡片，只呈现证据不评级）→ 本单元作品集快照 → 底部"完成本单元"。

**~~监护人页~~ → v2.4 废止**：单用户模式无监护人入口；学生作品可通过 FR-7.5 单独下载到本地。

### 7.4 移动端专项
- 录音/录像按钮底部固定、拇指可达；
- 视频学习器竖屏上半屏播放，下半屏字幕 + 清单滚动；
- 录像时锁定竖屏提示（或自动横屏引导，视内容）；横竖屏均可用；
- 所有点击目标 ≥ 44px；焦点态可见（键盘/辅助功能）。

### 7.5 可执行主题配置与组件状态规范（2026-09-02 补录）

设计 Token（§7.2）与交互规范（§6）的**唯一可执行落地源**为同目录《前端设计规范-主题配置与组件状态.md》——内含 `globals.css` 全局 CSS 变量清单（含强调色 hover/active/subtle 派生与 shadcn/ui 语义别名）、完整 `tailwind.config.ts`、组件五态规范（default/hover/active/focus-visible/disabled/loading）、骨架屏/空状态/错误降级态规则与业务组件（反馈卡/词块卡/热力图/diff）规格；可视化预览见《风格稿-style-guide.html》（渲染截图《风格稿-preview.png》）。
- **强调色派生口径**：`#2E7D6B` 的 hover/active/subtle 三级派生（#256A5B / #1F5A4D / #E4F0ED）属同一强调色的明度变体，不视为"新增强调色"；
- **功能色口径**：danger `#B3261E` / warning `#B26A00` 仅用于错误/告警的文字与图标，不作装饰强调；
- 偏离本规范的 PR 按 project_rules §6.1 打回。

## 8. 技术架构与技术栈

### 8.1 AI 应用形式：调研结论（定案）

针对"是否基于开源 DeepSeek harness 整合"，调研结论如下（约束：纯免费额度、无 GPU、单人开发、未成年人数据敏感）：

| 候选路线 | 结论 | 依据 |
|---|---|---|
| 自部署 DeepSeek 开源模型（Ollama/vLLM） | ❌ 不可行 | 7B 蒸馏版需 5GB+ 显存；免费额度无 GPU；小模型对教育批改稳定性不足 |
| 自部署编排平台（Dify/FastGPT/n8n） | ❌ 不采用 | 需 2C4G 独立服务器 + Docker 运维栈，超出免费额度；对 Next.js 单体项目是负担 |
| **DeepSeek API + Vercel AI SDK + 自建轻量编排层** | ✅ **采用** | Vercel AI SDK（`@ai-sdk/deepseek`）即本技术栈下"开源 harness"的正确形态：原生集成 App Router、流式输出、Zod 结构化输出、provider 一键切换；DeepSeek 官方 OpenAI 兼容接口，成本极低 |

要点：
- 模型 `deepseek-v4-flash`（旧模型名 deepseek-chat / deepseek-reasoner 已于 2026-07-24 如期弃用，本结论经 2026-09 外部核验）；官方定价：输入（缓存未命中）约 1 元/百万 token、输出约 2 元/百万 token、缓存命中约 0.02 元/百万（以官方定价页为准）；
- **v4-flash 默认开启思考模式（thinking mode）**，本项目全部调用必须显式传 `thinking: {"type":"disabled"}`，否则延迟与 token 成本同时失控（v2.1 强化，修复 I-1，固化于代码见《代码示例.md》§1）；
- 新开发者账号有免费 token 赠金（第三方信息，以账号实际为准）；
- 备份 provider：任意 OpenAI 兼容接口（环境变量切换，不改代码）。

### 8.2 选型总表

| 层 | 选型 | 理由 |
|---|---|---|
| 前端框架 | **Next.js 14（App Router）+ TypeScript** | 前后端同仓，AI 编程助手生成质量高；SSR/SSG 兼顾速度；本地部署（node 进程） |
| UI 组件 | **Tailwind CSS + shadcn/ui** | 与 Notion 风契合；组件源码在本地，AI 易改 |
| 图表 | Recharts（热力图自绘格子） | 成长曲线折线图 |
| AI SDK | **Vercel AI SDK（`ai` + `@ai-sdk/deepseek`）** | 开源 harness；`generateObject` 结构化输出 + `streamText` 流式；provider 可切换 |
| LLM | **deepseek-v4-flash**（**thinking 显式关闭**） | 成本极低、1M 上下文、JSON Output 原生支持 |
| ASR | **主：云端 Whisper 兼容服务（按量付费）；增强：iOS Safari Web Speech 实时预览**（v2.1 反转，修复 S-1） | 大陆 Android Chrome 无 Google 服务可达性，Web Speech 不能作主路径；且 Web Speech 无法回放已录音频 |
| TTS | MVP：浏览器 Speech Synthesis；二期：云端 TTS API | 零成本起步 |
| 后端 | **Next.js API Routes**（同仓） | MVP 阶段单代码库最快；本地模式即 node 进程 |
| 数据库 + 存储 | **Supabase 自托管**（Docker，Postgres + Storage，**v2.4 不启 Auth**——单用户无需认证；**全部私有桶 + RLS**，见 §8.8.1） | 本地 Docker，无配额限制 |
| ORM | Drizzle | 类型安全，AI 生成迁移方便 |
| 部署 | **纯本地**：Linux 主机 node 进程 + Docker Supabase + mkcert HTTPS | v2.3 定案，移除云端模式（见 §8.4） |
| 视频 | **YouTube iframe embed（react-youtube）** + 自存字幕/切片元数据 | 不下载不分发；onError 上报支撑失效检测 |
| 间隔重复 | ts-supermemo（SM-2 简化映射三档自评） | 成熟算法不自研 |
| 测试 | Vitest + React Testing Library + MSW + Playwright | 见《测试方案.md》 |

### 8.3 分层架构

```
┌─────────────────────────────────────────────────────┐
│ 学生浏览器（PWA）                                      │
│  ├ UI 层：Next.js App Router 页面 + shadcn/ui         │
│  ├ 媒体采集：MediaRecorder（mimeType 探测：mp4/webm）  │
│  └ 前端 ASR 预览：Web Speech API（仅 iOS 增强）        │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS
┌──────────────────────▼──────────────────────────────┐
│ Next.js 服务层（Linux 主机 node 进程）                  │
│  ├ 页面路由（SSR/SSG）                                │
│  ├ API Routes（业务编排，见 8.6 契约）                 │
│  └ AI 编排层 lib/ai（见 8.5）                          │
│     ├ provider.ts：createDeepSeek() + 备份 provider    │
│     │   （thinking=disabled 固化）                     │
│     ├ prompts/：场景模板（版本化）                     │
│     ├ schemas/：Zod 输出校验                          │
│     ├ retry.ts / usage.ts / guard.ts / logger.ts      │
└───────┬──────────────┬───────────────┬───────────────┘
        │              │               │
   Supabase          DeepSeek API     YouTube iframe
   DB / Storage      (v4-flash +      (嵌入播放，
   （v2.4 不启 Auth）  备份 provider)   字幕元数据自存)
        │              │
        │        云端 Whisper 兼容服务（ASR 主路径）
   oEmbed 日检（视频失效检测通道①）
```

### 8.4 部署模式（纯本地部署，v2.3 定案）

> v2.3 变更：移除 Vercel 云端模式。原因：① `*.vercel.app` 域名在大陆被 DNS 污染 + SNI 阻断，学生基本不可直接访问；② 数据库本地化后 Vercel 云端 Serverless 函数无法访问本机 Docker 数据库，双模式失去意义。唯一交付形态为本地部署。

| 项 | 说明 |
|---|---|
| 部署主机 | 独立 Linux 主机（旧笔记本/小主机），常开运行，无月租 |
| 服务运行 | `npm run build && npm start`（Next.js node 进程），systemd 管理 |
| 数据库/存储 | Docker Compose 自托管 Supabase（Postgres + Storage，v2.4 不启 Auth），同一台 Linux 主机 |
| HTTPS 证书 | mkcert 自签根证书，局域网设备安装后信任 |
| 访问链路 | `https://<局域网IP>:3000`（学生同一局域网访问） |
| 外网依赖 | 仅 DeepSeek API 调用 + YouTube iframe 嵌入（需主机可出墙） |
| 麦克风/摄像头 | secure context 必须保证——mkcert HTTPS 或 localhost 访问，**局域网 IP 裸 HTTP 不可用** |

**mkcert 根证书需逐台学生设备安装，iOS 还需在"设置→通用→关于本机→证书信任设置"中手动完全信任**（G-5）；提供一键脚本 + 图文指引，不可行时退化 localhost 单机模式。

### 8.5 AI 编排层设计（harness 组件）

```
lib/ai/
  provider.ts    # DeepSeek 主 + OpenAI 兼容备份（env 切换）
                 # 【固化参数】thinking: {type:"disabled"}、temperature≤0.3、timeout 9s
  prompts/       # speaking_eval / writing_review / coach_chat / chunk_pre
                 # 每个模板带 version 常量，写入 ai_call_logs.prompt_version
                 # 改模板 = 新增版本常量，旧版本保留供回归重放
  schemas/       # Zod：SpeakingFeedback / WritingReview / CoachTurn
  retry.ts       # 失败或校验不过 → 原参重试 1 次（temperature=0）→ 降级 pending
  usage.ts       # QUOTA-1～4：学生主动调用 ≤3/日；系统重试不计；admin/test 豁免
  guard.ts       # 未成年人护栏双层：输入注入过滤 + 输出敏感词扫描
                 # （陪练 system prompt 必含"不索取个人信息/只聊音乐学习/越界转向"）
  logger.ts      # 脱敏日志：kind/prompt_version/tokens/延迟/错误码 + submission_id 引用
                 # 【禁止】写入学生原文；重放按 submission_id 回表取原文（修复 I-6）
```

Prompt 版本化与灰度：模板改动 → 版本 +1 → golden 样本集（20 条）回归（§5.5 门槛）→ 激活。

### 8.6 API 契约

| 编号 | Method | Path | 输入 | 输出 | 说明 |
|---|---|---|---|---|---|
| API-01 | POST | /api/speech/feedback | lessonId, submissionId, transcript, durationMs, pauses | scores{completeness,fluency,clarity 1–5}, praise, suggestions[], model_answer | 口语评估；服务端组装 prompt → generateObject；`maxDuration=60` |
| API-02 | POST | /api/writing/review | lessonId, content, version | blocking_errors[{original,corrected,reason,hits_unit_grammar}], polish[], highlights[], stats{words,error_rate,grammar_hits} | 写作批改；error_rate 服务端计算（FR-8.2 口径） |
| API-03 | POST | /api/coach/chat | lessonId, sessionId, messages[] | SSE 流式文本 | AI 陪练（U6）；≤10 轮硬断；护栏注入；会话计次（QUOTA-3） |
| API-04 | POST | /api/anchor/submit | lessonId, videoPath, mimeType, selfCheck[], note | status | 锚点录像存档；**无 AI 评估** |
| API-05 | GET | /api/lessons/[id] | — | 任务卡/视频切片/词块/语法点/句型框架/L1·L2 问答题（**不下发 answer**，判分一律服务端进行）+ content_version | 关卡内容（SSG/缓存）；进行中学生锁定当前版本 |
| API-06 | GET | /api/review/queue | — | 今日待复习词块+单词 | SM-2 简化 |
| API-07 | POST | /api/submissions/finalize | type, refId | status | 学生选版入档 |
| API-08 | GET | /api/progress | — | 关卡状态/打卡/曲线数据 | 个人主页 |
| API-09 | POST | /api/admin/ai-audit/replay | promptVersion, sampleIds[] | 重放结果 | 质量回归；按 submission_id 回表取原文（§5.5） |
| API-10 | POST | /api/asr/transcribe | audioPath, mimeType | transcript | **ASR 主路径**（Whisper 兼容服务）；失败标记 transcript_pending，不阻塞过关 |
| API-11 | GET | /api/share/[token] | — | 毕业作品集只读视图 | share_tokens 校验有效期（FR-8.3） |
| API-12 | ~~POST~~ | ~~`/api/guardian/confirm`~~ | — | — | **v2.4 废止**（单用户模式无监护人确认链路） |
| API-13 | ~~POST~~ | ~~`/api/guardian/delete-request`~~ | — | — | **v2.4 废止**（单用户模式无账号删除流程） |
| API-14 | POST | /api/videos/report-error | videoId, errorCode | status | 学生端 iframe onError 上报（FR-3.6 通道②） |
| API-15 | POST | /api/quiz/submit | lessonId, phase(L1_predict/L2_comprehension), answers[{questionId, answer}] | 判分结果[{questionId, isCorrect, explanation}]（L1_predict 恒 null 不判分） | **问答提交（v2.2 新增）**：L2 服务端对固定答案库即时判分，**不调 LLM**；L1 仅落库并同步问题日志素材（FR-3.7/4.6） |
| API-16 | ~~GET~~ | ~~`/api/guardian/portal`~~ | — | — | **v2.4 废止**（单用户模式无监护人入口） |
| API-17 | ~~POST~~ | ~~`/api/guardian/export`~~ | — | — | **v2.4 废止**（单用户模式无批量导出；学生可经 FR-7.5 单独下载） |
| API-18 | ~~POST~~ | ~~`/api/guardian/resend`~~ | — | — | **v2.4 废止**（单用户模式无确认邮件重发） |
| API-19 | POST | /api/errors/report | message, stack, url, userAgent, userId? | status | **前端运行时错误上报（v2.2 新增，NFR-5）**：window.onerror/unhandledrejection + React error boundary 统一捕获，写 error_logs（DB-26）；静默失败不影响用户 |

### 8.7 核心链路时序

**口语任务全链路（目标 < 15s，v2.1 按 ASR 反转修订）**：
```
[1] 录音结束 → 音频上传 Supabase Storage（直传，≤5MB，mimeType 随行）
[2] POST /api/asr/transcribe（Whisper 兼容服务）
     ├ 成功 → transcript 落库
     └ 失败 → 重试 1 次 → 仍失败：标记 transcript_pending，本关可完成，反馈排队
    （iOS Safari 可并行展示 Web Speech 实时预览，仅增强不采信）
[3] POST /api/speech/feedback
[4] usage 检查（QUOTA-1～4）→ prompt 组装（模板 vN + 任务卡 + 句型 + 转写 + 时长/停顿元数据）
[5] generateObject(deepseek-v4-flash, thinking=disabled) → Zod 校验
     ├ 通过 → [6]
     └ 不通过 → 重试 1 次 → 仍失败 → pending + 降级文案
[6] 落库 speaking_submissions（含 prompt_version/tokens/延迟）
[7] 前端结构化渲染反馈卡
```

时序预算：上传 2s + 转写 3s + LLM 5s + 渲染 1s ≈ 11s。本地 node 进程无 Serverless 函数时长限制，但仍设 60s 请求超时兜底降级（`maxDuration` 保留以兼容潜在未来云迁移场景）。

**写作批改链路**：同构，[4] 中输入为文本+本单元语法点，[5] 输出三层结构（必改/润色/亮点）+ stats.error_rate 服务端计算。

**内容生产链路**：管理端录入视频引用 → oEmbed 探测 → 拉取 CC 字幕 → 人工校对落库 → 标注词块/语法点/任务卡 → CSV 幂等导入 → content_version 发布 → 学生端按版本加载（进行中锁定旧版本）。

### 8.8 核心数据模型（Postgres）

| 编号 | 表 | 关键字段 |
|---|---|---|
| DB-01 | users | id, nickname, role(student/admin/test), guitar_level, english_self_eval, **consent_at**（v2.4 替代 guardian_confirmed_at——知情同意时间戳）, created_at |
| DB-02 | units / lessons | id, unit_no, lesson_no(L1–L6), title, skill_goal, lang_goal, grammar_point, sentence_frames, checklist_json, self_check_json, assessment_note（单元评估卡观察点，v2.2 补录 FR-8.4，随内容灌装）, content_version |
| DB-03 | chunks | id, unit_no, item_no, text, meaning, example, audio_url —— 唯一约束 (unit_no, item_no)（幂等导入键） |
| DB-04 | vocab | id, unit_no, item_no, word, pos, phonetic, meaning, example —— 唯一约束 (unit_no, item_no) |
| DB-05 | chunk_review | user_id, item_id, item_type(chunk/vocab), familiarity(0/1/2), streak, next_review_at |
| DB-06 | grammar_points | id, unit_no, name, explain_md, exercises_json |
| DB-07 | videos | id, lesson_id, youtube_id, start_sec, end_sec, title, channel, priority, subtitle_json, status(active/disabled/region_blocked) —— 唯一约束 youtube_id |
| DB-08 | problem_logs | user_id, lesson_id, source(manual/quiz_l1，区分手工记录与 L1 问答同步素材), content, created_at |
| DB-09 | speaking_submissions | id, user_id, lesson_id, audio_path, mime_type, transcript, duration_ms, scores_json, feedback_md, status(ok/pending/transcript_pending), is_final, version |
| DB-10 | writing_submissions | id, user_id, lesson_id, content, review_json（含 stats.error_rate）, grammar_hits_json, version, created_at |
| DB-11 | anchor_submissions | id, user_id, **lesson_id**（v2.1 由 unit_no 改为外键对齐）, video_path, mime_type, media_type(video/audio), self_check_json, note, is_final, created_at |
| DB-12 | portfolio_items | user_id, type(speaking/writing/anchor), ref_id, unit_no |
| DB-13 | streaks | user_id, date, lesson_id |
| DB-14 | ai_call_logs | id, user_id, kind, prompt_version, tokens_in, tokens_out, latency_ms, status, error_code, source(student/system), **submission_id（引用，不存原文）**, created_at |
| DB-15 | prompt_templates | id, kind, version, content, active |
| DB-16 | **lesson_progress（v2.1 新增，修复 S-3①）** | user_id, lesson_id, step, position_sec, checklist_state_json, content_version（首见版本锁定，与 DB-25 联动：进行中学生按此版本取内容）, updated_at —— 主键 (user_id, lesson_id) |
| DB-17 | **coach_sessions（v2.1 新增，修复 S-3②）** | id, user_id, lesson_id, turn_count（≤10 在此强制）, created_at |
| DB-18 | **coach_messages（v2.1 新增，修复 S-3②）** | id, session_id, role(user/assistant), content, flagged（护栏命中）, created_at |
| DB-19 | **feedback_votes（v2.1 新增，修复 S-3③）** | id, user_id, submission_type(speaking/writing), submission_id, helpful, created_at |
| DB-20 | **share_tokens（v2.1 新增，G-3）** | token（UUID 主键）, user_id, expires_at（默认 30 天） |
| DB-21 | **quiz_questions（v2.2 新增，问答系统）** | id, lesson_id, phase(L1_predict/L2_comprehension), question_no, type(open/mcq), question_text, options_json（选择题选项）, answer（选择题正确项；开放题为 null）, explanation（选择题解析）, content_version —— 随内容灌装 CSV 导入，幂等键 (lesson_id, phase, question_no) |
| DB-22 | **quiz_submissions（v2.2 新增，问答系统）** | id, user_id, question_id, answer_text, is_correct（开放题为 null）, created_at —— L1 开放作答同步复制一份进 problem_logs 作写作素材（FR-4.6） |
| DB-23 | **notes（v2.2 新增，FR-3.3 时间戳笔记）** | id, user_id, lesson_id, position_sec, content（英语关键词）, created_at |
| DB-24 | **~~guardian_tokens~~ → v2.4 废止**（单用户模式无监护人链路；编号保留不复用，表不创建） |
| DB-25 | **content_versions（v2.2 新增，内容版本锁定）** | version（自增主键）, published_at, published_by, change_note, status(active/locked) —— 每次全量导入 +1；进行中学生锁定其当前版本号（users 无需存版本，lesson_progress 记录首见版本） |
| DB-26 | **error_logs（v2.2 新增，前端错误上报）** | id, user_id（可空）, message, stack（截断 ≤2KB）, url, user_agent, released_version, created_at —— 仅用于排障，不进学生可见功能（v2.4：~~账号删除时随行清除~~ SEC-4 已废止） |

#### 8.8.1 安全策略（v2.1 新增，修复 I-2）

| 编号 | 策略 |
|---|---|
| SEC-1 | 全部学生数据表启用 RLS（**v2.4 改写**：单用户模式不启 Supabase Auth，策略由 `auth.uid() = user_id` 改为**固定 user_id 过滤**——仅 seed 预设的唯一学生 ID 可读写，不依赖 `auth.uid()`，与 project_rules §5.1 同口径）；迁移 PR 未带 RLS 策略不予合入（SQL 示例见《代码示例.md》§9） |
| SEC-2 | Storage 全部私有桶，读写走 ≤15 分钟签名 URL；媒体路径规范 `{user_id}/{unit_no}/{kind}/{uuid}.{ext}` |
| SEC-3 | 分享不公开 Storage 路径：毕业页只读视图走 `share_tokens`（DB-20）+ 服务端渲染 |
| SEC-4 | ~~账号删除~~ → **v2.4 废止**（单用户模式无账号删除流程；如需清除数据，开发者直接操作 Docker Supabase 管理界面） |
| SEC-5 | 密钥管理：`SUPABASE_SERVICE_ROLE_KEY`、`DEEPSEEK_API_KEY` 只在服务端；`NEXT_PUBLIC_` 前缀仅允许匿名 key |

### 8.9 存储与配额管理（v2.1 重算，修复 S-2）

| 编号 | 介质 | 参数 | 保留策略 |
|---|---|---|---|
| STO-1 | 口语录音 | Opus/MP4，≤5MB/条 | 最终入档版保留；草稿 24h 清理 |
| STO-2 | 锚点录像 | ≤3 min，**540p / 700Kbps，≤16MB/条**（浏览器端 MediaRecorder bitrate 参数控制） | **14 天滚动保留** → 到期转仅元数据（自评+感想保留，视频删除，提前 7 天提示导出）；学生可随时下载 |
| STO-3 | 毕业作品（U8） | ≤5 min，**≤500Kbps，≤25MB/条** | 永久保留 |
| STO-4 | 稳态估算 | 20 生：14 天窗口 × 2 条/生 × 16MB ≈ 640MB + 毕业作品 500MB ≈ **峰值 1.1GB** | **磁盘占用 ≥80% 告警（管理端，W7 实现）触发最旧非毕业媒体清理**（v2.3：本地磁盘无 1GB 云限，但 14 天清理与告警机制保留以控制磁盘与维护数据卫生） |
| STO-5 | ~~本地扩展~~ → **已归并（v2.3）** | ~~StorageAdapter 抽象，local-fs 实现二期~~ → v2.3 改为纯本地部署后 Storage 直写 Docker Supabase 本地卷，无需额外适配层 | ~~写本地磁盘绕开 1GB 限制~~ → 已无此问题 |

### 8.10 成本测算（20 名学生 / 8 周，v2.1 修订）

| 项目 | 用量 | 费用 |
|---|---|---|
| 口语反馈 | 8 次 × 2（含重录）× 20 生 ≈ 320 次 × ~1.7K in + 0.5K out | ≈ 1.0 元 |
| 写作批改 | 同上量级 | ≈ 1.2 元 |
| 陪练对话（P1） | 8 次 × 10 轮 × 20 生 | ≈ 1.5 元 |
| 内容预生成（一次性） | 词块/单词/例句/操练题批量 | ≈ 2 元 |
| **ASR（Whisper 兼容，v2.1 新增行）** | 320 次 × 平均 60 秒 ≈ 320 分钟；各家按量报价差异大（约 0.03–0.35 元/分钟） | **≈ 10–110 元区间（待 W6 选型实测复核，与 NFR-7 同口径）** |
| **合计** | — | **≈ 16–116 元区间**（LLM 约 5.7 元 + ASR 区间；预算 300 元，仍在富余区间） |

## 9. MVP 排期（8 周）

| 编号 | 周 | 目标 | 交付物 |
|---|---|---|---|
| MS-W1 | W1–W2 | 脚手架（**建议以 Supabase Vercel AI Chatbot 为起点**，见 §12.2）+ **知情同意页 + 简化 onboarding（v2.4 改写）** + 课程地图 + 关卡状态机 + **前端错误上报接入（API-19）** + **本地部署套件（Docker Supabase + mkcert HTTPS + systemd，v2.3 新增）** | 知情同意后进入、可看到 8 单元地图逐关解锁；局域网 HTTPS 可访问 |
| MS-W2 | W3–W4 | 视频学习器（YouTube 嵌入+字幕自存+切片+onError 上报）+ 词卡/单词 + 语法微课堂 + 问题日志 + **问答组件（L1 预测问答 + L2 大意问答，API-15/DB-21/22，v2.2 新增）** + 锚点录像组件（540p/700Kbps + mimeType 探测 + QUOTA-5 限流） | L1–L3 三类关卡完整可用 |
| MS-W3 | W5–W6 | AI 编排层（SDK/prompt/schema/retry/usage/guard/logger）+ 口语任务闭环（含 Whisper 主路径）+ 写作任务闭环；**U1–U3 内容 W5 前完成灌装用于联调（v2.1 前置，G-4）；W6 完成 Whisper 成本实测复核（NFR-7）** | L4–L5 打通，内部自测 |
| MS-W4 | W7 | 作品集 + 成长曲线 + 打卡 + 内容灌装工具链（CSV 幂等导入 + 字幕导入脚本）+ **存储清理 cron 与 80% 磁盘告警（STO-4）** | L6 与首页完整；内容可无代码上线 |
| MS-W5 | W8 | 内容灌装（8 单元视频池/词块/语法点/任务卡，按课程文档第七节标准与《课程内容细化-U1-U8.md》附录 A.3 检查单）+ 打磨 + 试用部署（本地局域网） | 10–20 名学生小范围试用 |

（内容生产流程 §5.4 自 W5 起与开发并行推进。）

**二期**：教师点评入口、M4 提示词模块、AI 陪练升级、演奏音频分析评估、生词点查扩展、毕业分享页增强。
**三期**：M2/M3 模块、班级功能、原生封装。

## 10. 验收标准

| 编号 | 标准 | 对应 E2E（《测试方案.md》§4） |
|---|---|---|
| AC-01 | 一名新学生从知情同意到完成 U1 全部 6 关（含锚点录像存档），无需任何人工协助 | E1 |
| AC-02 | L4 口语任务：录音 → 服务端转写 → 三维评分 + 结构化反馈，全链路 < 15 秒 | E1 + 时序集成测试 |
| AC-03 | L5 写作任务：批改结果按 JSON 结构稳定渲染，连续 20 次提交无格式崩坏（**测试账号执行，QUOTA-4 豁免**）；本单元语法点错误正确归类（P1 项） | E4 |
| AC-04 | 成长曲线页正确反映至少 4 周历史数据 | E1 |
| AC-05 | iOS Safari 与 Android Chrome 全功能可用（含摄像头录像、mp4/webm 双格式链路） | E2 |
| AC-06 | AI 服务手动断网测试：学习主流程不阻塞，pending 反馈次日自动重试（不占学生配额） | E3 |
| AC-07 | 本地部署：一条命令启动（Docker Compose + node）+ 局域网 HTTPS 访问，麦克风/摄像头可用 | E6 |
| AC-08 | 内容无代码上线：新增一个单元的全部内容（视频/词块/语法点/任务卡）仅通过 CSV/后台完成，且重复导入不产生重复行（幂等） | E7 |
| AC-09 | 存储配额：14 天滚动清理策略生效，80% 告警触发正确，平台稳态占用受控（峰值 ≤1.1GB 且告警先于硬上限触发） | E8 |
| AC-10 | **~~监护人链路~~ → v2.4 废止**：知情同意页替代确认链路（AC-01 覆盖）；~~E10 删除流~~ 移除 | ~~E1 + E10~~ → E1 |
| AC-11 | **问答系统（v2.2 新增）**：L1 预测问答提交后不作判分且作答出现在问题日志素材库；L2 大意问答提交后即时判分展示对错与解析、全程无 LLM 调用；两类问答均不阻塞过关（LC-L1/LC-L2） | E9 + 集成测试 |

### 10.1 试用期成功标准（v2.2 新增，定量化）

试用结束（8 周课程 + 1 周缓冲）后按以下门槛判定 MVP 教学目标达成与否；未达标项触发对应复盘动作，**不自动解锁需求变更**（仍走 §0.1 冻结解除流程）：

| 编号 | 指标 | 门槛 | 数据来源 |
|---|---|---|---|
| TS-1 | 课程完成率 | ≥60% 试用学生完成 U8 全部 6 关（完成即毕业，FR-7.4） | lesson_progress / portfolio_items |
| TS-2 | 关键流失点 | U3–U4 期间流失率 <20%（RSK-7 首座高峰验证） | streaks 中断 + 最后活跃关卡 |
| TS-3 | AI 反馈接受度 | 反馈卡点踩率（feedback_votes）中 👍 占比 ≥70%，且点踩样本周抽检平均分 ≥4 | feedback_votes / §5.5 抽检 |
| TS-4 | 实操锚点完成率 | ≥80% 学生每单元 L3 锚点录像真实上传（非纯音频降级占比 ≤20%） | anchor_submissions.media_type |
| TS-5 | 教学口径验证 | 成长曲线显示：≥60% 学生 U8 口语三维均分或写作错误率相对 U1 基线有可测进步（"音乐领域内 B1"的过程性证据） | FR-8.2 曲线数据（AI 分数仅作反馈工具，此处仅统计不作结论） |

## 11. 风险与对策

| 编号 | 风险 | 对策 |
|---|---|---|
| RSK-1 | YouTube 视频 Content ID/下架/区域屏蔽 | 仅 iframe 嵌入不下载不分发；高风险频道（如 Rick Beato）不进学生端；每关卡 2 个备选；双通道失效检测（FR-3.6） |
| RSK-2 | 字幕自存与点查的版权灰色地带 | 字幕仅内部学习用途（点查/高亮）；统一术语表自建；不对外分发字幕文件；商业化前法务复核 |
| RSK-3 | ~~Web Speech API 在 iOS 上识别不稳定~~ → **大陆网络环境 Web Speech 不可用（v2.1 改写，修复 S-1）** | ASR 主路径反转为云端 Whisper 兼容服务；Web Speech 仅作 iOS 增强预览；成本已在 §8.10 补测 |
| RSK-4 | AI 反馈质量不稳定 | Prompt 版本化 + 周抽检 20 条 + golden 回归门槛（schema 100%/漂移 ≤1 分）+ JSON 失败率监控 |
| RSK-5 | ~~免费层配额（存储 1GB / 函数时长）~~ → **本地磁盘容量与主机运维（v2.3 改写）** | 14 天滚动清理 + 录像压缩参数（540p/700Kbps）+ 80% 磁盘告警；v2.3 改为本地自托管后无云免费层配额限制，但主机须常开、磁盘须有富余（建议 ≥20GB 可用空间） |
| RSK-6 | 未成年人合规（v2.4 改写） | 知情同意页 + 本地部署家长授权、数据私有默认、脱敏日志（只存引用）、双层护栏，上线前过个保法自评清单 |
| RSK-7 | 学生中途流失（U3 蓝调 / U4 即兴为首座高峰） | 单关卡体量控制、锚点任务分段小目标、AI 鼓励话术；试用数据验证后再调 |
| RSK-8 | 局域网 HTTPS 证书安装门槛（v2.3：纯本地部署后为学生设备唯一入口，风险升级） | 提供一键脚本 + 图文指引（含 iOS 证书信任步骤）；不可行时退化 localhost 单机模式 |
| RSK-9 | YouTube 大陆直连可行性假设 | 学习者画像假设"可直连 YouTube"是强假设；试用招募时把网络条件列为筛选/告知项，失败案例收集后评估备选视频源方案 |

## 12. 参考来源

### 12.1 官方文档
- DeepSeek API 定价与模型：https://api-docs.deepseek.com/zh-cn/quick_start/pricing
- DeepSeek API 更新日志（旧模型弃用，2026-09 核验）：https://api-docs.deepseek.com/zh-cn/updates
- Vercel AI SDK DeepSeek Provider：https://ai-sdk.dev/providers/ai-sdk-providers/deepseek
- Supabase 自托管文档：https://supabase.com/docs/guides/self-hosting
- Supabase Docker Compose：https://github.com/supabase/supabase/tree/master/docker

### 12.2 GitHub 开发基础调研结论（v2.1 新增）
- **脚手架起点（推荐）**：Supabase Vercel AI Chatbot（github.com/supabase-community/vercel-ai-chatbot）——Next.js App Router + Supabase Auth/Postgres + Vercel AI SDK + shadcn/ui，与本项目栈基本重合；fork 后删除聊天业务页再建课程域（v2.4：同时移除其 Auth 依赖模块，改为 seed 固定用户）；
- **AI 层参考实现**：vercel/ai-chatbot（官方）——lib/ai 组织、流式 UI、结构化输出范式对照；
- **备选**：vercel/next.js 的 with-supabase 示例（若前者依赖过旧）；
- 配套库：react-youtube（iframe 控制与 onError）、ts-supermemo（SM-2）、lucide-react、Recharts。

### 12.3 第三方服务与条款清单（2026-09-02 补录，FIX-09）

| 服务 | 用途 | 性质与条款要点 | 传输数据 |
|---|---|---|---|
| DeepSeek API（deepseek-v4-flash） | 口语/写作反馈、AI 陪练、内容预生成 | 商业按量付费（预充值制）；平台协议禁止转售与不合理负载；模型权重 MIT 开源不限商用；无硬性 rate limit，新账号有赠金（以官方页面为准） | 口语转写文本、写作文本、任务卡/prompt 上下文——**不发送学生姓名等身份信息** |
| 云端 Whisper 兼容 ASR（国内供应商，W6 选型定） | 录音转写主路径（FR-5.2） | 商业按量付费，受供应商服务条款约束；成本区间见 §8.10 | 录音音频（任务必需最小集） |
| YouTube iframe 嵌入 / oEmbed 探测 | 视频播放、失效检测（FR-3.6） | 平台免费功能，受 YouTube 服务条款约束；内容版权归创作者；只嵌入不下载（RSK-1）；字幕自存为教育内部使用灰色地带，商业化前法务复核（RSK-2） | 无学生数据；播放行为数据归 YouTube |
| 浏览器内置 API（Web Speech / MediaRecorder / Speech Synthesis） | iOS 转写预览增强、媒体采集、TTS 朗读 | 免费、无许可问题 | 本地处理为主（Web Speech 识别由浏览器厂商引擎处理，仅 iOS 增强预览，不作主路径） |

> 合规注记：知情同意页必须如实披露前两项的数据传输（§6.2 / NFR-4 / IX-0），个保法自评清单（T-0503）逐项核对本表；更换 ASR 供应商或新增任何第三方服务时，必须先更新本表与知情同意页文案再上线。

## 13. 修订记录

### 13.1 v2.2（需求访谈定稿）

| 修订编号 | 内容 | 落点（编号索引） |
|---|---|---|
| V22-01 | L1 预测问答 + L2 大意问答（问答系统） | FR-4.6 / FR-3.7 / §5.1–5.2 / §6.3[8] / §7.3 / API-15 / DB-21/22 / AC-11 |
| V22-02 | 注册收敛为仅邮箱 | FR-1.1 / §1.3 / §6.2 |
| V22-03 | 监护人链路补全（token 凭据/导出/重发/删除冷静期） | FR-1.5 / FR-1.6 / API-16/17/18 / DB-24 / MS-W1 |
| V22-04 | U8 砍管理员终审，完成即毕业 | FR-7.4 |
| V22-05 | 时区口径（北京时间 UTC+8） | NFR-8 / QUOTA-5 |
| V22-06 | 媒体上传限流 | QUOTA-5 / MS-W2 |
| V22-07 | 前端错误上报 | NFR-5 / API-19 / DB-26 / MS-W1 |
| V22-08 | content_versions 版本锁定表 | DB-25 / §5.4[8] |
| V22-09 | 教学目标口径定案（音乐领域内 B1 / U1 首作基线 / AI 分数仅反馈工具） | §2 / FR-8.2 / §10.1 TS-5 |
| V22-10 | 试用期量化成功标准 | §10.1 TS-1～TS-5 |
| V22-11 | 需求冻结 | §0.1 |
| V22-12 | 一致性修复：LC-L4 与 API-10 对齐（X-2）、FR-3.2 示例（X-4）、notes 表补数据模型（X-6）、§6.2 邮箱通道统一 | §5.2 / FR-3.2 / DB-23 / §6.2 |
| V22-13 | 单元评估卡补录（X 类缺陷：课程设计 v2.1 §6.2 定稿内容传递遗漏） | FR-8.4 / LC-L6 / §7.3 / API-16 / DB-02 |

### 13.3 v2.3（部署架构变更版）

| 修订编号 | 内容 | 落点（编号索引） |
|---|---|---|
| V23-1 | 部署架构变更：移除 Vercel 云端模式，改为纯本地部署（Docker 自托管 Supabase + node + mkcert HTTPS + Linux 主机 + 局域网访问）——用户授权变更，原因：`*.vercel.app` 大陆不可达 + 云端函数无法访问本机数据库 | NFR-3 / NFR-6 / NFR-7 / NFR-8 / §8.2 / §8.3 / §8.4 / §8.7[536] / STO-4 / STO-5 / MS-W1 / MS-W4 / MS-W5 / AC-07 / RSK-5 / RSK-8 / §12.1 / project_rules §2§10 / 测试方案 E6 / 流程图 §77 |
| V23-2 | 单用户简化：移除全部用户注册管理功能，改为单用户模式（无注册/登录/认证，首次知情同意页替代监护人确认链路）；FR-1.1/1.2/1.5/1.6 废止，FR-1.3 简化；API-12/13/16/17/18、DB-24、AC-10、SEC-4 废止；NFR-3 去 Auth，NFR-4/RSK-6 改写；DB-01 去监护人字段加 consent_at | FR-1.x / NFR-3 / NFR-4 / §5.1 / §6.2[IX-0] / §7.3 / §8.2 / §8.4 / API-12~18 / DB-01 / DB-24 / SEC-4 / MS-W1 / AC-01 / AC-10 / RSK-6 / RSK-8 / FR-8.3 / FR-8.4 |

### 13.2 v2.1（审查报告修复版）

| 修复编号 | 审查缺陷 | 落点（编号索引） |
|---|---|---|
| FA-01 | S-1 ASR 主路径反转 | FR-5.2 / §8.2 / §8.7 / API-10 / §8.10 / RSK-3 |
| FA-02 | S-2 存储参数重算 | NFR-2 / NFR-6 / FR-7.2 / STO-2～5 / MS-W4 |
| FA-03 | S-3 补表 | DB-16/17/18/19（另新增 DB-20 share_tokens） |
| FA-04 | S-4 监护人链路 | FR-1.2 / FR-1.5 / §6.2 / §7.3 / API-12/13 / AC-10 |
| FA-05 | S-5 限额口径 | QUOTA-1～4 / §5.3 / AC-03 |
| FA-06 | I-1 thinking 显式关闭 | §8.1 / §8.2 / §8.5 provider.ts |
| FA-07 | I-2 RLS 与签名 URL | §8.8.1 SEC-1～5 / DB-20 |
| FA-08 | I-3 MediaRecorder 格式探测 | FR-5.1 / FR-7.2 / DB-09/11 mime_type |
| FA-09 | I-4 视频失效双通道 | FR-3.6 / §6.3.7 / API-14 |
| FA-10 | I-5 CSV 幂等导入 | FR-10.1 / §5.4[8] / AC-08 |
| FA-11 | I-6 日志脱敏与重放关系 | §5.5[4] / §8.5 logger.ts / DB-14 / API-09 |
| FA-12 | I-7 关卡完成判据 | §5.2 LC-L1～L6 / FR-2.2 |
| FA-13 | I-8 写作错误率口径 | FR-8.2 / API-02 |
| — | G-1～G-6 一般优化 | §7.1（仅浅色）/ §6.1（无障碍）/ FR-8.3（分享安全）/ MS-W3（灌装前置）/ §8.4（iOS 证书）/ FR-3.5（OOV 降级） |

### 13.4 v2.4 一致性复审补丁（2026-09-02）

需求冻结期内的缺陷修复与条款澄清（§0.1 允许范围），不改变需求语义：

| 编号 | 修复项 | 落点 |
|---|---|---|
| FIX-01 | v2.4 单用户口径残留清除：RLS/认证表述统一为"固定 user_id 过滤、不启 Auth、无 401 用例" | SEC-1 / §8.3 / §12.2；联动《代码示例》§0/§4/§9/§11/§13、《测试方案》§1/§3.1/§3.2/E4、《project_rules》§9、《开发任务清单》T-0101/T-0104 |
| FIX-02 | §5.1 学生主旅程 onboarding 重复行清理（v2.4 改写残留） | §5.1 |
| FIX-03 | L1 关卡内顺序对齐：预测问答在词块/语法之前（与 FR-4.6"看视频前"、§7.3"提交后进入词卡学习"、流程图 §7 一致） | §5.2 |
| FIX-04 | ASR 成本口径统一为 20 生合计约 10–110 元区间（原 NFR-7"2–8 元"与 §8.10"110 元"数量级矛盾） | NFR-7 / §8.10；《开发任务清单》T-0318 联动 |
| FIX-05 | 数据模型补缺：problem_logs.source（L1 问答素材同步所需，对齐《代码示例》§13 submit_l1_quiz）；lesson_progress.content_version（首见版本锁定，DB-25/API-05 依赖） | DB-08 / DB-16 |
| FIX-06 | QUOTA-4 单用户实施口径澄清（无认证下 seed role 置 test / QUOTA_BYPASS 豁免） | QUOTA-4 / §1.3 |
| FIX-07 | API-05 输出补 L1/L2 问答题并明确 answer 不下发前端 | API-05；《测试方案》§3.1 联动追加断言 |
| FIX-08 | 前端设计规范落地：新增 §7.5 引用《前端设计规范-主题配置与组件状态.md》+《风格稿-style-guide.html》（CSS 变量/tailwind 配置/组件五态/业务组件规格），并澄清强调色派生与功能色口径 | §7.5；《开发任务清单》T-0115/T-0506 DoD 联动 |
| FIX-09 | 知情同意页口径修正：原"不上传至第三方"表述不准确（转写文本 → DeepSeek、录音 → ASR 服务商），改为如实披露第三方 AI 数据传输；新增 §12.3 第三方服务与条款清单 | §6.2 / NFR-4 / §12.3；《流程图与推演》§8、《开发任务清单》T-0106 联动 |
