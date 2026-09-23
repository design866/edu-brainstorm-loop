---
name: edu-brainstorm-loop
description: "Use when 任何教育问题（课题/教学/应用/活动/评价）：5 专家闭环讨论后可视化交付，OpenMAIC 执行。"
version: 2.6.0
platforms: [windows]
---

# 教育头脑风暴闭环 v2.6（触发 → 闭环 → 可视化 → 修改 → 统筹 → 直产交付 + 质检环 + 进度回报 + 群公告）

用户确认的**标准工作方式**（2026-09）：**凡是教育问题**（课题规划、教学设计、学习应用、活动方案、评价体系、题型创意…）**一律自动触发本流程**，不再单发单答。

## 触发规则（无脑触发 · 全年级全学科）

用户提出任何教育相关需求 → 自动进入本流程，无需确认。**不限年级（幼儿园/小学/初中/高中）、不限学科（语数英/理化生/史地政/音体美/科学…）、不限内容（概念/题型/知识扩展/跨学科）**。例：
- "做/设计一个 XX 英语/数学/物理学习应用" → 触发
- "规划 XX 课题 / 设计 XX 课 / 评 XX 教案" → 触发
- "XX 活动的创意 / 题型设计 / 评价方案" → 触发
- "教/学 XX 知识点 / XX 内容怎么设计" → 触发

## 前置依赖（一键自动安装）

本流程依赖 5 个专家机器人 + OpenMAIC，**安装技能后运行一键脚本自动完成全部依赖**（无需手动）：

```bash
bash scripts/setup.sh
```

setup.sh 自动完成：
1. **创建 5 个专家机器人**（edu-brains / edu-pedagogy / edu-planner / edu-designer / edu-reviewer，`hermes profile create --clone`，已存在则跳过）
2. **写入角色 SOUL**（从 `profiles/*-SOUL.md` 复制到对应 profile）
3. **配置模型**（继承火山方舟 Agent Plan / 可用 provider）
4. **安装 OpenMAIC**（未安装则 git clone THU-MAIC/OpenMAIC + pnpm install + 注入 ARK key 到 .env.local）
5. **启动 OpenMAIC**（localhost:3000，30-60 秒就绪）

> 若机器已具备依赖，setup.sh 自动跳过（幂等）。依赖不足时（如无火山方舟 key），setup.sh 会用 opencode-free 免费模型兜底。
> 手动步骤（等价于 setup.sh）：`hermes profile create` ×5 + 写 SOUL + 装/启 OpenMAIC。

## 参与机器人（Hermes Bots profiles）

| Profile | 角色 | 闭环职责 |
|---|---|---|
| edu-brains | 💡 点子哥 | 直觉发散引擎：轮0 发散 8-10 个点子；轮3 小组迭代 |
| edu-pedagogy | 🎓 苏博士 | 教育学博士/题型创意专家：轮0 理论创意+质疑深化；轮3 保理论根基 |
| edu-planner | 🧭 蔡老师 | 可行性评审：课标/课时/资源/学生适合度 → ✅/⚠️/❌ |
| edu-designer | 🎨 李老师 | 课堂落地评审：活动/课件/交互/可操作性 |
| edu-reviewer | 🔍 评课吴老师 | 轮2 质量评审 + 轮4 终审总把关（✅通过/⚠️有条件/❌打回） |

**创意小组** = edu-brains（直觉）× edu-pedagogy（理论/题型），先内部碰撞再对全师。

## 主流程（6 阶段）

