#pragma once

#include "CoreMinimal.h"

/**
 * Compact input log of one run for horizOn Validated Actions (format v1, the same in the
 * Unity, Godot and Unreal Seagull Storm examples).
 *
 * The SDK hashes these bytes (SHA-256) for the validated submit and, when the server asks
 * for evidence, uploads the same bytes. This is client-recorded evidence, not a complete
 * authoritative replay: physics, frame timing, balance config and upgrades are not encoded.
 *
 * Layout (little endian):
 *   Header, 5 bytes: uint8 version (1), uint32 seed of the run ticket (0 until the ticket arrives).
 *   Events, 3 bytes each: uint16 ticks since the previous event, uint8 code.
 *     Ticks run at TicksPerSecond of run time (game time, pauses excluded).
 *     0x00 to 0x0F: movement bits (1 left, 2 right, 4 up, 8 down), written when the direction
 *                   changes or when the tick gap reaches 65535.
 *     0x10 | index: level-up choice (index of the picked card).
 *     0xFF:         end of the run.
 *
 * The log never grows beyond MaxBytes (the server's evidence limit) and always keeps room for
 * the end event; further events are dropped and IsTruncated() turns true.
 */
class FSeagullInputLog
{
public:
	/** Evidence limit of the server (evidence.maxBytes). */
	static constexpr int32 MaxBytes = 32768;

	static constexpr uint8 FormatVersion = 1;
	static constexpr int32 HeaderBytes = 5;
	static constexpr int32 EventBytes = 3;
	static constexpr int32 TicksPerSecond = 60;
	static constexpr uint32 MaxTickGap = 65535;

	static constexpr uint8 MoveLeft = 0x01;
	static constexpr uint8 MoveRight = 0x02;
	static constexpr uint8 MoveUp = 0x04;
	static constexpr uint8 MoveDown = 0x08;
	static constexpr uint8 LevelUpChoiceCode = 0x10;
	static constexpr uint8 EndCode = 0xFF;

	FSeagullInputLog() { Reset(); }

	/** Starts a new log: header with seed 0, no events. */
	void Reset();

	/** Writes the ticket seed into the header. */
	void SetSeed(int32 Seed);

	/** Records the move stick (X right, Y up, -1 to 1) when its direction bits changed. */
	void RecordMove(float RunSeconds, float X, float Y);

	/** Records the index (0 to 15) of the chosen level-up card. */
	void RecordLevelUpChoice(float RunSeconds, int32 ChoiceIndex);

	/** Closes the log with the end event. Later calls do nothing. */
	void Finish(float RunSeconds);

	const TArray<uint8>& GetBytes() const { return Bytes; }
	bool IsTruncated() const { return bTruncated; }

	/** Movement bits of a stick value (1 left, 2 right, 4 up, 8 down, 0 = no input). */
	static uint8 MoveBits(float X, float Y);

private:
	/** Adds one event; fills tick gaps above MaxTickGap with repeated movement events. */
	void AddEvent(float RunSeconds, uint8 Code);
	void AppendEvent(uint32 TickGap, uint8 Code);
	static uint32 ToTick(float RunSeconds);

	TArray<uint8> Bytes;
	uint32 LastTick = 0;
	uint8 LastMove = 0;
	bool bTruncated = false;
	bool bFinished = false;
};
