#!/bin/bash
# ============================================================
# edu-brainstorm-loop 开工前服务启动器
# 启动/确认：① 桥接工作台(8790) ② OpenMAIC(3000) ③ 进度轮询
# 用法: bash start-services.sh    （有任务时先跑这个，再开工）
# ============================================================
export MSYS_NO_PATHCONV=1
PY=C:/Python314/python
BRIDGE="$LOCALAPPDATA/Temp/bridge-v4.py"
if [ ! -f "$BRIDGE" ]; then BRIDGE="C:/Users/Gilbert/AppData/Local/hermes/skills/edu/edu-brainstorm-loop/bridge.py"; fi
WATCH="C:/Users/Gilbert/AppData/Local/hermes/skills/edu/edu-brainstorm-loop/progress-watch.py"

echo "==============================================="
echo " 🔧 开工前服务检查与启动"
echo "==============================================="

# ---- 1. 桥接工作台 8790 ----
echo ""
echo "[1/3] 桥接工作台 (8790)..."
if netstat -ano 2>/dev/null | grep ":8790" | grep -q LISTENING; then
  echo "  ✓ 已在运行 (http://127.0.0.1:8790)"
else
  powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList '$(cygpath -w "$BRIDGE" 2>/dev/null || echo "$BRIDGE")'"
  sleep 3
  netstat -ano 2>/dev/null | grep ":8790" | grep -q LISTENING && echo "  ✓ 已启动 (http://127.0.0.1:8790)" || echo "  ⚠️ 启动失败，稍后重试"
fi

# ---- 2. OpenMAIC 3000 ----
echo ""
echo "[2/3] OpenMAIC (3000)..."
if netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING; then
  echo "  ✓ 已在运行 (http://localhost:3000)"
else
  if [ -f "C:/Users/Gilbert/OpenMAIC/start-openmaic.bat" ]; then
    powershell -NoProfile -Command "Start-Process -FilePath 'C:\Users\Gilbert\OpenMAIC\start-openmaic.bat' -WindowStyle Minimized"
    echo "  ⏳ OpenMAIC 启动中（30-60 秒就绪）..."
    sleep 40
    curl -s --noproxy '*' -m 5 "http://localhost:3000" -o /dev/null -w "  OpenMAIC: %{http_code}\n" 2>&1 || echo "  ⚠️ 尚未就绪，稍后 curl localhost:3000 确认"
  else
    echo "  ⚠️ 未找到 OpenMAIC 启动器（先运行 setup.sh 安装）"
  fi
fi

# ---- 3. 进度轮询 ----
echo ""
echo "[3/3] 制作进度轮询..."
if [ -f "$WATCH" ]; then
  # 已在跑则跳过
  if powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*progress-watch*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]"; then
    echo "  ✓ 进度轮询已在运行"
  else
    powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList '$(cygpath -w "$WATCH" 2>/dev/null || echo "$WATCH")'"
    echo "  ✓ 进度轮询已启动（每节完成自动汇报）"
  fi
else
  echo "  ⚠️ progress-watch.py 未找到"
fi

# ---- 4. 面板自动弹出守护 ----
echo ""
echo "[4/4] 面板自动弹出守护..."
WATCHER="C:/Users/Gilbert/AppData/Local/hermes/skills/edu/edu-brainstorm-loop/panel-watcher.py"
if [ -f "$WATCHER" ]; then
  if powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" | Where-Object { \$_.CommandLine -like '*panel-watcher*' } | Measure-Object | Select-Object -ExpandProperty Count" 2>/dev/null | grep -q "^[1-9]"; then
    echo "  ✓ 面板守护已在运行"
  else
    powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'C:\Python314\python.exe' -ArgumentList 'C:\Users\Gilbert\AppData\Local\hermes\skills\edu\edu-brainstorm-loop\panel-watcher.py'"
    echo "  ✓ 面板守护已启动（闭环完成自动弹可视化面板）"
  fi
fi

echo ""
echo "==============================================="
echo " ✅ 服务就绪，可以开工！"
echo "  工作台:  http://127.0.0.1:8790"
echo "  OpenMAIC: http://localhost:3000"
echo "  面板守护: 闭环完成自动弹出可视化方案面板"
echo "==============================================="
