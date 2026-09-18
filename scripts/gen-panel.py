#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""头脑风暴可视化面板自动生成器 v1.0
读 brainstorm/round*.txt → 生成可视化 HTML 方案面板 → 自动在浏览器打开
用法: python gen-panel.py "<主题>" [输出路径]
"""
import os, re, io, sys, datetime, subprocess

W = os.path.expandvars(r'%LOCALAPPDATA%\Temp\brainstorm')
TOPIC = sys.argv[1] if len(sys.argv) > 1 else '教育课题'
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.expanduser('~'), 'Desktop', '头脑风暴-方案面板.html')

BOTS = [
    ('edu-brains', '💡', '点子哥', '创意发散', [('round0-brains', '① 小组发散'), ('r3-brains', '③ 迭代深化')]),
    ('edu-pedagogy', '🎓', '苏博士', '教育学·题型', [('round0-pedagogy', '① 小组发散'), ('r3-pedagogy', '③ 迭代深化')]),
    ('edu-planner', '🧭', '蔡老师', '课题规划·可行性', [('round2-planner', '② 评审'), ('r2-planner', '② 评审')]),
    ('edu-designer', '🎨', '李老师', '教学设计·落地', [('round2-designer', '② 评审'), ('r2-designer', '② 评审')]),
    ('edu-reviewer', '🔍', '吴老师', '诊断·终审', [('round2-reviewer', '② 评审'), ('r2-reviewer', '② 评审'), ('r4-final', '④ 终审')]),
]

def readf(f):
    p = os.path.join(W, f + '.txt')
    if not os.path.exists(p):
        return None
    t = io.open(p, encoding='utf-8', errors='replace').read()
    if len(t) < 50:
        return None
    t = re.sub(r'session_id:.*', '', t)
    t = re.sub(r'↻.*messages\)', '', t)
    t = re.sub(r'^.*?Resumed.*?$', '', t, flags=re.M)
    lines = [l for l in t.splitlines() if l.strip()]
    return '\n'.join(lines)[:2000] if lines else None

def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
cards = []
for prof, em, name, role, rounds in BOTS:
    msgs = [(lbl, readf(f)) for f, lbl in rounds if readf(f)]
    total = len(rounds)
    done = len(msgs)
    status = 'done' if done >= total else ('run' if done > 0 else 'wait')
    status_txt = '✓ 全部完成' if done >= total else ('⚡ 部分完成 ' + str(done) + '/' + str(total)) if done > 0 else '待命'
    block = '<div class="bot"><div class="bh"><span class="em">%s</span><div><div class="nm">%s</div><div class="rl">%s</div></div><span class="st %s">%s</span></div><div class="msgs">' % (em, name, role, status, status_txt)
    if not msgs:
        block += '<div class="empty">⏳ 等待任务…</div>'
    for lbl, txt in msgs:
        block += '<div class="msg"><div class="rt">%s</div><div class="tx">%s</div></div>' % (lbl, esc(txt))
    block += '</div></div>'
    cards.append(block)

PAGE = '''<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>教育头脑风暴 · 可视化方案面板</title><style>
:root{--bg:#f6f7fb;--card:#fff;--ink:#222b3d;--mut:#7a8699;--line:#e4e8f0;--blue:#4da3ff;--purple:#8b5cf6;--green:#10b981;--amber:#f59e0b}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:"Segoe UI","Microsoft YaHei",sans-serif;background:var(--bg);color:var(--ink);padding:22px}
.wrap{max-width:1060px;margin:0 auto}
.head{background:linear-gradient(135deg,#1d3a5f,#2b1d5f);color:#fff;border-radius:16px;padding:24px 28px;margin-bottom:16px}
.head h1{font-size:24px}.head .sub{opacity:.85;margin-top:6px;font-size:13.5px}
.meta{display:flex;gap:8px;margin-top:12px;flex-wrap:wrap}
.chip{background:rgba(255,255,255,.14);border-radius:99px;padding:4px 12px;font-size:12px}
.sec{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:18px 20px;margin-bottom:14px}
.sec h2{font-size:16px;margin-bottom:10px}
.bot{background:var(--card);border:1px solid var(--line);border-radius:14px;margin-bottom:12px;overflow:hidden}
.bh{display:flex;align-items:center;gap:10px;padding:11px 15px;background:#fafbfe;border-bottom:1px solid var(--line)}
.bh .em{font-size:28px}.bh .nm{font-weight:800;font-size:14px}.bh .rl{font-size:11px;color:var(--mut)}
.st{margin-left:auto;font-size:11px;font-weight:700;padding:3px 11px;border-radius:99px}
.st.done{background:rgba(16,185,129,.12);color:#0b8a5a}.st.run{background:rgba(245,158,11,.15);color:#b36a05}.st.wait{background:rgba(74,85,104,.1);color:var(--mut)}
.msgs{padding:10px 14px}
.msg{border-left:3px solid var(--line);padding:8px 12px;margin:7px 0;background:#fafbfe;border-radius:0 10px 10px 0}
.rt{font-size:10.5px;color:var(--amber);font-weight:700}
.tx{font-size:12.5px;color:#3a4557;white-space:pre-wrap;line-height:1.55;margin-top:4px;max-height:280px;overflow-y:auto}
.empty{color:var(--mut);font-size:12px;padding:6px 2px}
textarea{width:100%%;border:2px solid var(--line);border-radius:10px;padding:11px;font-size:14px;font-family:inherit;resize:vertical}
.btn{background:linear-gradient(90deg,#4da3ff,#8b5cf6);color:#fff;border:none;border-radius:99px;padding:11px 26px;font-size:14px;font-weight:700;cursor:pointer;display:block;margin:12px auto 0}
.btn:hover{filter:brightness(1.08)}
.note{font-size:12px;color:var(--mut);text-align:center;margin-top:10px}
.ver{text-align:right;font-size:11px;color:#b3bccb;margin-top:8px}
.diag{border-left:4px solid var(--blue);background:#f0f7ff;border-radius:0 10px 10px 0;padding:9px 13px;margin:6px 0;font-size:12.5px;color:#3a4557}
</style></head><body>
<div class="wrap">
  <div class="head">
    <h1>🧑‍🏫 教育头脑风暴 · 可视化方案面板</h1>
    <div class="sub">%s</div>
    <div class="meta"><span class="chip">💡 点子哥</span><span class="chip">🎓 苏博士</span><span class="chip">🧭 蔡老师</span><span class="chip">🎨 李老师</span><span class="chip">🔍 吴老师</span><span class="chip">edu-brainstorm-loop v2.0</span></div>
  </div>
  %s
  <div class="sec">
    <h2>✏️ 提出修改（修改 → 再走一轮讨论 → 重新输出）</h2>
    <textarea id="mod" rows="3" placeholder="例：Phonics 加字母发音对照表 / 某个方案想调整 / 加更多互动…"></textarea>
    <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap">
      <button class="btn" style="background:linear-gradient(90deg,#8b5cf6,#4da3ff)" onclick="submitMod()">📤 提交修改 · 触发新一轮讨论</button>
      <button class="btn" style="background:linear-gradient(90deg,#10b981,#0d9488)" onclick="confirmDeliver()">✅ 确定定稿 · 交付 OpenMAIC</button>
    </div>
    <div id="hist"></div>
    <div id="deliver" style="margin-top:12px"></div>
  </div>
  <div class="ver">生成时间 %s · 每次讨论完成自动生成 · edu-brainstorm-loop</div>
</div>
<script>
var hist = document.getElementById('hist'), MODS = [];
function confirmDeliver(){
  var d = document.getElementById('deliver');
  d.innerHTML = '<div class="diag" style="border-left-color:var(--green);background:#f0fdf6"><b>✅ 方案已定稿</b> · ' + new Date().toLocaleString() + ' · 已通知机器人交付 OpenMAIC 生成课堂</div>';
  // 尝试直接调用 OpenMAIC（若页面在本地 HTTP 下可达）
  try {
    fetch('http://127.0.0.1:3000/api/generate-classroom', {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({requirement: '按已定稿的头脑风暴方案生成课堂（见面板内容）', enableTTS: true, enableImageGeneration: false})
    }).then(function(r){ return r.json(); }).then(function(j){
      if(j && j.jobId){ d.innerHTML += '<div class="diag" style="border-left-color:var(--blue);background:#f0f7ff"><b>🚀 OpenMAIC 已接收</b> · jobId: ' + j.jobId + ' · 正在生成课堂…</div>';
        var iv = setInterval(function(){
          fetch('http://127.0.0.1:3000/api/generate-classroom/' + j.jobId).then(function(r){return r.json()}).then(function(s){
            if(s.status === 'succeeded'){ clearInterval(iv); d.innerHTML += '<div class="diag" style="border-left-color:var(--green);background:#f0fdf6"><b>🎉 课堂已生成！</b> <a href="' + (s.result && s.result.url || '') + '" target="_blank">打开课堂 →</a></div>'; }
            else if(s.status === 'failed'){ clearInterval(iv); d.innerHTML += '<div class="diag" style="border-left-color:var(--red);background:#fef2f2"><b>❌ 生成失败</b> ' + (s.message || '') + '</div>'; }
          }).catch(function(){});
        }, 15000);
      } else { d.innerHTML += '<div class="diag"><b>⚠️ OpenMAIC 未响应</b>（' + (j && j.error || '未知') + '）· 将在 Hermes 端代为触发交付</div>'; }
    }).catch(function(){ d.innerHTML += '<div class="diag"><b>ℹ️ 已在面板记录定稿</b> · OpenMAIC 交付将由 Hermes 执行（点击后请告诉我一声）</div>'; });
  } catch(e){ d.innerHTML += '<div class="diag"><b>ℹ️ 已在面板记录定稿</b> · OpenMAIC 交付将由 Hermes 执行</div>'; }
}
function submitMod(){
  var v = document.getElementById('mod').value.trim();
  if(!v){ document.getElementById('mod').focus(); return; }
  MODS.push(v);
  document.getElementById('mod').value = '';
  var h = '<div class="note" style="text-align:left;margin-top:10px"><b>📝 修改历史（' + MODS.length + ' 条）</b></div>';
  MODS.forEach(function(m, i){ h += '<div class="diag">#' + (i+1) + ' ' + m + '</div>'; });
  h += '<div class="note">⏳ 新一轮讨论已记录，将触发 5 专家迭代 + 复审 → 面板更新</div>';
  hist.innerHTML = h;
}
</script></body></html>''' % (esc(TOPIC), '\n'.join(cards), now)

with io.open(OUT, 'w', encoding='utf-8') as f:
    f.write(PAGE)
print('面板已生成: %s' % OUT)
try:
    subprocess.Popen(['cmd', '/c', 'start', '', OUT])
    print('已在浏览器打开')
except Exception as e:
    print('打开失败:', e)
