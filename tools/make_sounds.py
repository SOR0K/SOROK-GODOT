# 웹 SOROK의 Web Audio 효과음·배경음 공식을 그대로 WAV로 만들어요.
# 실행: python3 tools/make_sounds.py  → sounds/*.wav
import numpy as np, wave, os
from scipy.signal import lfilter
SR = 32000
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
rng = np.random.default_rng(7)
NOISE = rng.uniform(-1, 1, SR)

class Buf:
    def __init__(s, sec): s.a = np.zeros(int(sec * SR) + SR)
    def add(s, t0, x):
        i = int(t0 * SR)
        if i + len(x) > len(s.a): s.a = np.concatenate([s.a, np.zeros(i + len(x) - len(s.a))])
        s.a[i:i + len(x)] += x

def expramp(a, b, n):
    if n <= 0: return np.zeros(0)
    return a * (b / a) ** (np.arange(n) / n)

def env_tn(v, d):
    n1 = int(0.012 * SR); n2 = max(1, int(d * SR) - n1); tail = int(0.05 * SR)
    return np.concatenate([expramp(1e-4, v, n1), expramp(v, 1e-4, n2), np.full(tail, 1e-4)])

def osc(ty, f, f2, d, n):
    t = np.arange(n) / SR
    if f2:
        k = np.log(f2 / f) / d
        fr = np.where(t < d, f * np.exp(k * np.minimum(t, d)), f2)
    else:
        fr = np.full(n, f)
    ph = np.cumsum(fr) / SR
    ph = ph - np.floor(ph)
    if ty == 'sine': return np.sin(2 * np.pi * ph)
    if ty == 'square': return np.where(ph < 0.5, 1.0, -1.0)
    if ty == 'sawtooth': return 2 * ph - 1
    return 1 - 4 * np.abs(ph - 0.5)  # triangle

def biquad(x, ty, f0, Q=None):
    w = 2 * np.pi * min(f0, SR * 0.45) / SR
    Q = Q or (1.0 if ty == 'bandpass' else 0.8)
    al = np.sin(w) / (2 * Q); c = np.cos(w)
    if ty == 'lowpass': b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
    elif ty == 'highpass': b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
    else: b = [al, 0, -al]
    a = [1 + al, -2 * c, 1 - al]
    return lfilter(np.array(b) / a[0], np.array(a) / a[0], x)

def noise(n):
    reps = n // SR + 1
    return np.tile(NOISE, reps)[:n]

class S:
    def __init__(s, sec=3): s.b = Buf(sec)
    def tn(s, f, d, ty='sine', v=0.2, t0=0, f2=None):
        e = env_tn(v, d); s.b.add(t0, osc(ty, f, f2, d, len(e)) * e)
    def nz(s, d, v=0.2, t0=0, fq=1000, ty='lowpass'):
        n = int((d + 0.05) * SR); e = np.concatenate([expramp(v, 1e-4, int(d * SR)), np.full(n - int(d * SR), 1e-4)])
        s.b.add(t0, biquad(noise(n), ty, fq) * e)
    def sw(s, d, v, t0=0, fq=3000, ty='highpass'):
        n1 = int(d * SR); n2 = int(0.25 * SR)
        e = np.concatenate([expramp(1e-4, v, n1), expramp(v, 1e-4, n2), np.full(int(0.1 * SR), 1e-4)])
        s.b.add(t0, biquad(noise(len(e)), ty, fq) * e)
    def arp(s, N, ty='triangle', v=0.16, gap=0.09, d=0.18):
        for i, f in enumerate(N): s.tn(f, d, ty, v, i * gap)

def save(name, x, gain):
    x = x * gain
    nz_ = np.nonzero(np.abs(x) > 1e-4)[0]
    if len(nz_): x = x[:nz_[-1] + 1]
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())

