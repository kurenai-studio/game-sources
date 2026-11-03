// Fill out your copyright notice in the Description page of Project Settings.


#include "ToonTanksGameMode.h"
#include "Kismet/GameplayStatics.h"
#include "Tank.h"
#include "Turret.h"
#include "ToonTanksPlayerController.h"

void AToonTanksGameMode::BeginPlay()
{
	Super::BeginPlay();

	HandleGameStart();
}

void AToonTanksGameMode::ActorDied(AActor* deadActor)
{
	if (deadActor == Tank)
	{
		Tank->HandleDestruction();

		if (ToonTanksPlayerController)
			ToonTanksPlayerController->SetPlayerEnabledState(false);

		GameOver(false);
	}
	else if (ATurret* destroyedTower = Cast<ATurret>(deadActor))
	{
		destroyedTower->HandleDestruction();
		TargetTowers--;
		if (TargetTowers <= 0)
		{
			GameOver(true);
		}
	}

	FTimerDelegate timerDel = FTimerDelegate::CreateUObject(this, &AToonTanksGameMode::BeginPlay);
}

void AToonTanksGameMode::HandleGameStart()
{
	TargetTowers = GetTargetTurretCount();
	Tank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	ToonTanksPlayerController = Cast<AToonTanksPlayerController>(UGameplayStatics::GetPlayerController(this, 0));
	
	StartGame();

	if (ToonTanksPlayerController)
	{
		ToonTanksPlayerController->SetPlayerEnabledState(false);
		
		FTimerHandle playerEnableTimerHandle;
		FTimerDelegate playerEnableTimerDelegate = FTimerDelegate::CreateUObject(
			ToonTanksPlayerController,
			&AToonTanksPlayerController::SetPlayerEnabledState,
			true
		);
		GetWorldTimerManager().SetTimer(playerEnableTimerHandle, playerEnableTimerDelegate, StartDelay, false);
	}
}

int8 AToonTanksGameMode::GetTargetTurretCount()
{
	TArray<AActor*> turrets;
	UGameplayStatics::GetAllActorsOfClass(this, ATurret::StaticClass(), turrets);
	return turrets.Num();
}
