// Copyright (c) 2026 Arena Runner contributors. MIT licensed.

#include "ArenaGameMode.h"

#include "ArenaCharacter.h"
#include "ArenaCollectible.h"
#include "ArenaGameState.h"
#include "ArenaHunter.h"
#include "ArenaHUD.h"
#include "ArenaPlayerController.h"
#include "ArenaGameInstance.h"
#include "ArenaSaveGame.h"

#include "CollisionQueryParams.h"
#include "Components/LightComponent.h"
#include "Engine/DamageEvents.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "TimerManager.h"
#include "UObject/ConstructorHelpers.h"

AArenaGameMode::AArenaGameMode()
{
	DefaultPawnClass = AArenaCharacter::StaticClass();
	PlayerControllerClass = AArenaPlayerController::StaticClass();
	GameStateClass = AArenaGameState::StaticClass();
	HUDClass = AArenaHUD::StaticClass();
}

void AArenaGameMode::BeginPlay()
{
	Super::BeginPlay();

	// Restore persisted best score.
	if (UGameplayStatics::DoesSaveGameExist(TEXT("ArenaRunnerSave"), 0))
	{
		SaveGame = Cast<UArenaSaveGame>(UGameplayStatics::LoadGameFromSlot(TEXT("ArenaRunnerSave"), 0));
	}
	if (!SaveGame)
	{
		SaveGame = Cast<UArenaSaveGame>(UGameplayStatics::CreateSaveGameObject(UArenaSaveGame::StaticClass()));
	}

	if (AArenaGameState* ArenaState = GetArenaGameState())
	{
		ArenaState->BestScore = SaveGame ? SaveGame->BestScore : 0;
	}

	BuildArena();
	StartRun();
}

// ---------------------------------------------------------------------------
// Arena construction
// ---------------------------------------------------------------------------

void AArenaGameMode::BuildArena()
{
	CreateArenaFloor();
	CreateArenaWalls();
	CreateBorderMarkers();
	CreateLighting();
}

void AArenaGameMode::CreateArenaFloor()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	UStaticMesh* CubeMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (!CubeMesh)
	{
		return;
	}

	// A single thick cube acts as the floor (100 uu cube scaled up).
	const float FloorScaleXY = (ArenaRadius * 2.f + 400.f) / 100.f;
	const float FloorThickness = 1.0f;
	const float FloorCenterZ = -(FloorThickness * 100.f) * 0.5f;

	AStaticMeshActor* Floor = World->SpawnActor<AStaticMeshActor>(
		FVector(0.f, 0.f, FloorCenterZ), FRotator::ZeroRotator);
	if (Floor)
	{
		Floor->SetMobility(EComponentMobility::Movable);
		Floor->GetStaticMeshComponent()->SetStaticMesh(CubeMesh);
		Floor->GetStaticMeshComponent()->SetWorldScale3D(FVector(FloorScaleXY, FloorScaleXY, FloorThickness));
		Floor->GetStaticMeshComponent()->SetCollisionProfileName(TEXT("BlockAll"));

		if (UMaterialInterface* BaseMaterial = Floor->GetStaticMeshComponent()->GetMaterial(0))
		{
			if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, Floor))
			{
				MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.10f, 0.12f, 0.16f));
				Floor->GetStaticMeshComponent()->SetMaterial(0, MID);
			}
		}
	}
}

