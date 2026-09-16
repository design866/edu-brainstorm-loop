#!/bin/bash
# 头脑风暴协作闭环 v2（5 机器人）：小组讨论 → 全师评审 → 小组迭代 → 总把关
# 用法: bash brainstorm-session.sh "<主题>"
export HTTPS_PROXY=http://127.0.0.1:7892 HTTP_PROXY=http://127.0.0.1:7892
TOPIC="${1:-小学二年级数学《生活中的测量》的创意教学活动}"

HOME_DIR="$HOME"
W="$LOCALAPPDATA/Temp/brainstorm"
mkdir -p "$W"

echo "=== [轮0] 创意小组激烈讨论：点子哥 × 苏博士 ==="
hermes -p edu-brains chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "小组讨论轮：主题《$TOPIC》。先和苏博士(edu-pedagogy)激烈碰撞——你从直觉创意角度发散 8-10 个点子（含题型/活动/跨学科方向），苏博士会从教育学理论补充。本回合你先输出你的发散清单。" 2>&1 | tail -40 > "$W/round0-brains.txt"
hermes -p edu-pedagogy chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "小组讨论轮：主题《$TOPIC》。点子哥(edu-brains)已从直觉创意发散，你从教育学博士角度：①补充有理论根基的创意点子和题型创意（变式题/开放题/情境题等）②对点子哥的点子提出质疑或深化 ③两人合并成创意池。本回合输出你的理论型创意清单。" 2>&1 | tail -40 > "$W/round0-pedagogy.txt"

echo "=== [轮1] 创意池汇合 ==="
echo "(点子哥发散 + 苏博士理论创意 = 创意池，进入全师评审)"

echo "=== [轮2] 三位专家并行评审 ==="
hermes -p edu-planner chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（可行性）：点子哥和苏博士对《$TOPIC》产出创意池（直觉创意+教育学理论创意+题型创意），请逐条评估可行性（课标/课时/资源/学生适合度），给出 ✅可行/⚠️有条件/❌不可行 结论和理由。" 2>&1 | tail -40 > "$W/round2-planner.txt" &
hermes -p edu-designer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（课堂落地）：点子哥和苏博士对《$TOPIC》产出创意池（直觉创意+教育学理论创意+题型创意），请评估课堂落地性（活动适合度/课件交互/老师能否直接上），给出改进建议。" 2>&1 | tail -40 > "$W/round2-designer.txt" &
hermes -p edu-reviewer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（质量把关）：点子哥和苏博士对《$TOPIC》产出创意池，请评估创新性/教育价值/可检测性，指出最弱和最值得保留的点子。" 2>&1 | tail -40 > "$W/round2-reviewer.txt" &
wait

echo "=== [轮3] 创意小组基于反馈迭代 ==="
hermes -p edu-brains chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "迭代轮：蔡老师、李老师、吴老师评审了你们小组(你和苏博士)的创意池。请根据可行性/落地性/质量反馈，和苏博士一起挑出最受认可的 2-3 个点子深化迭代：解决指出的问题、保留亮点、可跨点子融合。本回合你先输出深化方案框架。" 2>&1 | tail -40 > "$W/round3-brains.txt"
hermes -p edu-pedagogy chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "迭代轮：三位老师评审了创意池。请你从教育学角度补充深化：确保最终 2-3 个方案有理论根基、题型设计到位（变式/开放/情境），输出你的深化补充。" 2>&1 | tail -40 > "$W/round3-pedagogy.txt"

echo "=== [轮4] 吴老师总把关 ==="
hermes -p edu-reviewer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "终审轮：创意小组已根据三位专家反馈迭代出最终方案（含教育学理论支撑）。请做总把关：综合可行性/落地性/创新性/理论根基给出最终裁决（✅通过/⚠️有条件通过+条件/❌打回+原因），并给出实施顺序建议。" 2>&1 | tail -40 > "$W/round4-final.txt"

echo "=== 头脑风暴闭环完成（5 机器人） ==="
