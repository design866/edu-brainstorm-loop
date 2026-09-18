#!/bin/bash
# 交付质检闭环：OpenMAIC 生成 → 机器人质检 → 合格交付/不合格反馈重做
# 用法: bash deliver-quality.sh "<定稿方案要求>"
export HTTPS_PROXY=http://127.0.0.1:7892 HTTP_PROXY=http://127.0.0.1:7892
REQ="${1:-按定稿方案生成二年级英语互动课堂}"
W="$LOCALAPPDATA/Temp/brainstorm"
mkdir -p "$W"

echo "=== [1/5] 提交 OpenMAIC 生成课堂 ==="
JOB=$(curl -s --noproxy '*' -m 30 -X POST "http://127.0.0.1:3000/api/generate-classroom" \
  -H "Content-Type: application/json" \
  -d "{\"requirement\":\"$REQ\",\"enableTTS\":true,\"enableImageGeneration\":false}")
JOBID=$(echo "$JOB" | python -c "import sys,json;d=json.load(sys.stdin);print(d.get('jobId',''))" 2>/dev/null)
echo "jobId: $JOBID"
if [ -z "$JOBID" ]; then echo "提交失败: $JOB"; exit 1; fi

echo "=== [2/5] 轮询生成进度（每 20 秒，最长 40 分钟） ==="
CLASSROOM_ID=""
for i in $(seq 1 120); do
  sleep 20
  S=$(curl -s --noproxy '*' -m 20 "http://127.0.0.1:3000/api/generate-classroom/$JOBID")
  STATUS=$(echo "$S" | python -c "import sys,json;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null)
  STEP=$(echo "$S" | python -c "import sys,json;d=json.load(sys.stdin);print(d.get('step',''))" 2>/dev/null)
  echo "  [$i] $STATUS $STEP"
  if [ "$STATUS" = "succeeded" ]; then
    CLASSROOM_ID=$(echo "$S" | python -c "import sys,json;d=json.load(sys.stdin);r=d.get('result',{});print(r.get('classroomId',''))" 2>/dev/null)
    URL=$(echo "$S" | python -c "import sys,json;d=json.load(sys.stdin);r=d.get('result',{});print(r.get('url',''))" 2>/dev/null)
    echo "  课堂生成完成! classroomId=$CLASSROOM_ID url=$URL"
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "  生成失败: $(echo "$S" | head -c 300)"
    exit 1
  fi
done
[ -z "$CLASSROOM_ID" ] && { echo "超时未完成"; exit 1; }

echo "=== [3/5] 读取课堂内容供质检 ==="
CLASS_FILE="C:/Users/Gilbert/OpenMAIC/data/classrooms/$CLASSROOM_ID.json"
if [ -f "$CLASS_FILE" ]; then
  python -c "
import json,io
d=json.load(io.open(r'$CLASS_FILE',encoding='utf-8'))
# 提取场景/标题摘要
scenes=d.get('scenes',d.get('outlines',[]))
title=d.get('title',d.get('name','课堂'))
print('标题:',title)
if isinstance(scenes,list):
    for i,s in enumerate(scenes[:30]):
        n=s.get('title',s.get('name',s.get('stageTitle',''))) if isinstance(s,dict) else str(s)[:80]
        print(f'场景{i+1}:',str(n)[:80])
" > "$W/classroom-summary.txt" 2>&1
  echo "摘要已提取: $(wc -c < "$W/classroom-summary.txt") bytes"
else
  echo "课堂 JSON 未找到（可能在其他路径）: $CLASS_FILE"
  echo "$REQ" > "$W/classroom-summary.txt"
fi

echo "=== [4/5] 机器人质检（并行） ==="
SUMMARY=$(cat "$W/classroom-summary.txt" | head -c 1500)
REQ_SHORT=$(echo "$REQ" | head -c 400)
hermes -p edu-reviewer chat --in "$HOME" -c "Bot Chat" --create-if-missing -Q -q \
  "质检轮：OpenMAIC 已按定稿方案生成课堂。定稿要求：$REQ_SHORT。课堂内容：$SUMMARY。请做质量总检：是否符合终审标准/教学评一致？给出 ✅合格 / ⚠️需修正(具体问题) / ❌不合格。" 2>&1 | tail -40 > "$W/qa-reviewer.txt" &
hermes -p edu-designer chat --in "$HOME" -c "Bot Chat" --create-if-missing -Q -q \
  "质检轮：课堂已生成。定稿要求：$REQ_SHORT。内容：$SUMMARY。请检课堂落地质量（活动/交互/课件是否达标，老师能否直接上）。给 ✅/⚠️/❌ + 具体问题。" 2>&1 | tail -40 > "$W/qa-designer.txt" &
hermes -p edu-planner chat --in "$HOME" -c "Bot Chat" --create-if-missing -Q -q \
  "质检轮：课堂已生成。定稿要求：$REQ_SHORT。内容：$SUMMARY。请检内容是否符合定稿要求与课标。给 ✅/⚠️/❌ + 具体问题。" 2>&1 | tail -40 > "$W/qa-planner.txt" &
wait

echo "=== [5/5] 质检汇总 ==="
cat > "$W/qa-report.md" << EOF
# 交付质检报告
- 课堂: $CLASSROOM_ID ($URL)
- 定稿要求: $REQ_SHORT

## 吴老师（质量总检）
$(tail -n +2 "$W/qa-reviewer.txt" 2>/dev/null | head -c 700)

## 李老师（课堂落地）
$(tail -n +2 "$W/qa-designer.txt" 2>/dev/null | head -c 700)

## 蔡老师（内容要求）
$(tail -n +2 "$W/qa-planner.txt" 2>/dev/null | head -c 700)
EOF
echo "质检报告: $W/qa-report.md"
echo "QA_DONE"
