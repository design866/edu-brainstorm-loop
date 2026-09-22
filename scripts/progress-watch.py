#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""课堂生成进度轮询 v2：持续监控（不再 40 分钟超时），新课堂自动接续汇报"""
import json, os, io, time, datetime

CLASSROOMS = r'C:\Users\Gilbert\OpenMAIC\data\classrooms'
LOG = os.path.join(os.path.expandvars(r'%LOCALAPPDATA%\Temp\brainstorm'), 'progress-report.txt')
# 已汇报过的课堂 + 音频数（避免重复）
DONE = {}

def latest_classroom():
    best = None
    for f in os.listdir(CLASSROOMS):
        if f.endswith('.json'):
            p = os.path.join(CLASSROOMS, f)
            t = os.path.getmtime(p)
            if best is None or t > best[1]:
                best = (p, t, f[:-5])
    return best

def scene_progress(path):
    try:
        d = json.load(io.open(path, encoding='utf-8'))
        scenes = d.get('scenes', [])
        aud = os.path.join(os.path.dirname(path), os.path.splitext(os.path.basename(path))[0], 'audio')
        n_audio = len(os.listdir(aud)) if os.path.isdir(aud) else 0
        return len(scenes), n_audio
    except Exception:
        return 0, 0

def report(msg):
    line = '[%s] %s' % (datetime.datetime.now().strftime('%H:%M:%S'), msg)
    print(line, flush=True)
    with io.open(LOG, 'a', encoding='utf-8') as f:
        f.write(line + '\n')

if __name__ == '__main__':
    report('🔄 进度轮询 v2 启动（持续监控，不再超时退出）')
    while True:
        try:
            res = latest_classroom()
            if res:
                path, mtime, cid = res
                n_scenes, n_audio = scene_progress(path)
                prev = DONE.get(cid, -1)
                # 音频增长 → 汇报；完成（音频≥30 且稳定）→ 汇报一次
                if n_audio != prev:
                    report('📊 课堂 %s 进度：场景 %d/%d · 音频 %d 条 · %s' % (
                        cid, min(n_scenes, 14), n_scenes, n_audio,
                        datetime.datetime.fromtimestamp(mtime).strftime('%H:%M')))
                    DONE[cid] = n_audio
                # 完成检测：音频 ≥30 且 2 次轮询无增长
                if n_audio >= 30 and n_audio == prev:
                    if DONE.get(cid + '_done', False) is False:
                        report('🎉 课堂 %s 制作完成！%d 场景 + %d 音频 · 可交付' % (cid, n_scenes, n_audio))
                        DONE[cid + '_done'] = True
        except Exception as e:
            report('轮询错误: ' + str(e))
        time.sleep(45)