SG = 1.0  # 볼륨은 게임 안에서 조절
def sfx():
    D = {}
    def mk(name, fn, sec=3):
        s = S(sec); fn(s); D[name] = s.b.a
    mk('click', lambda s: s.tn(700, .05, 'triangle', .08))
    mk('err', lambda s: s.tn(220, .16, 'square', .07, 0, 150))
    mk('shoot', lambda s: s.tn(950, .07, 'square', .035, 0, 420))
    mk('hit', lambda s: s.nz(.06, .12, 0, 1800, 'bandpass'))
    mk('ehit', lambda s: s.nz(.05, .06, 0, 1200, 'bandpass'))
    def die(s): s.nz(.16, .13, 0, 900); s.tn(240, .16, 'sawtooth', .05, 0, 70)
    mk('die', die)
    mk('lost', lambda s: s.tn(330, .22, 'triangle', .1, 0, 110))
    def turret(s): s.tn(150, .25, 'sawtooth', .12, 0, 50); s.nz(.2, .14, 0, 600)
    mk('turret', turret)
    def myt(s): s.tn(330, .14, 'square', .07, 0, 130); s.nz(.08, .06, 0, 2500, 'highpass')
    mk('myturret', myt)
    mk('spawn', lambda s: s.arp([440, 660], 'triangle', .12, .06, .1))
    def ore(s): s.tn(1250, .05, 'sine', .05); s.tn(1660, .07, 'sine', .04, .04)
    mk('ore', ore)
    mk('capture', lambda s: s.arp([523, 659, 784, 1046], 'triangle', .16, .09, .22))
    def victory(s):
        for f, t in [(523, 0), (659, .14), (784, .28), (1046, .42)]:
            s.tn(f, .32, 'triangle', .16, t); s.tn(f / 2, .32, 'square', .04, t)
        for f in [523, 659, 784, 1046, 1318]: s.tn(f, 1.8, 'triangle', .09, .62)
        s.tn(130, 1.6, 'sine', .3, .62, 65)
        s.nz(.4, .2, .62, 5000, 'highpass')
        for t in [1.4, 1.75, 2.1, 2.6]:
            s.nz(.25, .12, t, 2500, 'bandpass'); s.tn(1800 + rng.random() * 900, .35, 'sine', .03, t + .05, 600)
    mk('victory', victory, 4)
    def alarm(s):
        for i in range(3): s.tn(880, .22, 'square', .07, i * .5); s.tn(660, .22, 'square', .07, i * .5 + .25)
    mk('alarm', alarm)
    def raid(s): s.tn(90, .6, 'sine', .35, 0, 40); s.nz(.5, .22, 0, 300); s.tn(110, .6, 'sine', .3, .35, 45)
    mk('raid', raid)
    mk('basehit', lambda s: s.tn(110, .14, 'square', .1, 0, 70))
    def boom(s): s.nz(1.8, .45, 0, 500); s.tn(85, 1.5, 'sine', .45, 0, 30); s.nz(1, .25, .3, 1500, 'bandpass')
    mk('boom', boom)
    mk('up', lambda s: s.arp([587, 880], 'triangle', .12, .07, .12))
    def evo(s): s.tn(300, .7, 'sine', .18, 0, 1200); s.arp([1046, 1318, 1568, 2093], 'sine', .08, .1, .3)
    mk('evo', evo)
    mk('drone', lambda s: s.tn(520, .35, 'sawtooth', .04, 0, 950))
    def vb(s): s.tn(220, .45, 'sine', .3, 0, 60); s.nz(.5, .18, 0, 2500, 'highpass')
    mk('vbomb', vb)
    def oil(s): s.nz(.28, .13, 0, 700, 'bandpass'); s.tn(300, .22, 'sine', .08, 0, 520)
    mk('oil', oil)
    mk('pause', lambda s: s.tn(440, .12, 'triangle', .1, 0, 330))
    def cm_atk(s): s.tn(520, .06, 'square', .03); s.tn(390, .09, 'square', .025, .05)
    mk('cmd_atk', cm_atk)
    def cm_mv(s): s.tn(980, .05, 'sine', .045); s.tn(1470, .07, 'sine', .035, .04)
    mk('cmd_mv', cm_mv)
    def flag(s): s.tn(660, .08, 'triangle', .05); s.tn(990, .12, 'triangle', .04, .06)
    mk('flag', flag)
    def box(s):
        for i in range(5): s.nz(.08, .2, i * .16, 420, 'bandpass'); s.tn(150 - i * 6, .09, 'sine', .14, i * .16, 90)
        s.nz(.04, .18, .84, 4200, 'highpass'); s.sw(.25, .1, .64, 6000)
        for i, f in enumerate([784, 988, 1175, 1568]): s.tn(f, .9, 'sine', .055, .9 + i * .025); s.tn(f * 2, .5, 'sine', .015, .9 + i * .025)
        s.tn(98, .7, 'sine', .2, .9, 60)
    mk('box', box)
    def reveal(s): s.tn(988, .38, 'triangle', .08); s.tn(1976, .22, 'sine', .025); s.tn(494, .3, 'sine', .03)
    mk('reveal', reveal)
    def rare(s): s.arp([784, 988, 1175, 1568, 1976], 'sine', .075, .05, .65); s.tn(392, .9, 'triangle', .05); s.nz(.5, .05, .15, 7000, 'highpass')
    mk('rare', rare)
    def jack(s):
        for f in [392, 523, 659, 784]: s.tn(f, 1.6, 'triangle', .06); s.tn(f * 2, 1.2, 'sine', .025)
        s.arp([1046, 1318, 1568, 2093, 2637], 'sine', .08, .07, .7); s.tn(98, 1.2, 'sine', .3, 0, 55); s.nz(1.2, .1, .2, 6000, 'highpass')
    mk('jack', jack)
    def sbox(s):
        s.tn(55, 1, 'sawtooth', .1, 0, 110); s.tn(82, 1, 'sine', .22, 0, 165)
        for f in [262, 330, 392, 523]: s.tn(f, 1.1, 'sine', .045); s.tn(f * 1.006, 1.1, 'sine', .035)
        s.sw(.9, .22, 0, 4000)
        for i in range(8): s.tn(72, .09, 'sine', .22, i * .11, 50)
        s.nz(1.3, .32, .95, 800); s.tn(65, 1.5, 'sine', .5, .95, 35)
        for f in [523, 659, 784, 1046, 1568]: s.tn(f, 1.7, 'triangle', .065, .95)
    mk('sbox', sbox, 4)
    def sreveal(s): s.tn(1568, .55, 'sine', .08); s.tn(3136, .32, 'sine', .03); s.tn(2093, .4, 'sine', .025, .03)
    mk('sreveal', sreveal)
    def srare(s): s.arp([1046, 1318, 1568, 2093], 'sine', .1, .06, .55); s.nz(.6, .07, .1, 7000, 'highpass')
    mk('srare', srare)
    def sjack(s):
        for i in range(10): s.tn(70, .1, 'sine', .25, i * .06, 48)
        s.sw(.6, .2, 0, 3000); s.tn(65, 2.2, 'sine', .45, .6, 40)
        for f in [131, 196, 262, 330, 392, 523, 659, 784, 1046]: s.tn(f, 2.6, 'triangle', .055, .6); s.tn(f * 1.004, 2.6, 'sine', .035, .6)
        s.arp([1568, 2093, 2637, 3136], 'sine', .06, .1, .7); s.nz(1.6, .14, .6, 6500, 'highpass')
    mk('sjack', sjack, 4)
    for k, x in D.items(): save(k, x, 1.4 * (0.6 if k in ("sbox", "sjack") else 1.0))  # 웹 효과음 음량(0.42)의 약 3.3배 · 큰 뽑기음은 찢어지지 않게 줄임

