"""ORBIT ZERO original cinematic space audio generator.

All waveforms and chord motifs are original, synthesized procedurally with NumPy.
To regenerate: python3 -m pip install numpy; python3 tools/generate_audio.py
No third-party samples, copyrighted themes or sound libraries are used.
"""
from pathlib import Path
import numpy as np
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'OrbitZero' / 'Audio'
ROOT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(20261101)


def save(name, data, headroom=.87):
    a = np.asarray(data, dtype=np.float32)
    a = np.nan_to_num(a)
    # Gentle compression / soft clipping, preserving headroom.
    a = np.tanh(a * 1.4)
    peak = max(float(np.max(np.abs(a))), 1e-6)
    a = a * (headroom / peak)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes((np.clip(a, -1, 1) * 32767).astype('<i2').tobytes())


def tone(t, hz, texture='sine'):
    phi = 2 * np.pi * hz * t
    if texture == 'pad':
        return (.76 * np.sin(phi) + .21 * np.sin(2*phi + .08*np.sin(2*np.pi*.23*t)) + .11*np.sin(3*phi))
    if texture == 'laser':
        return .8 * np.sin(phi) + .25 * np.sin(2*phi + 1.2) + .12*np.sin(3*phi)
    if texture == 'rough':
        return .64 * np.sin(phi)+.25*np.sin(2*phi)+.15*np.sin(3*phi)+.10*np.sin(4*phi)
    return np.sin(phi)


def smooth_env(t, duration, rise=.015, decay=.14):
    return np.minimum(1, t/max(rise, .0001))*np.minimum(1, (duration-t)/max(decay,.0001)).clip(0,1)


def filtered_noise(n, smoothing=32):
    noise = rng.normal(0,1,n)
    # lightweight low-pass with cumulative moving average
    kern = np.ones(smoothing)/smoothing
    smooth = np.convolve(noise, kern, mode='same')
    return smooth


def chirp(name, duration, start, end, effect='space', volume=.66):
    n = int(RATE * duration); t=np.arange(n)/RATE
    # frequency glide with non-linear curve + stereo-free phase modulation
    f = end+(start-end)*np.exp(-6*t/duration)
    phase=2*np.pi*np.cumsum(f)/RATE
    buzz=np.sin(phase+.35*np.sin(phase*.33))
    buzz+=.29*np.sin(2*phase)
    whine=np.sin(phase*.48+5*np.sin(2*np.pi*8*t))*0.35
    env=smooth_env(t,duration,.015,max(.08,duration*.22))
    if effect=='blast':
        noise=filtered_noise(n,10)
        data=(buzz*.52 + whine*.2 + noise*.4)*env*np.exp(-1.1*t/duration)
    elif effect=='warning':
        on=(np.sin(2*np.pi*4.2*t)>-.25).astype(float)
        data=(buzz*.7 +whine*.1)*env*on
    elif effect=='warp':
        whoosh=filtered_noise(n,25)
        data=(buzz*.48+whine*.2+whoosh*.65)*env
    else:
        data=(buzz*.72+whine*.18)*env
    save(name,volume*data)


def add_at(out, piece, at):
    start=int(at*RATE)
    if start>=len(out): return
    end=min(len(out),start+len(piece))
    out[start:end]+=piece[:end-start]


def note(out, hz, at, dur, gain=.1, shape='pad', rise=.18, tail=.18):
    n=int(dur*RATE)
    t=np.arange(n)/RATE
    if shape=='bell':
        s=(np.sin(2*np.pi*hz*t)+.35*np.sin(2*np.pi*2.01*hz*t)+.12*np.sin(2*np.pi*3.05*hz*t))
        env=np.exp(-4.3*t/max(dur,.1))*np.minimum(1,t/.008)
    elif shape=='bass':
        s=tone(t,hz,'rough');env=np.exp(-2.2*t/max(dur,.1))*np.minimum(1,t/.012)
    else:
        s=tone(t,hz,'pad')
        env=smooth_env(t,dur,rise,tail)
        env*=.94+.06*np.sin(2*np.pi*.21*t)
    add_at(out,gain*env*s,at)


