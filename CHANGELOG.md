# Changelog

本技能遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 规范，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-09-16

### 🚀 首发
- **5 位 AI 教育专家机器人闭环协作**：点子哥（创意发散）× 苏博士（教育学/题型创意）× 蔡老师（课题规划/可行性）× 李老师（教学设计/课堂落地）× 吴老师（课堂诊断/终审把关）
- **四轮闭环流程**：小组发散 → 全师评审 → 迭代深化 → 终审裁决
- **一键执行脚本** `brainstorm-session.sh`：`bash brainstorm-session.sh "课题"` 自动跑完整闭环（6 次 LLM 调用）
- **教育学理论根基**：皮亚杰认知发展阶段 / 布鲁纳三级表征 / 维果茨基最近发展区 / 认知负荷理论——每个点子都有理论依据
- **角色定义**：5 份 SOUL.md（profiles/），可直接创建 Hermes Bots 机器人
- **实战案例**：README 内置《二年级数学知识扩展》完整闭环纪要

### 🐛 修复
- 脚本轮间上下文传递：轮 2 评审老师可收到创意池摘要、轮 4 终审可收到最终方案（修复早期"评审老师拿不到创意池"的断链问题）

### 📦 兼容性
- 平台：Hermes Agent（Windows 实测），依赖 `hermes -p <profile> chat`
- 模型：默认火山方舟 Agent Plan；支持切换任意 LLM provider

## [Unreleased]

### 计划
- [ ] 3 课时教案模板自动生成（从终审通过方案一键展开）
- [ ] 评审意见可视化报告（markdown 汇总单文件）
- [ ] 机器人角色数量可配置（小组规模可调）
- [ ] 跨语言支持（English 角色定义）
