#!/usr/bin/env python3
"""Assemble the narrated film. AUDIO DRIVES VIDEO, by construction.

Inputs (paths at top): narration.md (cue blocks), slide/doc/card PNGs, tour webm
clips, the warped terminal gif, kokoro model files. Output: film/<name>.mp4 + .srt.

Core invariants (each one was a shipped defect before it became a rule):
- Every still's duration COVERS its own cue wherever the audio timeline has drifted:
  vo_start = max(t + 0.9, prev_end + 0.7); d = (vo_start - t) + vo_len + PAD.
  A global push-apart pass alone is NOT enough - drift accumulates and slides
  advance mid-sentence.
- Terminal plays at TS (setpts=PTS/TS); every cast anchor divides by TS; holds were
  pre-scaled by TS in gen_holds.py.
- Segment mp4s cache by filename: WIPE the cache when cue text, TS, or plan order
  changes, or stale durations ship silently.
- Cue wavs cache by key: delete the wav when its text changes.
"""
import json, os, re, subprocess, wave

# ---- EDIT ME: paths --------------------------------------------------------
S = os.environ.get('FILM_ROOT', os.getcwd())          # working root
OUT = f'{S}/film'
VO = f'{S}/vo'
NARRATION = f'{S}/narration.md'
TERM_GIF = f'{S}/term-warped.gif'
WARPED_CAST = f'{S}/take-warped.cast'
KOKORO_MODEL = f'{S}/voice/kokoro-v1.0.onnx'
KOKORO_VOICES = f'{S}/voice/voices-v1.0.bin'
VOICE, SPEED = 'af_heart', 0.95                       # the audition winner
TS = 1.0                                              # terminal playback speed
STILL_PAD = 1.0
os.makedirs(OUT, exist_ok=True); os.makedirs(VO, exist_ok=True)

def sh(*a):
    r = subprocess.run(a, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f'{a[0]}: {r.stderr[-400:]}')
    return r.stdout

# ---- narration -> cached wavs ---------------------------------------------
cues = {}
for m in re.finditer(r'\[([a-z0-9-]+)\]\n(.+?)(?=\n\[|\Z)', open(NARRATION).read(), re.S):
    cues[m.group(1)] = ' '.join(m.group(2).split())

_k = None
def vo(key):
    global _k
    w = f'{VO}/{key}.wav'
    if not os.path.exists(w):
        from kokoro_onnx import Kokoro
        import soundfile as sf
        if _k is None:
            _k = Kokoro(KOKORO_MODEL, KOKORO_VOICES)
        audio, sr = _k.create(cues[key], voice=VOICE, speed=SPEED)
        sf.write(w, audio, sr)
    with wave.open(w) as f:
        return f.getnframes() / f.getframerate()

durs = {k: vo(k) for k in cues}
print('VO cues:', len(durs))

# ---- EDIT ME: the ordered plan --------------------------------------------
# ('still', png_path, cue_key)
# ('clip', name, webm_path, lead_trim_s, cue_key, extra_dwell_s)
# ('termpart', 'p1')          terminal split at anchors so docs can interleave
# ('closing',)                cover slide + fade out
plan = [
    # ('still', f'{S}/deck/slide-01.png', 'slide-01'),
    # ('clip', 'home', f'{S}/tour/home.webm', 1.0, 'tour-01-home', 3.0),
    # ('termpart', 'p1'),
    # ('closing',),
]
CLOSING_PNG = f'{S}/deck/slide-01.png'

# ---- terminal mp4 at TS + anchors -----------------------------------------
term_mp4 = f'{OUT}/seg-term.mp4'
if not os.path.exists(term_mp4):
    sh('ffmpeg','-loglevel','error','-i',TERM_GIF,
       '-vf',f'scale=1920:1080:force_original_aspect_ratio=decrease,'
             f'pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x121212,setpts=PTS/{TS}',
       '-r','30','-pix_fmt','yuv420p','-y',term_mp4)
term_dur = float(sh('ffprobe','-v','error','-show_entries','format=duration',
                    '-of','csv=p=0',term_mp4).strip())

warped = [json.loads(l) for l in open(WARPED_CAST).read().strip().split('\n')[1:]]
def find_time(needle):
    for ts_, kind, data in warped:
        if needle in data:
            return ts_ / TS
    raise RuntimeError('anchor missing: ' + needle)

# EDIT ME: (cue_key, anchor time) pairs + part bounds keyed off them.
term_anchors = [
    # ('term-intro', 0.0),
    # ('term-plan', find_time('the second thing you typed')),
]
anch = dict(term_anchors)
bounds = {
    # 'p1': (0.0, anch['term-spec'] - 1.0),
    # 'p2': (anch['term-spec'] - 1.0, term_dur),
}

