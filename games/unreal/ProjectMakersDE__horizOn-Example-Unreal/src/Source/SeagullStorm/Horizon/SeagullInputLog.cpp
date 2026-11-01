#include "Horizon/SeagullInputLog.h"

// Named namespace: unity builds merge .cpp files, so helper names must stay unique.
namespace SeagullInputLogPrivate
{
	// Stick values inside this band count as "no input" on that axis.
	constexpr float MoveDeadZone = 0.3f;
}

void FSeagullInputLog::Reset()
{
	Bytes.Reset();
	Bytes.Reserve(1024);

	// Version byte plus a zero seed, filled in by SetSeed.
	Bytes.Add(FormatVersion);
	for (int32 Index = 1; Index < HeaderBytes; ++Index)
	{
		Bytes.Add(0);
	}

	LastTick = 0;
	LastMove = 0;
	bTruncated = false;
	bFinished = false;
}

void FSeagullInputLog::SetSeed(int32 Seed)
{
	const uint32 Value = static_cast<uint32>(Seed);
	Bytes[1] = static_cast<uint8>(Value & 0xFF);
	Bytes[2] = static_cast<uint8>((Value >> 8) & 0xFF);
	Bytes[3] = static_cast<uint8>((Value >> 16) & 0xFF);
	Bytes[4] = static_cast<uint8>((Value >> 24) & 0xFF);
}

void FSeagullInputLog::RecordMove(float RunSeconds, float X, float Y)
{
	const uint8 Move = MoveBits(X, Y);
	if (Move == LastMove)
	{
		return;
	}
	LastMove = Move;
	AddEvent(RunSeconds, Move);
}

void FSeagullInputLog::RecordLevelUpChoice(float RunSeconds, int32 ChoiceIndex)
{
	const int32 Clamped = ChoiceIndex < 0 ? 0 : (ChoiceIndex > 15 ? 15 : ChoiceIndex);
	AddEvent(RunSeconds, static_cast<uint8>(LevelUpChoiceCode | Clamped));
}

void FSeagullInputLog::Finish(float RunSeconds)
{
	if (bFinished)
	{
		return;
	}
	AddEvent(RunSeconds, EndCode);
	bFinished = true;
}

uint8 FSeagullInputLog::MoveBits(float X, float Y)
{
	using SeagullInputLogPrivate::MoveDeadZone;

	uint8 Bits = 0;
	if (X < -MoveDeadZone) Bits |= MoveLeft;
	if (X > MoveDeadZone) Bits |= MoveRight;
	if (Y > MoveDeadZone) Bits |= MoveUp;
	if (Y < -MoveDeadZone) Bits |= MoveDown;
	return Bits;
}

void FSeagullInputLog::AddEvent(float RunSeconds, uint8 Code)
{
	if (bFinished)
	{
		return;
	}

	uint32 Tick = ToTick(RunSeconds);
	if (Tick < LastTick)
	{
		Tick = LastTick;
	}

	// A gap longer than a uint16 is bridged with the current direction, repeated.
	while (Tick - LastTick > MaxTickGap && !bTruncated)
	{
		AppendEvent(MaxTickGap, LastMove);
	}

	// After a truncated bridge only the end event still fits; its gap is clamped.
	const uint32 Gap = Tick - LastTick;
	AppendEvent(Gap > MaxTickGap ? MaxTickGap : Gap, Code);
}

void FSeagullInputLog::AppendEvent(uint32 TickGap, uint8 Code)
{
	// Every event but the end event keeps room for the end event.
	const int32 ReservedForEnd = (Code == EndCode) ? 0 : EventBytes;
	if (Bytes.Num() + EventBytes + ReservedForEnd > MaxBytes)
	{
		bTruncated = true;
		return;
	}

	Bytes.Add(static_cast<uint8>(TickGap & 0xFF));
	Bytes.Add(static_cast<uint8>((TickGap >> 8) & 0xFF));
	Bytes.Add(Code);
	LastTick += TickGap;
}

uint32 FSeagullInputLog::ToTick(float RunSeconds)
{
	const double Ticks = static_cast<double>(RunSeconds) * TicksPerSecond;
	if (!(Ticks > 0.0)) return 0;
	if (Ticks >= 4294967295.0) return 4294967295u;
	return static_cast<uint32>(Ticks);
}
