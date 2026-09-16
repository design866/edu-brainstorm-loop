# 🧑‍🏫 edu-brainstorm-loop · 教育头脑风暴闭环（5 专家机器人协作）

小学教育课题/教学设计的**多机器人头脑风暴工作流**：5 位 AI 教育专家按「小组发散 → 全师评审 → 迭代深化 → 终审把关」闭环协作，产出有理论根基、可落地的创意方案。

## ✨ 特性

- **5 位教育专家机器人**，角色互补：
  - 💡 点子哥（edu-brains）：直觉创意发散引擎
  - 🎓 苏博士（edu-pedagogy）：教育学博士，教育理论 + 题型创意设计
  - 🧭 蔡老师（edu-planner）：课题规划，可行性评审
  - 🎨 李老师（edu-designer）：教学设计，课堂落地评审
  - 🔍 评课吴老师（edu-reviewer）：质量评审 + 终审总把关
- **多轮闭环流程**：创意小组先内部激烈碰撞（点子哥 × 苏博士）→ 全师评审可行性 → 小组迭代深化 → 吴老师终审裁决
- **一键执行**：`bash brainstorm-session.sh "课题"` 自动跑完整闭环
- **教育学根基**：每个点子都有教育理论依据（皮亚杰/布鲁纳/维果茨基/建构主义）

## 🚀 安装（Hermes 用户）

```bash
# 1. 创建 5 个专家机器人（Hermes profile）
hermes profile create edu-brains    --clone --description "小学教育头脑风暴主持人点子哥"
hermes profile create edu-pedagogy  --clone --description "教育学博士苏博士：教育理论+题型创意"
hermes profile create edu-planner   --clone --description "小学课题规划专家蔡老师"
hermes profile create edu-designer  --clone --description "小学教学设计专家李老师"
hermes profile create edu-reviewer  --clone --description "小学课堂诊断专家评课吴老师"

# 2. 将 profiles/*-SOUL.md 复制到对应 profile 的 SOUL.md
# 3. 将 SKILL.md 放入 Hermes skills 目录（如 ai/edu/edu-brainstorm-loop/）
# 4. 将 scripts/brainstorm-session.sh 放入技能目录
```

## 📖 用法

```bash
bash brainstorm-session.sh "小学二年级《认识钟表》的创意教学活动"
```

输出到 `%LOCALAPPDATA%\Temp\brainstorm\round*.txt`，完成后人工汇总成头脑风暴纪要。

## 📦 目录结构

```
SKILL/
├── SKILL.md                      # 技能定义（Hermes/Claude Code 技能格式）
├── scripts/
│   └── brainstorm-session.sh     # 四轮闭环执行脚本
├── profiles/                     # 5 个机器人角色定义（SOUL.md 合集）
│   ├── edu-brains-SOUL.md
│   ├── edu-pedagogy-SOUL.md
│   ├── edu-planner-SOUL.md
│   ├── edu-designer-SOUL.md
│   └── edu-reviewer-SOUL.md
├── 角色定义总览.md                # 角色速览 + 使用场景
├── README.md
└── LICENSE
```

## 🔧 技术说明

- 平台：Hermes Agent（Windows 实测），依赖 `hermes -p <profile> chat` 命令
- 模型：默认火山方舟 Agent Plan；可切换任意 LLM provider（见 SKILL.md 配额陷阱）
- 一次闭环 = 6 次 LLM 调用（轮0×2 + 轮2×3 + 轮3×2 + 轮4×1）

## 📄 许可证

MIT License
