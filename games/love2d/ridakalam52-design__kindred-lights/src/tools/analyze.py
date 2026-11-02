import librosa, numpy as np, json
y, sr = librosa.load('theme.wav', sr=22050, mono=True)
dur = len(y)/sr
tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
bt = librosa.frames_to_time(beats, sr=sr)
chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
cm = chroma.mean(axis=1)
names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
maj = np.array([6.35,2.23,3.48,2.33,4.38,4.09,2.52,5.19,2.39,3.66,2.29,2.88])
mnr = np.array([6.33,2.68,3.52,5.38,2.60,3.53,2.54,4.75,3.98,2.69,3.34,3.17])
scores=[]
for i in range(12):
    scores.append((np.corrcoef(np.roll(maj,i),cm)[0,1], names[i]+' major'))
    scores.append((np.corrcoef(np.roll(mnr,i),cm)[0,1], names[i]+' minor'))
scores.sort(reverse=True)
print("dur",dur,"tempo",tempo,"nbeats",len(bt))
print("key candidates", scores[:4])
print("chroma", dict(zip(names, np.round(cm/cm.max(),2))))
rms = librosa.feature.rms(y=y)[0]; t = librosa.times_like(rms, sr=sr)
cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
onset = librosa.onset.onset_strength(y=y, sr=sr)
# per 3 sec
for s in np.arange(0,dur,3):
    m=(t>=s)&(t<s+3)
    db = 20*np.log10(rms[m].mean()+1e-9)
    print(f"{s:5.1f}s rms_db {db:6.1f} cent {cent[m].mean():6.0f} onset {onset[m].mean():5.2f} chroma_top {names[int(chroma[:,m].mean(1).argmax())]}")
# segments
S = librosa.feature.stack_memory(chroma, n_steps=4)
bounds = librosa.segment.agglomerative(np.vstack([librosa.util.normalize(chroma),librosa.feature.mfcc(y=y,sr=sr,n_mfcc=13)/100]), 7)
print("segment bounds", np.round(librosa.frames_to_time(bounds, sr=sr),1))
# per-segment
bt_all = list(librosa.frames_to_time(bounds, sr=sr))+[dur]
for a,b in zip(bt_all[:-1],bt_all[1:]):
    m=(t>=a)&(t<b)
    print(f"seg {a:5.1f}-{b:5.1f} rms_db {20*np.log10(rms[m].mean()+1e-9):6.1f} cent {cent[m].mean():6.0f} onset {onset[m].mean():.2f}")
json.dump({"dur":dur,"tempo":float(np.atleast_1d(tempo)[0]),"beats":[float(x) for x in bt],
  "rms":[float(x) for x in rms[::10]],"rms_hop_s":float(t[10]-t[0])}, open('analysis.json','w'))