void AArenaGameMode::CreateArenaWalls()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	UStaticMesh* CubeMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (!CubeMesh)
	{
		return;
	}

	const int32 Segments = FMath::Max(8, WallSegments);
	const int32 TotalSegments = Segments * 2; // two arcs to form a full ring
	const float ArcLength = 2.f * PI * ArenaRadius;
	const float SegmentLength = ArcLength / static_cast<float>(TotalSegments) + 45.f;
	const float HalfHeight = WallHeight * 0.5f;

	for (int32 Index = 0; Index < TotalSegments; ++Index)
	{
		const float Angle = (2.f * PI * static_cast<float>(Index)) / static_cast<float>(TotalSegments);
		const FVector Direction(FMath::Cos(Angle), FMath::Sin(Angle), 0.f);
		const FVector Location = Direction * ArenaRadius + FVector(0.f, 0.f, HalfHeight);
		const FRotator Rotation(0.f, FMath::RadiansToDegrees(Angle) + 90.f, 0.f);

		AStaticMeshActor* WallSegment = World->SpawnActor<AStaticMeshActor>(Location, Rotation);
		if (!WallSegment)
		{
			continue;
		}

		WallSegment->SetMobility(EComponentMobility::Movable);
		WallSegment->GetStaticMeshComponent()->SetStaticMesh(CubeMesh);
		WallSegment->GetStaticMeshComponent()->SetWorldScale3D(FVector(SegmentLength / 100.f, 0.6f, WallHeight / 100.f));
		WallSegment->GetStaticMeshComponent()->SetCollisionProfileName(TEXT("BlockAll"));

		if (UMaterialInterface* BaseMaterial = WallSegment->GetStaticMeshComponent()->GetMaterial(0))
		{
			if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, WallSegment))
			{
				const bool bAccent = (Index % 5) == 0;
				const FLinearColor Color = bAccent
					? FLinearColor(0.10f, 0.55f, 1.0f)
					: FLinearColor(0.20f, 0.23f, 0.29f);
				MID->SetVectorParameterValue(TEXT("Color"), Color);
				WallSegment->GetStaticMeshComponent()->SetMaterial(0, MID);
			}
		}
	}
}

void AArenaGameMode::CreateBorderMarkers()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	UStaticMesh* CylinderMesh = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (!CylinderMesh)
	{
		return;
	}

	// Decorative pylons inside the ring, they also give the arena a sense of scale.
	const int32 MarkerCount = 12;
	for (int32 Index = 0; Index < MarkerCount; ++Index)
	{
		const float Angle = (2.f * PI * static_cast<float>(Index)) / static_cast<float>(MarkerCount);
		const FVector Direction(FMath::Cos(Angle), FMath::Sin(Angle), 0.f);
		const FVector Location = Direction * (ArenaRadius - 260.f) + FVector(0.f, 0.f, 150.f);

		AStaticMeshActor* Pylon = World->SpawnActor<AStaticMeshActor>(Location, FRotator::ZeroRotator);
		if (!Pylon)
		{
			continue;
		}

		Pylon->SetMobility(EComponentMobility::Movable);
		Pylon->GetStaticMeshComponent()->SetStaticMesh(CylinderMesh);
		Pylon->GetStaticMeshComponent()->SetWorldScale3D(FVector(0.55f, 0.55f, 3.0f));
		Pylon->GetStaticMeshComponent()->SetCollisionProfileName(TEXT("BlockAll"));

		if (UMaterialInterface* BaseMaterial = Pylon->GetStaticMeshComponent()->GetMaterial(0))
		{
			if (UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(BaseMaterial, Pylon))
			{
				MID->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.85f, 0.35f, 0.05f));
				Pylon->GetStaticMeshComponent()->SetMaterial(0, MID);
			}
		}
	}
}

void AArenaGameMode::CreateLighting()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	// Sun. If the map already has one, we just add a second cheap light — harmless.
	FActorSpawnParameters SpawnParams;
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	ADirectionalLight* Sun = World->SpawnActor<ADirectionalLight>(
		FVector(0.f, 0.f, 2000.f),
		FRotator(-42.f, 35.f, 0.f),
		SpawnParams);

	if (Sun && Sun->GetLightComponent())
	{
		Sun->GetLightComponent()->SetMobility(EComponentMobility::Movable);
		Sun->GetLightComponent()->SetIntensity(7.f);
	}

	// Fill light from the opposite side: there is no sky light in an empty map,
	// without it every shadowed face would be pure black.
	ADirectionalLight* FillLight = World->SpawnActor<ADirectionalLight>(
		FVector(0.f, 0.f, 1800.f),
		FRotator(-18.f, 215.f, 0.f),
		SpawnParams);

	if (FillLight && FillLight->GetLightComponent())
	{
		FillLight->GetLightComponent()->SetMobility(EComponentMobility::Movable);
		FillLight->GetLightComponent()->SetIntensity(2.2f);
		FillLight->GetLightComponent()->SetLightColor(FLinearColor(0.55f, 0.70f, 1.0f));
	}

}

