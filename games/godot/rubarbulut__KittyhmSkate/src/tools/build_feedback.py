"""Original short gameplay sounds and a 100 BPM calibration click track."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parents[1]/"assets/audio"
rng = np.random.default_rng(101104)


def write(name, samples):
    stereo = np.column_stack((samples,samples))
    with wave.open(str(OUT/(name+".wav")),"wb") as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes((np.clip(stereo,-.9,.9)*32767).astype("<i2").tobytes())


def ping(hz, duration=.07):
    t = np.arange(round(duration*RATE))/RATE
    return (np.sin(2*np.pi*hz*t)+.15*np.sin(4*np.pi*hz*t))*np.minimum(t/.002,1)*np.exp(-t*55)*.38


write("perfect",ping(1568))
write("good",ping(1046.5))
write("ui",ping(880,.055))
t = np.arange(round(.10*RATE))/RATE
write("land",rng.uniform(-1,1,len(t))*np.exp(-t*65)*.18+np.sin(2*np.pi*110*t)*np.exp(-t*60)*.16)
t = np.arange(round(.16*RATE))/RATE
write("bump",np.sin(2*np.pi*(140*t-180*t*t))*np.exp(-t*26)*.3)
t = np.arange(round(.18*RATE))/RATE
write("hold",(np.sin(2*np.pi*880*t)+np.sin(2*np.pi*1318.5*t))*.13*np.minimum(t/.003,1)*np.exp(-t*25))
t = np.arange(round(.5*RATE))/RATE
write("clear",sum(np.sin(2*np.pi*f*t) for f in [523.25,659.25,783.99])*np.minimum(t/.008,1)*np.exp(-t*10)*.13)

duration = 24*.6
clicks = np.zeros(round(duration*RATE))
for beat in range(24):
    sound = ping(1320 if beat%4 == 0 else 880,.06)*.8
    start = round(beat*.6*RATE)
    clicks[start:start+len(sound)] += sound
write("calibration",clicks)
print("Rendered 7 feedback sounds and a 24-beat calibration track")
