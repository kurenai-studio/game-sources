#pragma once

#include "CoreMinimal.h"
#include "SeagullAudioManager.generated.h"

class USoundWave;
class UAudioComponent;

UCLASS()
class USeagullAudioManager : public UObject
{
	GENERATED_BODY()

public:
	void Initialize();
	void PlayMusic(USoundWave* Track, UWorld* World);
	void StopMusic();
	void PlaySFX(USoundWave* Sound, UWorld* World);

	void CrossfadeToTrack(USoundWave* NewTrack, UWorld* World);

	// Asset references, filled exclusively by Initialize() via LoadObject path
	// lookups (plain UPROPERTY: this object is created with NewObject at runtime,
	// so there is no Blueprint/archetype surface where editor specifiers apply).
	UPROPERTY()
	USoundWave* MusicMenu = nullptr;

	UPROPERTY()
	USoundWave* MusicBattle = nullptr;

	UPROPERTY()
	USoundWave* MusicBoss = nullptr;

	UPROPERTY()
	USoundWave* SFX_Feather = nullptr;

	UPROPERTY()
	USoundWave* SFX_Screech = nullptr;

	UPROPERTY()
	USoundWave* SFX_Dive = nullptr;

	UPROPERTY()
	USoundWave* SFX_Gust = nullptr;

	UPROPERTY()
	USoundWave* SFX_PlayerHit = nullptr;

	UPROPERTY()
	USoundWave* SFX_EnemyHit = nullptr;

	UPROPERTY()
	USoundWave* SFX_EnemyAttack = nullptr;

	UPROPERTY()
	USoundWave* SFX_PickupXP = nullptr;

	UPROPERTY()
	USoundWave* SFX_LevelUp = nullptr;

	UPROPERTY()
	USoundWave* SFX_UpgradeSelect = nullptr;

	UPROPERTY()
	USoundWave* SFX_GameOver = nullptr;

private:
	UPROPERTY()
	UAudioComponent* MusicComponent = nullptr;

	UPROPERTY()
	USoundWave* CurrentMusicTrack = nullptr;

	// Polyphony tracking
	TMap<USoundWave*, int32> ActiveSFXCount;
	int32 GetMaxPolyphony(USoundWave* Sound) const;
};
