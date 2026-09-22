#!/bin/bash
# 清理机器人旧会话 + 确认服务
export MSYS_NO_PATHCONV=1
echo "=== [1] 清理所有机器人旧 Bot Chat 会话 ==="
for b in edu-brains edu-pedagogy edu-planner edu-designer edu-reviewer; do
  d="C:/Users/Gilbert/AppData/Local/hermes/profiles/$b/sessions"
  if [ -d "$d" ]; then
    rm -f "$d"/*.json 2>/dev/null
    n=$(ls "$d" 2>/dev/null | wc -l)
    echo "  $b: 会话历史已清（剩余 $n）"
  fi
done
echo ""
echo "=== 确认服务就绪 ==="
netstat -ano 2>/dev/null | grep ":8790" | grep -q LISTENING && echo "桥接 8790 ✅" || echo "桥接 8790 ❌"
netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING && echo "OpenMAIC 3000 ✅" || echo "OpenMAIC 3000 ❌"
cnt=$(powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*panel-watcher*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | tr -d ' \r')
echo "面板守护进程数: ${cnt:-0}"