// ---------------------------------------------------------------------------
// Run / wave flow
// ---------------------------------------------------------------------------

void AArenaGameMode::StartRun()
{
	AArenaGameState* ArenaState = GetArenaGameState();
	if (!ArenaState)
	{
		return;
	}

	ArenaState->Score = 0;
	ArenaState->Wave = 1;
	ArenaState->Collected = 0;
	ArenaState->TotalCollectibles = 0;

	ClearWave();

	if (AArenaCharacter* Character = GetArenaCharacter())
	{
		Character->ResetForRun(SpawnLocation, SpawnRotation);
	}
	else if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		if (APawn* Pawn = PC->GetPawn())
		{
			Pawn->SetActorLocationAndRotation(SpawnLocation, SpawnRotation);
		}
	}

	StartWave();
}

void AArenaGameMode::StartWave()
{
	AArenaGameState* ArenaState = GetArenaGameState();
	if (!ArenaState || !GetWorld())
	{
		return;
	}

	const int32 WaveNumber = FMath::Max(1, ArenaState->Wave);
	const int32 Count = FMath::Clamp(
		FMath::RoundToInt(BaseCollectibleCount + CollectiblesPerWave * static_cast<float>(WaveNumber - 1)),
		1,
		MaxCollectiblesPerWave);

	ArenaState->Collected = 0;
	ArenaState->TotalCollectibles = Count;

	FCollisionQueryParams QueryParams = GetArenaQueryParams();
	const float MinDistanceFromPlayer = 600.f;
	const float MinDistanceFromCore = 320.f;

	for (int32 Index = 0; Index < Count; ++Index)
	{
		FVector Spot = FVector::ZeroVector;
		bool bFoundSpot = false;

		for (int32 Attempt = 0; Attempt < 30 && !bFoundSpot; ++Attempt)
		{
			const float Angle = FMath::FRandRange(0.f, 2.f * PI);
			const float Radius = FMath::FRandRange(500.f, ArenaRadius - 520.f);
			const FVector Candidate(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius, 170.f);

			if (FVector::Dist2D(Candidate, SpawnLocation) < MinDistanceFromPlayer)
			{
				continue;
			}

			bool bTooClose = false;
			for (const TObjectPtr<AArenaCollectible>& Existing : ActiveCollectibles)
			{
				if (Existing && FVector::Dist2D(Existing->GetActorLocation(), Candidate) < MinDistanceFromCore)
				{
					bTooClose = true;
					break;
				}
			}
			if (bTooClose)
			{
				continue;
			}

			FHitResult Hit;
			const FVector TraceStart = Candidate + FVector(0.f, 0.f, 400.f);
			const FVector TraceEnd = Candidate - FVector(0.f, 0.f, 600.f);
			if (GetWorld()->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, ECC_Visibility, QueryParams))
			{
				Spot = Hit.ImpactPoint + FVector(0.f, 0.f, 110.f);
				bFoundSpot = true;
			}
		}

		if (!bFoundSpot)
		{
			const float Angle = FMath::FRandRange(0.f, 2.f * PI);
			const float Radius = FMath::FRandRange(500.f, ArenaRadius - 520.f);
			Spot = FVector(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius, 110.f);
		}

		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		AArenaCollectible* Collectible = GetWorld()->SpawnActor<AArenaCollectible>(
			Spot, FRotator::ZeroRotator, Params);

		if (Collectible)
		{
			Collectible->SetOwningGameMode(this);
			Collectible->SetOrbitPhase(FMath::FRandRange(0.f, 2.f * PI));
			ActiveCollectibles.Add(Collectible);
		}
	}

	ArenaState->TotalCollectibles = ActiveCollectibles.Num();

	if (ActiveCollectibles.Num() == 0)
	{
		Notify(TEXT("No spawn points found - does the map have a floor?"), FLinearColor(1.f, 0.6f, 0.2f), 5.f);
	}

	SpawnHunters(WaveNumber);
	Notify(FString::Printf(TEXT("WAVE %d"), WaveNumber), FLinearColor(0.55f, 0.9f, 1.f), 1.6f);
}

