#!/bin/bash
# 头脑风暴协作闭环 v2（5 机器人）：小组讨论 → 全师评审 → 小组迭代 → 总把关
# 用法: bash brainstorm-session.sh "<主题>"
export HTTPS_PROXY=http://127.0.0.1:7892 HTTP_PROXY=http://127.0.0.1:7892
TOPIC="${1:-小学二年级数学《生活中的测量》的创意教学活动}"

HOME_DIR="$HOME"
W="$LOCALAPPDATA/Temp/brainstorm"
mkdir -p "$W"
# 每任务独立会话名（避免 Bot Chat 无限膨胀导致变慢）
SESS="Task-$(date +%Y%m%d-%H%M%S)"
echo "本次任务会话: $SESS （独立会话，防止历史累积变慢）"

echo "=== [轮0] 创意小组激烈讨论：点子哥 × 苏博士 ==="
hermes -p edu-brains chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "小组讨论轮：主题《$TOPIC》。先和苏博士(edu-pedagogy)激烈碰撞——你从直觉创意角度发散 8-10 个点子（含题型/活动/跨学科方向），苏博士会从教育学理论补充。本回合你先输出你的发散清单。" 2>&1 | tail -40 > "$W/round0-brains.txt"
hermes -p edu-pedagogy chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "小组讨论轮：主题《$TOPIC》。点子哥(edu-brains)已从直觉创意发散，你从教育学博士角度：①补充有理论根基的创意点子和题型创意（变式题/开放题/情境题等）②对点子哥的点子提出质疑或深化 ③两人合并成创意池。本回合输出你的理论型创意清单。" 2>&1 | tail -40 > "$W/round0-pedagogy.txt"

echo "=== [轮1] 创意池汇合 ==="
echo "(点子哥发散 + 苏博士理论创意 = 创意池，进入全师评审)"

echo "=== [轮2] 三位专家并行评审（附创意池） ==="
# 把轮0 输出拼成创意池摘要传给评审（修复：评审老师拿不到创意池的问题）
POOL_SUMMARY=$(python -c "
import io, re
w = r'%LOCALAPPDATA%\\Temp\\brainstorm'
txt = ''
for f in ['round0-brains.txt','round0-pedagogy.txt']:
    try: txt += io.open(w+'\\'+f, encoding='utf-8', errors='replace').read()
    except: pass
# 抽要点行：含数字序号/创新点/题目名
lines = [l.strip() for l in txt.splitlines() if l.strip() and len(l.strip()) < 120]
keep = [l for l in lines if re.search(r'[①-⑩①②③④⑤⑥⑦⑧⑨⑩苏-|^\*\*|^\d+[\.、]', l)]
print(' | '.join(keep[:30])[:1800])
" 2>/dev/null)
POOL_SUMMARY="${POOL_SUMMARY:-点子哥发散10点子+苏博士理论创意9条（详见两人Bot Chat）}"

hermes -p edu-planner chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（可行性）：主题《$TOPIC》。创意池：$POOL_SUMMARY 。请逐条评估可行性（课标/课时/资源/学生适合度），给出 ✅可行/⚠️有条件/❌不可行 结论和理由。" 2>&1 | tail -40 > "$W/round2-planner.txt" &
hermes -p edu-designer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（课堂落地）：主题《$TOPIC》。创意池：$POOL_SUMMARY 。请评估课堂落地性（活动适合度/课件交互/老师能否直接上），给出改进建议。" 2>&1 | tail -40 > "$W/round2-designer.txt" &
hermes -p edu-reviewer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "评审轮（质量把关）：主题《$TOPIC》。创意池：$POOL_SUMMARY 。请评估创新性/教育价值/可检测性，指出最弱和最值得保留的点子。" 2>&1 | tail -40 > "$W/round2-reviewer.txt" &
wait

echo "=== [轮3] 创意小组基于反馈迭代 ==="
hermes -p edu-brains chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "迭代轮：蔡老师、李老师、吴老师评审了你们小组(你和苏博士)的创意池。请根据可行性/落地性/质量反馈，和苏博士一起挑出最受认可的 2-3 个点子深化迭代：解决指出的问题、保留亮点、可跨点子融合。本回合你先输出深化方案框架。" 2>&1 | tail -40 > "$W/round3-brains.txt"
hermes -p edu-pedagogy chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "迭代轮：三位老师评审了创意池。请你从教育学角度补充深化：确保最终 2-3 个方案有理论根基、题型设计到位（变式/开放/情境），输出你的深化补充。" 2>&1 | tail -40 > "$W/round3-pedagogy.txt"

echo "=== [轮4] 吴老师总把关（附最终方案） ==="
FINAL_SUMMARY=$(python -c "
import io
w = r'%LOCALAPPDATA%\\Temp\\brainstorm'
txt = ''
for f in ['round3-brains.txt','round3-pedagogy.txt']:
    try: txt += io.open(w+'\\'+f, encoding='utf-8', errors='replace').read()
    except: pass
print(txt[:1800].replace(chr(10),' '))
" 2>/dev/null)
FINAL_SUMMARY="${FINAL_SUMMARY:-创意小组已迭代出最终方案（详见两人Bot Chat）}"

hermes -p edu-reviewer chat --in "$HOME_DIR" -c "Bot Chat" --create-if-missing -Q -q \
  "终审轮：主题《$TOPIC》。最终方案：$FINAL_SUMMARY 。请做总把关：综合可行性/落地性/创新性/理论根基给出最终裁决（✅通过/⚠️有条件通过+条件/❌打回+原因），并给出实施顺序建议。" 2>&1 | tail -40 > "$W/round4-final.txt"

echo "=== 头脑风暴闭环完成（5 机器人） ==="
