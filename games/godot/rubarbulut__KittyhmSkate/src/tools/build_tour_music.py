"""Render new tour tracks from Godot's authoritative exported note charts.

Run Godot --headless --path . --script res://tools/export_charts.gd first.
The original Alley Shift is retained unchanged. No recorded samples are used.
"""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def render(spec):
    idx = spec["index"]
    if idx == 0:
        return
    rng = np.random.default_rng(261104 + idx)
    beat = spec["beat"]
    duration = spec["duration"]
    mix = np.zeros((round(duration * RATE), 2), dtype=np.float64)

    def add(sound, at, volume=1, pan=0):
        start = round(at * RATE)
        length = min(len(sound), len(mix)-start)
        if start < 0 or length <= 0:
            return
        mix[start:start+length, 0] += sound[:length]*volume*(1-pan*0.35)
        mix[start:start+length, 1] += sound[:length]*volume*(1+pan*0.35)

    def tone(midi, length, kind="lead"):
        t = np.arange(round(length*RATE))/RATE
        f = 440*2**((midi-69)/12)
        attack = np.minimum(t/0.006, 1)
        release = np.minimum((length-t)/0.055, 1)
        if kind == "bass":
            sound = np.sin(2*np.pi*f*t)+0.22*np.sin(4*np.pi*f*t)
            env = attack*release*np.exp(-t*5)
        elif kind == "pad":
            sound = np.sin(2*np.pi*f*t)+0.25*np.sin(2*np.pi*f*1.003*t)
            env = np.minimum(t/0.16, 1)*np.minimum((length-t)/0.25, 1)
        elif kind == "hold":
            sound = np.sin(2*np.pi*f*t)+0.2*np.sin(6*np.pi*f*t)
            env = attack*release*(0.4+0.6*np.exp(-t*3))
        else:
            sound = sum(np.sin(2*np.pi*f*h*t)/h for h in [1,3,5])/1.4
            env = attack*release*np.exp(-t*6)
        return sound*env

    t = np.arange(round(0.31*RATE))/RATE
    kick = np.sin(2*np.pi*(49*t+110*.023*(1-np.exp(-t/.023))))*np.exp(-t*15)
    kick += rng.normal(0,.05,len(t))*np.exp(-t*170)
    t = np.arange(round(.17*RATE))/RATE
    noise = rng.uniform(-1,1,len(t))
    snare = (noise-np.roll(noise,1)*.6)*np.exp(-t*27)*.35
    snare += np.sin(2*np.pi*195*t)*np.exp(-t*34)*.2
    t = np.arange(round(.055*RATE))/RATE
    noise = rng.uniform(-1,1,len(t))
    hat = (noise-np.roll(noise,1))*np.exp(-t*80)*.11
    roots = [45,41,48,43] if idx == 1 else ([40,36,43,38] if idx == 2 else [38,34,41,36])
    melody = [0,3,7,10,7,3,5,2,0,7,12,10,7,5,3,2]

    for b in range(spec["beats"]):
        root = roots[(b//8)%4]
        outro = b >= spec["beats"]-8
        drop = spec["drop_start"] <= b < spec["drop_end"]
        add(kick,b*beat,.58 if not outro else .28)
        if b >= 4 and b%2 == 1 and not outro:
            add(snare,b*beat,.48 if idx != -1 else .28)
        if idx >= 1 and b >= 8 and b%4 == 2 and drop:
            add(kick,(b+.75)*beat,.24)
        add(hat,(b+.5)*beat,.4 if idx >= 0 else .2,.35)
        if b >= 8:
            add(tone(root,beat*.65,"bass"),b*beat,.22)
            if idx >= 1 and not outro and b%4 != 3:
                add(tone(root+12,beat*.25,"bass"),(b+.75)*beat,.09)
        if b%8 == 0:
            for interval in [0,3,7]:
                add(tone(root+24+interval,beat*7.75,"pad"),b*beat,.025,-.25)
        if b < 8:
            add(tone(81 if b%4 == 0 else 76,.055),b*beat,.045)
        if b in range(int(spec["drop_start"])-8,int(spec["drop_start"])) and idx >= 0:
            add(snare,(b+.5)*beat,.08+(b-spec["drop_start"]+8)*.018)

    for note in spec["notes"]:
        b = note["beat"]
        root = roots[(int(b)//8)%4]
        midi = root+24+melody[int(b*2)%len(melody)]
        length = note["hold"] if note["hold"] > 0 else beat*.65
        kind = "hold" if note["hold"] > 0 else "lead"
        add(tone(midi,length,kind),note["time"],.11 if idx >= 0 else .13,-.1)
        if note["hold"] == 0 and idx >= 0:
            add(tone(midi,length),note["time"]+beat*.75,.023,.7)

    t = np.arange(round(1.4*RATE))/RATE
    noise = rng.uniform(-1,1,len(t))
    add((noise-np.roll(noise,1))*np.exp(-t*5),spec["drop_start"]*beat,.09)
    mix *= np.minimum(np.arange(len(mix))/RATE/.025,1)[:,None]
    mix *= np.minimum((len(mix)-1-np.arange(len(mix)))/RATE/.8,1)[:,None]
    mix = np.tanh(mix*1.4)
    mix *= .86/np.max(np.abs(mix))
    output = ROOT/spec["audio"].removeprefix("res://")
    with wave.open(str(output),"wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes((mix*32767).astype("<i2").tobytes())
    print(f"{output.name}: {duration:.2f}s / {spec['bpm']} BPM / {len(spec['notes'])} notes")


if __name__ == "__main__":
    for track in json.loads((ROOT/"assets/audio/charts.json").read_text(encoding="utf-8")):
        render(track)