# ---- build segments; every still covers its own cue -----------------------
segs, timeline, t, prev_end = [], [], 0.0, 0.0
for item in plan:
    if item[0] == 'still':
        _, png, key = item
        vo_start = max(t + 0.9, prev_end + 0.7)
        d = (vo_start - t) + durs[key] + STILL_PAD
        out = f'{OUT}/seg-{key}.mp4'
        if not os.path.exists(out):
            sh('ffmpeg','-loglevel','error','-loop','1','-i',png,'-t',f'{d:.2f}',
               '-vf','scale=1920:1080','-r','30','-pix_fmt','yuv420p','-y',out)
        timeline.append((vo_start, durs[key], key)); prev_end = vo_start + durs[key]
        segs.append(out); t += d
    elif item[0] == 'clip':
        _, name, path, trim, key, extra = item
        out = f'{OUT}/seg-{name}.mp4'
        dur = float(sh('ffprobe','-v','error','-show_entries','format=duration',
                       '-of','csv=p=0',path).strip())
        vo_start = max(t + 0.5, prev_end + 0.7)
        keep = min(dur - trim, (vo_start - t) + durs[key] + extra)
        if not os.path.exists(out):
            sh('ffmpeg','-loglevel','error','-ss',f'{trim:.2f}','-i',path,'-t',f'{keep:.2f}',
               '-vf','scale=1920:1080','-r','30','-pix_fmt','yuv420p','-y',out)
        timeline.append((vo_start, durs[key], key)); prev_end = vo_start + durs[key]
        segs.append(out); t += keep
    elif item[0] == 'closing':
        key = 'closing'
        vo_start = max(t + 1.0, prev_end + 0.7)
        d = (vo_start - t) + durs[key] + 3.0
        out = f'{OUT}/seg-closing.mp4'
        if not os.path.exists(out):
            sh('ffmpeg','-loglevel','error','-loop','1','-i',CLOSING_PNG,'-t',f'{d:.2f}',
               '-vf',f'scale=1920:1080,fade=t=in:st=0:d=0.8,fade=t=out:st={d-2.2:.2f}:d=2.2',
               '-r','30','-pix_fmt','yuv420p','-y',out)
        timeline.append((vo_start, durs[key], key)); prev_end = vo_start + durs[key]
        segs.append(out); t += d
    else:
        pname = item[1]
        p_start, p_end = bounds[pname]
        out = f'{OUT}/seg-term-{pname}.mp4'
        if not os.path.exists(out):
            sh('ffmpeg','-loglevel','error','-ss',f'{p_start:.2f}','-i',term_mp4,
               '-t',f'{p_end - p_start:.2f}','-r','30','-pix_fmt','yuv420p','-y',out)
        for key, at in term_anchors:
            if p_start <= at < p_end:
                vo_start = max(t + (at - p_start) + 0.5, prev_end + 0.7)
                timeline.append((vo_start, durs[key], key)); prev_end = vo_start + durs[key]
        segs.append(out); t += p_end - p_start
total = t
print('film total %.1f min' % (total / 60))

timeline.sort()
overlaps = sum(1 for i in range(1, len(timeline))
               if timeline[i][0] < timeline[i-1][0] + timeline[i-1][1])
print('overlaps:', overlaps)   # MUST be 0

with open(f'{OUT}/concat.txt','w') as f:
    for s0 in segs:
        f.write(f"file '{s0}'\n")
sh('ffmpeg','-loglevel','error','-f','concat','-safe','0','-i',f'{OUT}/concat.txt',
   '-c','copy','-y',f'{OUT}/film-silent.mp4')

inputs, filters, mix = [], [], []
for n, (start, dur, key) in enumerate(timeline):
    inputs += ['-i', f'{VO}/{key}.wav']
    filters.append(f'[{n}:a]adelay={int(start*1000)}|{int(start*1000)}[a{n}]')
    mix.append(f'[a{n}]')
fc = ';'.join(filters) + f';{"".join(mix)}amix=inputs={len(timeline)}:normalize=0,loudnorm[out]'
sh('ffmpeg','-loglevel','error', *inputs, '-filter_complex', fc, '-map','[out]',
   '-t',f'{total:.2f}','-y',f'{OUT}/vo-track.wav')
sh('ffmpeg','-loglevel','error','-i',f'{OUT}/film-silent.mp4','-i',f'{OUT}/vo-track.wav',
   '-c:v','copy','-c:a','aac','-b:a','160k','-shortest','-y',f'{OUT}/film.mp4')

def ts_(x):
    return f'{int(x//3600):02d}:{int(x%3600//60):02d}:{x%60:06.3f}'.replace('.', ',')
with open(f'{OUT}/film.srt','w') as f:
    idx = 1
    for start, dur, key in timeline:
        words, chunks, cur = cues[key].split(), [], []
        for w in words:
            cur.append(w)
            if len(' '.join(cur)) > 90:
                chunks.append(' '.join(cur)); cur = []
        if cur:
            chunks.append(' '.join(cur))
        step = dur / len(chunks)
        for i, c in enumerate(chunks):
            f.write(f'{idx}\n{ts_(start+i*step)} --> {ts_(min(start+(i+1)*step, start+dur))}\n{c}\n\n')
            idx += 1
print('DONE:', f'{OUT}/film.mp4')