```text
① 触发与群内任务布置（用户 2026-09 定·核心流程）──
     · 用户在任何地方发教育需求（聊天/BOTS 面板/群聊均可）
     · 机器人协调者（默认 edu-reviewer 吴老师）在群聊中**布置任务给其他机器人**
     · 分工：点子哥发散 → 苏博士理论 → 蔡老师可行性 → 李老师落地 → 吴老师统筹
     · 用户消息必须经群里转达，机器人不在群外单独开工
   ↓
①′ 开工前启动服务（用户 2026-09 硬性要求）── 有任务必须先把所需服务启动/确认就绪再干活：
     · **必须用 `bash scripts/start-services.sh` 一次性启动全部**（用户 2026-09 踩坑：手动只启 OpenMAIC 漏了桥接 8790 → 面板确认无法自动直达机器人）
     · 桥接工作台 (8790)  ── start-services.sh 自动
     · OpenMAIC (3000)    ── start-services.sh 自动
     · 制作进度轮询       ── start-services.sh 自动
     · 面板自动弹出守护   ── start-services.sh 自动
     · 未就绪不开工：start-services.sh 后逐项确认 8790/3000/守护 OK
   ↓
② 闭环讨论 ── 轮0 小组发散 → 轮2 三师评审 → 轮3 小组迭代 → 轮4 吴老师终审
   ↓
③ 可视化输出 ── 把讨论结果渲染成可交互的可视化方案（HTML 面板/图表），
                 结构化呈现：创意池 / 评审意见 / 深化方案 / 终审裁决
                 **方案必须通过可视化面板给用户确认**（用户 2026-09 定：确认门）
   ↓
④ 修改循环 ── 用户审阅可视化方案：
     · 满意 → 进入 ⑤
     · 要改 → 用户提出修改点 → **再走一轮讨论闭环**（点子哥+苏博士按修改意见迭代 →
       三位老师复审）→ 重新输出可视化方案 → 回到 ④ 直到满意
   ↓
⑤ 统筹确认 ── 方案经统筹（整合条件/优先级/实施顺序）确认定稿
   ↓
⑥ 执行交付 ── 由「执行老师」（执行 agent）按方案落地：
     · **确认门（用户 2026-09 修正）**：方案定稿后，**必须先向用户展示方案内容并确认**，用户 OK 后才丢给 OpenMAIC 制作；不得未经确认直接生成
     · 默认：交给 OpenMAIC 生成课堂/课程并交付（含 TTS 语音）
     · 用户指定格式：按指定格式输出交付（HTML/教案/PPT/文档…）
     · **直产模式（用户 2026-09 定）**：方案已确定即直接制作交付，**不再征集新点子**，团队只做质量把关
     · **进度回报·制作不停（用户 2026-09 修正）**：每制作好一节就**回报一次进度**（仅进度通知，不阻塞、不等待用户确认）；制作**持续进行直到全部内容完成**，不中断
     · **自动进度汇报（progress-watch.py）**：启动课堂制作时同步运行 `progress-watch.py`（每分钟轮询课堂 JSON+音频），每节完成自动输出汇报（场景 x/y · 音频 n 条），解决"制作中无人汇报"问题。固化于 scripts/progress-watch.py
     ↓
⑦ 交付质检环（用户 2026-09 新增）── 用户点「确定定稿」后：
     · OpenMAIC 生成课堂（异步 jobId 轮询）
     · 生成完成 → 读取课堂内容 → **机器人质检**：
         🔍 吴老师 质量总检（终审标准/教学评一致）
         🎨 李老师 课堂落地检（活动/交互/课件）
         🧭 蔡老师 内容要求检（定稿/课标）
     · 质检报告：✅合格→交付 | ⚠️需修正→列问题→反馈 OpenMAIC 重做→再质检 | ❌→打回
     · 编排脚本：`deliver-quality.sh "<定稿要求>"`（OpenMAIC 生成→读课堂→机器人质检→报告）
```

**交付质检**：OpenMAIC 制作过程中，机器人持续监控内容是否符合要求与交付质量，合格才交付（用户硬性要求，2026-09）。

## 直产模式（用户 2026-09 硬性要求，优先于发散）

- **不再提供新点子**：方案/课题一旦确定，直接进入制作交付，不发起新点子征集；团队职责收窄为**质量把关**
- **交付前确认门**：制作前必须把方案内容展示给用户确认（用户 OK 才丢 OpenMAIC），不直接未经确认生成（用户 2026-09 明确纠正）
- **词量要求（用户 2026-09）**：主题词汇课每主题 ≥50 词（10 主题 = 500 词扩量），分多课时（每课时 ≤8 新词 i+1 保护）
- **进度回报·制作不停**：每制作好一节（一课/一单元）即回报一次进度（仅通知，不阻塞）；制作持续进行直到**全部内容制作完成**才整体交付
- **更新都沉淀回本技能**：每次整理出的更新/新约定，统一写进 `edu-brainstorm-loop`，作为团队流程的唯一权威

## 语音约束（重要）

- **禁止使用 en-US / 任意系统英文语音合成**（`speechSynthesis` en-US 等一律不用）
- 语音一律走 **OpenMAIC 的 TTS**（火山 doubao TTS，`TTS_DOUBAO_API_KEY` + `https://openspeech.bytedance.com/api/v3/plan/tts`）或 **Browser Native 中文语音**
- 英语学习内容：读音由 OpenMAIC 课堂的朗读/跟读机制处理（TTS 或浏览器原生），不在自建 HTML 里用 en-US 合成
- 交付的应用/课堂若需发音：通过 OpenMAIC 生成（其 TTS 引擎负责），不手写 speechSynthesis

## 可视化输出规范

讨论结果必须**可视化**，不能只给文字纪要。**闭环一完成就自动运行 gen-panel.py 生成面板并弹出新标签页**（由 `panel-watcher.py` 守护自动完成，不依赖 agent 手动执行——用户 2026-09 反馈"每次都记不住"后修复）：
- 输出为单文件 HTML 可视化面板（可交互），包含：
  - ① 创意池卡片（来源标签：点子哥/苏博士/联合）
  - ② 三位老师评审意见（分栏/评分）
  - ③ 深化方案对比卡（可切换）
  - ④ 终审裁决横幅（✅/⚠️/❌ + 条件）
  - ⑤ 修改按钮 → 触发新一轮讨论
- 样式遵循 edu-app-builder 规范（若面向儿童：大字体/暖色/圆角/emoji）；面向老师可走专业清爽风
- 修改循环中，可视化面板实时更新（版本号 + 变更说明）

## 执行脚本

