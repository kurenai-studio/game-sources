// Fill out your copyright notice in the Description page of Project Settings.


#include "ToonTanks/GameMode/ToonTanksGameMode.h"
#include "ToonTanks/Tank.h"
#include "ToonTanks/Tower.h"
#include "Kismet/GameplayStatics.h"
#include "ToonTanks/ToonTanksPlayerController.h"

void AToonTanksGameMode::BeginPlay()
{
	Super::BeginPlay();
	
	HandleGameStart();
}

/// Manages TowerCount decrease and Tank/Player death condition
/// @param DeadActor 
void AToonTanksGameMode::ActorDied(AActor* DeadActor)
{
	if(DeadActor == Tank)
	{
		Tank->HandleDestruction();
		if(ToonTanksPlayerController)
		{
			ToonTanksPlayerController->SetPlayerEnabledState(false);
		}
		GameOver(false);
	}
	else if(ATower* DestroyedTower = Cast<ATower>(DeadActor))
	{
		DestroyedTower->HandleDestruction();
		TargetTowers--;
		if(TargetTowers == 0)
		{
			GameOver(true);
		}
	}
}

void AToonTanksGameMode::HandleGameStart()
{
	TargetTowers = GetTargetTowerCount();
	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	ToonTanksPlayerController = Cast<AToonTanksPlayerController>(UGameplayStatics::GetPlayerController(this, 0));

	StartGame();
	
	if(ToonTanksPlayerController)
	{
		ToonTanksPlayerController->SetPlayerEnabledState(false);

		FTimerHandle PlayerEnableTimerHandle;
		FTimerDelegate PlayerEnableTimerDelegate = FTimerDelegate::CreateUObject(ToonTanksPlayerController, &AToonTanksPlayerController::SetPlayerEnabledState, true);
		GetWorldTimerManager().SetTimer(
			PlayerEnableTimerHandle,
			PlayerEnableTimerDelegate,
			StartDelay,
			false);
	}
}

/// Used to assign initial tower count in BeginPlay and check WinCondition
/// @return Number of Towers in the game 
int32 AToonTanksGameMode::GetTargetTowerCount()
{
	TArray<AActor*> Towers;
	UGameplayStatics::GetAllActorsOfClass(this, ATower::StaticClass(), Towers);
	return Towers.Num();
}