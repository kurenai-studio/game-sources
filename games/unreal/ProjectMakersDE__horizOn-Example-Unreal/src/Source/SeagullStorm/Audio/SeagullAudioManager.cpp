#include "Audio/SeagullAudioManager.h"
#include "Core/SeagullTypes.h"
#include "Components/AudioComponent.h"
#include "Sound/SoundWave.h"
#include "Kismet/GameplayStatics.h"
#include "SeagullStorm.h"

void USeagullAudioManager::Initialize()
{
	MusicMenu = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/Music/music_menu"));
	MusicBattle = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/Music/music_battle"));
	MusicBoss = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/Music/music_boss"));
	SFX_Feather = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_feather"));
	SFX_Screech = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_screech"));
	SFX_Dive = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_dive"));
	SFX_Gust = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_gust"));
	SFX_PlayerHit = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_player_hit"));
	SFX_EnemyHit = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_enemy_hit"));
	SFX_EnemyAttack = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_enemy_attack"));
	SFX_PickupXP = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_pickup_xp"));
	SFX_LevelUp = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_levelup"));
	SFX_UpgradeSelect = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_upgrade_select"));
	SFX_GameOver = LoadObject<USoundWave>(nullptr, TEXT("/Game/Audio/SFX/sfx_game_over"));

	UE_LOG(LogSeagullStorm, Log, TEXT("AudioManager initialized — loaded %d/%d audio assets"),
		(MusicMenu ? 1 : 0) + (MusicBattle ? 1 : 0) + (MusicBoss ? 1 : 0) +
		(SFX_Feather ? 1 : 0) + (SFX_Screech ? 1 : 0) + (SFX_Dive ? 1 : 0) +
		(SFX_Gust ? 1 : 0) + (SFX_PlayerHit ? 1 : 0) + (SFX_EnemyHit ? 1 : 0) +
		(SFX_EnemyAttack ? 1 : 0) + (SFX_PickupXP ? 1 : 0) + (SFX_LevelUp ? 1 : 0) +
		(SFX_UpgradeSelect ? 1 : 0) + (SFX_GameOver ? 1 : 0), 14);
}

void USeagullAudioManager::PlayMusic(USoundWave* Track, UWorld* World)
{
	if (!Track || !World) return;
	if (CurrentMusicTrack == Track) return;

	StopMusic();

	MusicComponent = UGameplayStatics::CreateSound2D(World, Track, SeagullConstants::MusicVolume, 1.0f, 0.f, nullptr, false, true);
	if (MusicComponent)
	{
		MusicComponent->Play();
	}
	CurrentMusicTrack = Track;
}

void USeagullAudioManager::StopMusic()
{
	if (MusicComponent)
	{
		MusicComponent->Stop();
		MusicComponent = nullptr;
	}
	CurrentMusicTrack = nullptr;
}

void USeagullAudioManager::PlaySFX(USoundWave* Sound, UWorld* World)
{
	if (!Sound || !World) return;

	// Polyphony check
	int32 Max = GetMaxPolyphony(Sound);
	int32* Count = ActiveSFXCount.Find(Sound);
	if (Count && *Count >= Max) return;

	UGameplayStatics::PlaySound2D(World, Sound, SeagullConstants::SFXVolume);

	// Track active SFX (simplified -- no callback on completion)
	if (Count)
	{
		(*Count)++;
	}
	else
	{
		ActiveSFXCount.Add(Sound, 1);
	}

	// Reset count after a short time (simplified approach)
	FTimerHandle Handle;
	World->GetTimerManager().SetTimer(Handle, [this, Sound]()
	{
		int32* C = ActiveSFXCount.Find(Sound);
		if (C && *C > 0) (*C)--;
	}, 0.3f, false);
}

void USeagullAudioManager::CrossfadeToTrack(USoundWave* NewTrack, UWorld* World)
{
	if (!NewTrack || !World) return;
	if (CurrentMusicTrack == NewTrack) return;

	// Fade out current track
	if (MusicComponent)
	{
		MusicComponent->FadeOut(SeagullConstants::MusicCrossfadeDuration, 0.f);
	}

	// Start new track after crossfade duration
	USoundWave* TrackToPlay = NewTrack;
	FTimerHandle CrossfadeTimer;
	World->GetTimerManager().SetTimer(CrossfadeTimer, [this, TrackToPlay, World]()
	{
		if (MusicComponent)
		{
			MusicComponent->Stop();
			MusicComponent = nullptr;
		}
		MusicComponent = UGameplayStatics::CreateSound2D(World, TrackToPlay, 0.f, 1.0f, 0.f, nullptr, false, true);
		if (MusicComponent)
		{
			MusicComponent->Play();
			MusicComponent->FadeIn(SeagullConstants::MusicCrossfadeDuration, SeagullConstants::MusicVolume);
		}
		CurrentMusicTrack = TrackToPlay;
	}, SeagullConstants::MusicCrossfadeDuration, false);
}

int32 USeagullAudioManager::GetMaxPolyphony(USoundWave* Sound) const
{
	if (Sound == SFX_PickupXP) return SeagullConstants::MaxSFXPickupXP;
	if (Sound == SFX_EnemyHit) return SeagullConstants::MaxSFXEnemyHit;
	return 10; // Default max
}