`brainstorm-session.sh`（v2，存技能目录）：跑 ②闭环讨论，输出到 `%LOCALAPPDATA%\Temp\brainstorm\round*.txt`。
轮间已做上下文传递（轮2 评审收到创意池、轮4 收到最终方案）。修改循环可重跑 ②+③。

```bash
bash brainstorm-session.sh "<教育问题>"
```

**每次闭环讨论完成，必须自动运行面板生成器并弹出可视化方案面板**（用户硬性要求）：

```bash
C:/Python314/python "<技能目录>/gen-panel.py" "<教育问题>"
```

`gen-panel.py` 自动读取 `%LOCALAPPDATA%\Temp\brainstorm\round*.txt` → 生成可视化 HTML 方案面板（5 机器人消息流 + 修改对话框）→ 在浏览器新标签页打开。生成器已随技能发布（scripts/gen-panel.py），安装后即可复用。

**面板自动弹出守护（panel-watcher.py）**：随 start-services.sh 启动，每 30 秒监控 `round4-final.txt`——闭环完成（内容 ≥100 字）自动运行 gen-panel.py 生成并弹出面板，**全程无需人工/agent 记性**。

**面板公告进群（用户 2026-09 定）**：面板生成后，panel-watcher 自动调 bridge `/announce` → 吴老师在群聊（Bot Chat，群成员可见）**发布面板公告**（主题 + 文件路径 + 查看方式）→ 每次面板都在群里有记录、全员可见。修改意见触发 `/revise` → 点子哥+苏博士在各自 Bot Chat 讨论（群聊汇总显示）。

## 模型约定（用户 2026-09 定，v4.1 升级）

- **机器人讨论统一用 `deepseek-v4.1-flash`**（火山方舟 custom:huoshan）——最新版 + 最快
  - **额度策略（用户 2026-09 定）**：先用 V4.1 免费 tokens（50 万赠送），**免费额度耗尽后自动继续用 V4.1 Flash（走 Agent Plan 正常配额），不回退 v4-flash**——5 机器人保持 v4.1-flash 不变，无需切换
  - 方舟实际路由：`deepseek-v4.1-flash` → 响应模型 `deepseek-v4-1-flash`（实测 1.5s）
  - 对比：deepseek-v4-flash 2.7s / kimi-k3 4.6s（完整调用 35s 更慢）/ doubao-seed-2-1 41s ❌
  - 5 个机器人 config.yaml 均已配置 `model.default: deepseek-v4.1-flash / provider: custom:huoshan`
  - Hermes config.yaml custom_providers.huoshan.models 已注册 `deepseek-v4.1-flash`
- **opencode-free 已不可用**（2026-09 OpenCode 停止匿名免费通道，relay 403）——不作为备选
- 20-25s/次调用 = deepseek 推理思考时间（reasoning 特性），非故障；会话已用任务独立会话防膨胀

## 机器人运维（2026-09 汇总·用户反馈修复）

- **会话膨胀是变慢主因**：机器人共用 Bot Chat 会累积上百条消息（243 条 → 每次调用带 170-198KB 历史 → 20-35s 慢）。已修复：
  - 脚本改用**任务独立会话** `Task-时间戳`（brainstorm-session.sh 已改）
  - **会话清理**：任务前清机器人旧会话（`rm profiles/<bot>/sessions/*.json`）
  - 清后实测：edu-planner 23.8s（旧 29.9s，且不再越用越慢）
- **SESSION_NOT_OWNED**：机器人 Bot Chat 被旧 cli 进程持有 → 报错拒绝。处理：杀遗留 `edu-* chat` 进程释放 lease（`Stop-Process` 匹配 CommandLine 含 edu- 和 chat 的 python）。
- **面板公告进群**：面板生成后 panel-watcher 自动调 bridge `/announce` → 吴老师在群聊发布公告（留档+全员可见）。修改意见 `/revise` → 点子哥+苏博士在各自 Bot Chat 讨论（群聊汇总显示）。
- **清理脚本**：`bash scripts/cleanup.sh`（清 5 机器人旧会话 + 确认三服务）——或手动 `rm profiles/<bot>/sessions/*.json`。

## 模型配额陷阱（2026-09 实测）

- **火山方舟 Agent Plan 月配额有限**：多轮讨论会耗尽（429 "monthly usage quota, reset 09-24"）。跑前探测（一次最小调用），429 则**等重置**或换可用 provider（GLM zai 周额度、DeepSeek 官网按量）。
- **opencode-free 已不可用**（2026-09 OpenCode 停止匿名免费通道，relay 403）——429 时不再尝试它。
- GLM 周额度（zai）会耗尽（1310 错误，周重置）；DeepSeek 官网曾 402 余额不足。
- 一次闭环 ≈ 8 次 LLM 调用；修改循环再加。

## 交付格式

- 默认：OpenMAIC 生成课堂/课程交付（含 TTS），附带可视化方案面板链接
- 用户指定：按要求格式输出（如"HTML 应用""教案文档""PPT"）
- 每阶段向用户汇报，OK 后再推进到执行交付
