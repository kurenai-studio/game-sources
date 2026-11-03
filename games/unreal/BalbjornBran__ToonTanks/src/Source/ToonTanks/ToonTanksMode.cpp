// Created by Balbjorn Bran.


#include "ToonTanksMode.h"
#include "kismet/GameplayStatics.h"
#include "Tank.h"
#include "TankController.h"
#include "Tower.h"

void AToonTanksMode::ActorDied(AActor* DeadActor)
{
	if (DeadActor == PlayerTank)
	{
		PlayerTank->HandleDestruction();
		if (PlayerTankController)
		{
			PlayerTankController->SetPlayerEnabledState(false);
		}
		GameOver(false);
	}
	else if (ATower* DestroyedTower = Cast<ATower>(DeadActor))
	{
		DestroyedTower->HandleDestruction();
		NumTowersAlive--;
		if (NumTowersAlive == 0)
		{
			GameOver(true);
		}
	}
}

void AToonTanksMode::BeginPlay()
{
	Super::BeginPlay();

	HandleGameStart();
	
}

void AToonTanksMode::HandleGameStart()
{
	NumTowersAlive = GetTowersAlive();
	PlayerTank = Cast<ATank>(UGameplayStatics::GetPlayerPawn(this, 0));
	PlayerTankController = Cast<ATankController>(PlayerTank->GetController());

	StartGame();
	
	if (PlayerTankController)
	{
		// Disable player controls initially
		PlayerTankController->SetPlayerEnabledState(false);

		// Prepare Timer Handle
		FTimerHandle StartTimerHandle;

		// Create a delegate that enables player controls
		FTimerDelegate TimerDelegate;
		TimerDelegate.BindUObject(PlayerTankController, &ATankController::SetPlayerEnabledState, true);

		// Set a timer with the delegate and a delay
		GetWorld()->GetTimerManager().SetTimer(StartTimerHandle, TimerDelegate, StartDelay, false);
	}
	
}

int32 AToonTanksMode::GetTowersAlive()
{
	TArray<AActor*> TowersAlive;
	UGameplayStatics::GetAllActorsOfClass(this,ATower::StaticClass(),TowersAlive);
	return TowersAlive.Num();
}
