---
name: edu-brainstorm-loop
description: "Use when 教育课题需要头脑风暴：5 专家机器人多轮闭环协作。"
version: 1.0.0
platforms: [windows]
---

# 教育头脑风暴闭环（5 机器人多轮协作）

用户确认的**标准工作方式**（2026-09）：以后所有教育课题/教学设计的创意讨论都走此闭环。

## 参与机器人（Hermes Bots profiles）

| Profile | 角色 | 闭环职责 |
|---|---|---|
| edu-brains | 💡 点子哥 | 直觉发散引擎：轮0 发散 8-10 个点子；轮3 小组迭代 |
| edu-pedagogy | 🎓 苏博士 | 教育学博士/题型创意专家：轮0 理论创意+质疑深化；轮3 保理论根基 |
| edu-planner | 🧭 蔡老师 | 可行性评审：课标/课时/资源/学生适合度 → ✅/⚠️/❌ |
| edu-designer | 🎨 李老师 | 课堂落地评审：活动/课件/交互/可操作性 |
| edu-reviewer | 🔍 评课吴老师 | 轮2 质量评审 + 轮4 终审总把关（✅通过/⚠️有条件/❌打回） |

5 个 SOUL.md 已内置协作协议（profiles/<name>/SOUL.md），改角色职责先改 SOUL。
**创意小组** = edu-brains（直觉）× edu-pedagogy（理论/题型），两人先内部碰撞再对全师。

## 四轮闭环流程（v2，含小组讨论轮）

```text
轮0 创意小组激烈讨论 ── 点子哥发散直觉创意 + 苏博士补理论/题型创意 → 合并创意池(10-12个)
   ↓
轮1 创意池成型 ── 标注来源（点子哥/苏博士/联合）
   ↓
轮2 三专家并行评审 ── edu-planner(可行性) + edu-designer(落地) + edu-reviewer(质量)
   ↓
轮3 创意小组迭代 ── 点子哥+苏博士根据反馈挑 2-3 个深化（解决指出的问题、保留亮点、可融合）
   ↓
轮4 吴老师总把关 ── 综合裁决 ✅/⚠️/❌（含理论根基） + 实施顺序建议
```

## 执行脚本

`brainstorm-session.sh`（v2 模板存 C:\Users\Gilbert\AppData\Local\Temp\brainstorm-session.sh，可拷贝到项目）：

```bash
bash brainstorm-session.sh "<主题>"
```

脚本内部：每轮 `hermes -p <profile> chat --in $HOME -c "Bot Chat" --create-if-missing -Q -q "<轮次指令>"`，输出到 `%LOCALAPPDATA%\Temp\brainstorm\round*.txt`。轮2 三专家并行（& + wait）。

各轮指令要点（已在脚本内）：
- 轮0a 点子哥："你从直觉创意角度发散 8-10 个点子（含题型/活动/跨学科方向）"
- 轮0b 苏博士："你从教育学博士角度补充有理论根基的创意和题型创意，质疑/深化点子哥的点子"
- 轮2：蔡老师评可行性/李老师评落地/吴老师评质量（并行）
- 轮3a 点子哥："根据评审反馈挑 2-3 个深化迭代" + 轮3b 苏博士："从教育学角度补充确保理论根基和题型设计"
- 轮4："综合可行性/落地性/创新性/理论根基给出最终裁决（✅通过/⚠️有条件通过+条件/❌打回+原因），并给出实施顺序建议。"

## 模型配额陷阱（2026-09-15 实测）

- **火山方舟 Agent Plan 月配额有限**：4 bot × 多轮讨论会快速耗尽（演示 2 轮后 429 "monthly usage quota, reset 09-24"）。
- **GLM 周额度**（zai）9/8 重置过一次，之后可能再次耗尽；DeepSeek 官网曾 402 余额不足。
- **稳定备用**：opencode-free 免费模型（免 Key，如 deepseek-v4-flash-free）；给 bot 切模型：改 `profiles/<name>/config.yaml` 的 model 段（或 `hermes profile` 命令）。
- 跑闭环前先探测配额：`curl` 方舟 /health 或先跑一轮最小调用，429 就换模型/等重置。
- 演示前把 4 个 bot 的模型都确认可用（一次闭环 = 6 次 LLM 调用）。

## 交付格式

闭环完成后输出「头脑风暴纪要」：轮1 点子清单 → 轮2 评审意见（三人）→ 轮3 深化方案 → 轮4 终审裁决。用户偏好结构化中文汇报（表格+要点）。
