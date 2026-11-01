#pragma once

#include <array>
#include <cmath>

// Source-pixel poses from the accepted seagull-crab-motion.html mockup.
// Canvas coordinates are x right, y down. Angles are clockwise radians.
namespace SeagullCutout
{
enum class Character { Gull, Crab };
enum class Motion { Idle, Walk, Attack, Hurt };
struct PartDefinition { const char* Name; float X; float Y; };
struct Definition
{
	float Canvas, ActorX, ActorY, RootX, RootY, FeetX, FeetY, BaseFacing;
	int Count;
	std::array<PartDefinition, 9> Parts;
};
inline const Definition& GetDefinition(Character Kind)
{
	static const Definition Gull{512, 256, 256, 256, 420, 256, 477, 1, 7, {{{"tail", 159, 355}, {"backWing", 310, 304}, {"leftFoot", 215, 422}, {"rightFoot", 278, 422}, {"body", 260, 366}, {"frontWing", 228, 307}, {"head", 247, 282}, {nullptr, 0, 0}, {nullptr, 0, 0}}}};
	static const Definition Crab{256, 128, 128, 140, 132, 130, 200, -1, 9, {{{"leftBack", 84, 124}, {"rightBack", 195, 133}, {"leftMiddle", 88, 136}, {"rightMiddle", 192, 145}, {"leftFront", 98, 145}, {"rightFront", 182, 153}, {"backClaw", 84, 118}, {"body", 144, 116}, {"frontClaw", 169, 130}}}};
	return Kind == Character::Gull ? Gull : Crab;
}
struct PartPose { float Angle = 0, X = 0, Y = 0; };
struct Pose { float Lean = 0, Hop = 0; std::array<PartPose, 9> Parts{}; };
inline Pose Sample(Character Kind, Motion Mode, float Phase, bool Moving = false, float LocomotionPhase = 0.f)
{
	const bool Walk = Mode == Motion::Walk, Attack = Mode == Motion::Attack, Hurt = Mode == Motion::Hurt;
	// Frequent auto-fire keeps upper limbs attacking while moving feet/legs
	// continue their uninterrupted gait. Hurt retains the accepted recoil pose.
	const bool Locomotion = Walk || (Attack && Moving);
	const float GaitPhase = Walk ? Phase : LocomotionPhase;
	const float Sine = std::sin(Phase * 5.f);
	const float Pulse = Attack && Sine > 0.f ? Sine * Sine : 0.f;
	Pose Result;
	if (Kind == Character::Gull)
	{
		const float Step = Locomotion ? std::sin(GaitPhase * 8.f) : 0.f;
		const float Rear = Attack ? -.53f * Pulse : Walk ? std::sin(Phase * 8.f + .4f) * .15f : std::sin(Phase * 2.f) * .035f;
		const float Front = Attack ? .57f * Pulse : Walk ? -std::sin(Phase * 8.f + .4f) * .16f : std::sin(Phase * 2.f + 1.f) * .025f;
		Result.Lean = Hurt ? std::sin(Phase * 19.f) * .085f : Walk ? Step * .018f : 0.f;
		Result.Hop = Locomotion ? -std::abs(Step) * 7.f : std::sin(Phase * 2.f) * 1.6f;
		Result.Parts[0].Angle = -Rear * .35f;
		Result.Parts[1].Angle = Rear;
		Result.Parts[2] = {Step * .16f, -Step * 5.f, Step > 0.f ? -Step * 4.f : 0.f};
		Result.Parts[3] = {-Step * .16f, Step * 5.f, Step < 0.f ? Step * 4.f : 0.f};
		Result.Parts[5].Angle = Front;
		Result.Parts[6] = {Hurt ? -.10f : Walk ? -Step * .018f : std::sin(Phase * 2.f) * .014f, Pulse * 3.f, -Pulse * 4.f};
	}
	else
	{
		const float Step = Locomotion ? std::sin(GaitPhase * 10.f) : 0.f;
		Result.Lean = Hurt ? std::sin(Phase * 21.f) * .09f : Walk ? Step * .015f : 0.f;
		Result.Hop = Locomotion ? -std::abs(Step) * 4.f : std::sin(Phase * 2.f) * 1.8f;
		for (int I = 0; I < 6; ++I) Result.Parts[I].Angle = Step * (I % 2 ? 1.f : -1.f) * (.09f + (I % 3) * .035f);
		Result.Parts[6].Angle = Attack ? -.35f * Pulse : std::sin(Phase * 2.f) * .05f;
		Result.Parts[8] = {Attack ? .33f * Pulse : std::sin(Phase * 2.f + 1.f) * .04f, -Pulse * 6.f, -Pulse * 4.f};
	}
	return Result;
}

class Clock
{
public:
	void Advance(float Delta)
	{
		if (Delta <= 0.f) return;
		Time += Delta;
		AttackRemaining = std::fmax(0.f, AttackRemaining - Delta);
		HurtRemaining = std::fmax(0.f, HurtRemaining - Delta);
	}
	void Attack()
	{
		if (AttackRemaining <= 0.f) AttackStart = Time;
		AttackRemaining = .6f;
	}
	void Hurt() { HurtStart = Time; HurtRemaining = .22f; }
	Motion Current(bool Moving) const { return HurtRemaining > 0.f ? Motion::Hurt : AttackRemaining > 0.f ? Motion::Attack : Moving ? Motion::Walk : Motion::Idle; }
	float Phase() const { return HurtRemaining > 0.f ? Time - HurtStart : AttackRemaining > 0.f ? Time - AttackStart : Time; }
	float TimeSeconds() const { return Time; }
private:
	float Time = 0, AttackStart = 0, HurtStart = 0, AttackRemaining = 0, HurtRemaining = 0;
};

struct Point { float X, Y; };
// Project a custom sprite pivot into screen space (X right, Y up) after the
// whole-body rotation. The rig maps screen Y to world Y via SeagullScreenUpY.
inline Point Project(const Definition& D, float PivotX, float PivotY, const PartPose& P, float Lean, float Hop, float Mirror)
{
	const float X = PivotX + P.X - D.RootX, Y = PivotY + P.Y - D.RootY;
	return {(D.RootX + X * std::cos(Lean) - Y * std::sin(Lean) - D.ActorX) * Mirror,
		D.ActorY - (D.RootY + X * std::sin(Lean) + Y * std::cos(Lean) + Hop)};
}
inline float WorldYaw(float CanvasAngle) { return CanvasAngle; } // both turn clockwise on screen
}