def music(name,boss=False):
    length=48
    n=RATE*length
    out=np.zeros(n,dtype=np.float32)
    # Original 6-chord sequence, two evolving passes (48 seconds in total).
    chords=[(146.83,174.61,220.00), (130.81,164.81,196.00), (155.56,196.00,233.08),
            (116.54,146.83,174.61), (130.81,174.61,207.65), (123.47,155.56,185.00)]
    for k in range(12):
        at=4*k
        ch=chords[k%6]
        for j,hz in enumerate(ch):
            # The second pass evolves by emphasizing the upper harmonics.
            shifted = hz * (2 if k>=6 and j==2 else 1)
            note(out,shifted,at,4.0,gain=(.052 if boss else .065),rise=.6,tail=.45)
            note(out,hz/2,at,4.0,gain=.026 if boss else .021,rise=.35,tail=.45)
    # a unique non-heroic arpeggio; no borrowed film melodies
    motif=[0,2,1,0,1,2,0,1,2,1,0,2]
    for k in range(96):
        beat=k*.5
        ch=chords[int(beat//4)%6]
        tone_idx=motif[(k + (3 if k>=48 else 0))%12]
        pitch=ch[tone_idx]*(2 if k%8 in ([3,7] if k<48 else [1,5]) else 1)
        note(out,pitch,beat,.55 if not boss else .38,gain=.045 if not boss else .065,shape='bell')
    # deep propulsion pulse / procedural orchestral percussion
    for k in range(96):
        at=k*.5
        f=(55 if not boss else 73) * (1 + .06*(k%4==0))
        note(out,f,at,.32,gain=.062 if not boss else .090,shape='bass')
        if boss or k%4==0:
            nt=int(.18*RATE)
            tt=np.arange(nt)/RATE
            impact=np.sin(2*np.pi*np.cumsum((80+170*np.exp(-tt*18)))/RATE)
            impact*=np.exp(-tt*(24 if boss else 30))
            add_at(out,(.065 if boss else .027)*impact,at)
    if boss:
        # tension shimmer in 4-bar phrases, low enough to preserve gameplay focus
        for at in range(0,length,2):
            note(out,440*(2 if at%4==0 else 1.5),at,1.4,gain=.029,shape='bell')
    else:
        for at in range(0,length,4):
            note(out,392,at,2.4,gain=.025,shape='bell')
    # warm echo with periodic wrap ensures seamless loops
    delay=int((.26 if boss else .39)*RATE)
    out+=np.roll(out,delay)*(.12 if boss else .17)
    # final 0.1 seconds crossfade to first samples with no discontinuity
    fade=int(.15*RATE)
    c=np.linspace(0,1,fade,dtype=np.float32)
    out[-fade:]=out[-fade:]*(1-c)+out[:fade]*c
    save(name,out,headroom=.52 if boss else .47)


def start():
    chirp('start',1.05,110,960,effect='warp')
    chirp('success',.36,1100,390,effect='space') # short jump drive burst
    chirp('perfect',.63,420,2100,effect='warp')
    chirp('failure',.72,450,75,effect='blast')
    chirp('boss',1.3,75,360,effect='warning')
    chirp('intercept',.43,900,210,effect='blast')
    chirp('deploy',.52,360,650,effect='warning')
    chirp('surge',.90,70,1600,effect='warp')
    chirp('shift',.44,680,240,effect='space')
    chirp('bomb',1.18,220,45,effect='blast')
    chirp('victory',1.6,360,1020,effect='warp')
    chirp('focus',.58,550,1250,effect='space')
    music('orbit_ambient',boss=False)
    music('boss_protocol',boss=True)
    for name in sorted(ROOT.glob('*.wav')):
        print(f'{name.name}: {name.stat().st_size//1024} KiB')

if __name__=='__main__': start()