void AArenaGameMode::SpawnHunters(int32 WaveNumber)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	const int32 DesiredTotal = FMath::Clamp(WaveNumber - FirstHunterWave + 1, 0, MaxHunters);
	const float Speed = FMath::Min(
		HunterBaseSpeed + HunterSpeedPerWave * static_cast<float>(FMath::Max(0, WaveNumber - FirstHunterWave)),
		HunterMaxSpeed);

	APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0);

	// Drop stale entries, then upgrade the hunters that survived the previous wave.
	ActiveHunters.RemoveAll([](const TObjectPtr<AArenaHunter>& Hunter) { return !IsValid(Hunter); });
	for (const TObjectPtr<AArenaHunter>& Existing : ActiveHunters)
	{
		Existing->SetChaseSpeed(Speed);
		Existing->SetTarget(PlayerPawn);
	}

	const int32 ToSpawn = FMath::Max(0, DesiredTotal - ActiveHunters.Num());
	if (ToSpawn == 0)
	{
		return;
	}

	for (int32 Index = 0; Index < ToSpawn; ++Index)
	{
		FVector Spot = FVector::ZeroVector;
		bool bFoundSpot = false;

		for (int32 Attempt = 0; Attempt < 20 && !bFoundSpot; ++Attempt)
		{
			const float Angle = FMath::FRandRange(0.f, 2.f * PI);
			const float Radius = FMath::FRandRange(ArenaRadius * 0.45f, ArenaRadius - 320.f);
			const FVector Candidate(FMath::Cos(Angle) * Radius, FMath::Sin(Angle) * Radius, 110.f);

			if (PlayerPawn && FVector::Dist2D(Candidate, PlayerPawn->GetActorLocation()) < 900.f)
			{
				continue;
			}

			Spot = Candidate;
			bFoundSpot = true;
		}

		if (!bFoundSpot)
		{
			Spot = FVector(ArenaRadius * 0.6f, 0.f, 110.f);
		}

		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

		AArenaHunter* Hunter = World->SpawnActor<AArenaHunter>(Spot, FRotator::ZeroRotator, Params);
		if (Hunter)
		{
			Hunter->SetChaseSpeed(Speed);
			Hunter->SetContactDamage(HunterContactDamage);
			Hunter->SetTarget(PlayerPawn);
			ActiveHunters.Add(Hunter);
		}
	}

	Notify(
		FString::Printf(TEXT("%d HUNTER%s ACTIVE"), ActiveHunters.Num(), ActiveHunters.Num() == 1 ? TEXT("") : TEXT("S")),
		FLinearColor(1.f, 0.45f, 0.25f),
		2.f);
}

void AArenaGameMode::ClearWave()
{
	for (const TObjectPtr<AArenaCollectible>& Collectible : ActiveCollectibles)
	{
		if (IsValid(Collectible))
		{
			Collectible->Destroy();
		}
	}
	ActiveCollectibles.Reset();

	for (const TObjectPtr<AArenaHunter>& Hunter : ActiveHunters)
	{
		if (IsValid(Hunter))
		{
			Hunter->Destroy();
		}
	}
	ActiveHunters.Reset();

	if (GetWorld())
	{
		GetWorld()->GetTimerManager().ClearTimer(WaveTimer);
	}
}

