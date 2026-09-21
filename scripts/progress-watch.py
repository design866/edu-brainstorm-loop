#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""课堂生成进度轮询：每节完成向用户汇报（进度回报·制作不停）"""
import json, os, io, time, subprocess, datetime

CLASSROOMS = r'C:\Users\Gilbert\OpenMAIC\data\classrooms'
KNOWN = {}

def latest_classroom():
    """找最近修改的课堂 JSON"""
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
        # 统计音频完成数（更准：音频=已合成）
        aud = os.path.join(os.path.dirname(path), os.path.splitext(os.path.basename(path))[0], 'audio')
        n_audio = len(os.listdir(aud)) if os.path.isdir(aud) else 0
        return len(scenes), n_audio
    except Exception:
        return 0, 0

def report(msg):
    line = '[%s] %s' % (datetime.datetime.now().strftime('%H:%M:%S'), msg)
    print(line)
    # 写入汇报日志
    log = os.path.join(os.path.expandvars(r'%LOCALAPPDATA%\Temp\brainstorm'), 'progress-report.txt')
    with io.open(log, 'a', encoding='utf-8') as f:
        f.write(line + '\n')

if __name__ == '__main__':
    last_scene = -1
    last_audio = -1
    for _ in range(240):  # 轮询 40 分钟
        res = latest_classroom()
        if res:
            path, mtime, cid = res
            n_scenes, n_audio = scene_progress(path)
            # 场景全生成 + 音频增长 = 制作中；每完成一节（音频突增）汇报
            if n_audio != last_audio:
                report('📊 课堂 %s 进度：场景 %d/%d 已生成 · 音频 %d 条 · %s' % (
                    cid, min(n_scenes, 7), n_scenes, n_audio, datetime.datetime.fromtimestamp(mtime).strftime('%H:%M')))
                last_audio = n_audio
            # 全部完成检测：音频不再增长且 ≥30
            if n_scenes >= 7 and n_audio >= 30 and n_audio == last_audio:
                # 检查是否稳定（两次相同）
                if getattr(__import__('sys'), '_stable', 0) >= 2:
                    report('🎉 课堂 %s 制作完成！7 场景 + %d 音频 · 可交付' % (cid, n_audio))
                    break
                __import__('sys')._stable = getattr(__import__('sys'), '_stable', 0) + 1
        time.sleep(60)
    report('⏹ 轮询结束（或 40 分钟超时）')
