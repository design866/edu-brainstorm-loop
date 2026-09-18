#!/bin/bash
# ============================================================
# edu-brainstorm-loop 一键安装依赖脚本（Windows）
# 自动完成：①创建 5 个专家机器人 ②写入 SOUL ③检测/安装 OpenMAIC
#           ④配置模型与 .env ⑤启动 OpenMAIC
# 用法: bash setup.sh
# ============================================================
export HTTPS_PROXY=http://127.0.0.1:7892 HTTP_PROXY=http://127.0.0.1:7892
HERMES_HOME="C:/Users/Gilbert/AppData/Local/hermes"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROFILES="$HERMES_HOME/profiles"
OPENMAIC_DIR="C:/Users/Gilbert/OpenMAIC"
PNPM="$LOCALAPPDATA/hermes/node/pnpm.cmd"

echo "==============================================="
echo " edu-brainstorm-loop · 一键安装依赖"
echo "==============================================="

# ---- 1. 创建 5 个专家机器人 ----
echo ""
echo "[1/5] 创建 5 个专家机器人..."
BOTS=(
  "edu-brains|小学教育头脑风暴主持人点子哥"
  "edu-pedagogy|教育学博士苏博士：教育理论+题型创意"
  "edu-planner|小学课题规划专家蔡老师"
  "edu-designer|小学教学设计专家李老师"
  "edu-reviewer|小学课堂诊断专家评课吴老师"
)
for entry in "${BOTS[@]}"; do
  name="${entry%%|*}"; desc="${entry##*|}"
  if [ -d "$PROFILES/$name" ]; then
    echo "  ✓ $name 已存在"
  else
    hermes profile create "$name" --clone --description "$desc" >/dev/null 2>&1 && echo "  ✓ $name 已创建" || echo "  ✗ $name 创建失败"
  fi
done

# ---- 2. 写入 SOUL.md ----
echo ""
echo "[2/5] 写入角色 SOUL..."
for f in "$HERE"/profiles/*-SOUL.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" | sed 's/-SOUL.md//')
  if [ -d "$PROFILES/$name" ]; then
    cp "$f" "$PROFILES/$name/SOUL.md" && echo "  ✓ $name SOUL 已写入"
  fi
done

# ---- 3. 模型配置（继承方舟/可用 provider） ----
echo ""
echo "[3/5] 配置机器人模型..."
for b in edu-brains edu-pedagogy edu-planner edu-designer edu-reviewer; do
  cfg="$PROFILES/$b/config.yaml"
  if [ -f "$cfg" ]; then
    # 若 config 有 deepseek 官网 provider 或无效配置，切到方舟（或保留已有可用配置）
    if grep -q "provider: deepseek$" "$cfg" 2>/dev/null; then
      python - "$cfg" <<'PY'
import sys,re
p=sys.argv[1]
c=open(p,encoding='utf-8').read()
c=re.sub(r'^model:\n  default: .*\n  provider: .*\n(  base_url: .*\n)?',
         'model:\n  default: deepseek-v4-flash\n  provider: custom:huoshan\n  base_url: https://ark.cn-beijing.volces.com/api/plan/v3\n', c, count=1, flags=re.M)
open(p,'w',encoding='utf-8').write(c)
PY
      echo "  ✓ $b 模型已切到方舟"
    else
      echo "  ✓ $b 模型配置保留（$(grep -A1 '^model:' "$cfg" | grep default | head -1 | tr -d ' ')）"
    fi
  fi
done

# ---- 4. 检测/安装 OpenMAIC ----
echo ""
echo "[4/5] 检测 OpenMAIC..."
if [ -d "$OPENMAIC_DIR" ] && [ -f "$OPENMAIC_DIR/package.json" ]; then
  echo "  ✓ OpenMAIC 已存在 ($OPENMAIC_DIR)"
else
  echo "  ⏳ OpenMAIC 未安装，开始克隆安装（约 2-5 分钟）..."
  git clone --depth 1 https://github.com/THU-MAIC/OpenMAIC.git "$OPENMAIC_DIR" 2>&1 | tail -1
  cd "$OPENMAIC_DIR" || exit 1
  # npmmirror 直连
  env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy \
    "$PNPM" install 2>&1 | tail -2
  # .env.local
  if [ ! -f ".env.local" ] && [ -f ".env.example" ]; then
    cp .env.example .env.local
    # 从 Hermes .env 注入 key
    ARK_KEY=$(grep "^ARK_API_KEY" "$HERMES_HOME/.env" | cut -d= -f2 | tr -d '\r')
    if [ -n "$ARK_KEY" ]; then
      sed -i "s|^DOUBAO_API_KEY=.*|DOUBAO_API_KEY=$ARK_KEY|" .env.local 2>/dev/null
      sed -i "s|^TTS_DOUBAO_API_KEY=.*|TTS_DOUBAO_API_KEY=$ARK_KEY|" .env.local 2>/dev/null
      echo "  ✓ ARK key 已注入 .env.local"
    fi
  fi
  echo "  ✓ OpenMAIC 安装完成"
fi

# ---- 5. 启动 OpenMAIC ----
echo ""
echo "[5/5] 启动 OpenMAIC..."
if netstat -ano 2>/dev/null | grep ":3000" | grep -q LISTENING; then
  echo "  ✓ OpenMAIC 已在运行 (localhost:3000)"
else
  if [ -f "$OPENMAIC_DIR/start-openmaic.bat" ]; then
    powershell -NoProfile -Command "Start-Process -FilePath '$OPENMAIC_DIR\\start-openmaic.bat' -WindowStyle Minimized"
  else
    powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/c cd /d $OPENMAIC_DIR && set HTTPS_PROXY=http://127.0.0.1:7892 && set HTTP_PROXY=http://127.0.0.1:7892 && $PNPM dev'"
  fi
  echo "  ⏳ OpenMAIC 启动中（30-60 秒就绪）..."
  sleep 40
  curl -s --noproxy '*' -m 5 "http://localhost:3000" -o /dev/null -w "  OpenMAIC: %{http_code}\n" 2>&1 || echo "  ⚠️ 仍在启动，稍后 curl localhost:3000 确认"
fi

echo ""
echo "==============================================="
echo " ✅ 安装完成！5 位专家机器人 + OpenMAIC 已就绪"
echo "  · BOTS 面板可见 5 位老师（可拖入教育区建群聊）"
echo "  · 现在可以运行: bash brainstorm-session.sh \"<教育问题>\""
echo "==============================================="
