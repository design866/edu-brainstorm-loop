#!/bin/bash
# ============================================================
# edu-brainstorm-loop 开工前服务启动器 v2（自检+自动修复）
# 一次性启动并验证全部服务，输出 ✅/❌ 状态清单
# 任何服务缺失自动补启，绝不让问题留到任务中途
# 用法: bash start-services.sh
# ============================================================
export MSYS_NO_PATHCONV=1
PY="C:/Python314/python"
SKILL_DIR="C:/Users/Gilbert/AppData/Local/hermes/skills/edu/edu-brainstorm-loop"
OPENMAIC_DIR="C:/Users/Gilbert/OpenMAIC"
PNPM="$LOCALAPPDATA/hermes/node/pnpm.cmd"
PASS=0; FAIL=0

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo "==============================================="
echo " 🔧 开工前服务检查与启动 v2（自检+自动修复）"
echo "==============================================="

# ---- 1. 桥接工作台 8790 ----
echo ""
echo "[1/5] 桥接工作台 (8790)..."
if netstat -ano 2>/dev/null | grep ":8790" | grep -q LISTENING; then
  ok "桥接已在运行 (http://127.0.0.1:8790)"
else
  echo "  ⏳ 未运行，启动中..."
  powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList 'C:\Users\Gilbert\AppData\Local\hermes\skills\edu\edu-brainstorm-loop\bridge.py'"
  sleep 4
  if netstat -ano 2>/dev/null | grep ":8790" | grep -q LISTENING; then
    ok "桥接已启动 (8790)"
  else
    bad "桥接启动失败！"
  fi
fi

# ---- 2. OpenMAIC 3000 ----
echo ""
echo "[2/5] OpenMAIC (3000)..."
if netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING; then
  ok "OpenMAIC 已在运行"
else
  echo "  ⏳ 未运行，启动中（约 40-60 秒）..."
  powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/c cd /d $OPENMAIC_DIR && set HTTPS_PROXY=http://127.0.0.1:7892&& set HTTP_PROXY=http://127.0.0.1:7892&& $PNPM dev > C:\Users\Gilbert\AppData\Local\Temp\openmaic-dev.log 2>&1'"
  sleep 50
  if netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING && curl -s --noproxy '*' -m 4 "http://localhost:3000" -o /dev/null -w "" 2>/dev/null; then
    ok "OpenMAIC 已启动 (HTTP 200)"
  else
    # 再等 20 秒重试
    sleep 20
    if netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING; then
      ok "OpenMAIC 已启动（延迟就绪）"
    else
      bad "OpenMAIC 启动失败！日志: Temp/openmaic-dev.log"
    fi
  fi
fi

# ---- 3. 进度轮询 ----
echo ""
echo "[3/5] 制作进度轮询..."
if powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*progress-watch*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]"; then
  ok "进度轮询已在运行"
else
  powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList 'C:\Users\Gilbert\AppData\Local\hermes\skills\edu\edu-brainstorm-loop\progress-watch.py'"
  sleep 3
  powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*progress-watch*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]" && ok "进度轮询已启动" || bad "进度轮询启动失败"
fi

# ---- 4. 面板自动弹出守护 ----
echo ""
echo "[4/5] 面板自动弹出守护..."
if powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*panel-watcher*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]"; then
  ok "面板守护已在运行"
else
  powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList 'C:\Users\Gilbert\AppData\Local\hermes\skills\edu\edu-brainstorm-loop\panel-watcher.py'"
  sleep 3
  powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*panel-watcher*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]" && ok "面板守护已启动" || bad "面板守护启动失败"
fi

# ---- 5. 确认链路自检（面板确认→吴老师 是否通） ----
echo ""
echo "[5/5] 确认链路自检（面板确认 → 吴老师）..."
RESP=$(curl -s --noproxy '*' -m 8 -X POST "http://127.0.0.1:8790/confirm" -H "Content-Type: application/json" -d '{"requirement":"__selftest__"}' 2>/dev/null)
if echo "$RESP" | grep -q '"ok": true'; then
  ok "确认链路正常（面板点确认可直达吴老师）"
else
  bad "确认链路异常！面板确认将无法自动直达机器人"
fi

echo ""
echo "==============================================="
echo " ✅ 自检完成：$PASS 项通过 / $FAIL 项失败"
if [ "$FAIL" -gt 0 ]; then
  echo " ⚠️ 有服务未就绪，请检查上方 ❌ 项（任务开始前必须全 ✅）"
  exit 1
fi
echo " 🚀 全部就绪，可以开工！"
echo "  桥接: http://127.0.0.1:8790 · OpenMAIC: http://localhost:3000"
echo "==============================================="
