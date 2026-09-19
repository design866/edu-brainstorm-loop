#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""头脑风暴桥接服务 v3：面板确认/修改 → 直接派活给机器人（无需回对话）
端点:
  GET  /            工作台页面
  GET  /api         机器人状态
  POST /revise      修改意见 → 派活 edu-brains + edu-pedagogy 开始新一轮讨论
  POST /confirm     定稿确认 → 派活 edu-reviewer 立即制作 OpenMAIC 课堂
"""
import json, os, re, io, subprocess, threading, datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

W = os.path.expandvars(r'%LOCALAPPDATA%\Temp\brainstorm')
HERMES = os.path.expanduser(r'~\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe')
CONFIRM_LOG = os.path.join(W, 'confirm-jobs.json')
PAGE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'board-page.html')

BOTS = [
    ('edu-brains', '💡', '点子哥', '创意发散', [('round0-brains', '① 小组发散'), ('r3-brains', '③ 迭代深化'), ('revise-brains', '✏️ 修改迭代')]),
    ('edu-pedagogy', '🎓', '苏博士', '教育学·题型', [('round0-pedagogy', '① 小组发散'), ('r3-pedagogy', '③ 迭代深化'), ('revise-pedagogy', '✏️ 修改迭代')]),
    ('edu-planner', '🧭', '蔡老师', '课题规划·可行性', [('round2-planner', '② 评审'), ('r2-planner', '② 评审')]),
    ('edu-designer', '🎨', '李老师', '教学设计·落地', [('round2-designer', '② 评审'), ('r2-designer', '② 评审')]),
    ('edu-reviewer', '🔍', '吴老师', '诊断·终审·执行', [('round2-reviewer', '② 评审'), ('r2-reviewer', '② 评审'), ('r4-final', '④ 终审'), ('reviewer-exec', '🚀 执行制作')]),
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
    lines = [l for l in t.splitlines() if l.strip()]
    return '\n'.join(lines)[:1400] if lines else None

def status():
    bots = []
    for prof, em, name, role, rounds in BOTS:
        msgs = []
        for f, label in rounds:
            t = readf(f)
            if t:
                msgs.append({'round': label, 'text': t})
        total = len(rounds)
        bots.append({'em': em, 'name': name, 'role': role, 'msgs': msgs,
                     'working': 0 < len(msgs) < total, 'done': len(msgs) >= total})
    return {'bots': bots}

def _env():
    env = dict(os.environ)
    env['HTTPS_PROXY'] = 'http://127.0.0.1:7892'
    env['HTTP_PROXY'] = 'http://127.0.0.1:7892'
    return env

def _log(job):
    jobs = []
    if os.path.exists(CONFIRM_LOG):
        try:
            jobs = json.load(io.open(CONFIRM_LOG, encoding='utf-8'))
        except Exception:
            jobs = []
    jobs.append(job)
    io.open(CONFIRM_LOG, 'w', encoding='utf-8').write(json.dumps(jobs, ensure_ascii=False))

def dispatch_revise(mod_text):
    job = {'time': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
           'revise': mod_text[:200], 'status': 'dispatched'}
    _log(job)

    def run():
        for prof, out in [('edu-brains', 'revise-brains'), ('edu-pedagogy', 'revise-pedagogy')]:
            try:
                q = ('【修改意见·立即开始新一轮讨论】用户提交修改意见，请立即行动不要等待：'
                     + mod_text[:200] +
                     '（点子哥：按意见迭代创意方案；苏博士：补教育学理论支撑）完成后把结果写入输出。')
                subprocess.Popen(
                    [HERMES, '-p', prof, 'chat', '--in', os.path.expanduser('~'),
                     '-c', 'Bot Chat', '--create-if-missing', '-Q', '-q', q],
                    env=_env(), stdout=open(os.path.join(W, out + '.txt'), 'w', encoding='utf-8'),
                    stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
            except Exception as e:
                io.open(os.path.join(W, out + '.txt'), 'a', encoding='utf-8').write('\nERR: ' + str(e))
    threading.Thread(target=run, daemon=True).start()
    return job

def dispatch_reviewer(requirement):
    job = {'time': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
           'requirement': requirement[:200], 'status': 'dispatched'}
    _log(job)

    def run():
        try:
            q = ('【定稿确认·立即执行】用户已在面板点击"确定定稿"。请立即行动，不要等待、不要询问：'
                 '① 按定稿要求直接调用 OpenMAIC 生成课堂：' + requirement[:150] +
                 ' ② 生成后按验收清单自检 ③ 输出联调对话脚本（15秒闭环节奏+三档反馈话术）。完成后把结果写入输出。')
            subprocess.Popen(
                [HERMES, '-p', 'edu-reviewer', 'chat', '--in', os.path.expanduser('~'),
                 '-c', 'Bot Chat', '--create-if-missing', '-Q', '-q', q],
                env=_env(), stdout=open(os.path.join(W, 'reviewer-exec.txt'), 'w', encoding='utf-8'),
                stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
        except Exception as e:
            io.open(os.path.join(W, 'reviewer-exec.txt'), 'a', encoding='utf-8').write('\nERR: ' + str(e))
    threading.Thread(target=run, daemon=True).start()
    return job

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
    def do_OPTIONS(self):
        self.send_response(200); self._cors(); self.end_headers()
    def do_GET(self):
        p = urlparse(self.path).path
        if p == '/api':
            data = json.dumps(status(), ensure_ascii=False).encode()
            self.send_response(200); self._cors()
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(data))); self.end_headers(); self.wfile.write(data)
        else:
            page = '<html><body>board page missing</body></html>'
            if os.path.exists(PAGE_FILE):
                page = io.open(PAGE_FILE, encoding='utf-8').read()
            b = page.encode()
            self.send_response(200); self._cors()
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_POST(self):
        p = urlparse(self.path).path
        length = int(self.headers.get('Content-Length', 0))
        body = {}
        if length:
            try:
                body = json.loads(self.rfile.read(length).decode('utf-8'))
            except Exception:
                body = {}
        if p == '/revise':
            job = dispatch_revise(body.get('mod', '请优化方案'))
            out = {'ok': True, 'message': '已通知点子哥+苏博士按修改意见开始新一轮讨论', 'job': job}
        elif p == '/confirm':
            job = dispatch_reviewer(body.get('requirement', '按定稿方案执行交付'))
            out = {'ok': True, 'message': '已通知吴老师立即开工制作课堂', 'job': job}
        else:
            self.send_response(404); self._cors(); self.end_headers(); return
        data = json.dumps(out, ensure_ascii=False).encode()
        self.send_response(200); self._cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data))); self.end_headers(); self.wfile.write(data)

if __name__ == '__main__':
    print('桥接服务: http://127.0.0.1:8790  (POST /revise | /confirm → 派活机器人)')
    HTTPServer(('127.0.0.1', 8790), H).serve_forever()
