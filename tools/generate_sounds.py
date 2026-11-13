#!/usr/bin/env python3
"""Deterministically create royalty-free original OneLife UI notification tones.
No external audio, sample library, copyrighted composition, or remote service.
WAV 22050 Hz mono PCM16. Playback is opt-in/muted by default in the future app.
"""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
import struct
import wave

RATE=22050
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets"/"sounds"
PROFILES={
    "remind": {"duration":0.62,"startHz":600,"endHz":830,"pulseHz":0,"gain":0.19},
    "alarm": {"duration":1.35,"startHz":720,"endHz":800,"pulseHz":3.6,"gain":0.17},
    "done": {"duration":0.68,"startHz":700,"endHz":1080,"pulseHz":0,"gain":0.21},
    "focus": {"duration":0.42,"startHz":360,"endHz":410,"pulseHz":0,"gain":0.12},
    "sleepy": {"duration":0.84,"startHz":520,"endHz":280,"pulseHz":0,"gain":0.13},
}

def render(name,p):
    duration=p["duration"]
    samples=round(RATE*duration)
    phase=0.0
    pcm=bytearray()
    peak=0.0
    for i in range(samples):
        t=i/RATE
        frac=i/max(1,samples-1)
        freq=p["startHz"]+(p["endHz"]-p["startHz"])*frac
        phase+=2*math.pi*freq/RATE
        attack=min(1.0,t/0.016)
        release=(max(0.0,1-frac))**2.2
        pulse=1.0
        if p["pulseHz"]:
            # An intermittent two-note alert, not a continuous high-volume alarm.
            pulse=0.28+0.72*(math.sin(2*math.pi*p["pulseHz"]*t)>0)
        signal=(math.sin(phase)+0.2*math.sin(2*phase))*attack*release*pulse*p["gain"]
        peak=max(peak,abs(signal))
        pcm.extend(struct.pack("<h",int(max(-1,min(1,signal))*32767)))
    if peak>0.45: raise ValueError(f"Unexpectedly loud asset {name}: {peak}")
    file=OUT/f"{name}.wav"
    with wave.open(str(file),"wb") as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE);wav.writeframes(pcm)
    return {"file":file.name,"sampleRateHz":RATE,"channels":1,"sampleWidthBits":16,
            "durationSeconds":duration,"peakAmplitude":round(peak,4),
            "sha256":hashlib.sha256(file.read_bytes()).hexdigest(),
            "usage":"optional, muted by default"}

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    entries={k:render(k,v) for k,v in PROFILES.items()}
    (OUT/"manifest.json").write_text(json.dumps({"schemaVersion":1,"origin":"original synthesised UI alert sounds for OneLife","sounds":entries},
                                    indent=2)+"\n")
    print(f"PASS: {len(entries)} original audio cues, <=0.45 peak, no external samples")
if __name__=="__main__":main()