BGC = {'lobby': [[220, 262, 330], [175, 220, 262], [262, 330, 392], [196, 247, 294]],
       'game': [[147, 175, 220], [117, 147, 175], [175, 220, 262], [131, 165, 196]],
       'raid': [[165, 196, 247], [131, 165, 196], [147, 185, 220], [124, 156, 185]]}

def bgm(md):
    step = 0.26; n = 32
    s = S(step * n * 3 + 3)
    for g in range(n * 3):
        t0 = g * step; C = BGC[md]; ch = C[(g // 8) % 4]; s8 = g % 8
        if s8 == 0:
            for f in ch: s.tn(f, 2.1, 'sine', .05, t0)
        if md == 'raid':
            if s8 % 2 == 0: s.tn(62, .16, 'sine', .3, t0, 38)
            if s8 % 2 == 1: s.nz(.04, .05, t0, 7000, 'highpass')
            s.tn(ch[s8 % 3] * 2, .12, 'square', .02, t0)
        elif s8 % 2 == 0 or md == 'lobby':
            s.tn(ch[(s8 >> 1) % 3] * 2, .4, 'triangle', .035, t0)
    L = int(step * n * SR)
    loop = s.b.a[L:2 * L]  # 배경음:효과음 비율은 웹과 같게 (0.1575 : 0.42) · 두 번째 바퀴 = 앞 바퀴 꼬리까지 들어간 끊김 없는 반복
    pcm = (np.clip(loop * 0.52, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, 'bgm_' + md + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    sfx()
    for m in BGC: bgm(m)
    print('done', sorted(os.listdir(OUT)))
