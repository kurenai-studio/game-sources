#pragma once

#include "CoreMinimal.h"
#include "SeagullTypes.generated.h"

class UPaperFlipbook;

// --- Game Screen States ---

UENUM(BlueprintType)
enum class ESeagullGameScreen : uint8
{
	Title,
	Hub,
	Run,
	GameOver
};

// --- Weapon Types ---

UENUM(BlueprintType)
enum class ESeagullWeaponType : uint8
{
	Feather,
	Screech,
	Dive,
	Gust
};

// --- Enemy Types ---

UENUM(BlueprintType)
enum class ESeagullEnemyType : uint8
{
	Crab,
	Jellyfish,
	Pirate,
	Boss
};

// --- Pickup Types ---

UENUM(BlueprintType)
enum class ESeagullPickupType : uint8
{
	XP,
	Coin,
	Health
};

// --- Feedback Category ---

UENUM(BlueprintType)
enum class ESeagullFeedbackCategory : uint8
{
	Bug,
	Feature,
	General
};

// --- Level-Up Choice ---

USTRUCT(BlueprintType)
struct FSeagullLevelUpChoice
{
	GENERATED_BODY()

	UPROPERTY()
	FString Id;

	UPROPERTY()
	FString Type; // "weapon_upgrade", "weapon_new", "stat_boost"

	UPROPERTY()
	int32 Weight = 1;

	UPROPERTY()
	FString DisplayName;

	UPROPERTY()
	FString Description;
};

// --- Run Stats (for user log at game over) ---

USTRUCT(BlueprintType)
struct FSeagullRunStats
{
	GENERATED_BODY()

	UPROPERTY()
	int32 Kills = 0;

	UPROPERTY()
	int32 XPCollected = 0;

	UPROPERTY()
	float Duration = 0.f;

	UPROPERTY()
	int32 WavesReached = 0;

	UPROPERTY()
	int32 LevelReached = 0;

	UPROPERTY()
	int32 Score = 0;

	UPROPERTY()
	int32 CoinsEarned = 0;
};

// --- Enemy Stats (from Remote Config) ---

USTRUCT()
struct FSeagullEnemyStats
{
	GENERATED_BODY()

	float Speed = 40.f;
	int32 HP = 30;
	int32 Damage = 10;
	int32 XPDrop = 10;
};

// --- Weapon Stats (from Remote Config) ---

USTRUCT()
struct FSeagullWeaponStats
{
	GENERATED_BODY()

	float Damage = 20.f;
	float Cooldown = 0.8f;
	float Range = 0.f;
	int32 Projectiles = 1;
	float Knockback = 0.f;
};

// --- Color Palette ---

// Design-doc palette. The hex values are sRGB; UMG/Slate treats FLinearColor as
// linear and gamma-encodes on output, so the bytes must be converted (writing them
// straight into the float channels renders every color drastically lighter).
namespace SeagullColors
{
	const FLinearColor Orange       = FLinearColor::FromSRGBColor(FColor(0xE7, 0x8A, 0x53)); // #E78A53
	const FLinearColor Teal         = FLinearColor::FromSRGBColor(FColor(0x5F, 0x87, 0x87)); // #5F8787
	const FLinearColor DarkBG       = FLinearColor::FromSRGBColor(FColor(0x12, 0x11, 0x13)); // #121113
	const FLinearColor PanelBG      = FLinearColor::FromSRGBColor(FColor(0x1C, 0x1C, 0x1C)); // #1C1C1C panel/card surface
	const FLinearColor LightText    = FLinearColor::FromSRGBColor(FColor(0xF5, 0xEF, 0xE4)); // #F5EFE4
	const FLinearColor DarkText     = FLinearColor::FromSRGBColor(FColor(0x1C, 0x1C, 0x1C)); // #1C1C1C
	const FLinearColor Sand         = FLinearColor::FromSRGBColor(FColor(0xF2, 0xD2, 0xA9)); // #F2D2A9
	const FLinearColor Water        = FLinearColor::FromSRGBColor(FColor(0x3B, 0x7D, 0xD8)); // #3B7DD8
	const FLinearColor XPGold       = FLinearColor::FromSRGBColor(FColor(0xFF, 0xD7, 0x00)); // #FFD700
	const FLinearColor CrabRed      = FLinearColor::FromSRGBColor(FColor(0xE0, 0x5B, 0x4B)); // #E05B4B
	const FLinearColor JellyPurple  = FLinearColor::FromSRGBColor(FColor(0x9B, 0x59, 0xB6)); // #9B59B6
	const FLinearColor PirateDark   = FLinearColor::FromSRGBColor(FColor(0x4A, 0x4A, 0x4A)); // #4A4A4A
	const FLinearColor SeagullWhite = FLinearColor::FromSRGBColor(FColor(0xF5, 0xF5, 0xF0)); // #F5F5F0
}

// --- Asset Helpers ---

namespace SeagullAssets
{
	// Session-cached flipbook lookup for actors that spawn many times per second
	// (projectiles, pickups, enemies). A plain LoadObject in the constructor would
	// re-probe the disk and spam LogUObjectGlobals warnings on EVERY spawn while
	// the editor-created assets (EDITOR_SETUP.md) do not exist yet.
	// Null-guarded like the direct loads it replaces.
	UPaperFlipbook* LoadFlipbookCached(const TCHAR* Path);
}

// --- Game Constants ---

namespace SeagullConstants
{
	constexpr float BaseResolutionWidth = 480.f;
	constexpr float BaseResolutionHeight = 270.f;
	constexpr float RenderScale = 3.f;
	constexpr float InvincibilityDuration = 0.5f;
	constexpr float MusicCrossfadeDuration = 0.5f;
	constexpr float MusicVolume = 0.7f;
	constexpr float SFXVolume = 1.0f;
	constexpr int32 MaxSFXPickupXP = 3;
	constexpr int32 MaxSFXEnemyHit = 5;
	constexpr int32 LeaderboardTopCount = 10;
	constexpr int32 NewsCount = 5;
	constexpr float ArenaWidth = 1200.f;
	constexpr float ArenaHeight = 800.f;
}
