import librosa, numpy as np
y, sr = librosa.load('theme.wav', sr=22050)
H,P = librosa.effects.hpss(y)
names=['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
for a,b in [(0,9),(9,21.3),(21.3,41.5),(41.5,54.9),(54.9,60)]:
    s,e=int(a*sr),int(b*sr)
    print(f"{a}-{b} harm/perc energy ratio {np.sum(H[s:e]**2)/(np.sum(P[s:e]**2)+1e-9):.1f}")
ch = librosa.feature.chroma_cqt(y=H, sr=sr, hop_length=512)
t = librosa.times_like(ch, sr=sr, hop_length=512)
# chord templates triads
tmpl={}
for r in range(12):
    for q,iv in [('',[0,4,7]),('m',[0,3,7])]:
        v=np.zeros(12); v[[(r+i)%12 for i in iv]]=1; tmpl[names[r]+q]=v
bar = 60/117.45*4
out=[]
for s in np.arange(0,56,bar):
    m=(t>=s)&(t<s+bar); c=ch[:,m].mean(1)
    best=max(tmpl,key=lambda k: np.dot(tmpl[k],c)/np.linalg.norm(c))
    out.append(f"{s:4.1f}:{best}")
print(" ".join(out))
# pitch range of melody: dominant high-freq
f0,vf,vp = librosa.pyin(H[int(9*sr):int(40*sr)], fmin=150, fmax=1500, sr=sr)
f0=f0[~np.isnan(f0)]
print("melody median note", librosa.hz_to_note(np.median(f0)) if len(f0) else None, "range", librosa.hz_to_note(np.percentile(f0,5)), librosa.hz_to_note(np.percentile(f0,95)))
