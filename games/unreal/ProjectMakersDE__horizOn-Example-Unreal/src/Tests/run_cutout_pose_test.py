#!/usr/bin/env python3
"""Compile the production cutout pose math without Unreal or a backend.

Checks the accepted mockup's pivots, pose amplitude, priority, pause and XY
projection. This is not UHT, native module compilation or render verification.
"""
from pathlib import Path
import json
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEST = r'''
#include "Animation/SeagullCutoutPose.h"
#include <cassert>
#include <cmath>
#include <iostream>
using namespace SeagullCutout;
bool Near(float A, float B) { return std::abs(A-B) < .0001f; }
int main() {
    const float Pi = 3.14159265358979323846f;
    auto Gull = Sample(Character::Gull, Motion::Walk, Pi/16.f);
    assert(Near(Gull.Hop, -7.f));
    assert(Near(Gull.Parts[2].Angle, .16f) && Near(Gull.Parts[3].Angle, -.16f));
    assert(Near(Gull.Parts[2].X, -5.f) && Near(Gull.Parts[2].Y, -4.f));
    assert(Near(Gull.Parts[3].X, 5.f) && Near(Gull.Parts[3].Y, 0.f));
    auto Attack = Sample(Character::Gull, Motion::Attack, Pi/10.f);
    assert(Near(Attack.Parts[1].Angle, -.53f) && Near(Attack.Parts[5].Angle, .57f));
    assert(Near(Attack.Parts[6].X, 3.f) && Near(Attack.Parts[6].Y, -4.f));
    auto MovingAttack = Sample(Character::Gull, Motion::Attack, Pi/10.f, true, Pi/16.f);
    assert(Near(MovingAttack.Parts[2].Angle, .16f) && Near(MovingAttack.Parts[3].Angle, -.16f));
    assert(Near(MovingAttack.Hop, -7.f) && Near(MovingAttack.Parts[5].Angle, Attack.Parts[5].Angle));
    assert(Near(Sample(Character::Gull, Motion::Attack, Pi/10.f, true, 0.f).Parts[2].Angle, 0.f));
    auto Crab = Sample(Character::Crab, Motion::Walk, Pi/20.f);
    assert(Near(Crab.Hop, -4.f));
    for (int I=0; I<6; ++I) {
        assert(Near(Crab.Parts[I].Angle, (I%2 ? 1.f : -1.f)*(.09f+(I%3)*.035f)));
    }
    auto Claws = Sample(Character::Crab, Motion::Attack, Pi/10.f);
    assert(Near(Claws.Parts[6].Angle, -.35f) && Near(Claws.Parts[8].Angle, .33f));
    assert(Near(Claws.Parts[8].X, -6.f) && Near(Claws.Parts[8].Y, -4.f));
    auto MovingClaws = Sample(Character::Crab, Motion::Attack, Pi/10.f, true, Pi/20.f);
    assert(Near(MovingClaws.Parts[0].Angle, -.09f) && Near(MovingClaws.Parts[1].Angle, .125f));
    assert(Near(MovingClaws.Hop, -4.f) && Near(MovingClaws.Parts[8].Angle, Claws.Parts[8].Angle));
    assert(Near(Sample(Character::Crab, Motion::Attack, Pi/10.f, true, 0.f).Parts[0].Angle, 0.f));
    assert(Near(Sample(Character::Gull, Motion::Hurt, .1f).Parts[6].Angle, -.10f));
    Clock State;
    assert(State.Current(false) == Motion::Idle && State.Current(true) == Motion::Walk);
    State.Attack(); State.Advance(.1f); assert(State.Current(true) == Motion::Attack);
    const float AttackPhase = State.Phase(); State.Attack();
    assert(Near(State.Phase(), AttackPhase)); // Simultaneous weapons do not restart the pose.
    State.Hurt(); State.Advance(.05f); assert(State.Current(true) == Motion::Hurt);
    const float Paused = State.Phase(); State.Advance(0.f); assert(Near(State.Phase(), Paused));
    State.Advance(.2f); assert(State.Current(true) == Motion::Attack);
    State.Advance(.5f); assert(State.Current(true) == Motion::Walk);
    const Definition& D = GetDefinition(Character::Gull);
    PartPose P{};
    auto Origin = Project(D, D.ActorX, D.ActorY, P, 0.f, 0.f, 1.f);
    assert(Near(Origin.X, 0.f) && Near(Origin.Y, 0.f));
    auto Right = Project(D, D.ActorX+1.f, D.ActorY, P, 0.f, 0.f, 1.f);
    auto Up = Project(D, D.ActorX, D.ActorY-1.f, P, 0.f, 0.f, 1.f);
    assert(Near(Right.X, 1.f) && Near(Right.Y, 0.f));
    assert(Near(Up.X, 0.f) && Near(Up.Y, 1.f));
    auto Rotated = Project(D, D.RootX+1.f, D.RootY, P, Pi/2.f, 0.f, 1.f);
    assert(Near(Rotated.X, D.RootX-D.ActorX) && Near(Rotated.Y, D.ActorY-D.RootY-1.f));
    auto Mirrored = Project(D, D.ActorX+5.f, D.ActorY+3.f, P, 0.f, 0.f, -1.f);
    assert(Near(Mirrored.X, -5.f) && Near(Mirrored.Y, -3.f));
    // Screen up is world -Y (SeagullScreenUpY), so a clockwise canvas angle is a
    // positive world yaw: both turn clockwise on screen.
    assert(Near(WorldYaw(Pi/2.f), Pi/2.f));
    for (auto Kind : {Character::Gull, Character::Crab}) {
        const auto& Def = GetDefinition(Kind);
        std::cout << (Kind == Character::Gull ? "gull" : "crab") << ':' << Def.Canvas << ':' << Def.ActorX << ',' << Def.ActorY << ':' << Def.RootX << ',' << Def.RootY << ':' << Def.BaseFacing << '\n';
        for (int I=0; I<Def.Count; ++I) std::cout << Def.Parts[I].Name << ':' << Def.Parts[I].X << ',' << Def.Parts[I].Y << '\n';
    }
}
'''

with tempfile.TemporaryDirectory(prefix="seagull-cutout-pose-") as temporary:
    folder = Path(temporary)
    source = folder / "pose.cpp"
    source.write_text(TEST)
    binary = folder / "pose"
    subprocess.run([os.environ.get("CXX", "c++"), "-std=c++17", "-I", str(ROOT / "Source/SeagullStorm"), str(source), "-o", str(binary)], check=True)
    lines = iter(subprocess.check_output([str(binary)], text=True).splitlines())
    manifest = json.loads((ROOT / "Content/Textures/Cutout/rig.json").read_text())
    for name in ("gull", "crab"):
        record = manifest["characters"][name]
        family, canvas, actor, pivot, facing = next(lines).split(":")
        assert family == name and [float(canvas)]*2 == record["canvas"]
        assert list(map(float, actor.split(","))) == record["actorOrigin"]
        assert list(map(float, pivot.split(","))) == record["rootPivot"]
        assert int(facing) == record["baseFacing"]
        for layer, part in enumerate(record["parts"]):
            part_name, part_pivot = next(lines).split(":")
            assert part_name == part["name"] and layer == part["layer"]
            assert list(map(float, part_pivot.split(","))) == part["pivot"]
    assert next(lines, None) is None
print("PASS: production cutout poses, manifest pivots/layers, action priority, pause, facing and XY axis/sign projection")
