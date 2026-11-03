#include "Game/CoinRunGameMode.h"

#include "Engine/World.h"
#include "Game/CoinRunDirector.h"
#include "Game/CoinRunHUD.h"
#include "Game/CoinRunPawn.h"

ACoinRunGameMode::ACoinRunGameMode()
{
	DefaultPawnClass = ACoinRunPawn::StaticClass();
	HUDClass = ACoinRunHUD::StaticClass();
}

void ACoinRunGameMode::StartPlay()
{
	Super::StartPlay();

	if (UWorld* World = GetWorld())
	{
		World->SpawnActor<ACoinRunDirector>(FVector::ZeroVector, FRotator::ZeroRotator);
	}
}