void AArenaGameMode::HandleCollectibleCollected(AArenaCollectible* Collectible)
{
	if (!IsValid(Collectible))
	{
		return;
	}

	ActiveCollectibles.Remove(Collectible);
	Collectible->Destroy();

	AArenaGameState* ArenaState = GetArenaGameState();
	if (!ArenaState)
	{
		return;
	}

	ArenaState->Score += ScorePerCollectible;
	ArenaState->Collected = FMath::Min(ArenaState->Collected + 1, ArenaState->TotalCollectibles);

	if (ActiveCollectibles.Num() > 0)
	{
		Notify(
			FString::Printf(TEXT("Core %d / %d"), ArenaState->Collected, ArenaState->TotalCollectibles),
			FLinearColor(0.4f, 0.9f, 1.f),
			1.2f);
		return;
	}

	// Wave cleared.
	ArenaState->Score += WaveClearBonus;
	ArenaState->Wave += 1;
	Notify(FString::Printf(TEXT("WAVE CLEAR  +%d"), WaveClearBonus), FLinearColor(0.2f, 1.f, 0.55f), 2.5f);

	if (GetWorld())
	{
		GetWorld()->GetTimerManager().SetTimer(
			WaveTimer, this, &AArenaGameMode::StartWave, 1.4f, false);
	}
}

void AArenaGameMode::HandlePlayerDied()
{
	AArenaGameState* ArenaState = GetArenaGameState();
	if (ArenaState && ArenaState->Score > ArenaState->BestScore)
	{
		ArenaState->BestScore = ArenaState->Score;
		SaveBestScore();
	}

	if (ArenaState)
	{
		if (UArenaGameInstance* GameInstance = GetGameInstance<UArenaGameInstance>())
		{
			GameInstance->AddRunScore(ArenaState->Score);
		}
	}

	Notify(TEXT("GAME OVER"), FLinearColor(1.f, 0.25f, 0.25f), 3.f);
	EndRun(RestartDelay);
}

void AArenaGameMode::EndRun(float Delay)
{
	if (!GetWorld())
	{
		return;
	}

	GetWorld()->GetTimerManager().ClearTimer(RestartTimer);
	GetWorld()->GetTimerManager().SetTimer(
		RestartTimer, this, &AArenaGameMode::StartRun, FMath::Max(0.2f, Delay), false);
}

void AArenaGameMode::SaveBestScore()
{
	AArenaGameState* ArenaState = GetArenaGameState();
	if (!ArenaState)
	{
		return;
	}

	if (!SaveGame)
	{
		SaveGame = Cast<UArenaSaveGame>(UGameplayStatics::CreateSaveGameObject(UArenaSaveGame::StaticClass()));
	}

	if (SaveGame)
	{
		SaveGame->BestScore = ArenaState->BestScore;
		UGameplayStatics::SaveGameToSlot(SaveGame, TEXT("ArenaRunnerSave"), 0);
	}
}

void AArenaGameMode::Notify(const FString& Message, FLinearColor Color, float Duration)
{
	AArenaGameState* ArenaState = GetArenaGameState();
	if (!ArenaState)
	{
		return;
	}

	// Broadcast is defined on the HUD; we go through the player controller to be safe
	// even if the HUD has not been created yet.
	if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		if (AArenaHUD* HUD = Cast<AArenaHUD>(PC->GetHUD()))
		{
			HUD->ShowMessage(Message, Color, Duration);
		}
	}
}

FVector AArenaGameMode::GetPlayerSpawnLocation() const
{
	return SpawnLocation;
}

AArenaGameState* AArenaGameMode::GetArenaGameState() const
{
	return GetWorld() ? GetWorld()->GetGameState<AArenaGameState>() : nullptr;
}

AArenaCharacter* AArenaGameMode::GetArenaCharacter() const
{
	return GetWorld() ? Cast<AArenaCharacter>(UGameplayStatics::GetPlayerPawn(this, 0)) : nullptr;
}

FCollisionQueryParams AArenaGameMode::GetArenaQueryParams() const
{
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ArenaSpawnTrace), false);
	if (const AArenaCharacter* Character = GetArenaCharacter())
	{
		Params.AddIgnoredActor(Character);
	}
	return Params;
}
