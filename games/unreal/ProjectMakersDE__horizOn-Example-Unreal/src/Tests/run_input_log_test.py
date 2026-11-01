#!/usr/bin/env python3
"""Compile the actual input-log implementation against a minimal array boundary."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SHIM = r"""
#pragma once
#include <cstdint>
#include <vector>
using uint8 = uint8_t;
using uint32 = uint32_t;
using int32 = int32_t;
template<typename T> class TArray {
 std::vector<T> V;
public:
 void Reset() { V.clear(); }
 void Reserve(int32 N) { V.reserve(N); }
 void Add(T Value) { V.push_back(Value); }
 int32 Num() const { return static_cast<int32>(V.size()); }
 T& operator[](int32 Index) { return V.at(Index); }
 const T& operator[](int32 Index) const { return V.at(Index); }
};
"""
TEST = r"""
#include "Horizon/SeagullInputLog.h"
#include <cassert>
#include <cmath>
#include <iostream>
int main() {
 FSeagullInputLog Log;
 Log.SetSeed(0x12345678);
 auto& B = Log.GetBytes();
 assert(B.Num() == 5 && B[0] == 1 && B[1] == 0x78 && B[4] == 0x12);
 Log.RecordMove(1.f, 1.f, 0.f);
 assert(B.Num() == 8 && B[5] == 60 && B[6] == 0 && B[7] == 2);
 Log.RecordMove(1.2f, 1.f, 0.f); assert(B.Num() == 8);
 Log.RecordMove(2.f, 0.f, 0.f); assert(B[8] == 60 && B[10] == 0);
 Log.RecordLevelUpChoice(2.f, 2); assert(B[13] == 0x12);
 Log.Finish(3.f); assert(B[B.Num()-1] == 255);
 int32 Closed = B.Num(); Log.Finish(9.f); Log.RecordMove(9.f, -1.f, 0.f); assert(B.Num() == Closed);
 assert(Log.MoveBits(0.2f, -0.2f) == 0 && Log.MoveBits(-1.f, 1.f) == 5);
 Log.Reset(); Log.RecordMove(1200.f, 1.f, 0.f); Log.Finish(1200.f);
 uint32 Tick = 0;
 for (int32 I = 5; I < Log.GetBytes().Num(); I += 3) Tick += Log.GetBytes()[I] | (uint32(Log.GetBytes()[I+1]) << 8);
 assert(Tick == 72000);
 Log.Reset();
 for (int32 I=0; I<20000; ++I) Log.RecordMove(I/60.f, I%2 ? -1.f : 1.f, 0.f);
 assert(Log.IsTruncated()); Log.Finish(400.f);
 assert(Log.GetBytes().Num() <= 32768 && Log.GetBytes()[Log.GetBytes().Num()-1] == 255);
 assert((Log.GetBytes().Num()-5)%3 == 0);
 Log.Reset(); Log.RecordMove(NAN, 1.f, 0.f); Log.Finish(-1.f); assert(Log.GetBytes()[5] == 0);
 std::cout << "PASS: actual input log header, direction changes, choices, pause-time gaps, closure and evidence limit\n";
}
"""
with tempfile.TemporaryDirectory(prefix="seagull-input-log-") as temporary:
    folder = Path(temporary)
    (folder / "CoreMinimal.h").write_text(SHIM)
    (folder / "InputLogTest.cpp").write_text(TEST)
    binary = folder / "input-log-test"
    subprocess.run([os.environ.get("CXX", "c++"), "-std=c++17", "-I", str(folder), "-I", str(ROOT / "Source/SeagullStorm"),
        str(ROOT / "Source/SeagullStorm/Horizon/SeagullInputLog.cpp"), str(folder / "InputLogTest.cpp"), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
