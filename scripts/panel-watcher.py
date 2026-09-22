#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""闭环完成自动弹出可视化面板守护 v1.0
监控 brainstorm/round4-final.txt，一旦完成（内容非空）且面板未弹出 → 自动运行 gen-panel.py 生成并弹出。
解决"方案讨论好了但没人弹面板"——不依赖 agent 记性，全程自动。
"""
import os, io, subprocess, time, datetime

W = os.path.expandvars(r'%LOCALAPPDATA%\Temp\brainstorm')
SKILL = os.path.expanduser(r'~\AppData\Local\hermes\skills\edu\edu-brainstorm-loop')
GEN_PANEL = os.path.join(SKILL, 'gen-panel.py')
MARKER = os.path.join(W, 'panel-popped.txt')
POLLED = {}  # filename -> 上次大小

def tail_text(path, n=800):
    try:
        t = io.open(path, encoding='utf-8', errors='replace').read()
        return t[-n:]
    except Exception:
        return ''

def check_and_poppanel():
    """闭环完成判定：round4-final.txt 存在且非空（≥100字）"""
    final = os.path.join(W, 'round4-final.txt')
    if not os.path.exists(final):
        return
    size = os.path.getsize(final)
    if size < 100:
        return
    # 已弹过则不重复（除非内容变大）
    popped = 0
    if os.path.exists(MARKER):
        try:
            popped = int(io.open(MARKER, encoding='utf-8').read().strip() or '0')
        except Exception:
            popped = 0
    if popped >= size:
        return

    # 取主题（从 round0 或 requirement 推断）
    topic = '教育课题'
    for f in ['round0-brains.txt', 'round0-pedagogy.txt']:
        t = tail_text(os.path.join(W, f), 400)
        if t:
            topic = t.splitlines()[0][:40] if t.splitlines() else topic
            break

    print('[%s] 🎉 闭环完成，自动生成并弹出可视化方案面板' % datetime.datetime.now().strftime('%H:%M:%S'))
    try:
        out = os.path.join(os.path.expanduser('~'), 'Desktop', '头脑风暴-方案面板-自动.html')
        subprocess.Popen(['C:/Python314/python', GEN_PANEL, topic, out],
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        io.open(MARKER, 'w', encoding='utf-8').write(str(size))
        print('  已触发面板生成: ' + out)
        # 通知桥接 → 吴老师在群聊发布面板公告（全员可见留档）
        import json as _json, urllib.request as _ur
        try:
            payload = _json.dumps({'panel': out, 'topic': topic}).encode()
            req = _ur.Request('http://127.0.0.1:8790/announce', data=payload,
                              headers={'Content-Type': 'application/json'}, method='POST')
            _ur.urlopen(req, timeout=10)
            print('  已通知吴老师群聊发布面板公告')
        except Exception as e:
            print('  公告通知失败(桥接未运行?): ' + str(e))
    except Exception as e:
        print('  生成失败: ' + str(e))

if __name__ == '__main__':
    print('面板自动弹出守护已启动（监控闭环完成，自动弹可视化面板）')
    while True:
        try:
            check_and_poppanel()
        except Exception as e:
            print('err:', e)
        time.sleep(30)
